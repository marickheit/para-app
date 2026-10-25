import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/workspace_manager.dart';

class TestDirectoryAccess implements WorkspaceDirectoryAccess {
  WorkspaceLocation? selection;
  @override
  Future<WorkspaceLocation?> choose() async => selection;
  @override
  Future<WorkspaceLocation> restore(WorkspaceLocation location) async =>
      location;
}

void main() {
  late Directory base;
  late WorkspaceManager manager;
  late TestDirectoryAccess access;
  WorkspaceManager create({Directory? override}) => WorkspaceManager(
    configurationDirectory: Directory(p.join(base.path, 'configuration')),
    defaultRoot: Directory(p.join(base.path, 'original')),
    overrideRoot: override,
    access: access,
  );
  setUp(() async {
    base = await Directory.systemTemp.createTemp('para-manager-');
    access = TestDirectoryAccess();
    manager = create();
    await manager.initialize();
  });
  tearDown(() async {
    await manager.close();
    manager.dispose();
    await base.delete(recursive: true);
  });
  Future<Directory> target(String name) =>
      Directory(p.join(base.path, name)).create();

  test(
    'copy preserves identities, all settings, attachments, trash and versions and survives restart',
    () async {
      final source = manager.repository!;
      final file = await source.importFile(
        name: 'data.bin',
        bytes: Stream.value([1, 2, 3]),
      );
      final note = await source.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: 'Link', body: markdownLink(file)),
      );
      await source.trash(file.id);
      await source.writeSetting('session.v1', '{"version":1,"view":"trash"}');
      await source.saveContext(name: 'Computer', color: contextColors[4]);
      final destination = await target('copy');
      await manager.switchTo(
        WorkspaceLocation(destination.path),
        WorkspaceOpenMode.copyCurrent,
      );
      final copied = manager.repository!;
      expect(copied.root.path, await destination.resolveSymbolicLinks());
      expect((await copied.getEntries()).single.id, note.id);
      expect((await copied.getTrash()).single.id, file.id);
      expect(await File(await copied.filePath(file.id)).readAsBytes(), [
        1,
        2,
        3,
      ]);
      expect(await copied.readSetting('session.v1'), contains('trash'));
      expect(
        (await copied.getContexts()).any((e) => e.name == 'Computer'),
        isTrue,
      );
      expect(await copied.noteVersions(note.id), hasLength(1));
      expect(
        await File(p.join(source.root.path, 'workspace.sqlite')).exists(),
        isTrue,
      );
      await manager.close();
      manager.dispose();
      manager = create();
      await manager.initialize();
      expect(
        manager.repository!.root.path,
        await destination.resolveSymbolicLinks(),
      );
      expect((await manager.repository!.getTrash()).single.id, file.id);
    },
  );

  test(
    'new and existing workspaces load their own context definitions and settings',
    () async {
      final oldRoot = manager.repository!.root;
      await manager.repository!.writeSetting('session.v1', 'original');
      final definition = await manager.repository!.saveContext(
        name: 'Nur hier',
        color: contextColors.first,
      );
      final other = await target('new');
      await manager.switchTo(
        WorkspaceLocation(other.path),
        WorkspaceOpenMode.create,
      );
      expect(await manager.repository!.getEntries(), isEmpty);
      expect(await manager.repository!.readSetting('session.v1'), isNull);
      expect(
        (await manager.repository!.getContexts()).map((e) => e.id),
        isNot(contains(definition.id)),
      );
      await manager.repository!.writeSetting('session.v1', 'other');
      await manager.switchTo(
        WorkspaceLocation(oldRoot.path),
        WorkspaceOpenMode.open,
      );
      expect(await manager.repository!.readSetting('session.v1'), 'original');
      expect(
        (await manager.repository!.getContexts()).map((e) => e.id),
        contains(definition.id),
      );
    },
  );

  test(
    'invalid, nonempty and overlapping targets leave current root and remembered choice unchanged',
    () async {
      final original = manager.repository!;
      final preference = File(
        p.join(base.path, 'configuration', 'workspace-location.json'),
      );
      final before = await preference.readAsString();
      final foreign = await target('foreign');
      await File(p.join(foreign.path, 'personal.txt')).writeAsString('Keep');
      for (final mode in WorkspaceOpenMode.values) {
        await expectLater(
          manager.switchTo(WorkspaceLocation(foreign.path), mode),
          throwsA(isA<WorkspaceException>()),
        );
        expect(manager.repository, same(original));
        expect(await preference.readAsString(), before);
      }
      final inside = await Directory(
        p.join(original.root.path, 'nested'),
      ).create();
      await expectLater(
        manager.switchTo(
          WorkspaceLocation(inside.path),
          WorkspaceOpenMode.copyCurrent,
        ),
        throwsA(isA<WorkspaceException>()),
      );
      expect(
        await File(p.join(foreign.path, 'personal.txt')).readAsString(),
        'Keep',
      );
    },
  );

  test(
    'missing remembered root never creates a fresh empty replacement',
    () async {
      final other = await target('external');
      await manager.switchTo(
        WorkspaceLocation(other.path),
        WorkspaceOpenMode.create,
      );
      await manager.close();
      manager.dispose();
      await other.rename('${other.path}-unavailable');
      manager = create();
      await manager.initialize();
      expect(manager.error, isA<WorkspaceException>());
      expect(manager.repository, isNull);
      expect(await other.exists(), isFalse);
    },
  );

  test(
    'explicit test override neither reads nor rewrites regular remembered selection',
    () async {
      final prefs = File(
        p.join(base.path, 'configuration', 'workspace-location.json'),
      );
      final before = await prefs.readAsString();
      await manager.close();
      manager.dispose();
      manager = create(override: await target('isolated-test'));
      await manager.initialize();
      expect(manager.repository!.root.path, endsWith('isolated-test'));
      expect(await prefs.readAsString(), before);
      await expectLater(
        manager.switchTo(WorkspaceLocation(base.path), WorkspaceOpenMode.open),
        throwsA(isA<WorkspaceException>()),
      );
    },
  );

  test(
    'unknown newer schemas are rejected without resetting data or changing selection',
    () async {
      final directory = await target('future');
      final repo = await LocalWorkspaceRepository.open(directory);
      await repo.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Future', body: 'Keep'),
      );
      await repo.close();
      final db = sqlite3.open(p.join(directory.path, 'workspace.sqlite'));
      db.execute('PRAGMA user_version = 999');
      db.close();
      final preferences = File(
        p.join(base.path, 'configuration', 'workspace-location.json'),
      );
      final before = await preferences.readAsString();
      await expectLater(
        manager.switchTo(
          WorkspaceLocation(directory.path),
          WorkspaceOpenMode.open,
        ),
        throwsA(isA<WorkspaceException>()),
      );
      final check = sqlite3.open(
        p.join(directory.path, 'workspace.sqlite'),
        mode: OpenMode.readOnly,
      );
      expect(check.select('PRAGMA user_version').single.values.single, 999);
      expect(
        check.select('SELECT title FROM entries').single['title'],
        'Future',
      );
      check.close();
      expect(await preferences.readAsString(), before);
    },
  );

  test(
    'already open roots reject a second writer and release their lease on close',
    () async {
      final originalRoot = manager.repository!.root;
      await expectLater(
        LocalWorkspaceRepository.open(originalRoot),
        throwsA(isA<WorkspaceException>()),
      );
      await manager.close();
      final reopened = await LocalWorkspaceRepository.open(originalRoot);
      await reopened.close();
    },
  );

  test(
    'incomplete copy markers are refused and configuration write failures keep the original usable',
    () async {
      final incomplete = await target('incomplete');
      await File(p.join(incomplete.path, '.para-transfer')).writeAsString('{}');
      await expectLater(
        manager.switchTo(
          WorkspaceLocation(incomplete.path),
          WorkspaceOpenMode.open,
        ),
        throwsA(isA<WorkspaceException>()),
      );
      final prefs = File(
        p.join(base.path, 'configuration', 'workspace-location.json'),
      );
      final previous = jsonDecode(await prefs.readAsString());
      await Directory('${prefs.path}.tmp').create();
      final destination = await target('ready');
      await expectLater(
        manager.switchTo(
          WorkspaceLocation(destination.path),
          WorkspaceOpenMode.create,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(manager.repository!.root.path, previous['path']);
      await manager.repository!.create(
        kind: EntryKind.note,
        draft: const EntryDraft(title: 'Still works'),
      );
      expect(
        (await manager.repository!.getEntries()).single.title,
        'Still works',
      );
      expect(jsonDecode(await prefs.readAsString()), previous);
    },
  );
}
