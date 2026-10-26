import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/inbox_ingest_service.dart';
import 'package:para_workspace/services/workspace_manager.dart';
import 'support/ingest_file_access.dart';

void main() {
  late Directory temp, source, config;
  late LocalWorkspaceRepository repo;
  late InboxIngestService service;
  late TestIngestFileAccess files;
  Future<void> activate() async {
    await service.configure(WorkspaceLocation(source.path));
    await service.activate();
  }

  InboxIngestService worker({
    Future<void> Function(String, dynamic)? checkpoint,
  }) => InboxIngestService(
    repo,
    config,
    files: files,
    quietPeriod: Duration.zero,
    schedule: false,
    checkpoint: checkpoint,
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('para-ingest-test-');
    source = await Directory(p.join(temp.path, 'input')).create();
    config = Directory(p.join(temp.path, 'config'));
    repo = await LocalWorkspaceRepository.open(
      Directory(p.join(temp.path, 'workspace')),
    );
    files = TestIngestFileAccess();
    service = worker();
  });
  tearDown(() async {
    await service.close();
    service.dispose();
    await repo.close();
    await temp.delete(recursive: true);
  });

  test(
    'recursive inbox tree preserves empty folders, Unicode and exact Markdown bytes; originals retained',
    () async {
      final folder = await Directory(
        p.join(source.path, 'Steuern', '2026', 'Leer'),
      ).create(recursive: true);
      final bytes = [239, 187, 191, ...utf8.encode('# Grüße\r\n')];
      await File(
        p.join(folder.parent.path, 'Übersicht.md'),
      ).writeAsBytes(bytes);
      await File(p.join(source.path, 'empty.txt')).writeAsBytes([]);
      await activate();
      await service.runOnce();
      final entries = await repo.getEntries();
      expect(entries, hasLength(5));
      final md = entries.singleWhere((e) => e.title == 'Übersicht.md');
      expect(md.kind, EntryKind.file);
      expect(ancestorsOf(md, entries).map((e) => e.title), ['2026', 'Steuern']);
      expect(await File(await repo.filePath(md.id)).readAsBytes(), bytes);
      expect(
        entries.singleWhere((e) => e.title == 'Leer').kind,
        EntryKind.folder,
      );
      expect(await Directory(p.join(source.path, 'Steuern')).exists(), false);
      expect(
        await File(
          p.join(
            service.recoveryPath,
            service.jobs.firstWhere((j) => j.name == 'Steuern').id,
            'Steuern',
            '2026',
            'Übersicht.md',
          ),
        ).readAsBytes(),
        bytes,
      );
      await service.runOnce();
      expect(await repo.getEntries(), hasLength(5));
    },
  );

  test(
    'new drop with the same name and bytes creates a separate tree without merging',
    () async {
      await Directory(p.join(source.path, 'Ordner')).create();
      await File(p.join(source.path, 'Ordner', 'a.txt')).writeAsString('same');
      await activate();
      await service.runOnce();
      final before = (await repo.getEntries()).map((e) => e.id).toSet();
      await Directory(p.join(source.path, 'Ordner')).create();
      await File(p.join(source.path, 'Ordner', 'a.txt')).writeAsString('same');
      await service.runOnce();
      final entries = await repo.getEntries();
      expect(entries, hasLength(4));
      expect(entries.map((e) => e.id).toSet().containsAll(before), true);
      expect(entries.where((e) => e.title == 'Ordner'), hasLength(2));
    },
  );

  for (final transition in ['ready', 'committed', 'moved']) {
    test(
      'reopening after interruption at $transition retains UUIDs and never duplicates',
      () async {
        await service.close();
        service.dispose();
        service = worker(
          checkpoint: (phase, job) async {
            if (phase == transition) throw StateError('simulated interruption');
          },
        );
        await File(p.join(source.path, 'a.txt')).writeAsString('original');
        await activate();
        await service.runOnce();
        final job = (await repo.ingestJobs()).single;
        final ids = job.items.map((e) => e.id).toList();
        expect(job.error, contains('simulated interruption'));
        await service.close();
        service.dispose();
        await repo.close();
        repo = await LocalWorkspaceRepository.open(
          Directory(p.join(temp.path, 'workspace')),
          create: false,
        );
        service = worker();
        await service.initialize();
        await service.runOnce();
        expect((await repo.ingestJobs()).single.phase, 'done');
        expect((await repo.getEntries()).map((e) => e.id), ids);
        expect(await File(p.join(source.path, 'a.txt')).exists(), false);
      },
    );
  }

  test(
    'a new arrival after moved interruption is not mistaken for the original source',
    () async {
      await service.close();
      service.dispose();
      service = worker(
        checkpoint: (phase, job) async {
          if (phase == 'moved') throw StateError('stop');
        },
      );
      await File(p.join(source.path, 'a.txt')).writeAsString('old');
      await activate();
      await service.runOnce();
      await File(p.join(source.path, 'a.txt')).writeAsString('new');
      await service.close();
      service.dispose();
      service = worker();
      await service.initialize();
      await service.runOnce();
      await service.runOnce();
      expect(await repo.getEntries(), hasLength(2));
      final texts = <String>[];
      for (final entry in await repo.getEntries()) {
        texts.add(await File(await repo.filePath(entry.id)).readAsString());
      }
      expect(texts, containsAll(['old', 'new']));
    },
  );

  test(
    'late source edits after commit are retained and never silently deleted or reimported',
    () async {
      await service.close();
      service.dispose();
      service = worker(
        checkpoint: (phase, job) async {
          if (phase == 'committed') {
            await File(p.join(source.path, 'a.txt')).writeAsString('changed');
          }
        },
      );
      await File(p.join(source.path, 'a.txt')).writeAsString('before');
      await activate();
      await service.runOnce();
      await service.runOnce();
      expect(
        await File(p.join(source.path, 'a.txt')).readAsString(),
        'changed',
      );
      expect(await repo.getEntries(), hasLength(1));
      expect(service.error, contains('verändert'));
    },
  );

  test(
    'a deep edit during copying leaves the whole tree unpublished and resumable',
    () async {
      final nested = await Directory(
        p.join(source.path, 'Tree', 'Deep'),
      ).create(recursive: true);
      await File(p.join(nested.path, 'one.txt')).writeAsString('before');
      var changed = false;
      files.afterCopy = (_) async {
        if (!changed) {
          changed = true;
          await File(p.join(nested.path, 'two.txt')).writeAsString('late');
        }
      };
      await activate();
      await service.runOnce();
      expect(await repo.getEntries(), isEmpty);
      expect(await Directory(p.join(source.path, 'Tree')).exists(), true);
      files.afterCopy = null;
      await service.runOnce();
      await service.runOnce();
      expect(await repo.getEntries(), hasLength(4));
      expect((await repo.ingestJobs()).single.phase, 'done');
    },
  );

  test(
    'symlinks, packages and unfinished descendants do not cause partial tree deletion',
    () async {
      final tree = await Directory(p.join(source.path, 'Tree')).create();
      await File(p.join(tree.path, 'fine.txt')).writeAsString('safe');
      final outside = await File(
        p.join(temp.path, 'outside.txt'),
      ).writeAsString('outside');
      await Link(p.join(tree.path, 'link.txt')).create(outside.path);
      await Directory(p.join(source.path, 'Program.app')).create();
      await activate();
      await service.runOnce();
      expect(await repo.getEntries(), isEmpty);
      expect(await outside.readAsString(), 'outside');
      expect(await tree.exists(), true);
      await Link(p.join(tree.path, 'link.txt')).delete();
      await File(p.join(tree.path, 'wait.part')).writeAsString('partial');
      await service.runOnce();
      expect(await repo.getEntries(), isEmpty);
      expect(await File(p.join(tree.path, 'wait.part')).exists(), true);
    },
  );

  test(
    'only one workspace consumes a source and nested workspaces are rejected',
    () async {
      await activate();
      final otherRepo = await LocalWorkspaceRepository.open(
        Directory(p.join(temp.path, 'other')),
      );
      final other = InboxIngestService(
        otherRepo,
        config,
        files: files,
        schedule: false,
      );
      try {
        await other.configure(WorkspaceLocation(source.path));
        await expectLater(other.activate(), throwsA(anything));
        await expectLater(
          service.configure(WorkspaceLocation(repo.root.path)),
          throwsA(anything),
        );
        await expectLater(
          service.configure(WorkspaceLocation(temp.path)),
          throwsA(anything),
        );
      } finally {
        await other.close();
        other.dispose();
        await otherRepo.close();
      }
    },
  );

  test(
    'pause blocks consumption; normal restart resumes explicitly enabled configuration',
    () async {
      await activate();
      await service.pause();
      await File(p.join(source.path, 'queued.txt')).writeAsString('wait');
      await service.runOnce();
      expect(await repo.getEntries(), isEmpty);
      await service.activate();
      await service.close();
      service.dispose();
      service = worker();
      await service.initialize();
      expect(service.enabled, true);
      await service.runOnce();
      expect(await repo.getEntries(), hasLength(1));
    },
  );

  test(
    'independent backup restores verified snapshots but never consumes the original source',
    () async {
      await service.close();
      service.dispose();
      service = worker(
        checkpoint: (phase, job) async {
          if (phase == 'ready') throw StateError('stop');
        },
      );
      await File(
        p.join(source.path, 'queued.md'),
      ).writeAsBytes([239, 187, 191, 65]);
      await activate();
      await service.runOnce();
      final originalJob = (await repo.ingestJobs()).single;
      final backup = await repo.exportBackup(p.join(temp.path, 'backups'));
      final restored = await LocalWorkspaceRepository.open(
        Directory(backup),
        create: false,
      );
      final restoredService = InboxIngestService(
        restored,
        config,
        files: files,
        schedule: false,
      );
      try {
        await restoredService.initialize();
        expect(restoredService.enabled, false);
        final item = (await restored.getEntries()).single;
        expect(item.id, originalJob.items.single.id);
        expect(await File(await restored.filePath(item.id)).readAsBytes(), [
          239,
          187,
          191,
          65,
        ]);
        expect((await restored.ingestJobs()).single.phase, 'recovered');
        expect(await File(p.join(source.path, 'queued.md')).exists(), true);
        expect(
          jsonDecode(
            await File(p.join(backup, 'backup.json')).readAsString(),
          )['version'],
          3,
        );
      } finally {
        await restoredService.close();
        restoredService.dispose();
        await restored.close();
      }
    },
  );

  test(
    'failed atomic journal commit leaves the source and resumes with one content',
    () async {
      await File(p.join(source.path, 'safe.txt')).writeAsString('keep');
      await repo.database.customStatement(
        '''CREATE TRIGGER fail_ingest_commit BEFORE UPDATE ON ingest_jobs
      WHEN json_extract(NEW.payload, '\$.phase') = 'committed'
      BEGIN SELECT RAISE(ABORT, 'simulated disk failure'); END''',
      );
      await activate();
      await service.runOnce();
      expect(await repo.getEntries(), isEmpty);
      expect((await repo.ingestJobs()).single.phase, 'ready');
      expect(
        await File(p.join(source.path, 'safe.txt')).readAsString(),
        'keep',
      );
      final id = (await repo.ingestJobs()).single.items.single.id;
      await repo.database.customStatement('DROP TRIGGER fail_ingest_commit');
      await service.runOnce();
      expect((await repo.getEntries()).single.id, id);
      expect((await repo.ingestJobs()).single.phase, 'done');
    },
  );

  test(
    'ready snapshot is refreshed when a source changes before publication',
    () async {
      await service.close();
      service.dispose();
      var changed = false;
      service = worker(
        checkpoint: (phase, job) async {
          if (phase == 'ready' && !changed) {
            changed = true;
            await File(
              p.join(source.path, 'a.txt'),
            ).writeAsString('new content');
          }
        },
      );
      await File(p.join(source.path, 'a.txt')).writeAsString('before');
      await activate();
      for (var i = 0; i < 4; i++) {
        await service.runOnce();
      }
      final entry = (await repo.getEntries()).single;
      expect(
        await File(await repo.filePath(entry.id)).readAsString(),
        'new content',
      );
      expect((await repo.ingestJobs()).single.phase, 'done');
    },
  );

  test(
    'schema 5 migrates with full rollback and independently restores existing data',
    () async {
      final note = await repo.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Existing', body: 'kept'),
      );
      await repo.trash(note.id);
      final root = repo.root;
      await service.close();
      service.dispose();
      await repo.close();
      final legacy = sqlite3.open(p.join(root.path, 'workspace.sqlite'));
      legacy.execute('DROP TABLE ingest_jobs');
      legacy.execute('PRAGMA user_version = 5');
      legacy.close();
      repo = await LocalWorkspaceRepository.open(root, create: false);
      service = worker();
      expect((await repo.getTrash()).single.id, note.id);
      expect((await repo.noteVersions(note.id)).single.body, 'kept');
      final backups = await Directory(
        p.join(root.path, '.migration-backups'),
      ).list().toList();
      expect(backups, hasLength(1));
      final rollback = sqlite3.open(
        p.join(backups.single.path, 'workspace.sqlite'),
      );
      expect(rollback.select('PRAGMA user_version').single.values.single, 5);
      rollback.close();
      final restored = await LocalWorkspaceRepository.open(
        Directory(backups.single.path),
        create: false,
      );
      try {
        expect((await restored.getTrash()).single.id, note.id);
        expect((await restored.noteVersions(note.id)).single.body, 'kept');
      } finally {
        await restored.close();
      }
    },
  );

  test(
    'a corrupted copied file is rejected before any Inbox entry or source movement',
    () async {
      await File(p.join(source.path, 'a.txt')).writeAsString('original');
      files.corruptCopy = true;
      await activate();
      await service.runOnce();
      expect(await repo.getEntries(), isEmpty);
      expect(
        await File(p.join(source.path, 'a.txt')).readAsString(),
        'original',
      );
      expect(service.error, contains('Prüfsumme'));
      files.corruptCopy = false;
      await service.runOnce();
      expect((await repo.getEntries()).single.title, 'a.txt');
    },
  );

  test('the running app consumes new nested arrivals automatically', () async {
    await service.close();
    service.dispose();
    service = InboxIngestService(
      repo,
      config,
      files: files,
      quietPeriod: const Duration(milliseconds: 20),
      scanInterval: const Duration(milliseconds: 50),
    );
    await activate();
    await Directory(p.join(source.path, 'New', 'Deep')).create(recursive: true);
    await File(
      p.join(source.path, 'New', 'Deep', 'automatic.txt'),
    ).writeAsString('automatic');
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!(await repo.ingestJobs()).any((j) => j.phase == 'done') &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await service.pause();
    expect(await repo.getEntries(), hasLength(3));
    expect((await repo.ingestJobs()).single.phase, 'done');
    expect(await Directory(p.join(source.path, 'New')).exists(), false);
  });

  test(
    'unknown snapshot layout is rejected without changing existing note bytes',
    () async {
      final note = await repo.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Keep', body: 'unchanged'),
      );
      final root = repo.root;
      final snapshot = await Directory(p.join(root.path, 'ingest')).create();
      final format = await File(
        p.join(snapshot.path, 'format.json'),
      ).writeAsString('{"version":999}');
      await service.close();
      service.dispose();
      await repo.close();
      await expectLater(
        LocalWorkspaceRepository.open(root, create: false),
        throwsA(anything),
      );
      expect(
        await File(p.join(root.path, 'notes', '${note.id}.md')).readAsString(),
        'unchanged',
      );
      await format.writeAsString('{"version":1}');
      repo = await LocalWorkspaceRepository.open(root, create: false);
      service = worker();
    },
  );
}
