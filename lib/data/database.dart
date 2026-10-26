import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../domain/task_details.dart';
import '../domain/workspace_format.dart';
part 'database.g.dart';

@DataClassName('EntryRow')
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get kind => text()();
  TextColumn get section => text()();
  TextColumn get parentId => text().nullable().references(Entries, #id)();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  TextColumn get archiveLocation => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get taskState => text().withDefault(const Constant('inbox'))();
  TextColumn get previousTaskState => text().nullable()();
  TextColumn get context => text().withDefault(const Constant(''))();
  TextColumn get contextIds => text().withDefault(const Constant('[]'))();
  IntColumn get estimatedMinutes => integer().nullable()();
  TextColumn get energy => text().nullable()();
  TextColumn get goal => text().withDefault(const Constant(''))();
  // A due date is a calendar day, stored without a timezone.
  TextColumn get dueDate => text().nullable()();
  TextColumn get fileName => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get searchText => text().withDefault(const Constant(''))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get trashBatchId => text().nullable()();
  TextColumn get trashLocation => text().nullable()();
  BoolColumn get trashArchived =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('NoteVersionRow')
class NoteVersions extends Table {
  IntColumn get sequence => integer().autoIncrement()();
  TextColumn get id => text().unique()();
  TextColumn get entryId => text().references(Entries, #id)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get bodyHash => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class EntryLinks extends Table {
  @ReferenceName('outgoingLinkRows')
  TextColumn get sourceId => text().references(Entries, #id)();
  @ReferenceName('incomingLinkRows')
  TextColumn get targetId => text().references(Entries, #id)();
  @override
  Set<Column<Object>> get primaryKey => {sourceId, targetId};
}

@DataClassName('TaskContextRow')
class TaskContexts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get position => integer()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WorkspaceSettingRow')
class WorkspaceSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('IngestJobRow')
class IngestJobs extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Entries,
    EntryLinks,
    NoteVersions,
    TaskContexts,
    WorkspaceSettings,
    IngestJobs,
  ],
)
class WorkspaceDatabase extends _$WorkspaceDatabase {
  WorkspaceDatabase(super.executor);
  @override
  int get schemaVersion => workspaceSchemaVersion;
  Future<void> _initialContexts() async {
    final names = <String, String>{};
    for (final row in await customSelect(
      "SELECT DISTINCT context FROM entries WHERE context <> ''",
    ).get()) {
      final name = row.read<String>('context');
      names[name] = const Uuid().v4();
    }
    for (final name in ['Zuhause', 'Unterwegs', 'Arbeit']) {
      if (!names.keys.any(
        (value) => value.toLowerCase() == name.toLowerCase(),
      )) {
        names[name] = const Uuid().v4();
      }
    }
    var position = 0;
    for (final pair in names.entries) {
      await into(taskContexts).insert(
        TaskContextsCompanion.insert(
          id: pair.value,
          name: pair.key,
          color: contextColors[position % contextColors.length],
          position: position++,
        ),
      );
      await customStatement(
        'UPDATE entries SET context_ids = ? WHERE context = ?',
        [
          jsonEncode([pair.value]),
          pair.key,
        ],
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _initialContexts();
    },
    onUpgrade: (migrator, from, to) async {
      await transaction(() async {
        if (from < 2) {
          await migrator.addColumn(entries, entries.archivedAt);
          await migrator.addColumn(entries, entries.archiveLocation);
          await customStatement(
            'UPDATE entries SET archived_at = updated_at WHERE archived = 1',
          );
        }
        if (from < 3) {
          await migrator.addColumn(entries, entries.previousTaskState);
        }
        if (from < 4) {
          await migrator.addColumn(entries, entries.trashBatchId);
          await migrator.addColumn(entries, entries.trashLocation);
          await migrator.addColumn(entries, entries.trashArchived);
          await migrator.createTable(noteVersions);
        }
        if (from < 5) {
          await migrator.addColumn(entries, entries.contextIds);
          await migrator.addColumn(entries, entries.estimatedMinutes);
          await migrator.addColumn(entries, entries.energy);
          await migrator.createTable(taskContexts);
          await migrator.createTable(workspaceSettings);
          await _initialContexts();
        }
        if (from < 6) await migrator.createTable(ingestJobs);
      });
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
