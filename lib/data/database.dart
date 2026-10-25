import 'package:drift/drift.dart';
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

@DriftDatabase(tables: [Entries, EntryLinks, NoteVersions])
class WorkspaceDatabase extends _$WorkspaceDatabase {
  WorkspaceDatabase(super.executor);
  @override
  int get schemaVersion => 4;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
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
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
