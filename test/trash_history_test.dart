import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/domain/search.dart';
import 'package:para_workspace/ui/entry_actions.dart';

void main() {
  late Directory directory;
  late LocalWorkspaceRepository repo;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('para-trash-');
    repo = await LocalWorkspaceRepository.open(directory);
  });
  tearDown(() async {
    await repo.close();
    await directory.delete(recursive: true);
  });

  Future<Entry> note(
    String title, {
    String? parentId,
    String body = 'Erster Text',
  }) => repo.create(
    kind: EntryKind.note,
    parentId: parentId,
    draft: EntryDraft(title: title, body: body),
  );
  Future<Entry> current(String id) async =>
      (await repo.getEntries()).firstWhere((e) => e.id == id);
  Future<void> save(String id, String body, {String? title}) async {
    final entry = await current(id), snapshot = await repo.readNote(id);
    await repo.save(
      id: id,
      expectedRevision: entry.revision,
      expectedBodyHash: snapshot.hash,
      draft: EntryDraft(title: title ?? entry.title, body: body),
    );
  }

  Future<void> reopen() async {
    await repo.close();
    repo = await LocalWorkspaceRepository.open(directory);
  }

  test(
    'trash keeps links, bytes and versions, survives reopen and excludes search',
    () async {
      final target = await note('Ziel');
      final source = await note('Quelle', body: markdownLink(target));
      await save(target.id, 'Zweiter Text');
      await repo.trash(target.id);
      expect((await repo.getEntries()).map((e) => e.id), [source.id]);
      await reopen();
      final trashed = (await repo.getTrash()).single;
      expect(trashed.id, target.id);
      expect((await repo.readNote(target.id)).text, 'Zweiter Text');
      expect((await repo.noteVersions(target.id)).length, 2);
      expect((await repo.backlinks(target.id)).single.id, source.id);
      expect((await repo.outgoingLinks(source.id)).single.inTrash, isTrue);
      expect(searchWorkspace([trashed], 'Ziel'), isEmpty);
      expect(availableEntryActions(trashed, [trashed]).map((e) => e.id), [
        'copy',
        'trash-restore',
        'purge',
      ]);
      await expectLater(save(target.id, 'Nein'), throwsA(isA<StateError>()));
      final snapshot = await repo.readNote(target.id);
      await expectLater(
        repo.save(
          id: target.id,
          expectedRevision: trashed.revision,
          expectedBodyHash: snapshot.hash,
          draft: const EntryDraft(title: 'Ziel', body: 'Nein'),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      await repo.restoreTrash(target.id);
      expect((await current(target.id)).id, target.id);
      expect((await repo.backlinks(target.id)).single.id, source.id);
    },
  );

  test(
    'restoring a folder keeps independently trashed children separate across repeated cycles',
    () async {
      final folder = await repo.create(
        kind: EntryKind.folder,
        draft: const EntryDraft(title: 'Ordner'),
      );
      final child = await note('Mitnehmen', parentId: folder.id);
      final earlier = await note('Schon entfernt', parentId: folder.id);
      await repo.trash(earlier.id);
      await repo.trash(folder.id);
      final firstBatch = (await repo.getTrash())
          .firstWhere((e) => e.id == folder.id)
          .trashBatchId;
      await repo.restoreTrash(folder.id);
      expect((await current(child.id)).parentId, folder.id);
      expect((await repo.getTrash()).single.id, earlier.id);
      await repo.trash(folder.id);
      expect(
        (await repo.getTrash())
            .firstWhere((e) => e.id == folder.id)
            .trashBatchId,
        isNot(firstBatch),
      );
      await repo.restoreTrash(folder.id);
      expect((await repo.getTrash()).single.id, earlier.id);
      await repo.restoreTrash(earlier.id);
      expect((await current(earlier.id)).parentId, folder.id);
    },
  );

  test(
    'restoring a child from a trashed project needs a valid destination and keeps its UUID',
    () async {
      final project = await repo.create(
        kind: EntryKind.project,
        draft: EntryDraft(
          title: 'Projekt',
          goal: 'Ergebnis',
          dueDate: DateTime(2026, 12, 1),
        ),
      );
      final child = await note('Kind', parentId: project.id);
      await repo.trash(project.id);
      await expectLater(
        repo.restoreTrash(child.id),
        throwsA(isA<WorkspaceException>()),
      );
      await expectLater(
        repo.restoreTrash(child.id, section: ParaSection.projects),
        throwsA(isA<WorkspaceException>()),
      );
      await repo.restoreTrash(child.id, section: ParaSection.resources);
      expect((await current(child.id)).section, ParaSection.resources);
      expect((await current(child.id)).parentId, isNull);
      await repo.permanentlyDelete(project.id);
      expect((await repo.readNote(child.id)).text, 'Erster Text');
    },
  );

  test(
    'archived descendants and task state retain their meaning through trash',
    () async {
      final project = await repo.create(
        kind: EntryKind.project,
        draft: EntryDraft(
          title: 'Alt',
          goal: 'Ergebnis',
          dueDate: DateTime(2026, 12, 1),
        ),
      );
      final task = await repo.create(
        kind: EntryKind.task,
        parentId: project.id,
        draft: const EntryDraft(title: 'Aufgabe', taskState: TaskState.waiting),
      );
      await repo.setTaskState(task.id, TaskState.cancelled);
      await repo.archive(project.id, true);
      await repo.trash(task.id);
      await repo.restoreTrash(task.id, section: ParaSection.inbox);
      final restored = await current(task.id);
      expect(restored.archived, isTrue);
      expect(
        restored.archiveLocation!.ancestors.map((e) => e.id),
        contains(project.id),
      );
      expect(restored.taskState, TaskState.cancelled);
      expect(restored.previousTaskState, TaskState.waiting);
    },
  );

  test(
    'permanent removal includes separately trashed descendants, files and histories',
    () async {
      final folder = await repo.create(
        kind: EntryKind.folder,
        draft: const EntryDraft(title: 'Ordner'),
      );
      final child = await note('Kind', parentId: folder.id);
      final attachment = await repo.importFile(
        name: 'datei.bin',
        parentId: folder.id,
        bytes: Stream.value([1, 2, 3]),
      );
      final filePath = await repo.filePath(attachment.id);
      final source = await note('Quelle', body: markdownLink(child));
      await repo.trash(child.id);
      await repo.trash(folder.id);
      await expectLater(
        repo.permanentlyDelete(source.id),
        throwsA(isA<WorkspaceException>()),
      );
      await repo.permanentlyDelete(folder.id);
      expect(await repo.getTrash(), isEmpty);
      expect(await File(filePath).exists(), isFalse);
      expect(
        await File(p.join(directory.path, 'notes', '${child.id}.md')).exists(),
        isFalse,
      );
      expect(await repo.outgoingLinks(source.id), isEmpty);
      expect(
        await repo.database.select(repo.database.noteVersions).get(),
        hasLength(1),
      );
      await reopen();
      expect((await repo.getEntries()).single.id, source.id);
    },
  );

  test(
    'trash round trip preserves inherited archive flags when the project becomes active again',
    () async {
      final project = await repo.create(
        kind: EntryKind.project,
        draft: EntryDraft(
          title: 'Archivprojekt',
          goal: 'Ergebnis',
          dueDate: DateTime(2026, 12, 1),
        ),
      );
      final child = await note('Kind', parentId: project.id);
      await repo.archive(project.id, true);
      await repo.trash(project.id);
      await repo.restoreTrash(project.id);
      expect((await current(child.id)).archived, isFalse);
      expect(
        isArchived(await current(child.id), await repo.getEntries()),
        isTrue,
      );
      await repo.archive(project.id, false);
      expect(
        isArchived(await current(child.id), await repo.getEntries()),
        isFalse,
      );
    },
  );

  test('empty trash leaves active data intact', () async {
    final one = await note('Weg'), keep = await note('Bleibt');
    await repo.trash(one.id);
    await repo.emptyTrash();
    await repo.emptyTrash();
    expect((await repo.getEntries()).single.id, keep.id);
    expect(await repo.getTrash(), isEmpty);
  });

  test(
    'failed permanent removal rolls back metadata, history and staged bytes',
    () async {
      final entry = await note('Behalten');
      await repo.trash(entry.id);
      await repo.database.customStatement(
        "CREATE TRIGGER reject_removal BEFORE DELETE ON entries BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      await expectLater(
        repo.permanentlyDelete(entry.id),
        throwsA(
          predicate((error) => error.toString().contains('injected failure')),
        ),
      );
      expect((await repo.getTrash()).single.id, entry.id);
      expect((await repo.readNote(entry.id)).text, 'Erster Text');
      expect(await repo.noteVersions(entry.id), hasLength(1));
      expect(
        (await directory.list().toList()).where(
          (e) => p.basename(e.path).startsWith('.purging-'),
        ),
        isEmpty,
      );
      await repo.database.customStatement('DROP TRIGGER reject_removal');
      await repo.permanentlyDelete(entry.id);
      expect(await repo.getTrash(), isEmpty);
    },
  );

  test(
    'restoring a text version rebuilds links to trash and is blocked in archive and trash',
    () async {
      final target = await note('Ziel');
      final source = await note('Quelle', body: markdownLink(target));
      await save(source.id, 'Ohne Link');
      final version = (await repo.noteVersions(source.id)).last;
      await repo.trash(target.id);
      var state = await current(source.id),
          snapshot = await repo.readNote(source.id);
      await repo.restoreNoteVersion(
        source.id,
        version.id,
        expectedRevision: state.revision,
        expectedBodyHash: snapshot.hash,
      );
      expect((await repo.backlinks(target.id)).single.id, source.id);
      await repo.archive(source.id, true);
      state = await current(source.id);
      snapshot = await repo.readNote(source.id);
      await expectLater(
        repo.restoreNoteVersion(
          source.id,
          version.id,
          expectedRevision: state.revision,
          expectedBodyHash: snapshot.hash,
        ),
        throwsA(isA<WorkspaceException>()),
      );
      await repo.trash(source.id);
      await expectLater(
        repo.restoreNoteVersion(
          source.id,
          version.id,
          expectedRevision: state.revision,
          expectedBodyHash: snapshot.hash,
        ),
        throwsA(isA<WorkspaceException>()),
      );
    },
  );

  test(
    'history records text changes in save order and restores as a new version',
    () async {
      final entry = await note('Titel', body: 'A');
      await save(entry.id, 'B');
      await save(entry.id, 'B', title: 'Neuer Titel');
      await save(entry.id, 'C');
      var versions = await repo.noteVersions(entry.id);
      expect(versions.map((e) => e.body), ['C', 'B', 'A']);
      final state = await current(entry.id),
          snapshot = await repo.readNote(entry.id);
      await repo.restoreNoteVersion(
        entry.id,
        versions.last.id,
        expectedRevision: state.revision,
        expectedBodyHash: snapshot.hash,
      );
      versions = await repo.noteVersions(entry.id);
      expect(versions.map((e) => e.body), ['A', 'C', 'B', 'A']);
      expect((await current(entry.id)).title, 'Neuer Titel');
      await reopen();
      expect((await repo.readNote(entry.id)).text, 'A');
      expect(await repo.noteVersions(entry.id), hasLength(4));
    },
  );

  test(
    'history preserves first observed old text and rejects stale and unrelated restores',
    () async {
      final file = await repo.importFile(
        name: 'Text.txt',
        bytes: Stream.value(utf8.encode('Alt')),
      );
      await save(file.id, 'Neu');
      final versions = await repo.noteVersions(file.id);
      expect(versions.map((e) => e.body), ['Neu', 'Alt']);
      final state = await current(file.id),
          snapshot = await repo.readNote(file.id);
      await save(file.id, 'Noch neuer');
      await expectLater(
        repo.restoreNoteVersion(
          file.id,
          versions.last.id,
          expectedRevision: state.revision,
          expectedBodyHash: snapshot.hash,
        ),
        throwsA(isA<WorkspaceException>()),
      );
      final other = await note('Anders');
      final otherSnapshot = await repo.readNote(other.id);
      await expectLater(
        repo.restoreNoteVersion(
          other.id,
          versions.last.id,
          expectedRevision: other.revision,
          expectedBodyHash: otherSnapshot.hash,
        ),
        throwsA(isA<WorkspaceException>()),
      );
      final latest = await current(file.id),
          latestSnapshot = await repo.readNote(file.id);
      await File(await repo.filePath(file.id)).writeAsString('Extern');
      await expectLater(
        repo.restoreNoteVersion(
          file.id,
          versions.last.id,
          expectedRevision: latest.revision,
          expectedBodyHash: latestSnapshot.hash,
        ),
        throwsA(isA<WorkspaceException>()),
      );
      expect((await repo.readNote(file.id)).text, 'Extern');
    },
  );

  test(
    'backup independently restores trash bytes, links, and complete text histories',
    () async {
      final destination = await Directory.systemTemp.createTemp(
        'para-trash-backup-',
      );
      addTearDown(() => destination.delete(recursive: true));
      final file = await repo.importFile(
        name: 'Text.md',
        bytes: Stream.value(utf8.encode('Alt')),
      );
      final source = await note('Quelle', body: markdownLink(file));
      await save(file.id, 'Neu');
      await repo.trash(file.id);
      final path = await repo.exportBackup(destination.path);
      await repo.close();
      final copy = await LocalWorkspaceRepository.open(Directory(path));
      try {
        expect((await copy.getTrash()).single.id, file.id);
        expect((await copy.noteVersions(file.id)).map((e) => e.body), [
          'Neu',
          'Alt',
        ]);
        expect((await copy.readNote(file.id)).text, 'Neu');
        expect((await copy.backlinks(file.id)).single.id, source.id);
        await copy.restoreTrash(file.id);
        expect((await copy.getEntries()).length, 2);
      } finally {
        await copy.close();
        repo = await LocalWorkspaceRepository.open(directory);
      }
    },
  );

  test(
    'schema 3 migration preserves old notes, files and links without requiring history',
    () async {
      final entry = await note('Bestehend');
      final file = await repo.importFile(
        name: 'Text.txt',
        bytes: Stream.value([65]),
      );
      final source = await note('Link', body: markdownLink(file));
      await repo.close();
      final legacy = sqlite3.open(p.join(directory.path, 'workspace.sqlite'));
      legacy.execute('DROP TABLE note_versions');
      legacy.execute('ALTER TABLE entries DROP COLUMN trash_batch_id');
      legacy.execute('ALTER TABLE entries DROP COLUMN trash_location');
      legacy.execute('ALTER TABLE entries DROP COLUMN trash_archived');
      legacy.execute('PRAGMA user_version = 3');
      legacy.close();
      repo = await LocalWorkspaceRepository.open(directory);
      expect((await repo.readNote(entry.id)).text, 'Erster Text');
      expect((await repo.readNote(file.id)).text, 'A');
      expect((await repo.backlinks(file.id)).single.id, source.id);
      expect(await repo.noteVersions(entry.id), isEmpty);
      await save(entry.id, 'Geändert');
      expect((await repo.noteVersions(entry.id)).map((e) => e.body), [
        'Geändert',
        'Erster Text',
      ]);
    },
  );

  test(
    'interrupted purge restores staged bytes before commit and removes them after commit',
    () async {
      final entry = await note('Weg');
      await repo.trash(entry.id);
      final stage = await Directory(
        p.join(directory.path, '.purging-test'),
      ).create();
      await File(p.join(stage.path, 'manifest.json')).writeAsString(
        jsonEncode([
          {'id': entry.id, 'file': false},
        ]),
      );
      await File(
        p.join(directory.path, 'notes', '${entry.id}.md'),
      ).rename(p.join(stage.path, entry.id));
      await reopen();
      expect((await repo.readNote(entry.id)).text, 'Erster Text');
      expect(await stage.exists(), isFalse);
      await repo.permanentlyDelete(entry.id);
      await stage.create();
      await File(p.join(stage.path, 'manifest.json')).writeAsString(
        jsonEncode([
          {'id': entry.id, 'file': false},
        ]),
      );
      await File(p.join(stage.path, entry.id)).writeAsString('Restbytes');
      await reopen();
      expect(await stage.exists(), isFalse);
      expect(await repo.getTrash(), isEmpty);
    },
  );
}
