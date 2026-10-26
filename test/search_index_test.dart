import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';

// All documents and databases are synthetic and live in a temporary root.
// Completers hold the expensive boundary without timing-dependent sleeps.
void main() {
  late Directory root;
  LocalWorkspaceRepository? repository;
  late List<Completer<String?>> pending;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('para-search-index-');
    repository = null;
    pending = [];
  });
  tearDown(() async {
    for (final gate in pending) {
      if (!gate.isCompleted) gate.complete('released by teardown');
    }
    await repository?.close();
    await root.delete(recursive: true);
  });

  Future<LocalWorkspaceRepository> open({
    Future<String?> Function(String)? extractor,
  }) async {
    final next = await LocalWorkspaceRepository.open(
      root,
      pdfTextExtractor: extractor,
    );
    repository = next;
    return next;
  }

  Completer<String?> gate() {
    final result = Completer<String?>();
    pending.add(result);
    return result;
  }

  Future<Entry> pdf(LocalWorkspaceRepository repo) => repo.importFile(
    name: 'document.pdf',
    bytes: Stream.value(utf8.encode('%PDF synthetic fixture')),
  );

  Future<Entry> current(LocalWorkspaceRepository repo, String id) async =>
      (await repo.getEntries()).firstWhere((entry) => entry.id == id);

  Future<Entry> seedPdf({String text = 'original searchable text'}) async {
    final repo = await open(extractor: (_) async => text);
    final entry = await pdf(repo);
    await repo.searchIndexReady;
    expect((await current(repo, entry.id)).searchText, text);
    await repo.close();
    return entry;
  }

  Future<void> invalidate(String id) async {
    await File(
      p.join(root.path, 'files', id, 'document.pdf'),
    ).writeAsString('%PDF externally changed fixture with new size');
  }

  test(
    'PDF import and unrelated writes finish while extraction is blocked',
    () async {
      final started = Completer<void>(), extracted = gate();
      final repo = await open(
        extractor: (_) {
          if (!started.isCompleted) started.complete();
          return extracted.future;
        },
      );
      await repo.searchIndexReady;
      final entry = await pdf(repo).timeout(const Duration(seconds: 5));
      await started.future.timeout(const Duration(seconds: 5));
      expect(repo.searchIndexStatus.updating, isTrue);
      final note = await repo
          .create(
            kind: EntryKind.note,
            draft: const EntryDraft(
              title: 'Usable immediately',
              body: 'new text',
            ),
          )
          .timeout(const Duration(seconds: 5));
      expect((await current(repo, note.id)).searchText, 'new text');
      extracted.complete('PDF searchable text');
      await repo.searchIndexReady;
      expect((await current(repo, entry.id)).searchText, 'PDF searchable text');
      expect(repo.searchIndexStatus.updating, isFalse);
      expect(repo.searchIndexStatus.failures, 0);
    },
  );

  test(
    'worker started by import respects the exclusive writer queue',
    () async {
      final started = Completer<void>(), extracted = gate();
      final writerEntered = Completer<void>(),
          writerRelease = Completer<void>();
      final repo = await open(
        extractor: (_) {
          started.complete();
          return extracted.future;
        },
      );
      await repo.searchIndexReady;
      final entry = await pdf(repo);
      await started.future;
      final writing = repo.exclusive(() async {
        writerEntered.complete();
        await writerRelease.future;
      });
      await writerEntered.future;
      try {
        extracted.complete('serialized result');
        // Let extraction and the native DB connection run while the writer owns
        // the queue. A worker inheriting the import zone would bypass the lock.
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect((await current(repo, entry.id)).searchText, isEmpty);
        expect(repo.searchIndexStatus.updating, isTrue);
      } finally {
        writerRelease.complete();
        await writing;
      }
      await repo.searchIndexReady;
      expect((await current(repo, entry.id)).searchText, 'serialized result');
    },
  );

  test(
    'opening returns with old index before a changed PDF finishes',
    () async {
      final entry = await seedPdf();
      await invalidate(entry.id);
      final started = Completer<void>(), extracted = gate();
      final repo = await open(
        extractor: (_) {
          started.complete();
          return extracted.future;
        },
      ).timeout(const Duration(seconds: 5));
      await started.future.timeout(const Duration(seconds: 5));
      expect(
        (await current(repo, entry.id)).searchText,
        'original searchable text',
      );
      await repo
          .create(
            kind: EntryKind.note,
            draft: const EntryDraft(title: 'No startup writer lock'),
          )
          .timeout(const Duration(seconds: 5));
      extracted.complete('updated searchable text');
      await repo.searchIndexReady;
      expect(
        (await current(repo, entry.id)).searchText,
        'updated searchable text',
      );
    },
  );

  test('unchanged PDF uses the persistent index on repeated opening', () async {
    final entry = await seedPdf();
    var calls = 0;
    final repo = await open(
      extractor: (_) async {
        calls++;
        return 'should not be used';
      },
    );
    await repo.searchIndexReady;
    expect(calls, 0);
    expect(
      (await current(repo, entry.id)).searchText,
      'original searchable text',
    );
    await repo.close();
    final again = await open(
      extractor: (_) async {
        calls++;
        return 'should not be used';
      },
    );
    await again.searchIndexReady;
    expect(calls, 0);
  });

  test(
    'changed PDF is re-extracted once and the new signature persists',
    () async {
      final entry = await seedPdf();
      await invalidate(entry.id);
      var calls = 0;
      final repo = await open(
        extractor: (_) async {
          calls++;
          return 'new external contents';
        },
      );
      await repo.searchIndexReady;
      expect(calls, 1);
      expect(
        (await current(repo, entry.id)).searchText,
        'new external contents',
      );
      await repo.close();
      final again = await open(
        extractor: (_) async {
          calls++;
          return 'unexpected';
        },
      );
      await again.searchIndexReady;
      expect(calls, 1);
    },
  );

  test(
    'extractor failure preserves prior text and retries next opening',
    () async {
      final entry = await seedPdf();
      await invalidate(entry.id);
      final repo = await open(
        extractor: (_) async => throw StateError('offline'),
      );
      await repo.searchIndexReady;
      expect(
        (await current(repo, entry.id)).searchText,
        'original searchable text',
      );
      expect(repo.searchIndexStatus.failures, 1);
      await repo.close();
      var calls = 0;
      final recovered = await open(
        extractor: (_) async {
          calls++;
          return 'recovered text';
        },
      );
      await recovered.searchIndexReady;
      expect(calls, 1);
      expect((await current(recovered, entry.id)).searchText, 'recovered text');
      expect(recovered.searchIndexStatus.failures, 0);
    },
  );

  test(
    'null PDF result preserves text while valid empty text replaces it',
    () async {
      final entry = await seedPdf();
      await invalidate(entry.id);
      final repo = await open(extractor: (_) async => null);
      await repo.searchIndexReady;
      expect(
        (await current(repo, entry.id)).searchText,
        'original searchable text',
      );
      expect(repo.searchIndexStatus.failures, 1);
      await repo.close();
      final empty = await open(extractor: (_) async => '');
      await empty.searchIndexReady;
      expect((await current(empty, entry.id)).searchText, isEmpty);
      expect(empty.searchIndexStatus.failures, 0);
    },
  );

  test('file mutation during extraction discards the obsolete text', () async {
    final entry = await seedPdf();
    await invalidate(entry.id);
    final started = Completer<void>(), extracted = gate();
    var calls = 0;
    final seen = <String>[];
    final repo = await open(
      extractor: (_) {
        calls++;
        if (calls > 1) return Future.value('latest outside edit');
        started.complete();
        return extracted.future;
      },
    );
    final subscription = repo.watchEntries().listen((entries) {
      seen.addAll(
        entries.where((e) => e.id == entry.id).map((e) => e.searchText),
      );
    });
    addTearDown(subscription.cancel);
    await started.future;
    await File(
      p.join(root.path, 'files', entry.id, 'document.pdf'),
    ).writeAsString(
      '%PDF yet another edit with an entirely different byte count',
    );
    extracted.complete('obsolete outside edit');
    await repo.searchIndexReady;
    expect(calls, 2);
    expect((await current(repo, entry.id)).searchText, 'latest outside edit');
    expect(seen, isNot(contains('obsolete outside edit')));
  });

  test(
    'missing and damaged cache rebuild without losing existing search data',
    () async {
      final entry = await seedPdf();
      for (final cache in [null, 'not json', '{"version":999}']) {
        final setup = await open(
          extractor: (_) async => 'original searchable text',
        );
        await setup.searchIndexReady;
        if (cache == null) {
          await setup.database.customStatement(
            'DELETE FROM workspace_settings WHERE key = ?',
            ['search-index.v1.${entry.id}'],
          );
        } else {
          await setup.writeSetting('search-index.v1.${entry.id}', cache);
        }
        await setup.close();
        final started = Completer<void>(), extracted = gate();
        final repo = await open(
          extractor: (_) {
            started.complete();
            return extracted.future;
          },
        ).timeout(const Duration(seconds: 5));
        await started.future.timeout(const Duration(seconds: 5));
        expect(
          (await current(repo, entry.id)).searchText,
          'original searchable text',
        );
        extracted.complete('original searchable text');
        await repo.searchIndexReady;
        await repo.close();
      }
    },
  );

  test(
    'renaming during extraction discards stale result and indexes new name',
    () async {
      final entry = await seedPdf();
      await invalidate(entry.id);
      final started = Completer<void>(), extracted = gate();
      final seen = <String>[];
      var calls = 0;
      final repo = await open(
        extractor: (path) async {
          calls++;
          if (p.basename(path) == 'renamed.pdf') {
            return 'current renamed result';
          }
          started.complete();
          return extracted.future;
        },
      );
      final subscription = repo.watchEntries().listen((entries) {
        seen.addAll(
          entries.where((e) => e.id == entry.id).map((e) => e.searchText),
        );
      });
      addTearDown(subscription.cancel);
      await started.future;
      final snapshot = await repo.readNote(entry.id);
      final before = await current(repo, entry.id);
      await repo
          .save(
            id: entry.id,
            expectedRevision: before.revision,
            expectedBodyHash: snapshot.hash,
            draft: const EntryDraft(title: 'renamed.pdf'),
          )
          .timeout(const Duration(seconds: 5));
      extracted.complete('stale result');
      await repo.searchIndexReady;
      final after = await current(repo, entry.id);
      expect(after.fileName, 'renamed.pdf');
      expect(after.searchText, 'current renamed result');
      expect(calls, greaterThanOrEqualTo(2));
      expect(seen, isNot(contains('stale result')));
    },
  );

  test('permanent deletion during extraction cannot resurrect a row', () async {
    final entry = await seedPdf();
    await invalidate(entry.id);
    final started = Completer<void>(), extracted = gate();
    final repo = await open(
      extractor: (_) {
        started.complete();
        return extracted.future;
      },
    );
    await started.future;
    await repo.trash(entry.id);
    await repo.permanentlyDelete(entry.id).timeout(const Duration(seconds: 5));
    extracted.complete('stale deleted result');
    await repo.searchIndexReady;
    expect(await repo.getEntries(), isEmpty);
    expect(await repo.getTrash(), isEmpty);
    expect(await repo.readSetting('search-index.v1.${entry.id}'), isNull);
  });

  test('closing with extraction pending prevents a late commit', () async {
    final entry = await seedPdf();
    await invalidate(entry.id);
    final started = Completer<void>(), extracted = gate();
    final repo = await open(
      extractor: (_) {
        started.complete();
        return extracted.future;
      },
    );
    await started.future;
    await repo.close().timeout(const Duration(seconds: 5));
    // Native work may finish (or fail) after close without holding the root.
    extracted.completeError(StateError('late native extraction failure'));
    await Future<void>.delayed(Duration.zero);
    // Hold the next extraction too, so a late old commit cannot be hidden.
    final nextStarted = Completer<void>(), nextExtracted = gate();
    final reopened = await open(
      extractor: (_) {
        nextStarted.complete();
        return nextExtracted.future;
      },
    );
    await nextStarted.future.timeout(const Duration(seconds: 5));
    expect(
      (await current(reopened, entry.id)).searchText,
      'original searchable text',
    );
    nextExtracted.complete('fresh next opening');
    await reopened.searchIndexReady;
  });

  test(
    'cached link refresh cannot overwrite a concurrent index repair',
    () async {
      final seed = await open();
      final target = await seed.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Link target'),
      );
      final body = 'correct cached text ${markdownLink(target)}';
      final source = await seed.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: 'Source', body: body),
      );
      await seed.searchIndexReady;
      await seed.database.customStatement(
        'UPDATE entries SET search_text = ? WHERE id = ?',
        ['stale derived text', source.id],
      );
      await seed.close();
      final repo = await open();
      final entered = Completer<void>(), release = Completer<void>();
      final repairing = repo.exclusive(() async {
        entered.complete();
        await release.future;
        // Represents a text import finishing its derived index while the
        // background link refresher is queued, with no authoritative revision.
        await repo.database.customStatement(
          'UPDATE entries SET search_text = ? WHERE id = ?',
          [body, source.id],
        );
      });
      await entered.future;
      try {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(repo.searchIndexStatus.updating, isTrue);
      } finally {
        release.complete();
        await repairing;
      }
      await repo.searchIndexReady;
      expect((await current(repo, source.id)).searchText, body);
      expect((await repo.backlinks(target.id)).single.id, source.id);
    },
  );

  test('external Markdown changes replace text and links atomically', () async {
    final repo = await open();
    final first = await repo.create(
      kind: EntryKind.note,
      draft: const EntryDraft(title: 'First target'),
    );
    final second = await repo.create(
      kind: EntryKind.note,
      draft: const EntryDraft(title: 'Second target'),
    );
    final source = await repo.create(
      kind: EntryKind.note,
      draft: EntryDraft(title: 'Source', body: markdownLink(first)),
    );
    await repo.searchIndexReady;
    await repo.close();
    final body = 'externally changed ${markdownLink(second)}';
    await File(
      p.join(root.path, 'notes', '${source.id}.md'),
    ).writeAsString(body);
    final reopened = await open();
    await reopened.searchIndexReady;
    expect((await current(reopened, source.id)).searchText, body);
    expect(await reopened.backlinks(first.id), isEmpty);
    expect((await reopened.backlinks(second.id)).single.id, source.id);
  });

  test(
    'backup independently restores authoritative data with derived cache',
    () async {
      final repo = await open(extractor: (_) async => 'PDF search text');
      final attachment = await pdf(repo);
      await repo.searchIndexReady;
      final project = await repo.create(
        kind: EntryKind.project,
        draft: EntryDraft(
          title: 'Archived project',
          goal: 'Preserved outcome',
          dueDate: DateTime(2026, 12, 31),
        ),
      );
      final task = await repo.create(
        kind: EntryKind.task,
        parentId: project.id,
        draft: const EntryDraft(
          title: 'Waiting task',
          taskState: TaskState.waiting,
        ),
      );
      final note = await repo.create(
        kind: EntryKind.note,
        draft: EntryDraft(
          title: 'Versioned source',
          body: markdownLink(attachment),
        ),
      );
      final firstBody = (await repo.readNote(note.id)).text;
      final snapshot = await repo.readNote(note.id);
      await repo.save(
        id: note.id,
        expectedRevision: note.revision,
        expectedBodyHash: snapshot.hash,
        draft: EntryDraft(title: note.title, body: 'second $firstBody'),
      );
      await repo.archive(project.id, true);
      await repo.trash(note.id);
      await repo.searchIndexReady;
      final expectedVersions = (await repo.noteVersions(
        note.id,
      )).map((v) => v.body).toList();
      final destination = await Directory.systemTemp.createTemp(
        'para-index-backup-',
      );
      addTearDown(() => destination.delete(recursive: true));
      final path = await repo.exportBackup(destination.path);
      final restored = await LocalWorkspaceRepository.open(
        Directory(path),
        pdfTextExtractor: (_) async => 'PDF search text',
      );
      try {
        await restored.searchIndexReady;
        expect((await restored.getTrash()).single.id, note.id);
        expect((await restored.readNote(note.id)).text, 'second $firstBody');
        expect(
          (await restored.noteVersions(note.id)).map((v) => v.body).toList(),
          expectedVersions,
        );
        expect((await restored.backlinks(attachment.id)).single.id, note.id);
        expect(
          await File(await restored.filePath(attachment.id)).readAsString(),
          '%PDF synthetic fixture',
        );
        final entries = await restored.getEntries();
        final restoredTask = entries.firstWhere((e) => e.id == task.id);
        expect(restoredTask.taskState, TaskState.waiting);
        expect(restoredTask.parentId, project.id);
        expect(isArchived(restoredTask, entries), isTrue);
        expect(
          entries.firstWhere((e) => e.id == project.id).goal,
          'Preserved outcome',
        );
        expect(
          (await current(restored, attachment.id)).searchText,
          'PDF search text',
        );
      } finally {
        await restored.close();
      }
    },
  );
}
