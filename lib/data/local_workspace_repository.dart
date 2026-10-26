import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../domain/workspace.dart';
import 'database.dart';
import 'workspace_storage.dart';
import '../services/file_formats.dart';
import '../domain/ingest.dart';
part 'ingest_repository.dart';

class LocalWorkspaceRepository implements WorkspaceRepository {
  LocalWorkspaceRepository._(
    this.root,
    this.database,
    this._now,
    this._pdfTextExtractor,
    this._lease,
  );
  final Future<String?> Function(String)? _pdfTextExtractor;
  final Directory root;
  final WorkspaceLease _lease;
  bool _closed = false;
  final WorkspaceDatabase database;
  final DateTime Function() _now;
  final _uuid = const Uuid();
  Future<void> _pending = Future.value();

  static Future<LocalWorkspaceRepository> open(
    Directory root, {
    DateTime Function()? now,
    Future<String?> Function(String)? pdfTextExtractor,
    bool create = true,
  }) async {
    final lease = await WorkspaceStorage.acquire(root, create: create);
    root = lease.root;
    WorkspaceDatabase? db;
    try {
      await Directory(p.join(root.path, 'notes')).create(recursive: true);
      await Directory(p.join(root.path, 'files')).create(recursive: true);
      db = WorkspaceDatabase(
        NativeDatabase.createInBackground(
          File(p.join(root.path, 'workspace.sqlite')),
        ),
      );
      final repo = LocalWorkspaceRepository._(
        root,
        db,
        now ?? DateTime.now,
        pdfTextExtractor,
        lease,
      );
      await repo._recoverPurges();
      await repo._backfillArchives();
      await repo._rebuildIndex();
      return repo;
    } catch (_) {
      await db?.close();
      await lease.close();
      rethrow;
    }
  }

  // Serialize application mutations, including backup, to avoid partial views.
  final Object _operationZone = Object();

  @override
  Future<T> exclusive<T>(Future<T> Function() operation) => _write(operation);

  @override
  Future<EntrySnapshot> readSnapshot(String id) => _write(
    () async => EntrySnapshot(
      _entry(await _require(id, includeTrash: true)),
      await readNote(id),
    ),
  );

  @override
  Future<EntrySnapshot> saveSnapshot({
    required String id,
    required int expectedRevision,
    required String expectedBodyHash,
    required EntryDraft draft,
  }) => _write(() async {
    await _save(
      id: id,
      expectedRevision: expectedRevision,
      expectedBodyHash: expectedBodyHash,
      draft: draft,
    );
    return readSnapshot(id);
  });

  Future<T> _write<T>(Future<T> Function() operation) {
    if (Zone.current[_operationZone] == this) return operation();
    if (_closed) {
      return Future.error(
        const WorkspaceException('Arbeitsbereich geschlossen.'),
      );
    }
    final next = _pending.then(
      (_) => runZoned(operation, zoneValues: {_operationZone: this}),
    );
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  TaskContext _contextDefinition(TaskContextRow row) => TaskContext(
    id: row.id,
    name: row.name,
    color: row.color,
    active: row.active,
    position: row.position,
  );
  SimpleSelectStatement<TaskContexts, TaskContextRow> _contextQuery() =>
      database.select(database.taskContexts)..orderBy([
        (e) => OrderingTerm.asc(e.position),
        (e) => OrderingTerm.asc(e.name),
      ]);
  @override
  Stream<List<TaskContext>> watchContexts() => _contextQuery().watch().map(
    (rows) => rows.map(_contextDefinition).toList(),
  );
  @override
  Future<List<TaskContext>> getContexts() async =>
      (await _contextQuery().get()).map(_contextDefinition).toList();

  @override
  Future<TaskContext> saveContext({
    String? id,
    required String name,
    required int color,
    bool active = true,
    int? position,
  }) => _write(() async {
    final title = _title(name), all = await getContexts();
    if (color < 0 || color > 0xffffffff) {
      throw const WorkspaceException('Ungültige Kontextfarbe.');
    }
    final currentName = all.where((e) => e.id == id).firstOrNull?.name;
    if (currentName != title &&
        all.any(
          (e) => e.id != id && e.name.toLowerCase() == title.toLowerCase(),
        )) {
      throw const WorkspaceException(
        'Ein Kontext mit diesem Namen ist bereits vorhanden.',
      );
    }
    if (id != null && !all.any((e) => e.id == id)) {
      throw const WorkspaceException('Der Kontext wurde nicht gefunden.');
    }
    final contextId = id ?? _uuid.v4();
    await database.transaction(() async {
      if (id == null) {
        await database
            .into(database.taskContexts)
            .insert(
              TaskContextsCompanion.insert(
                id: contextId,
                name: title,
                color: color,
                active: Value(active),
                position: all.length,
              ),
            );
      } else {
        await (database.update(
          database.taskContexts,
        )..where((e) => e.id.equals(id))).write(
          TaskContextsCompanion(
            name: Value(title),
            color: Value(color),
            active: Value(active),
          ),
        );
      }
      if (position != null) {
        final order = all
            .where((e) => e.id != contextId)
            .map((e) => e.id)
            .toList();
        order.insert(position.clamp(0, order.length), contextId);
        for (var i = 0; i < order.length; i++) {
          await (database.update(database.taskContexts)
                ..where((e) => e.id.equals(order[i])))
              .write(TaskContextsCompanion(position: Value(i)));
        }
      }
      if (id != null && all.firstWhere((e) => e.id == id).name != title) {
        final definitions = {for (final e in await getContexts()) e.id: e.name};
        for (final row in await database.select(database.entries).get()) {
          final ids = (jsonDecode(row.contextIds) as List).cast<String>();
          if (!ids.contains(id)) continue;
          await (database.update(
            database.entries,
          )..where((e) => e.id.equals(row.id))).write(
            EntriesCompanion(
              context: Value(ids.map((id) => definitions[id]!).join(', ')),
              revision: Value(row.revision + 1),
              updatedAt: Value(_now().toUtc()),
            ),
          );
        }
      }
    });
    return (await getContexts()).firstWhere((e) => e.id == contextId);
  });

  Future<(List<String>, String)> _taskContextSelection(
    EntryDraft draft, {
    EntryRow? previous,
  }) async {
    final all = await getContexts();
    var ids = draft.contextIds?.toSet().toList();
    if (ids == null) {
      if (previous != null && draft.context == previous.context) {
        ids = (jsonDecode(previous.contextIds) as List).cast<String>();
      } else if (draft.context.trim().isEmpty) {
        ids = [];
      } else {
        final name = draft.context.trim();
        var definition = all.where((e) => e.name == name).firstOrNull;
        if (definition == null) {
          final id = _uuid.v4();
          await database
              .into(database.taskContexts)
              .insert(
                TaskContextsCompanion.insert(
                  id: id,
                  name: name,
                  color: contextColors[all.length % contextColors.length],
                  position: all.length,
                ),
              );
          definition = TaskContext(
            id: id,
            name: name,
            color: contextColors[all.length % contextColors.length],
          );
          all.add(definition);
        }
        ids = [definition.id];
      }
    }
    final prior = previous == null
        ? <String>[]
        : (jsonDecode(previous.contextIds) as List).cast<String>();
    for (final id in ids) {
      final definition = all.where((e) => e.id == id).firstOrNull;
      if (definition == null || !definition.active && !prior.contains(id)) {
        throw const WorkspaceException(
          'Ein gewählter Kontext ist nicht verfügbar. Bitte Auswahl aktualisieren.',
        );
      }
    }
    return (
      ids,
      ids.map((id) => all.firstWhere((e) => e.id == id).name).join(', '),
    );
  }

  @override
  Future<String?> readSetting(String key) async => (await (database.select(
    database.workspaceSettings,
  )..where((e) => e.key.equals(key))).getSingleOrNull())?.value;
  @override
  Future<void> writeSetting(String key, String value) => _write(() async {
    await database
        .into(database.workspaceSettings)
        .insert(
          WorkspaceSettingsCompanion.insert(key: key, value: value),
          mode: InsertMode.insertOrReplace,
        );
  });

  Entry _entry(EntryRow row) => Entry(
    id: row.id,
    title: row.title,
    kind: EntryKind.values.byName(row.kind),
    section: ParaSection.values.byName(row.section),
    parentId: row.parentId,
    archived: row.archived,
    completed: row.completed,
    taskState: TaskState.values.byName(row.taskState),
    deletedAt: row.deletedAt,
    trashBatchId: row.trashBatchId,
    trashLocation: row.trashLocation,
    trashArchived: row.trashArchived,
    previousTaskState: row.previousTaskState == null
        ? null
        : TaskState.values.byName(row.previousTaskState!),
    context: row.context,
    contextIds: (jsonDecode(row.contextIds) as List).cast<String>(),
    estimatedMinutes: row.estimatedMinutes,
    energy: row.energy == null ? null : EnergyLevel.values.byName(row.energy!),
    goal: row.goal,
    dueDate: row.dueDate == null ? null : DateTime.parse(row.dueDate!),
    revision: row.revision,
    updatedAt: row.updatedAt,
    fileName: row.fileName,
    fileSize: row.fileSize,
    searchText: row.searchText,
    archivedAt: row.archivedAt,
    archiveLocation: row.archiveLocation == null
        ? null
        : _decodeArchiveLocation(row.archiveLocation!),
  );

  String _encodeArchiveLocation(ArchiveLocation location) => jsonEncode({
    'year': location.year,
    'section': location.section.name,
    'someday': location.someday,
    'ancestors': location.ancestors
        .map((e) => {'id': e.id, 'title': e.title, 'kind': e.kind.name})
        .toList(),
  });

  ArchiveLocation _decodeArchiveLocation(String value) {
    final data = jsonDecode(value) as Map<String, dynamic>;
    return ArchiveLocation(
      year: data['year'] as int,
      section: ParaSection.values.byName(data['section'] as String),
      someday: data['someday'] == true,
      ancestors: (data['ancestors'] as List).map((value) {
        final item = value as Map<String, dynamic>;
        return ArchiveAncestor(
          id: item['id'] as String,
          title: item['title'] as String,
          kind: EntryKind.values.byName(item['kind'] as String),
        );
      }).toList(),
    );
  }

  Future<void> _backfillArchives() async {
    final rows = await _query().get();
    final all = rows.map(_entry).toList();
    await database.transaction(() async {
      for (final row in rows.where(
        (e) => e.archived && e.archiveLocation == null,
      )) {
        final at = row.archivedAt ?? row.updatedAt;
        final location = archiveLocationFor(_entry(row), all, at);
        await (database.update(
          database.entries,
        )..where((e) => e.id.equals(row.id))).write(
          EntriesCompanion(
            archivedAt: Value(at),
            archiveLocation: Value(_encodeArchiveLocation(location)),
          ),
        );
      }
    });
  }

  SimpleSelectStatement<Entries, EntryRow> _query() =>
      database.select(database.entries)
        ..where((e) => e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.desc(e.updatedAt)]);

  @override
  Stream<List<Entry>> watchEntries() =>
      _query().watch().map((rows) => rows.map(_entry).toList());
  @override
  Future<List<Entry>> getEntries() async =>
      (await _query().get()).map(_entry).toList();

  SimpleSelectStatement<Entries, EntryRow> _trashQuery() =>
      database.select(database.entries)
        ..where((e) => e.deletedAt.isNotNull())
        ..orderBy([(e) => OrderingTerm.desc(e.deletedAt)]);

  @override
  Stream<List<Entry>> watchTrash() =>
      _trashQuery().watch().map((rows) => rows.map(_entry).toList());
  @override
  Future<List<Entry>> getTrash() async =>
      (await _trashQuery().get()).map(_entry).toList();

  ArchiveLocation _trashArchiveLocation(
    Entry entry,
    List<Entry> all,
    DateTime at,
  ) {
    if (entry.archiveLocation != null) return entry.archiveLocation!;
    final root = archiveRootOf(entry, all);
    final location =
        root.archiveLocation ??
        archiveLocationFor(root, all, root.archivedAt ?? at);
    if (root.id == entry.id) return location;
    final chain = [
      root,
      ...ancestorsOf(
        entry,
        all,
      ).takeWhile((e) => e.id != root.id).toList().reversed,
    ];
    return ArchiveLocation(
      year: location.year,
      section: location.section,
      someday: location.someday,
      ancestors: [
        ...location.ancestors,
        ...chain.map(
          (e) => ArchiveAncestor(id: e.id, title: e.title, kind: e.kind),
        ),
      ],
    );
  }

  @override
  Future<void> trash(String id) => _write(() async {
    await _require(id);
    final all = await getEntries();
    final batch = _uuid.v4(), at = _now().toUtc();
    final affected = all.where((e) => e.id == id || belongsTo(e, id, all));
    await database.transaction(() async {
      for (final entry in affected) {
        final archived = isArchived(entry, all);
        final root = archiveRootOf(entry, all);
        final location = _trashArchiveLocation(entry, all, at);
        await (database.update(
          database.entries,
        )..where((e) => e.id.equals(entry.id))).write(
          EntriesCompanion(
            deletedAt: Value(at),
            trashBatchId: Value(batch),
            trashLocation: Value(
              [
                if (archived) 'Archiv',
                entry.section.label,
                ...ancestorsOf(entry, all).reversed.map((e) => e.title),
              ].join(' / '),
            ),
            // Keep explicit flags distinct from the inherited archive status.
            trashArchived: Value(archived),
            archivedAt: archived
                ? Value(entry.archivedAt ?? root.archivedAt ?? at)
                : const Value.absent(),
            archiveLocation: archived
                ? Value(_encodeArchiveLocation(location))
                : const Value.absent(),
            revision: Value(entry.revision + 1),
            updatedAt: Value(at),
          ),
        );
      }
    });
  });

  @override
  Future<void> restoreTrash(
    String id, {
    ParaSection? section,
    String? parentId,
  }) => _write(() async {
    final source = _entry(await _require(id, includeTrash: true));
    if (!source.inTrash) {
      throw const WorkspaceException(
        'Dieser Inhalt liegt nicht im Papierkorb.',
      );
    }
    final all = (await database.select(database.entries).get())
        .map(_entry)
        .toList();
    final oldParent = all.where((e) => e.id == source.parentId).firstOrNull;
    var targetParent = source.parentId;
    var targetSection = oldParent?.section ?? source.section;
    if (section != null) {
      targetSection = await _location(source.kind, section, parentId);
      targetParent = parentId;
    } else if (source.parentId != null &&
        (oldParent == null || oldParent.inTrash)) {
      throw const WorkspaceException(
        'Der ursprüngliche Ablageort ist nicht verfügbar. Bitte wähle ein Ziel.',
      );
    }
    final affected = all
        .where(
          (e) =>
              e.inTrash &&
              e.trashBatchId == source.trashBatchId &&
              (e.id == id || belongsTo(e, id, all)),
        )
        .toList();
    final destinationParent = all
        .where((e) => e.id == targetParent)
        .firstOrNull;
    final inheritsArchive =
        destinationParent != null && isArchived(destinationParent, all);
    await database.transaction(() async {
      for (final entry in affected) {
        await (database.update(
          database.entries,
        )..where((e) => e.id.equals(entry.id))).write(
          EntriesCompanion(
            deletedAt: const Value(null),
            trashBatchId: const Value(null),
            trashLocation: const Value(null),
            trashArchived: const Value(false),
            archived: entry.id == id && source.trashArchived && !inheritsArchive
                ? const Value(true)
                : const Value.absent(),
            section: Value(targetSection.name),
            parentId: entry.id == id
                ? Value(targetParent)
                : const Value.absent(),
            revision: Value(entry.revision + 1),
            updatedAt: Value(_now().toUtc()),
          ),
        );
      }
    });
  });

  @override
  Future<void> permanentlyDelete(String id) => _write(() async {
    final source = _entry(await _require(id, includeTrash: true));
    if (!source.inTrash) {
      throw const WorkspaceException(
        'Nur Inhalte im Papierkorb können endgültig entfernt werden.',
      );
    }
    final all = await getTrash();
    await _purge(
      all.where((e) => e.id == id || belongsTo(e, id, all)).toList(),
    );
  });

  @override
  Future<void> emptyTrash() => _write(() async => _purge(await getTrash()));

  // Staged bytes plus a manifest allow interrupted permanent removals to recover.
  Future<void> _purge(List<Entry> entries) async {
    if (entries.isEmpty) return;
    final staging = Directory(p.join(root.path, '.purging-${_uuid.v4()}'));
    await staging.create();
    try {
      await File(p.join(staging.path, 'manifest.json')).writeAsString(
        jsonEncode(
          entries
              .map((e) => {'id': e.id, 'file': e.kind == EntryKind.file})
              .toList(),
        ),
        flush: true,
      );
      for (final entry in entries) {
        final source = entry.kind == EntryKind.file
            ? Directory(p.join(root.path, 'files', entry.id))
            : _note(entry.id);
        if (await source.exists()) {
          await source.rename(p.join(staging.path, entry.id));
        }
      }
      await database.transaction(() async {
        for (final entry in entries) {
          await (database.delete(database.entryLinks)..where(
                (e) =>
                    e.sourceId.equals(entry.id) | e.targetId.equals(entry.id),
              ))
              .go();
          await (database.delete(
            database.noteVersions,
          )..where((e) => e.entryId.equals(entry.id))).go();
        }
        final ordered = [...entries]
          ..sort(
            (a, b) => ancestorsOf(
              b,
              entries,
            ).length.compareTo(ancestorsOf(a, entries).length),
          );
        for (final entry in ordered) {
          await (database.delete(
            database.entries,
          )..where((e) => e.id.equals(entry.id))).go();
        }
      });
    } catch (_) {
      await _recoverPurge(staging);
      rethrow;
    }
    // A cleanup failure leaves only unregistered staging bytes; retry on open.
    try {
      await staging.delete(recursive: true);
    } on FileSystemException {
      /* Retry on next startup. */
    }
  }

  Future<void> _recoverPurges() async {
    await for (final entity in root.list()) {
      if (entity is Directory &&
          p.basename(entity.path).startsWith('.purging-')) {
        await _recoverPurge(entity);
      }
    }
  }

  Future<void> _recoverPurge(Directory staging) async {
    final manifest = File(p.join(staging.path, 'manifest.json'));
    if (!await manifest.exists()) {
      if (await staging.list().isEmpty) await staging.delete();
      return;
    }
    final items = jsonDecode(await manifest.readAsString()) as List;
    for (final value in items) {
      final item = value as Map<String, dynamic>, id = value['id'] as String;
      if (entryIdFromLink(entryLink(id)) == null) {
        throw const WorkspaceException(
          'Ungültiger Wiederherstellungsdatensatz.',
        );
      }
      final row = await (database.select(
        database.entries,
      )..where((e) => e.id.equals(id))).getSingleOrNull();
      final stagedPath = p.join(staging.path, id);
      final staged = item['file'] == true
          ? Directory(stagedPath)
          : File(stagedPath);
      if (row != null && await staged.exists()) {
        final destination = item['file'] == true
            ? p.join(root.path, 'files', id)
            : _note(id).path;
        if (await FileSystemEntity.type(destination) !=
            FileSystemEntityType.notFound) {
          throw const WorkspaceException(
            'Eine unterbrochene Entfernung benötigt Prüfung: Quelldatei und Rückfallkopie sind vorhanden.',
          );
        }
        await staged.rename(destination);
      }
    }
    await staging.delete(recursive: true);
  }

  Future<void> _recordVersion(
    String id,
    String title,
    String body,
    DateTime at,
  ) async {
    final last =
        await (database.select(database.noteVersions)
              ..where((e) => e.entryId.equals(id))
              ..orderBy([(e) => OrderingTerm.desc(e.sequence)])
              ..limit(1))
            .getSingleOrNull();
    final hash = _hash(body);
    if (last?.bodyHash == hash) return;
    await database
        .into(database.noteVersions)
        .insert(
          NoteVersionsCompanion.insert(
            id: _uuid.v4(),
            entryId: id,
            title: title,
            body: body,
            bodyHash: hash,
            createdAt: at,
          ),
        );
  }

  @override
  Future<List<NoteVersion>> noteVersions(String id) async {
    await _require(id, includeTrash: true);
    final rows =
        await (database.select(database.noteVersions)
              ..where((e) => e.entryId.equals(id))
              ..orderBy([(e) => OrderingTerm.desc(e.sequence)]))
            .get();
    return rows
        .map(
          (e) => NoteVersion(
            id: e.id,
            entryId: e.entryId,
            title: e.title,
            body: e.body,
            bodyHash: e.bodyHash,
            createdAt: e.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> restoreNoteVersion(
    String id,
    String versionId, {
    required int expectedRevision,
    required String expectedBodyHash,
  }) => _write(() async {
    final row = await _require(id);
    final version =
        await (database.select(database.noteVersions)
              ..where((e) => e.entryId.equals(id) & e.id.equals(versionId)))
            .getSingleOrNull();
    if (version == null) {
      throw const WorkspaceException('Die Textversion wurde nicht gefunden.');
    }
    if (row.kind != EntryKind.note.name &&
        !(row.kind == EntryKind.file.name &&
            isEditableTextName(row.fileName ?? ''))) {
      throw const WorkspaceException(
        'Dieser Inhalt unterstützt keine Textversionen.',
      );
    }
    await _save(
      id: id,
      expectedRevision: expectedRevision,
      expectedBodyHash: expectedBodyHash,
      draft: EntryDraft(
        title: row.title,
        body: version.body,
        goal: row.goal,
        dueDate: row.dueDate == null ? null : DateTime.parse(row.dueDate!),
        context: row.context,
        taskState: TaskState.values.byName(row.taskState),
      ),
    );
  });

  Future<EntryRow> _require(String id, {bool includeTrash = false}) async {
    final row =
        await (database.select(database.entries)..where(
              (e) =>
                  e.id.equals(id) &
                  (includeTrash ? const Constant(true) : e.deletedAt.isNull()),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw const WorkspaceException('Der Inhalt wurde nicht gefunden.');
    }
    return row;
  }

  String _title(String value) {
    final title = value.trim();
    if (title.isEmpty) {
      throw const WorkspaceException('Bitte gib einen Titel ein.');
    }
    return title;
  }

  void _validateDraft(EntryKind kind, EntryDraft draft) {
    _title(draft.title);
    if (draft.estimatedMinutes != null && draft.estimatedMinutes! <= 0) {
      throw const WorkspaceException(
        'Bitte eine positive Minutenzahl eingeben.',
      );
    }
    if (kind == EntryKind.project) {
      if (draft.dueDate == null || draft.goal.trim().isEmpty) {
        throw const WorkspaceException(
          'Ein Projekt braucht ein Ergebnis und ein Fälligkeitsdatum.',
        );
      }
      if (draft.taskState != TaskState.inbox) {
        throw const WorkspaceException(
          'Projekte haben keinen Aufgaben- oder Irgendwann-Status.',
        );
      }
    }
  }

  Future<ParaSection> _location(
    EntryKind kind,
    ParaSection section,
    String? parentId,
  ) async {
    final fixed = switch (kind) {
      EntryKind.project => ParaSection.projects,
      EntryKind.area => ParaSection.areas,
      EntryKind.resource => ParaSection.resources,
      EntryKind.idea => ParaSection.inbox,
      _ => null,
    };
    if (fixed != null) {
      if (parentId != null) {
        throw const WorkspaceException(
          'Dieser Inhalt steht auf der obersten Ebene.',
        );
      }
      return fixed;
    }
    if (parentId == null) {
      if (section == ParaSection.projects) {
        throw const WorkspaceException(
          'Wähle ein Projekt oder einen Bereich als Ablageort.',
        );
      }
      return section;
    }
    final parent = _entry(await _require(parentId));
    final all = await getEntries();
    if (!parent.kind.isContainer ||
        isArchived(parent, all) ||
        parent.completed ||
        ancestorsOf(parent, all).any((e) => e.completed)) {
      throw const WorkspaceException(
        'Wähle einen aktiven Ordner, ein Projekt oder eine Sammlung.',
      );
    }
    return parent.section;
  }

  File _attachment(EntryRow row) =>
      File(p.join(root.path, 'files', row.id, row.fileName!));

  String? _previousState(EntryRow row, TaskState state) {
    if (state.name == row.taskState) return row.previousTaskState;
    return state.isClosed
        ? (TaskState.values.byName(row.taskState).isClosed
              ? row.previousTaskState
              : row.taskState)
        : null;
  }

  File _note(String id) => File(p.join(root.path, 'notes', '$id.md'));
  String _hash(String text) => sha256.convert(utf8.encode(text)).toString();
  String? _date(DateTime? date) => date?.toIso8601String().split('T').first;

  Future<void> _writeBody(String id, String body) async {
    final file = _note(id);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(body, flush: true);
    await temporary.rename(file.path);
  }

  @override
  Future<Entry> create({
    required EntryKind kind,
    required EntryDraft draft,
    ParaSection section = ParaSection.inbox,
    String? parentId,
  }) => _write(() async {
    if (kind == EntryKind.file) {
      throw const WorkspaceException('Bitte importiere die Datei.');
    }
    _validateDraft(kind, draft);
    final location = await _location(kind, section, parentId);
    final details = await _taskContextSelection(draft);
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _writeBody(id, draft.body);
    try {
      await database.transaction(() async {
        await database
            .into(database.entries)
            .insert(
              EntriesCompanion.insert(
                id: id,
                title: _title(draft.title),
                kind: kind.name,
                section: location.name,
                parentId: Value(parentId),
                goal: Value(draft.goal.trim()),
                dueDate: Value(_date(draft.dueDate)),
                context: Value(details.$2),
                contextIds: Value(jsonEncode(details.$1)),
                estimatedMinutes: Value(draft.estimatedMinutes),
                energy: Value(draft.energy?.name),
                taskState: Value(draft.taskState.name),
                searchText: Value(draft.body),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _indexLinks(id, draft.body);
        if (kind == EntryKind.note) {
          await _recordVersion(id, _title(draft.title), draft.body, now);
        }
      });
    } catch (_) {
      await _note(id).delete();
      rethrow;
    }
    return _entry(await _require(id));
  });

  @override
  Future<NoteSnapshot> readNote(String id) async {
    final row = await _require(id, includeTrash: true);
    if (row.kind == EntryKind.file.name) {
      final body = isEditableTextName(row.fileName ?? '')
          ? await readSmallTextFile(_attachment(row))
          : null;
      return NoteSnapshot(
        body ?? '',
        _hash(body ?? ''),
        editable: body != null,
      );
    }
    final text = await _note(id).readAsString();
    return NoteSnapshot(text, _hash(text));
  }

  @override
  Future<void> save({
    required String id,
    required int expectedRevision,
    required String expectedBodyHash,
    required EntryDraft draft,
  }) => _write(
    () => _save(
      id: id,
      expectedRevision: expectedRevision,
      expectedBodyHash: expectedBodyHash,
      draft: draft,
    ),
  );

  Future<void> _save({
    required String id,
    required int expectedRevision,
    required String expectedBodyHash,
    required EntryDraft draft,
  }) async {
    final row = await _require(id);
    _validateDraft(EntryKind.values.byName(row.kind), draft);
    if (row.revision != expectedRevision) {
      throw const WorkspaceException(
        'Der Inhalt wurde inzwischen geändert. Bitte neu öffnen.',
      );
    }
    final all = await getEntries();
    if (isArchived(_entry(row), all)) {
      throw const WorkspaceException(
        'Archivierte Inhalte sind schreibgeschützt.',
      );
    }
    final taskDetails =
        draft.updateTaskDetails ||
            draft.contextIds != null ||
            draft.context != row.context
        ? await _taskContextSelection(draft, previous: row)
        : null;
    final filename = row.kind == EntryKind.file.name
        ? draft.title == row.title
              ? row.fileName!
              : _title(draft.title)
        : null;
    if (filename != null &&
        (p.basename(filename) != filename ||
            filename.contains(String.fromCharCode(92)) ||
            filename == '.' ||
            filename == '..')) {
      throw const WorkspaceException('Ungültiger Dateiname.');
    }
    final current = await readNote(id);
    final writeBody = row.kind != EntryKind.file.name || current.editable;
    if (current.hash != expectedBodyHash ||
        row.kind == EntryKind.file.name &&
            !current.editable &&
            draft.body.isNotEmpty) {
      throw const WorkspaceException(
        'Die Datei wurde außerhalb der App geändert oder ist nicht mehr als Text lesbar. Bitte neu öffnen.',
      );
    }
    final versioned =
        row.kind == EntryKind.note.name ||
        row.kind == EntryKind.file.name && current.editable;
    final textChanged = versioned && current.text != draft.body;
    if (textChanged) {
      // Preserve the observed old bytes before replacing the authoritative file.
      await _recordVersion(row.id, row.title, current.text, row.updatedAt);
    }
    if (writeBody) {
      if (row.kind == EntryKind.file.name) {
        if (utf8.encode(draft.body).length > maxTextFileBytes) {
          throw const WorkspaceException(
            'Textdateien dürfen höchstens 16 MiB groß sein.',
          );
        }
        final file = _attachment(row);
        final temporary = File('${file.path}.saving');
        await temporary.writeAsString(draft.body, flush: true);
        await temporary.rename(file.path);
      } else {
        await _writeBody(id, draft.body);
      }
    }
    final original = row.kind == EntryKind.file.name ? _attachment(row) : null;
    final renamed = filename != null && filename != row.fileName
        ? File(p.join(original!.parent.path, filename))
        : null;
    if (renamed != null) await original!.rename(renamed.path);
    // File text is authoritative; the search/link index is recoverable on open.
    try {
      await database.transaction(() async {
        await (database.update(
          database.entries,
        )..where((e) => e.id.equals(id))).write(
          EntriesCompanion(
            title: Value(_title(draft.title)),
            fileName: filename != null ? Value(filename) : const Value.absent(),
            goal: Value(draft.goal.trim()),
            dueDate: Value(_date(draft.dueDate)),
            context: taskDetails == null
                ? const Value.absent()
                : Value(taskDetails.$2),
            contextIds: taskDetails == null
                ? const Value.absent()
                : Value(jsonEncode(taskDetails.$1)),
            estimatedMinutes: draft.updateTaskDetails
                ? Value(draft.estimatedMinutes)
                : const Value.absent(),
            energy: draft.updateTaskDetails
                ? Value(draft.energy?.name)
                : const Value.absent(),
            taskState: Value(draft.taskState.name),
            previousTaskState: Value(_previousState(row, draft.taskState)),
            fileSize: row.kind == EntryKind.file.name && writeBody
                ? Value(utf8.encode(draft.body).length)
                : const Value.absent(),
            revision: Value(row.revision + 1),
            searchText: writeBody ? Value(draft.body) : const Value.absent(),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
        if (row.kind != EntryKind.file.name) await _indexLinks(id, draft.body);
        if (textChanged) {
          await _recordVersion(id, draft.title, draft.body, _now().toUtc());
        }
      });
    } catch (_) {
      if (renamed != null && await renamed.exists()) {
        await renamed.rename(original!.path);
      }
      rethrow;
    }
    if (row.kind == EntryKind.file.name) await _indexFile(await _require(id));
  }

  @override
  Future<Entry> importFile({
    required String name,
    required Stream<List<int>> bytes,
    ParaSection section = ParaSection.inbox,
    String? parentId,
  }) => _write(() async {
    final location = await _location(EntryKind.file, section, parentId);
    final filename = p.basename(name.replaceAll(r'\', '/'));
    if (filename.isEmpty || filename == '.' || filename == '..') {
      throw const WorkspaceException('Ungültiger Dateiname.');
    }
    final id = _uuid.v4();
    final folder = await Directory(p.join(root.path, 'files', id)).create();
    try {
      final temporary = File(p.join(folder.path, '.importing'));
      final sink = temporary.openWrite();
      try {
        await sink.addStream(bytes);
        await sink.flush();
      } catch (error, stack) {
        try {
          await sink.close();
        } catch (_) {
          // Preserve the original stream error if the sink already closed.
        }
        Error.throwWithStackTrace(error, stack);
      }
      await sink.close();
      final file = await temporary.rename(p.join(folder.path, filename));
      final now = DateTime.now().toUtc();
      await database
          .into(database.entries)
          .insert(
            EntriesCompanion.insert(
              id: id,
              title: filename,
              kind: EntryKind.file.name,
              section: location.name,
              parentId: Value(parentId),
              fileName: Value(filename),
              fileSize: Value(await file.length()),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } catch (_) {
      await folder.delete(recursive: true);
      rethrow;
    }
    await _indexFile(await _require(id));
    return _entry(await _require(id));
  });

  @override
  Future<void> move(String id, ParaSection section, {String? parentId}) =>
      _write(() async {
        final row = await _require(id);
        final entries = await getEntries();
        final source = _entry(row);
        if (isArchived(source, entries)) {
          throw const WorkspaceException(
            'Stelle den Inhalt vor dem Verschieben wieder her.',
          );
        }
        if (parentId != null) {
          final parent = _entry(await _require(parentId));
          if (parent.id == id ||
              ancestorsOf(parent, entries).any((e) => e.id == id)) {
            throw const WorkspaceException(
              'Ein Ordner kann nicht in sich selbst verschoben werden.',
            );
          }
        }
        final location = await _location(source.kind, section, parentId);
        await database.transaction(() async {
          await (database.update(
            database.entries,
          )..where((e) => e.id.equals(id))).write(
            EntriesCompanion(
              section: Value(location.name),
              parentId: Value(parentId),
              revision: Value(row.revision + 1),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
          for (final child in entries.where((e) => belongsTo(e, id, entries))) {
            await (database.update(
              database.entries,
            )..where((e) => e.id.equals(child.id))).write(
              EntriesCompanion(
                section: Value(location.name),
                revision: Value(child.revision + 1),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );
          }
        });
      });

  @override
  Future<void> archive(String id, bool archived) => _write(() async {
    final row = await _require(id);
    final now = _now().toUtc();
    final all = await getEntries();
    if (!archived && ancestorsOf(_entry(row), all).any((e) => e.archived)) {
      throw const WorkspaceException(
        'Wähle beim Wiederherstellen einen aktiven Ablageort.',
      );
    }
    final location = archived
        ? row.archiveLocation ??
              _encodeArchiveLocation(archiveLocationFor(_entry(row), all, now))
        : null;
    await (database.update(
      database.entries,
    )..where((e) => e.id.equals(id))).write(
      EntriesCompanion(
        archived: Value(archived),
        archivedAt: Value(archived ? row.archivedAt ?? now : null),
        archiveLocation: Value(location),
        completed: Value(archived ? row.completed : false),
        revision: Value(row.revision + 1),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });

  @override
  Future<void> completeProject(String id) => _write(() async {
    final row = await _require(id);
    if (row.kind != EntryKind.project.name) {
      throw const WorkspaceException('Dies ist kein Projekt.');
    }
    final now = _now().toUtc();
    final location =
        row.archiveLocation ??
        _encodeArchiveLocation(
          archiveLocationFor(_entry(row), await getEntries(), now),
        );
    await (database.update(
      database.entries,
    )..where((e) => e.id.equals(id))).write(
      EntriesCompanion(
        completed: const Value(true),
        archived: const Value(true),
        archivedAt: Value(row.archivedAt ?? now),
        archiveLocation: Value(location),
        revision: Value(row.revision + 1),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });

  @override
  Future<void> restoreTo(String id, ParaSection section, {String? parentId}) =>
      _write(() async {
        final row = await _require(id);
        final all = await getEntries();
        if (!isArchived(_entry(row), all)) {
          throw const WorkspaceException('Dieser Inhalt ist nicht archiviert.');
        }
        if (parentId == id ||
            (parentId != null &&
                ancestorsOf(
                  _entry(await _require(parentId)),
                  all,
                ).any((e) => e.id == id))) {
          throw const WorkspaceException(
            'Ein Ordner kann nicht in sich selbst verschoben werden.',
          );
        }
        final location = await _location(
          EntryKind.values.byName(row.kind),
          section,
          parentId,
        );
        final now = _now().toUtc();
        await database.transaction(() async {
          await (database.update(
            database.entries,
          )..where((e) => e.id.equals(id))).write(
            EntriesCompanion(
              archived: const Value(false),
              archivedAt: const Value(null),
              archiveLocation: const Value(null),
              completed: const Value(false),
              section: Value(location.name),
              parentId: Value(parentId),
              revision: Value(row.revision + 1),
              updatedAt: Value(now),
            ),
          );
          for (final child in all.where((e) => belongsTo(e, id, all))) {
            await (database.update(
              database.entries,
            )..where((e) => e.id.equals(child.id))).write(
              EntriesCompanion(
                section: Value(location.name),
                revision: Value(child.revision + 1),
                updatedAt: Value(now),
              ),
            );
          }
        });
      });

  @override
  Future<Entry> convertToProject(
    String id, {
    required EntryDraft draft,
    required int expectedRevision,
  }) => _write(() async {
    final row = await _require(id);
    final entry = _entry(row);
    if (entry.revision != expectedRevision) {
      throw const WorkspaceException(
        'Der Inhalt wurde inzwischen geändert. Bitte neu öffnen.',
      );
    }
    if (isArchived(entry, await getEntries()) ||
        !(entry.kind == EntryKind.idea ||
            entry.kind == EntryKind.task &&
                entry.taskState == TaskState.someday)) {
      throw const WorkspaceException(
        'Nur Ideen und zurückgestellte Aufgaben lassen sich so in Projekte umwandeln.',
      );
    }
    _validateDraft(EntryKind.project, draft);
    // Keep the UUID, Markdown file, createdAt and every incoming/outgoing link.
    await (database.update(
      database.entries,
    )..where((e) => e.id.equals(id))).write(
      EntriesCompanion(
        title: Value(_title(draft.title)),
        kind: Value(EntryKind.project.name),
        section: Value(ParaSection.projects.name),
        parentId: const Value(null),
        goal: Value(draft.goal.trim()),
        dueDate: Value(_date(draft.dueDate)),
        taskState: Value(TaskState.inbox.name),
        context: const Value(''),
        revision: Value(row.revision + 1),
        updatedAt: Value(_now().toUtc()),
      ),
    );
    return _entry(await _require(id));
  });

  @override
  Future<void> setTaskState(String id, TaskState state) => _write(() async {
    final row = await _require(id);
    if (row.kind != EntryKind.task.name) {
      throw const WorkspaceException('Dies ist keine Aufgabe.');
    }
    if (isArchived(_entry(row), await getEntries())) {
      throw const WorkspaceException(
        'Archivierte Aufgaben sind schreibgeschützt.',
      );
    }
    await (database.update(
      database.entries,
    )..where((e) => e.id.equals(id))).write(
      EntriesCompanion(
        previousTaskState: Value(_previousState(row, state)),
        taskState: Value(state.name),
        revision: Value(row.revision + 1),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });

  Future<void> _indexLinks(String sourceId, String body) async {
    final visitor = _Links();
    for (final node in md.Document().parseLines(body.split('\n'))) {
      node.accept(visitor);
    }
    await (database.delete(
      database.entryLinks,
    )..where((l) => l.sourceId.equals(sourceId))).go();
    for (final target in visitor.ids) {
      final row = await (database.select(
        database.entries,
      )..where((e) => e.id.equals(target))).getSingleOrNull();
      if (row != null) {
        await database
            .into(database.entryLinks)
            .insert(
              EntryLinksCompanion.insert(sourceId: sourceId, targetId: target),
              mode: InsertMode.insertOrIgnore,
            );
      }
    }
  }

  Future<void> _indexFile(EntryRow row) async {
    String? text;
    try {
      final file = _attachment(row);
      if (isSearchableTextName(row.fileName ?? '')) {
        text = await readSmallTextFile(file);
      } else if (p.extension(row.fileName ?? '').toLowerCase() == '.pdf' &&
          _pdfTextExtractor != null &&
          await file.length() <= 100 * 1024 * 1024) {
        text = await _pdfTextExtractor(file.path);
      }
    } catch (_) {
      // Unsupported, protected or missing files remain accessible by name.
    }
    final body = text ?? '';
    if (body != row.searchText) {
      await (database.update(database.entries)
            ..where((e) => e.id.equals(row.id)))
          .write(EntriesCompanion(searchText: Value(body)));
    }
    if (isMarkdownName(row.fileName ?? '')) await _indexLinks(row.id, body);
  }

  Future<void> _rebuildIndex() async {
    final rows = await database.select(database.entries).get();
    await database.transaction(() async {
      await database.delete(database.entryLinks).go();
      for (final row in rows) {
        if (row.kind == EntryKind.file.name) {
          await _indexFile(row);
          continue;
        }
        final file = _note(row.id);
        if (!await file.exists()) continue; // The editor reports missing files.
        final body = await file.readAsString();
        await _indexLinks(row.id, body);
        if (body != row.searchText) {
          await (database.update(database.entries)
                ..where((e) => e.id.equals(row.id)))
              .write(EntriesCompanion(searchText: Value(body)));
        }
      }
    });
  }

  Future<List<Entry>> _linked(String id, {required bool incoming}) async {
    final rows =
        await (database.select(database.entryLinks)..where(
              (l) => incoming ? l.targetId.equals(id) : l.sourceId.equals(id),
            ))
            .get();
    final ids = rows.map((l) => incoming ? l.sourceId : l.targetId).toSet();
    return (await database.select(database.entries).get())
        .where((e) => ids.contains(e.id))
        .map(_entry)
        .toList();
  }

  @override
  Future<List<Entry>> backlinks(String id) => _linked(id, incoming: true);
  @override
  Future<List<Entry>> outgoingLinks(String id) => _linked(id, incoming: false);

  @override
  Future<String> filePath(String id) async {
    final row = await _require(id, includeTrash: true);
    if (row.kind != EntryKind.file.name || row.fileName == null) {
      throw const WorkspaceException('Dies ist keine Datei.');
    }
    final file = File(p.join(root.path, 'files', id, row.fileName!));
    if (!await file.exists()) {
      throw const WorkspaceException('Die Datei fehlt im Arbeitsbereich.');
    }
    return file.path;
  }

  @override
  Future<String> exportBackup(String destinationDirectory) => _write(() async {
    final destination = p.normalize(p.absolute(destinationDirectory));
    final source = p.normalize(p.absolute(root.path));
    if (destination == source || p.isWithin(source, destination)) {
      throw const WorkspaceException(
        'Bitte wähle einen Ordner außerhalb des Arbeitsbereichs.',
      );
    }
    final token = _uuid.v4();
    final temporary = Directory(p.join(destination, '.para-sicherung-$token'));
    await temporary.create(recursive: true);
    try {
      await Directory(p.join(temporary.path, 'notes')).create();
      await Directory(p.join(temporary.path, 'files')).create();
      // SQLite creates a consistent standalone snapshot, including WAL contents.
      await database.customStatement('VACUUM INTO ?', [
        p.join(temporary.path, 'workspace.sqlite'),
      ]);
      for (final row in await database.select(database.entries).get()) {
        final entry = _entry(row);
        if (entry.kind == EntryKind.file) {
          final target = await Directory(
            p.join(temporary.path, 'files', entry.id),
          ).create();
          await File(
            await filePath(entry.id),
          ).copy(p.join(target.path, entry.fileName!));
        } else {
          await _note(
            entry.id,
          ).copy(p.join(temporary.path, 'notes', '${entry.id}.md'));
        }
      }
      await WorkspaceStorage.copyTree(
        Directory(p.join(root.path, 'ingest')),
        Directory(p.join(temporary.path, 'ingest')),
      );
      // Restored/copy workspaces never inherit permission to consume a source.
      final backupDb = WorkspaceDatabase(
        NativeDatabase(File(p.join(temporary.path, 'workspace.sqlite'))),
      );
      try {
        final setting = await (backupDb.select(
          backupDb.workspaceSettings,
        )..where((e) => e.key.equals('ingest.sources.v1'))).getSingleOrNull();
        if (setting != null) {
          final value = jsonDecode(setting.value) as Map<String, dynamic>;
          value['enabled'] = false;
          value['binding'] = _uuid.v4();
          await (backupDb.update(
            backupDb.workspaceSettings,
          )..where((e) => e.key.equals(setting.key))).write(
            WorkspaceSettingsCompanion(value: Value(jsonEncode(value))),
          );
        }
      } finally {
        await backupDb.close();
      }
      await File(p.join(temporary.path, 'backup.json')).writeAsString(
        jsonEncode({
          'format': 'para-workspace',
          'version': 3,
          'schemaVersion': database.schemaVersion,
          'appVersion': workspaceAppVersion,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final result = await temporary.rename(
        p.join(destination, 'PARA-Sicherung-$stamp-$token'),
      );
      return result.path;
    } catch (_) {
      if (await temporary.exists()) await temporary.delete(recursive: true);
      rethrow;
    }
  });

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _pending;
    try {
      await database.close();
    } finally {
      await _lease.close();
    }
  }
}

class _Links implements md.NodeVisitor {
  final ids = <String>{};
  @override
  bool visitElementBefore(md.Element element) {
    if (element.tag == 'a') {
      final id = entryIdFromLink(element.attributes['href'] ?? '');
      if (id != null) ids.add(id);
    }
    return true;
  }

  @override
  void visitElementAfter(md.Element element) {}
  @override
  void visitText(md.Text text) {}
}
