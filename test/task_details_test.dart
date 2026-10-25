import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/domain/search.dart';

void main() {
  late Directory root;
  late LocalWorkspaceRepository repo;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('para-details-');
    repo = await LocalWorkspaceRepository.open(root);
  });
  tearDown(() async {
    await repo.close();
    await root.delete(recursive: true);
  });
  Future<Entry> task(List<String> ids, {int? minutes, EnergyLevel? energy}) =>
      repo.create(
        kind: EntryKind.task,
        draft: EntryDraft(
          title: 'Aufgabe',
          contextIds: ids,
          estimatedMinutes: minutes,
          energy: energy,
          taskState: TaskState.next,
        ),
      );
  Future<Entry> current(String id) async =>
      (await repo.getEntries()).firstWhere((e) => e.id == id);

  test(
    'multiple contexts, custom minutes, energy and settings survive reopen and backup',
    () async {
      final contexts = await repo.getContexts();
      final entry = await task(
        contexts.take(2).map((e) => e.id).toList(),
        minutes: 42,
        energy: EnergyLevel.medium,
      );
      await repo.writeSetting(
        'session.v1',
        jsonEncode({'version': 1, 'view': 'actions'}),
      );
      final destination = await Directory.systemTemp.createTemp(
        'para-details-backup-',
      );
      addTearDown(() => destination.delete(recursive: true));
      final backup = await repo.exportBackup(destination.path);
      await repo.close();
      repo = await LocalWorkspaceRepository.open(Directory(backup));
      final copy = await current(entry.id);
      expect(copy.contextIds, contexts.take(2).map((e) => e.id));
      expect(copy.estimatedMinutes, 42);
      expect(copy.energy, EnergyLevel.medium);
      expect(await repo.readSetting('session.v1'), contains('actions'));
      expect(
        (await repo.getContexts()).map((e) => e.id),
        contexts.map((e) => e.id),
      );
    },
  );

  test(
    'rename changes all labels and search without replacing identities; deactivate keeps assignments',
    () async {
      final definition = (await repo.getContexts()).first;
      final entry = await task([definition.id]);
      await repo.saveContext(
        id: definition.id,
        name: 'Daheim',
        color: contextColors[1],
        active: false,
      );
      var updated = await current(entry.id);
      expect(updated.contextIds, [definition.id]);
      expect(updated.context, 'Daheim');
      expect(searchWorkspace([updated], 'Daheim'), hasLength(1));
      await expectLater(
        task([definition.id]),
        throwsA(isA<WorkspaceException>()),
      );
      final snapshot = await repo.readNote(entry.id);
      await repo.save(
        id: entry.id,
        expectedRevision: updated.revision,
        expectedBodyHash: snapshot.hash,
        draft: EntryDraft(
          title: updated.title,
          contextIds: updated.contextIds,
          updateTaskDetails: true,
        ),
      );
      updated = await current(entry.id);
      expect(updated.contextIds, [definition.id]);
      await repo.save(
        id: entry.id,
        expectedRevision: updated.revision,
        expectedBodyHash: snapshot.hash,
        draft: EntryDraft(
          title: updated.title,
          contextIds: const [],
          updateTaskDetails: true,
        ),
      );
      expect((await current(entry.id)).contextIds, isEmpty);
      expect((await current(entry.id)).context, isEmpty);
    },
  );

  test(
    'context ordering and settings are per workspace and duplicate names are rejected',
    () async {
      final before = await repo.getContexts();
      final first = before.first;
      await repo.saveContext(
        id: first.id,
        name: first.name,
        color: first.color,
        position: before.length - 1,
      );
      expect((await repo.getContexts()).last.id, first.id);
      await expectLater(
        repo.saveContext(name: first.name.toUpperCase(), color: first.color),
        throwsA(isA<WorkspaceException>()),
      );
      await repo.writeSetting('theme', 'dark');
      final otherRoot = await Directory.systemTemp.createTemp(
        'para-other-details-',
      );
      await repo.close();
      repo = await LocalWorkspaceRepository.open(otherRoot);
      expect(await repo.readSetting('theme'), isNull);
      expect(
        (await repo.getContexts()).map((e) => e.id),
        isNot(contains(first.id)),
      );
      await repo.close();
      await otherRoot.delete(recursive: true);
      repo = await LocalWorkspaceRepository.open(root);
    },
  );

  test(
    'metadata-only legacy saves preserve new task fields; explicit edits can clear them',
    () async {
      final definition = (await repo.getContexts()).first;
      final entry = await task(
        [definition.id],
        minutes: 15,
        energy: EnergyLevel.high,
      );
      final snapshot = await repo.readNote(entry.id);
      await repo.save(
        id: entry.id,
        expectedRevision: entry.revision,
        expectedBodyHash: snapshot.hash,
        draft: EntryDraft(title: 'Umbenannt', context: entry.context),
      );
      var updated = await current(entry.id);
      expect(updated.estimatedMinutes, 15);
      expect(updated.energy, EnergyLevel.high);
      await repo.save(
        id: entry.id,
        expectedRevision: updated.revision,
        expectedBodyHash: snapshot.hash,
        draft: EntryDraft(
          title: updated.title,
          contextIds: [definition.id],
          updateTaskDetails: true,
        ),
      );
      updated = await current(entry.id);
      expect(updated.estimatedMinutes, isNull);
      expect(updated.energy, isNull);
    },
  );

  test(
    'unknown context and invalid duration are rejected before writing text',
    () async {
      await expectLater(task(['missing']), throwsA(isA<WorkspaceException>()));
      await expectLater(
        task([], minutes: 0),
        throwsA(isA<WorkspaceException>()),
      );
      expect(await repo.getEntries(), isEmpty);
    },
  );

  test(
    'schema 4 migration makes a complete pre-migration backup and keeps legacy text, links, trash and history',
    () async {
      final entry = await repo.create(
        kind: EntryKind.task,
        draft: const EntryDraft(
          title: 'Alt',
          context: 'Computer / Arbeit',
          body: 'Unverändert',
        ),
      );
      final note = await repo.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: 'Link', body: markdownLink(entry)),
      );
      await repo.trash(entry.id);
      await repo.close();
      final legacy = sqlite3.open(p.join(root.path, 'workspace.sqlite'));
      for (final sql in [
        'DROP TABLE task_contexts',
        'DROP TABLE workspace_settings',
        'ALTER TABLE entries DROP COLUMN context_ids',
        'ALTER TABLE entries DROP COLUMN estimated_minutes',
        'ALTER TABLE entries DROP COLUMN energy',
        'PRAGMA user_version = 4',
      ]) {
        legacy.execute(sql);
      }
      legacy.close();
      repo = await LocalWorkspaceRepository.open(root);
      final migrated = (await repo.getTrash()).single;
      expect(migrated.id, entry.id);
      expect(migrated.context, 'Computer / Arbeit');
      expect(migrated.contextIds, hasLength(1));
      expect(
        (await repo.getContexts())
            .firstWhere((e) => e.id == migrated.contextIds.single)
            .name,
        'Computer / Arbeit',
      );
      expect((await repo.backlinks(entry.id)).single.id, note.id);
      expect((await repo.readNote(entry.id)).text, 'Unverändert');
      expect(await repo.noteVersions(note.id), hasLength(1));
      final backups = await Directory(
        p.join(root.path, '.migration-backups'),
      ).list().toList();
      expect(backups, hasLength(1));
      final db = sqlite3.open(
        p.join(backups.single.path, 'workspace.sqlite'),
        mode: OpenMode.readOnly,
      );
      expect(db.select('PRAGMA user_version').single.values.single, 4);
      db.close();
      expect(
        await File(
          p.join(backups.single.path, 'notes', '${entry.id}.md'),
        ).readAsString(),
        'Unverändert',
      );
    },
  );

  test(
    'filters combine contexts, maximum duration and ordered energy without treating unknown as zero',
    () {
      const filter = TaskFilter(
        contextIds: ['a', 'b'],
        allContexts: true,
        maxMinutes: 30,
        maxEnergy: EnergyLevel.medium,
        includeUnspecified: false,
      );
      expect(
        filter.matches(
          contexts: ['a', 'b', 'c'],
          minutes: 15,
          energy: EnergyLevel.low,
        ),
        isTrue,
      );
      expect(
        filter.matches(contexts: ['a'], minutes: 15, energy: EnergyLevel.low),
        isFalse,
      );
      expect(
        filter.matches(
          contexts: ['a', 'b'],
          minutes: 45,
          energy: EnergyLevel.low,
        ),
        isFalse,
      );
      expect(
        filter.matches(
          contexts: ['a', 'b'],
          minutes: 15,
          energy: EnergyLevel.high,
        ),
        isFalse,
      );
      expect(
        filter.matches(
          contexts: ['a', 'b'],
          minutes: null,
          energy: EnergyLevel.low,
        ),
        isFalse,
      );
      const broad = TaskFilter(
        contextIds: ['a', 'b'],
        maxMinutes: 30,
        maxEnergy: EnergyLevel.medium,
      );
      expect(
        broad.matches(contexts: ['b'], minutes: 15, energy: EnergyLevel.medium),
        isTrue,
      );
      expect(broad.matches(contexts: [], minutes: null, energy: null), isTrue);
      expect(TaskFilter.fromJson(filter.toJson()).toJson(), filter.toJson());
    },
  );
}
