import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/domain/search.dart';
import 'package:para_workspace/services/file_formats.dart';

void main() {
  late Directory directory;
  late LocalWorkspaceRepository repo;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('para-target-');
    repo = await LocalWorkspaceRepository.open(directory);
  });
  tearDown(() async {
    await repo.close();
    await directory.delete(recursive: true);
  });
  test('v2 migration preserves task identity and previous status', () async {
    final task = await repo.create(
      kind: EntryKind.task,
      draft: const EntryDraft(title: 'Vorhanden', taskState: TaskState.someday),
    );
    await repo.close();
    final legacy = sqlite3.open('${directory.path}/workspace.sqlite');
    legacy.execute('DROP TABLE task_contexts');
    legacy.execute('DROP TABLE workspace_settings');
    legacy.execute('ALTER TABLE entries DROP COLUMN context_ids');
    legacy.execute('ALTER TABLE entries DROP COLUMN estimated_minutes');
    legacy.execute('ALTER TABLE entries DROP COLUMN energy');
    legacy.execute('DROP TABLE note_versions');
    legacy.execute('ALTER TABLE entries DROP COLUMN trash_batch_id');
    legacy.execute('ALTER TABLE entries DROP COLUMN trash_location');
    legacy.execute('ALTER TABLE entries DROP COLUMN trash_archived');
    legacy.execute('ALTER TABLE entries DROP COLUMN previous_task_state');
    legacy.execute('PRAGMA user_version = 2');
    legacy.close();
    repo = await LocalWorkspaceRepository.open(directory);
    var current = (await repo.getEntries()).single;
    expect(current.id, task.id);
    expect(current.taskState, TaskState.someday);
    await repo.setTaskState(current.id, TaskState.cancelled);
    await repo.close();
    repo = await LocalWorkspaceRepository.open(directory);
    current = (await repo.getEntries()).single;
    expect(current.taskState, TaskState.cancelled);
    expect(current.previousTaskState, TaskState.someday);
  });
  test(
    'cancelled tasks survive reopening and remember their working state',
    () async {
      final task = await repo.create(
        kind: EntryKind.task,
        draft: const EntryDraft(
          title: 'Antwort abwarten',
          taskState: TaskState.waiting,
        ),
      );
      await repo.setTaskState(task.id, TaskState.cancelled);
      await repo.close();
      repo = await LocalWorkspaceRepository.open(directory);
      var item = (await repo.getEntries()).single;
      expect(item.taskState, TaskState.cancelled);
      expect(item.previousTaskState, TaskState.waiting);
      await repo.setTaskState(item.id, TaskState.done);
      item = (await repo.getEntries()).single;
      expect(item.previousTaskState, TaskState.waiting);
      await repo.setTaskState(item.id, item.previousTaskState!);
      item = (await repo.getEntries()).single;
      expect(item.taskState, TaskState.waiting);
      expect(item.previousTaskState, isNull);
      await repo.archive(item.id, true);
      await expectLater(
        repo.setTaskState(item.id, TaskState.cancelled),
        throwsA(isA<WorkspaceException>()),
      );
    },
  );
  test(
    'TXT saves bytes and index, survives reopen and rejects external changes',
    () async {
      final file = await repo.importFile(
        name: 'Gedanken.txt',
        bytes: Stream.value(utf8.encode('Alt')),
      );
      var snapshot = await repo.readNote(file.id);
      expect(snapshot.editable, isTrue);
      await repo.save(
        id: file.id,
        expectedRevision: file.revision,
        expectedBodyHash: snapshot.hash,
        draft: const EntryDraft(
          title: 'Gedanken.txt',
          body: 'Grüße aus der neuen Oberfläche.',
        ),
      );
      expect(
        await File(await repo.filePath(file.id)).readAsString(),
        'Grüße aus der neuen Oberfläche.',
      );
      await repo.close();
      repo = await LocalWorkspaceRepository.open(directory);
      final current = (await repo.getEntries()).single;
      expect(current.searchText, contains('Grüße'));
      expect(current.fileSize, utf8.encode(current.searchText).length);
      snapshot = await repo.readNote(file.id);
      await File(await repo.filePath(file.id)).writeAsString('Extern geändert');
      await expectLater(
        repo.save(
          id: file.id,
          expectedRevision: current.revision,
          expectedBodyHash: snapshot.hash,
          draft: const EntryDraft(
            title: 'Gedanken.txt',
            body: 'Nicht überschreiben',
          ),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      expect(
        await File(await repo.filePath(file.id)).readAsString(),
        'Extern geändert',
      );
    },
  );
  test(
    'legacy attachment aliases keep their original file extension on text save',
    () async {
      final file = await repo.importFile(
        name: 'Original.txt',
        bytes: Stream.value(utf8.encode('Alt')),
      );
      await repo.database.customStatement(
        'UPDATE entries SET title = ? WHERE id = ?',
        ['Anzeigename', file.id],
      );
      final entry = (await repo.getEntries()).single,
          snapshot = await repo.readNote(file.id);
      await repo.save(
        id: file.id,
        expectedRevision: entry.revision,
        expectedBodyHash: snapshot.hash,
        draft: const EntryDraft(title: 'Anzeigename', body: 'Neuer Text'),
      );
      final saved = (await repo.getEntries()).single;
      expect(saved.title, 'Anzeigename');
      expect(saved.fileName, 'Original.txt');
      expect((await repo.readNote(file.id)).text, 'Neuer Text');
      expect((await repo.readNote(file.id)).editable, isTrue);
    },
  );
  test(
    'renaming an attachment changes its real file name without breaking links',
    () async {
      final file = await repo.importFile(
        name: 'Alt.txt',
        bytes: Stream.value(utf8.encode('Erhalten')),
      );
      final oldPath = await repo.filePath(file.id);
      await repo.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: 'Verweis', body: markdownLink(file)),
      );
      final snapshot = await repo.readNote(file.id);
      await repo.save(
        id: file.id,
        expectedRevision: file.revision,
        expectedBodyHash: snapshot.hash,
        draft: const EntryDraft(title: 'Neu.txt', body: 'Erhalten'),
      );
      final current = (await repo.getEntries()).firstWhere(
        (e) => e.id == file.id,
      );
      expect(current.fileName, 'Neu.txt');
      expect(await File(oldPath).exists(), isFalse);
      expect(
        await File(await repo.filePath(file.id)).readAsString(),
        'Erhalten',
      );
      expect(await repo.backlinks(file.id), hasLength(1));
      final now = await repo.readNote(file.id);
      await expectLater(
        repo.save(
          id: file.id,
          expectedRevision: current.revision,
          expectedBodyHash: now.hash,
          draft: const EntryDraft(
            title: '../falsch.txt',
            body: 'Nicht schreiben',
          ),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      expect((await repo.readNote(file.id)).text, 'Erhalten');
    },
  );
  test(
    'binary and oversized text remain attachments; CSV quoted fields render correctly',
    () async {
      final binary = await repo.importFile(
        name: 'KeinText.txt',
        bytes: Stream.value([0xff, 0x00, 0xff]),
      );
      expect((await repo.readNote(binary.id)).editable, isFalse);
      expect(
        csvPreview('Titel,Notiz\r\n"A,B","mehr\nText"\r\n"Zitat","""Hallo"""'),
        [
          ['Titel', 'Notiz'],
          ['A,B', 'mehr\nText'],
          ['Zitat', '"Hallo"'],
        ],
      );
      final oversized = File('${directory.path}/large.txt');
      final writer = oversized.openWrite();
      writer.add(List.filled(maxTextFileBytes + 1, 65));
      await writer.close();
      expect(await readSmallTextFile(oversized), isNull);
    },
  );
  test(
    'fuzzy names and file contents match, name-only search keeps its scope',
    () async {
      final image = await repo.importFile(
        name: 'Grundriss.svg',
        bytes: Stream.value(utf8.encode('<svg/>')),
      );
      final text = await repo.importFile(
        name: 'Notizen.txt',
        bytes: Stream.value(utf8.encode('Wände vorbereiten und streichen')),
      );
      final entries = await repo.getEntries();
      expect(searchWorkspace(entries, 'grndriss').first.entry.id, image.id);
      expect(
        searchWorkspace(entries, 'wande streichen').single.entry.id,
        text.id,
      );
      expect(searchWorkspace(entries, 'streichen', filesOnly: true), isEmpty);
    },
  );
  test(
    'folder moves to Areas preserve descendants, file contents and link identities',
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
        draft: const EntryDraft(title: 'Ordner'),
      );
      final file = await repo.importFile(
        name: 'Text.txt',
        parentId: folder.id,
        bytes: Stream.value(utf8.encode('Inhalt')),
      );
      final task = await repo.create(
        kind: EntryKind.task,
        parentId: folder.id,
        draft: const EntryDraft(title: 'Aktion', taskState: TaskState.next),
      );
      await repo.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: 'Link', body: markdownLink(file)),
      );
      await repo.move(folder.id, ParaSection.areas);
      final entries = await repo.getEntries(),
          moved = entries.firstWhere((e) => e.id == file.id),
          movedTask = entries.firstWhere((e) => e.id == task.id);
      expect(moved.section, ParaSection.areas);
      expect(
        ancestorsOf(
          movedTask,
          entries,
        ).where((e) => e.kind == EntryKind.project),
        isEmpty,
      );
      expect((await repo.readNote(file.id)).text, 'Inhalt');
      expect(await repo.backlinks(file.id), hasLength(1));
      await expectLater(
        repo.move(folder.id, ParaSection.areas, parentId: folder.id),
        throwsA(isA<WorkspaceException>()),
      );
    },
  );
}
