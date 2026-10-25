enum EntryKind { project, area, resource, folder, note, task, file, idea }

enum ParaSection { inbox, projects, areas, resources }

enum TaskState { inbox, next, waiting, someday, done, cancelled }

extension SectionLabel on ParaSection {
  String get label => switch (this) {
    ParaSection.inbox => 'Inbox',
    ParaSection.projects => 'Projekte',
    ParaSection.areas => 'Bereiche',
    ParaSection.resources => 'Ressourcen',
  };
}

extension KindLabel on EntryKind {
  String get label => switch (this) {
    EntryKind.project => 'Projekt',
    EntryKind.area => 'Bereich',
    EntryKind.resource => 'Ressourcensammlung',
    EntryKind.folder => 'Ordner',
    EntryKind.note => 'Notiz',
    EntryKind.task => 'Aufgabe',
    EntryKind.file => 'Datei',
    EntryKind.idea => 'Idee',
  };
  bool get isContainer => {
    EntryKind.project,
    EntryKind.area,
    EntryKind.resource,
    EntryKind.folder,
  }.contains(this);
}

extension TaskStateLabel on TaskState {
  String get label => switch (this) {
    TaskState.inbox => 'Noch zu klären',
    TaskState.next => 'Nächste Aktion',
    TaskState.waiting => 'Warten auf',
    TaskState.someday => 'Irgendwann / Vielleicht',
    TaskState.done => 'Erledigt',
    TaskState.cancelled => 'Nicht mehr relevant',
  };
  bool get isClosed => this == TaskState.done || this == TaskState.cancelled;
}

class Entry {
  const Entry({
    required this.id,
    required this.title,
    required this.kind,
    required this.section,
    required this.archived,
    required this.completed,
    required this.taskState,
    required this.context,
    required this.goal,
    required this.revision,
    required this.updatedAt,
    required this.searchText,
    this.parentId,
    this.dueDate,
    this.fileName,
    this.fileSize,
    this.archivedAt,
    this.archiveLocation,
    this.previousTaskState,
    this.deletedAt,
    this.trashBatchId,
    this.trashLocation,
    this.trashArchived = false,
  });
  final String id;
  final String title;
  final EntryKind kind;
  final ParaSection section;
  final String? parentId;
  final bool archived;
  final bool completed;
  final TaskState taskState;
  final String context;
  final String goal;
  final DateTime? dueDate;
  final String? fileName;
  final int? fileSize;
  final int revision;
  final DateTime updatedAt;
  final String searchText;
  final DateTime? archivedAt;
  final ArchiveLocation? archiveLocation;
  final TaskState? previousTaskState;
  final DateTime? deletedAt;
  final String? trashBatchId;
  final String? trashLocation;
  final bool trashArchived;
  bool get inTrash => deletedAt != null;
}

class NoteVersion {
  const NoteVersion({
    required this.id,
    required this.entryId,
    required this.title,
    required this.body,
    required this.bodyHash,
    required this.createdAt,
  });
  final String id;
  final String entryId;
  final String title;
  final String body;
  final String bodyHash;
  final DateTime createdAt;
}

class ArchiveAncestor {
  const ArchiveAncestor({
    required this.id,
    required this.title,
    required this.kind,
  });
  final String id;
  final String title;
  final EntryKind kind;
}

class ArchiveLocation {
  const ArchiveLocation({
    required this.year,
    required this.section,
    required this.ancestors,
    this.someday = false,
  });
  final int year;
  final ParaSection section;
  final List<ArchiveAncestor> ancestors;
  final bool someday;
}

Entry archiveRootOf(Entry entry, List<Entry> entries) =>
    ancestorsOf(entry, entries).where((e) => e.archived).lastOrNull ?? entry;

ArchiveLocation archiveLocationFor(
  Entry entry,
  List<Entry> entries,
  DateTime at,
) => ArchiveLocation(
  year: at.toLocal().year,
  section: entry.section,
  someday:
      entry.parentId == null &&
      (entry.kind == EntryKind.idea ||
          entry.kind == EntryKind.task && entry.taskState == TaskState.someday),
  ancestors: ancestorsOf(entry, entries).reversed
      .map((e) => ArchiveAncestor(id: e.id, title: e.title, kind: e.kind))
      .toList(),
);

class NoteSnapshot {
  const NoteSnapshot(this.text, this.hash, {this.editable = true});
  final bool editable;
  final String text;
  final String hash;
}

class EntryDraft {
  const EntryDraft({
    required this.title,
    this.body = '',
    this.goal = '',
    this.dueDate,
    this.taskState = TaskState.inbox,
    this.context = '',
  });
  final String title;
  final String body;
  final String goal;
  final DateTime? dueDate;
  final TaskState taskState;
  final String context;
}

class WorkspaceException implements Exception {
  const WorkspaceException(this.message);
  final String message;
  @override
  String toString() => message;
}

String entryLink(String id) => 'para://entry/$id';

String? entryIdFromLink(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'para' ||
      uri.host != 'entry' ||
      uri.pathSegments.length != 1) {
    return null;
  }
  final id = uri.pathSegments.single;
  return RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(id)
      ? id
      : null;
}

String markdownLink(Entry entry) {
  final title = entry.title
      .replaceAll(r'\', r'\\')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]')
      .replaceAll('\n', ' ');
  return '[$title](para://entry/${entry.id})';
}

List<Entry> ancestorsOf(Entry entry, List<Entry> entries) {
  final byId = {for (final item in entries) item.id: item};
  final result = <Entry>[];
  var parent = byId[entry.parentId];
  final visited = {entry.id};
  while (parent != null && visited.add(parent.id)) {
    result.add(parent);
    parent = byId[parent.parentId];
  }
  return result;
}

bool isArchived(Entry entry, List<Entry> entries) =>
    entry.archived || ancestorsOf(entry, entries).any((e) => e.archived);

bool isActiveTask(Entry entry, List<Entry> entries) =>
    entry.kind == EntryKind.task &&
    !entry.inTrash &&
    !isArchived(entry, entries) &&
    !ancestorsOf(entry, entries).any((e) => e.completed);

bool belongsTo(Entry entry, String parentId, List<Entry> entries) =>
    entry.parentId == parentId ||
    ancestorsOf(entry, entries).any((e) => e.id == parentId);

/// This application boundary is also usable by a future MCP adapter.
abstract class WorkspaceRepository {
  Stream<List<Entry>> watchEntries();
  Future<List<Entry>> getEntries();
  Stream<List<Entry>> watchTrash();
  Future<List<Entry>> getTrash();
  Future<void> trash(String id);
  Future<void> restoreTrash(
    String id, {
    ParaSection? section,
    String? parentId,
  });
  Future<void> permanentlyDelete(String id);
  Future<void> emptyTrash();
  Future<List<NoteVersion>> noteVersions(String id);
  Future<void> restoreNoteVersion(
    String id,
    String versionId, {
    required int expectedRevision,
    required String expectedBodyHash,
  });
  Future<Entry> create({
    required EntryKind kind,
    required EntryDraft draft,
    ParaSection section = ParaSection.inbox,
    String? parentId,
  });
  Future<NoteSnapshot> readNote(String id);
  Future<void> save({
    required String id,
    required int expectedRevision,
    required String expectedBodyHash,
    required EntryDraft draft,
  });
  Future<Entry> importFile({
    required String name,
    required Stream<List<int>> bytes,
    ParaSection section = ParaSection.inbox,
    String? parentId,
  });
  Future<void> move(String id, ParaSection section, {String? parentId});
  Future<void> archive(String id, bool archived);
  Future<void> restoreTo(String id, ParaSection section, {String? parentId});
  Future<void> completeProject(String id);
  Future<Entry> convertToProject(
    String id, {
    required EntryDraft draft,
    required int expectedRevision,
  });
  Future<void> setTaskState(String id, TaskState state);
  Future<List<Entry>> backlinks(String id);
  Future<List<Entry>> outgoingLinks(String id);
  Future<String> filePath(String id);
  Future<String> exportBackup(String destinationDirectory);
  Future<void> close();
}
