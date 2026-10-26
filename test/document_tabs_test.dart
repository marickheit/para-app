import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/ui/document_tabs.dart';
import 'package:para_workspace/services/workspace_session.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';

void main() {
  test('preview replacement preserves permanent tabs and UUID order', () {
    final tabs = DocumentTabs();
    tabs.open('a');
    tabs.open('b', temporary: true);
    tabs.open('c');
    expect(tabs.preview, 'b');
    tabs.open('d', temporary: true);
    expect(tabs.ids, ['a', 'c', 'd']);
    tabs.keep('d');
    tabs.open('e', temporary: true);
    expect(tabs.persistent, ['a', 'c', 'd']);
    tabs.open('a', temporary: true);
    expect(tabs.ids, ['a', 'c', 'd', 'e']);
    expect(tabs.close('c'), 'd');
    expect(tabs.close('e'), 'd');
    tabs.close('a');
    expect(tabs.close('d'), isNull);
  });

  test('session decoder rejects unknown versions and malformed fields', () {
    for (final value in [
      {'version': 3},
      {'version': 2, 'explorerWidth': 0},
      {'version': 2, 'explorerWidth': '320'},
      {
        'version': 2,
        'documentTabs': [1],
      },
      {
        'version': 2,
        'contentSelection': {'id': 3},
      },
      {'version': 2, 'readable': 'yes'},
      {'version': 2, 'collapsed': {}},
    ]) {
      expect(
        () => WorkspaceSession.decode(jsonEncode(value), 2),
        throwsA(isA<WorkspaceException>()),
      );
    }
    expect(
      WorkspaceSession.decode(
        '{"version":2,"explorerWidth":520}',
        2,
      )['explorerWidth'],
      520,
    );
  });

  test(
    'legacy session export restores independently with content, links and history',
    () async {
      final temp = await Directory.systemTemp.createTemp('para-session-test-');
      final root = Directory('${temp.path}/root');
      var repo = await LocalWorkspaceRepository.open(root);
      try {
        final note = await repo.create(
          kind: EntryKind.note,
          draft: const EntryDraft(title: 'Notiz', body: 'Erster Stand'),
        );
        final other = await repo.create(
          kind: EntryKind.note,
          draft: EntryDraft(title: 'Link', body: markdownLink(note)),
        );
        final snap = await repo.readSnapshot(note.id);
        await repo.saveSnapshot(
          id: note.id,
          expectedRevision: snap.entry.revision,
          expectedBodyHash: snap.note.hash,
          draft: const EntryDraft(title: 'Notiz', body: 'Zweiter Stand'),
        );
        await repo.importFile(
          name: 'Anhang.bin',
          bytes: Stream.value([0, 12, 255]),
        );
        await repo.trash(other.id);
        final legacy = jsonEncode({
          'version': 1,
          'view': 'inbox',
          'selected': note.id,
          'sidebarVisible': false,
          'collapsed': ['folder'],
          'filter': {},
        });
        await repo.writeSetting('session.v1', legacy);
        final result = await WorkspaceSession.load(repo, root.path);
        expect(result!['selected'], note.id);
        expect(result['version'], 2);
        expect(result['sidebarVisible'], false);
        expect(await repo.readSetting('session.v1'), legacy);
        final exportRoot = Directory('${root.path}/.migration-backups');
        final snapshot =
            (await exportRoot.list().where((e) => e is Directory).toList())
                .single;
        final copy = Directory('${temp.path}/restored');
        Future<void> copyTree(Directory from, Directory to) async {
          await to.create(recursive: true);
          await for (final e in from.list()) {
            final dest =
                '${to.path}/${e.uri.pathSegments.where((s) => s.isNotEmpty).last}';
            if (e is Directory) {
              await copyTree(e, Directory(dest));
            } else if (e is File) {
              await e.copy(dest);
            }
          }
        }

        await copyTree(Directory(snapshot.path), copy);
        final restored = await LocalWorkspaceRepository.open(copy);
        try {
          expect((await restored.readNote(note.id)).text, 'Zweiter Stand');
          expect((await restored.noteVersions(note.id)).length, 2);
          expect((await restored.getTrash()).single.id, other.id);
          expect((await restored.outgoingLinks(other.id)).single.id, note.id);
          final file = (await restored.getEntries()).singleWhere(
            (e) => e.kind == EntryKind.file,
          );
          expect(await File(await restored.filePath(file.id)).readAsBytes(), [
            0,
            12,
            255,
          ]);
          expect(await restored.readSetting('session.v1'), legacy);
        } finally {
          await restored.close();
        }
        final current = jsonEncode({
          ...result,
          'documentTabs': [note.id],
          'explorerWidth': 390,
        });
        await repo.writeSetting('session.v2', current);
        await repo.close();
        repo = await LocalWorkspaceRepository.open(root);
        expect(
          (await WorkspaceSession.load(repo, root.path))!['explorerWidth'],
          390,
        );
        expect((await exportRoot.list().toList()).length, 1);
        await repo.writeSetting('session.v2', '{"version":99}');
        await expectLater(
          WorkspaceSession.load(repo, root.path),
          throwsA(isA<WorkspaceException>()),
        );
        expect(await repo.readSetting('session.v2'), '{"version":99}');
      } finally {
        await repo.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
