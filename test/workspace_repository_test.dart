import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';

void main() {
  late Directory directory;
  late LocalWorkspaceRepository repo;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('para-repository-');
    repo = await LocalWorkspaceRepository.open(directory);
  });
  tearDown(() async {
    await repo.close();
    await directory.delete(recursive: true);
  });
  Future<Entry> project() => repo.create(
    kind: EntryKind.project,
    draft: EntryDraft(
      title: 'Renovieren',
      goal: 'Arbeitszimmer fertig',
      dueDate: DateTime(2026, 12, 15),
    ),
  );
  Future<Entry> current(String id) async =>
      (await repo.getEntries()).firstWhere((entry) => entry.id == id);
  Future<void> save(Entry entry, {String? title, String body = ''}) async {
    final snapshot = await repo.readNote(entry.id);
    await repo.save(
      id: entry.id,
      expectedRevision: entry.revision,
      expectedBodyHash: snapshot.hash,
      draft: EntryDraft(
        title: title ?? entry.title,
        body: body,
        goal: entry.goal,
        dueDate: entry.dueDate,
        taskState: entry.taskState,
        context: entry.context,
      ),
    );
  }

  test(
    'projects require an outcome and calendar deadline, never a someday status',
    () async {
      await expectLater(
        repo.create(
          kind: EntryKind.project,
          draft: const EntryDraft(title: 'Unbegrenzt'),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      await expectLater(
        repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Später',
            goal: 'Ergebnis',
            dueDate: DateTime(2026, 12, 15),
            taskState: TaskState.someday,
          ),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      final entry = await project();
      expect(entry.section, ParaSection.projects);
      expect(entry.dueDate, DateTime(2026, 12, 15));
      final idea = await repo.create(
        kind: EntryKind.idea,
        draft: const EntryDraft(title: 'Vielleicht irgendwann'),
      );
      expect(idea.kind, EntryKind.idea);
      expect(idea.dueDate, isNull);
    },
  );

  test(
    'several Markdown notes survive closing and reopening the workspace',
    () async {
      final parent = await project();
      final one = await repo.create(
        kind: EntryKind.note,
        parentId: parent.id,
        draft: const EntryDraft(title: 'Plan', body: '# Planung\n\nGedanken'),
      );
      final two = await repo.create(
        kind: EntryKind.note,
        parentId: parent.id,
        draft: const EntryDraft(
          title: 'Entscheidungen',
          body: 'Eine zweite Notiz.',
        ),
      );
      expect(
        await File(
          p.join(directory.path, 'notes', '${one.id}.md'),
        ).readAsString(),
        '# Planung\n\nGedanken',
      );
      await repo.close();
      repo = await LocalWorkspaceRepository.open(directory);
      expect(
        (await repo.getEntries()).where((e) => e.parentId == parent.id),
        hasLength(2),
      );
      expect((await repo.readNote(two.id)).text, 'Eine zweite Notiz.');
    },
  );

  test(
    'links and backlinks survive renaming and moving, code is not a link',
    () async {
      final parent = await project();
      final folder = await repo.create(
        kind: EntryKind.folder,
        parentId: parent.id,
        draft: const EntryDraft(title: 'Unterlagen'),
      );
      final target = await repo.create(
        kind: EntryKind.note,
        parentId: parent.id,
        draft: const EntryDraft(title: 'Ziel [mit Klammern]'),
      );
      final source = await repo.create(
        kind: EntryKind.note,
        parentId: parent.id,
        draft: EntryDraft(title: 'Quelle', body: markdownLink(target)),
      );
      expect((await repo.backlinks(target.id)).single.id, source.id);
      await save(target, title: 'Neuer Titel');
      await repo.move(target.id, ParaSection.projects, parentId: folder.id);
      expect((await repo.outgoingLinks(source.id)).single.title, 'Neuer Titel');
      expect((await repo.backlinks(target.id)).single.id, source.id);
      await save(
        source,
        body:
            'Nur Code: ${String.fromCharCode(96)}${markdownLink(target)}${String.fromCharCode(96)}',
      );
      expect(await repo.backlinks(target.id), isEmpty);
    },
  );

  test('folder moves update descendants and reject cycles', () async {
    final parent = await project();
    final folder = await repo.create(
      kind: EntryKind.folder,
      parentId: parent.id,
      draft: const EntryDraft(title: 'Ordner'),
    );
    final child = await repo.create(
      kind: EntryKind.folder,
      parentId: folder.id,
      draft: const EntryDraft(title: 'Unterordner'),
    );
    final note = await repo.create(
      kind: EntryKind.note,
      parentId: child.id,
      draft: const EntryDraft(title: 'Notiz'),
    );
    await expectLater(
      repo.move(folder.id, ParaSection.projects, parentId: child.id),
      throwsA(isA<WorkspaceException>()),
    );
    await repo.move(folder.id, ParaSection.resources);
    expect((await current(note.id)).section, ParaSection.resources);
    expect((await current(child.id)).parentId, folder.id);
  });

  test(
    'archived or completed project actions are excluded through nested folders',
    () async {
      final parent = await project();
      final folder = await repo.create(
        kind: EntryKind.folder,
        parentId: parent.id,
        draft: const EntryDraft(title: 'Planung'),
      );
      final task = await repo.create(
        kind: EntryKind.task,
        parentId: folder.id,
        draft: const EntryDraft(title: 'Anrufen', taskState: TaskState.next),
      );
      expect(isActiveTask(task, await repo.getEntries()), isTrue);
      await repo.completeProject(parent.id);
      expect(isActiveTask(task, await repo.getEntries()), isFalse);
      await repo.archive(parent.id, false);
      expect(isActiveTask(task, await repo.getEntries()), isTrue);
      expect((await current(parent.id)).completed, isFalse);
    },
  );

  test(
    'rejects stale revisions and externally edited Markdown without overwriting',
    () async {
      final note = await repo.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Notiz', body: 'Ursprünglich'),
      );
      final original = await repo.readNote(note.id);
      await save(note, body: 'Gespeichert');
      await expectLater(
        repo.save(
          id: note.id,
          expectedRevision: note.revision,
          expectedBodyHash: original.hash,
          draft: const EntryDraft(title: 'Alt', body: 'Veraltet'),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      final fresh = await current(note.id);
      final snapshot = await repo.readNote(note.id);
      await File(
        p.join(directory.path, 'notes', '${note.id}.md'),
      ).writeAsString('Extern geändert');
      await expectLater(
        repo.save(
          id: note.id,
          expectedRevision: fresh.revision,
          expectedBodyHash: snapshot.hash,
          draft: const EntryDraft(title: 'Neu', body: 'Überschreiben'),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      expect((await repo.readNote(note.id)).text, 'Extern geändert');
    },
  );

  test(
    'missing Markdown reports an error instead of creating an empty replacement',
    () async {
      final note = await repo.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Wichtig', body: 'Inhalt'),
      );
      await File(p.join(directory.path, 'notes', '${note.id}.md')).delete();
      await expectLater(
        repo.readNote(note.id),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'imports file streams, sanitizes paths and cleans failed imports',
    () async {
      final file = await repo.importFile(
        name: '../../backup.bin',
        bytes: Stream.fromIterable(
          List.generate(128, (_) => List.filled(8192, 42)),
        ),
      );
      expect(file.fileName, 'backup.bin');
      expect(file.fileSize, 1024 * 1024);
      expect(await File(await repo.filePath(file.id)).length(), 1024 * 1024);
      await expectLater(
        repo.importFile(
          name: 'defekt.zip',
          bytes: Stream<List<int>>.error(
            const WorkspaceException('Testfehler'),
          ),
        ),
        throwsA(isA<WorkspaceException>()),
      );
      expect(
        (await repo.getEntries()).where((e) => e.kind == EntryKind.file),
        hasLength(1),
      );
      expect(await Directory(p.join(directory.path, 'files')).list().length, 1);
    },
  );

  test(
    'backup reopens independently with notes, files and stable links',
    () async {
      final destination = await Directory.systemTemp.createTemp('para-backup-');
      addTearDown(() => destination.delete(recursive: true));
      final target = await repo.importFile(
        name: 'Daten.txt',
        bytes: Stream.value([65, 66, 67]),
      );
      final note = await repo.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: 'Quelle', body: markdownLink(target)),
      );
      final backup = await repo.exportBackup(destination.path);
      await repo.close();
      final restored = await LocalWorkspaceRepository.open(Directory(backup));
      try {
        expect((await restored.readNote(note.id)).text, markdownLink(target));
        expect((await restored.backlinks(target.id)).single.id, note.id);
        expect(
          await File(await restored.filePath(target.id)).readAsString(),
          'ABC',
        );
      } finally {
        await restored.close();
        repo = await LocalWorkspaceRepository.open(directory);
      }
    },
  );

  test('rebuilds derived search and link index after external edits', () async {
    final target = await repo.create(
      kind: EntryKind.note,
      draft: const EntryDraft(title: 'Ziel'),
    );
    final source = await repo.create(
      kind: EntryKind.note,
      draft: const EntryDraft(title: 'Quelle'),
    );
    await repo.close();
    await File(
      p.join(directory.path, 'notes', '${source.id}.md'),
    ).writeAsString('Suchwort ${markdownLink(target)}');
    repo = await LocalWorkspaceRepository.open(directory);
    await repo.searchIndexReady;
    expect((await current(source.id)).searchText, contains('Suchwort'));
    expect((await repo.backlinks(target.id)).single.id, source.id);
  });
}
