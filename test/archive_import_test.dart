import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/archive.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/workspace_importer.dart';

void main() {
  late Directory directory;
  late LocalWorkspaceRepository repo;
  late DateTime now;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('para-archive-import-');
    now = DateTime(2026, 10, 25, 12);
    repo = await LocalWorkspaceRepository.open(directory, now: () => now);
  });
  tearDown(() async {
    await repo.close();
    await directory.delete(recursive: true);
  });
  Future<Entry> current(String id) async =>
      (await repo.getEntries()).firstWhere((e) => e.id == id);
  List<String>? pathTo(List<ArchiveNode> nodes, String id) {
    for (final node in nodes) {
      if (node.entry?.id == id) return [node.title];
      final path = pathTo(node.children, id);
      if (path != null) return [node.title, ...path];
    }
    return null;
  }

  test(
    'archive contains years, PARA origins and nested individual contents',
    () async {
      final resource = await repo.create(
        kind: EntryKind.resource,
        draft: const EntryDraft(title: 'Wissen'),
      );
      final folder = await repo.create(
        kind: EntryKind.folder,
        parentId: resource.id,
        draft: const EntryDraft(title: 'Technik'),
      );
      final note = await repo.create(
        kind: EntryKind.note,
        parentId: folder.id,
        draft: const EntryDraft(title: 'Netzwerk', body: 'Wichtig'),
      );
      final file = await repo.importFile(
        name: 'Backup.zip',
        bytes: Stream.value([1, 2, 3]),
      );
      now = DateTime(2025, 8, 12);
      await repo.archive(note.id, true);
      now = DateTime(2026, 10, 25);
      await repo.archive(file.id, true);
      final tree = buildArchiveTree(await repo.getEntries());
      expect(tree.map((e) => e.title), ['2026', '2025']);
      expect(pathTo(tree, note.id), [
        '2025',
        'Ressourcen',
        'Wissen',
        'Technik',
        'Netzwerk',
      ]);
      expect(pathTo(tree, file.id), ['2026', 'Inbox', 'Backup.zip']);
      await repo.move(folder.id, ParaSection.inbox);
      final afterMove = buildArchiveTree(await repo.getEntries());
      expect(pathTo(afterMove, note.id), [
        '2025',
        'Ressourcen',
        'Wissen',
        'Technik',
        'Netzwerk',
      ]);
    },
  );

  test(
    'whole project archive keeps descendants together without duplicates',
    () async {
      final project = await repo.create(
        kind: EntryKind.project,
        draft: EntryDraft(
          title: 'Projekt',
          goal: 'Ergebnis',
          dueDate: DateTime(2026, 12, 1),
        ),
      );
      final folder = await repo.create(
        kind: EntryKind.folder,
        parentId: project.id,
        draft: const EntryDraft(title: 'Planung'),
      );
      final note = await repo.create(
        kind: EntryKind.note,
        parentId: folder.id,
        draft: const EntryDraft(title: 'Plan'),
      );
      final task = await repo.create(
        kind: EntryKind.task,
        parentId: folder.id,
        draft: const EntryDraft(title: 'Anrufen', taskState: TaskState.next),
      );
      await repo.completeProject(project.id);
      final tree = buildArchiveTree(await repo.getEntries());
      expect(pathTo(tree, project.id), ['2026', 'Projekte', 'Projekt']);
      expect(pathTo(tree, note.id), [
        '2026',
        'Projekte',
        'Projekt',
        'Planung',
        'Plan',
      ]);
      expect(pathTo(tree, task.id), [
        '2026',
        'Projekte',
        'Projekt',
        'Planung',
        'Anrufen',
      ]);
      final projectNode = tree.single.children.single.children.single;
      expect(projectNode.children, hasLength(1));
      expect(projectNode.children.single.children, hasLength(2));
      await repo.restoreTo(note.id, ParaSection.inbox);
      final restored = await current(note.id);
      expect(restored.parentId, isNull);
      expect(isArchived(restored, await repo.getEntries()), isFalse);
      expect(
        isArchived(await current(task.id), await repo.getEntries()),
        isTrue,
      );
      expect((await current(project.id)).archived, isTrue);
    },
  );

  test(
    'restore clears archive metadata and rearchive captures the new year',
    () async {
      final idea = await repo.create(
        kind: EntryKind.idea,
        draft: const EntryDraft(title: 'Später'),
      );
      now = DateTime(2024, 12, 1);
      await repo.archive(idea.id, true);
      expect((await current(idea.id)).archiveLocation!.someday, isTrue);
      await repo.archive(idea.id, false);
      expect((await current(idea.id)).archivedAt, isNull);
      expect((await current(idea.id)).archiveLocation, isNull);
      now = DateTime(2026, 10, 25);
      await repo.archive(idea.id, true);
      expect(pathTo(buildArchiveTree(await repo.getEntries()), idea.id), [
        '2026',
        'Irgendwann / Vielleicht',
        'Später',
      ]);
    },
  );

  test(
    'v1 migration preserves content, UUIDs, links and archive history',
    () async {
      final target = await repo.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Archivnotiz', body: '# Inhalt'),
      );
      final source = await repo.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: 'Link', body: markdownLink(target)),
      );
      await repo.archive(target.id, true);
      await repo.close();
      final legacy = sqlite3.open(p.join(directory.path, 'workspace.sqlite'));
      try {
        legacy.execute('ALTER TABLE entries DROP COLUMN archived_at');
        legacy.execute('ALTER TABLE entries DROP COLUMN archive_location');
        legacy.execute('DROP TABLE note_versions');
        legacy.execute('ALTER TABLE entries DROP COLUMN trash_batch_id');
        legacy.execute('ALTER TABLE entries DROP COLUMN trash_location');
        legacy.execute('ALTER TABLE entries DROP COLUMN trash_archived');
        legacy.execute('ALTER TABLE entries DROP COLUMN previous_task_state');
        legacy.execute('PRAGMA user_version = 1');
        legacy.execute('UPDATE entries SET updated_at = ? WHERE id = ?', [
          DateTime(2023, 7, 12).millisecondsSinceEpoch ~/ 1000,
          target.id,
        ]);
      } finally {
        legacy.close();
      }
      repo = await LocalWorkspaceRepository.open(directory);
      final migrated = await current(target.id);
      expect(migrated.archiveLocation!.year, 2023);
      expect(migrated.id, target.id);
      expect((await repo.readNote(target.id)).text, '# Inhalt');
      expect((await repo.backlinks(target.id)).single.id, source.id);
      expect(buildArchiveTree(await repo.getEntries()).single.title, '2023');
    },
  );

  test(
    'Markdown picker/drop import creates editable notes without changing sources',
    () async {
      final source = File(p.join(directory.path, 'Gedanken.MD'));
      await source.writeAsString('# Grüße\n\nZwei **Ideen**.\n');
      final importer = WorkspaceImporter(repo);
      final note = await importer.importPath(XFile(source.path));
      expect(note.kind, EntryKind.note);
      expect(note.title, 'Gedanken');
      expect(note.section, ParaSection.inbox);
      expect(
        (await repo.readNote(note.id)).text,
        '# Grüße\n\nZwei **Ideen**.\n',
      );
      expect(await source.readAsString(), '# Grüße\n\nZwei **Ideen**.\n');
      final file = await importer.importFile(
        XFile.fromData(Uint8List.fromList([255, 254, 0, 1]), path: 'binary.md'),
      );
      expect(file.kind, EntryKind.file);
      expect(await File(await repo.filePath(file.id)).readAsBytes(), [
        255,
        254,
        0,
        1,
      ]);
    },
  );

  test(
    'directory import preserves folders and classifies Markdown in projects',
    () async {
      final project = await repo.create(
        kind: EntryKind.project,
        draft: EntryDraft(
          title: 'Projekt',
          goal: 'Fertig',
          dueDate: DateTime(2026, 12, 1),
        ),
      );
      final source = await Directory(
        p.join(directory.path, 'Quelle', 'Planung'),
      ).create(recursive: true);
      await File(p.join(source.path, 'Notiz.md')).writeAsString('Notiztext');
      await File(p.join(source.path, 'Datei.bin')).writeAsBytes([10, 20]);
      final imported = await WorkspaceImporter(repo).importPath(
        XFile(source.parent.path),
        section: ParaSection.projects,
        parentId: project.id,
      );
      final all = await repo.getEntries();
      expect(imported.kind, EntryKind.folder);
      expect(imported.parentId, project.id);
      final note = all.singleWhere((e) => e.kind == EntryKind.note);
      expect(ancestorsOf(note, all).map((e) => e.title), [
        'Planung',
        'Quelle',
        'Projekt',
      ]);
      expect(note.section, ParaSection.projects);
      expect(all.where((e) => e.kind == EntryKind.file), hasLength(1));
    },
  );

  test(
    'idea conversion preserves Markdown and both directions of links',
    () async {
      final target = await repo.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Wissen'),
      );
      final idea = await repo.create(
        kind: EntryKind.idea,
        draft: EntryDraft(
          title: 'Serveridee',
          body: 'Plan\n\n${markdownLink(target)}',
        ),
      );
      final reference = await repo.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: 'Verweis', body: markdownLink(idea)),
      );
      final project = await repo.convertToProject(
        idea.id,
        expectedRevision: idea.revision,
        draft: EntryDraft(
          title: 'Server einrichten',
          goal: 'Sicherung läuft',
          dueDate: DateTime(2026, 12, 20),
        ),
      );
      expect(project.id, idea.id);
      expect(project.kind, EntryKind.project);
      expect(project.section, ParaSection.projects);
      expect(project.taskState, TaskState.inbox);
      expect(
        (await repo.readNote(project.id)).text,
        'Plan\n\n${markdownLink(target)}',
      );
      expect((await repo.backlinks(project.id)).single.id, reference.id);
      expect((await repo.outgoingLinks(project.id)).single.id, target.id);
    },
  );

  test(
    'only eligible ideas/tasks convert and invalid projects leave the source intact',
    () async {
      final task = await repo.create(
        kind: EntryKind.task,
        draft: const EntryDraft(
          title: 'Zurückgestellt',
          taskState: TaskState.someday,
          body: 'Details',
        ),
      );
      await expectLater(
        repo.convertToProject(
          task.id,
          expectedRevision: task.revision,
          draft: const EntryDraft(title: 'Ohne Datum'),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      expect((await current(task.id)).kind, EntryKind.task);
      final converted = await repo.convertToProject(
        task.id,
        expectedRevision: task.revision,
        draft: EntryDraft(
          title: task.title,
          goal: 'Ergebnis',
          dueDate: DateTime(2026, 12, 20),
        ),
      );
      expect(converted.kind, EntryKind.project);
      expect((await repo.readNote(task.id)).text, 'Details');
      await expectLater(
        repo.convertToProject(
          converted.id,
          expectedRevision: converted.revision,
          draft: EntryDraft(
            title: 'Noch einmal',
            goal: 'Ergebnis',
            dueDate: DateTime(2026, 12, 20),
          ),
        ),
        throwsA(isA<WorkspaceException>()),
      );
    },
  );

  test(
    'Markdown links use the same stream path for byte-backed drop items',
    () async {
      final note = await WorkspaceImporter(repo).importFile(
        XFile.fromData(
          Uint8List.fromList(utf8.encode('# Eintrag\n\nText')),
          path: 'Eintrag.markdown',
        ),
      );
      expect(note.kind, EntryKind.note);
      expect((await repo.readNote(note.id)).text, '# Eintrag\n\nText');
    },
  );
}
