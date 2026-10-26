import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/mcp_access_service.dart';
import 'package:para_workspace/services/mcp_bridge.dart';
import 'package:para_workspace/services/mcp_editor_guard.dart';
import 'package:para_workspace/services/workspace_manager.dart';

void main() {
  late Directory temp;
  late LocalWorkspaceRepository repo;
  late McpAccessService access;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('para-mcp-test-');
    repo = await LocalWorkspaceRepository.open(
      Directory('${temp.path}/workspace'),
    );
    access = McpAccessService(repo, canWrite: true);
  });
  tearDown(() async {
    access.revoke();
    await repo.close();
    await temp.delete(recursive: true);
  });
  Future<Entry> note(String title, {String body = '', String? parentId}) =>
      repo.create(
        kind: EntryKind.note,
        draft: EntryDraft(title: title, body: body),
        parentId: parentId,
      );
  Matcher code(String value) =>
      throwsA(isA<McpException>().having((e) => e.code, 'code', value));
  Future<Map<String, dynamic>> read(Entry entry) =>
      access.call('read_text', {'id': entry.id});

  test('shared contract is complete', () async {
    final fixture = jsonDecode(
      await File('test/fixtures/mcp/contract.json').readAsString(),
    );
    expect(mcpReadTools, unorderedEquals(fixture['read_tools']));
    expect(mcpWriteTools, unorderedEquals(fixture['write_tools']));
  });
  test(
    'consistent snapshot, text history, revision/hash conflicts and duplicate requests',
    () async {
      final entry = await note('Original', body: 'before');
      final before = await read(entry);
      final args = {
        'id': entry.id,
        'expected_revision': before['revision'],
        'expected_body_hash': before['body_hash'],
        'text': 'after',
        'request_id': 'save-1',
      };
      final values = await Future.wait([
        access.call('update_text', args),
        access.call('update_text', args),
      ]);
      expect(values[0], values[1]);
      expect((await read(entry))['text'], 'after');
      expect(
        (await repo.noteVersions(entry.id)).map((e) => e.body),
        containsAll(['before', 'after']),
      );
      await expectLater(
        access.call('update_text', {...args, 'request_id': 'save-2'}),
        code('conflict'),
      );
      expect(
        () => access.call('update_text', {...args, 'text': 'different'}),
        code('request_conflict'),
      );
      final saved = await repo.readSnapshot(entry.id);
      expect(saved.entry.revision, values[0]['revision']);
      expect(saved.note.hash, values[0]['body_hash']);
    },
  );
  test(
    'archive/trash hidden from all metadata, search and backlinks',
    () async {
      final visible = await note('Visible');
      final folder = await repo.create(
        kind: EntryKind.folder,
        draft: const EntryDraft(title: 'Hidden folder'),
      );
      final archived = await note(
        'Secret archived',
        parentId: folder.id,
        body: markdownLink(visible),
      );
      final trashed = await note('Secret trash', body: markdownLink(visible));
      await repo.archive(folder.id, true);
      await repo.trash(trashed.id);
      final listing = await access.call('list_entries', {});
      expect((listing['items'] as List).map((e) => e['id']), [visible.id]);
      expect(
        (await access.call('get_links', {
          'id': visible.id,
          'direction': 'incoming',
        }))['items'],
        isEmpty,
      );
      expect(
        (await access.call('search', {'query': 'Secret'}))['items'],
        isEmpty,
      );
      await expectLater(
        access.call('get_entry', {'id': archived.id}),
        code('not_found'),
      );
      await expectLater(
        access.call('get_entry', {'id': trashed.id}),
        code('not_found'),
      );
      await expectLater(
        access.call('list_entries', {'include_archive': true}),
        code('forbidden'),
      );
      final permitted = McpAccessService(
        repo,
        canWrite: true,
        allowArchive: true,
      );
      final archivedRead = await permitted.call('get_entry', {
        'id': archived.id,
        'include_archive': true,
      });
      expect(archivedRead['archived'], true);
      expect((await permitted.call('list_entries', {}))['total'], 1);
    },
  );
  test(
    'create project preserves details, links and child grouping after reopen',
    () async {
      final linked = await note('Reference');
      final args = {
        'title': 'Release',
        'goal': 'Published release',
        'due_date': '2028-02-29',
        'text': markdownLink(linked),
        'request_id': 'project-create',
      };
      final results = await Future.wait([
        access.call('create_project', args),
        access.call('create_project', args),
      ]);
      expect(results[0], results[1]);
      final project = results.first;
      expect(project['kind'], 'project');
      expect(project['section'], 'projects');
      expect(project['parent_id'], isNull);
      expect(project['goal'], args['goal']);
      expect(project['due_date'], args['due_date']);
      expect(
        (await access.call('read_text', {'id': project['id']}))['text'],
        args['text'],
      );
      expect(
        (await access.call('get_links', {
          'id': project['id'],
          'direction': 'outgoing',
        }))['total'],
        1,
      );
      final child = await access.call('create_task', {
        'title': 'Publish',
        'parent_id': project['id'],
        'state': 'next',
        'request_id': 'project-child',
      });
      expect(child['project_id'], project['id']);
      expect(
        (await access.call('list_tasks', {
          'project_id': project['id'],
        }))['total'],
        1,
      );
      expect(
        (await access.call('list_entries', {'kind': 'project'}))['total'],
        1,
      );
      access.revoke();
      await repo.close();
      repo = await LocalWorkspaceRepository.open(
        Directory('${temp.path}/workspace'),
      );
      access = McpAccessService(repo, canWrite: true);
      final reopened = await access.call('get_entry', {'id': project['id']});
      expect(reopened['link'], project['link']);
      expect(reopened['goal'], args['goal']);
      expect(reopened['due_date'], args['due_date']);
      expect(
        (await access.call('read_text', {'id': project['id']}))['text'],
        args['text'],
      );
      expect(
        (await access.call('list_tasks', {
          'project_id': project['id'],
        }))['total'],
        1,
      );
    },
  );
  test(
    'project creation rejects incomplete dates, location, status and read-only access',
    () async {
      final valid = <String, dynamic>{
        'title': 'Project',
        'goal': 'Result',
        'due_date': '2026-12-01',
        'request_id': 'invalid-project',
      };
      for (final field in ['title', 'goal', 'due_date']) {
        final missing = {...valid}..remove(field);
        expect(
          () => access.call('create_project', missing),
          code('invalid_input'),
        );
        expect(
          () => access.call('create_project', {...valid, field: ' '}),
          code('invalid_input'),
        );
      }
      for (final date in [
        '2026-02-29',
        '2026-04-31',
        '2026-13-01',
        '2026-00-01',
        '0000-01-01',
        '2026-1-01',
        '2026-01-01T12:00:00Z',
      ]) {
        expect(
          () => access.call('create_project', {...valid, 'due_date': date}),
          code('invalid_input'),
        );
      }
      for (final extra in [
        {'parent_id': '00000000-0000-4000-8000-000000000001'},
        {'section': 'inbox'},
        {'state': 'someday'},
      ]) {
        expect(
          () => access.call('create_project', {...valid, ...extra}),
          code('invalid_input'),
        );
      }
      final readonly = McpAccessService(repo, canWrite: false);
      expect(() => readonly.call('create_project', valid), code('read_only'));
      readonly.revoke();
      expect(await repo.getEntries(), isEmpty);
    },
  );
  test('task filters and patch preserve omitted fields, null clears', () async {
    final context = await repo.saveContext(name: 'Computer', color: 0xff123456);
    final created = await access.call('create_task', {
      'title': 'Review',
      'text': 'Details',
      'context_ids': [context.id],
      'estimated_minutes': 15,
      'energy': 'low',
      'state': 'next',
      'request_id': 'new-task',
    });
    final changed = await access.call('update_task', {
      'id': created['id'],
      'expected_revision': created['revision'],
      'title': 'Review now',
      'request_id': 'patch',
    });
    expect(changed['estimated_minutes'], 15);
    expect(changed['energy'], 'low');
    expect(changed['context_ids'], [context.id]);
    final cleared = await access.call('update_task', {
      'id': created['id'],
      'expected_revision': changed['revision'],
      'estimated_minutes': null,
      'energy': null,
      'request_id': 'clear',
    });
    expect(cleared['estimated_minutes'], isNull);
    final listed = await access.call('list_tasks', {
      'state': 'next',
      'context_ids': [context.id],
      'all_contexts': true,
    });
    expect(listed['total'], 1);
    await access.call('set_task_state', {
      'id': created['id'],
      'expected_revision': cleared['revision'],
      'state': 'done',
      'request_id': 'done',
    });
    final current = await repo.readSnapshot(created['id']);
    expect(current.entry.previousTaskState, TaskState.next);
    expect(current.note.text, 'Details');
  });
  test(
    'revision checked in same queue, queued operations revoked, pagination expires',
    () async {
      final entry = await note('A', body: 'first');
      await note('B');
      final first = await access.call('list_entries', {'limit': 1});
      final snapshot = await read(entry);
      final blocker = Completer<void>();
      final started = Completer<void>();
      final holding = repo.exclusive(() async {
        started.complete();
        await blocker.future;
      });
      await started.future;
      final mutation = repo.saveSnapshot(
        id: entry.id,
        expectedRevision: entry.revision,
        expectedBodyHash: snapshot['body_hash'] as String,
        draft: const EntryDraft(title: 'A', body: 'UI changed'),
      );
      final mcp = access.call('update_text', {
        'id': entry.id,
        'expected_revision': entry.revision,
        'expected_body_hash': snapshot['body_hash'],
        'text': 'MCP',
        'request_id': 'race',
      });
      final assertion = expectLater(mcp, code('conflict'));
      blocker.complete();
      await holding;
      await mutation;
      await assertion;
      await expectLater(
        access.call('list_entries', {
          'limit': 1,
          'cursor': first['next_cursor'],
        }),
        code('stale_cursor'),
      );
      final waiting = repo.exclusive(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      final queued = access.call('list_entries', {});
      access.revoke();
      await expectLater(queued, code('revoked'));
      await waiting;
    },
  );
  test('read-only access and editor guard block writes', () async {
    final entry = await note('Draft', body: 'saved');
    final readonly = McpAccessService(repo, canWrite: false);
    expect(
      () => readonly.call('create_note', {'title': 'No', 'request_id': 'no'}),
      code('read_only'),
    );
    final guard = McpEditorGuard.forRepository(repo), owner = Object();
    guard.report(owner, entry.id, blocked: true);
    await expectLater(
      access.call('update_text', {
        'id': entry.id,
        'expected_revision': entry.revision,
        'expected_body_hash': (await read(entry))['body_hash'],
        'text': 'No',
        'request_id': 'dirty',
      }),
      code('editor_busy'),
    );
    guard.remove(owner);
    expect((await read(entry))['text'], 'saved');
  });
  test(
    'bridge validates token, origin, host, opening and payload; revokes and removes file',
    () async {
      final destination = await Directory('${temp.path}/connection').create();
      final bridge = McpBridge(
        repo,
        repo.root,
        connectionWriter: (path, text) =>
            File(path).writeAsString(text).then((_) {}),
      );
      await bridge.enable(destination, write: true);
      final config = jsonDecode(
        await File(bridge.connectionPath!).readAsString(),
      );
      final client = HttpClient();
      Future<(int, String)> request({
        String? token,
        String? origin,
        String? host,
        Map<String, dynamic>? payload,
      }) async {
        final req = await client.postUrl(
          Uri.parse(config['endpoint'] as String),
        );
        req.headers.contentType = ContentType.json;
        req.headers.set('authorization', 'Bearer ${token ?? config['token']}');
        if (origin != null) req.headers.set('origin', origin);
        if (host != null) req.headers.set('host', host);
        req.write(
          jsonEncode(
            payload ??
                {
                  'version': 1,
                  'opening_id': config['opening_id'],
                  'tool': 'workspace_info',
                  'arguments': {},
                },
          ),
        );
        final res = await req.close();
        return (res.statusCode, await utf8.decodeStream(res));
      }

      try {
        expect((await request()).$1, 200);
        expect((await request(token: 'wrong')).$1, 403);
        expect((await request(origin: 'https://example.com')).$1, 403);
        expect((await request(host: 'evil.example')).$1, 403);
        final bad = await request(
          payload: {'version': 1, 'opening_id': 'wrong'},
        );
        expect(jsonDecode(bad.$2)['error']['code'], 'opening_changed');
        final path = bridge.connectionPath!;
        await bridge.disable();
        expect(await File(path).exists(), false);
        expect(bridge.enabled, false);
      } finally {
        client.close(force: true);
        if (bridge.enabled) await bridge.disable();
        bridge.dispose();
      }
    },
  );
  test(
    'connection file cannot be placed in a workspace or repository',
    () async {
      final bridge = McpBridge(repo, repo.root);
      await expectLater(
        bridge.enable(repo.root, write: false),
        throwsA(isA<WorkspaceException>()),
      );
      await expectLater(
        bridge.enable(Directory.current, write: false),
        throwsA(isA<WorkspaceException>()),
      );
      bridge.dispose();
    },
  );
  test(
    'actual stdio SDK client reads and writes through bridge to repository',
    () async {
      final destination = await Directory('${temp.path}/connection').create();
      final bridge = McpBridge(
        repo,
        repo.root,
        connectionWriter: (path, content) async {
          await File(path).writeAsString('');
          final result = await Process.run('/bin/chmod', ['600', path]);
          if (result.exitCode != 0) throw StateError('chmod failed');
          await File(path).writeAsString(content);
        },
      );
      try {
        await bridge.enable(destination, write: true);
        final process = await Process.run('node', [
          'mcp/test/app-smoke.mjs',
          bridge.connectionPath!,
        ]);
        expect(
          process.exitCode,
          0,
          reason: '${process.stdout} ${process.stderr}',
        );
        expect(
          (await repo.getEntries())
              .where((e) => e.title == 'MCP integration')
              .length,
          1,
        );
        final saved = (await repo.getEntries()).firstWhere(
          (e) => e.title == 'MCP integration',
        );
        expect(
          (await repo.noteVersions(saved.id)).map((v) => v.body),
          containsAll(['before', 'after']),
        );
      } finally {
        await bridge.disable();
        bridge.dispose();
      }
    },
  );
  test(
    'disable cancels delayed enable and closes bridge after repository close',
    () async {
      final destination = await Directory('${temp.path}/delayed').create();
      final started = Completer<void>(), release = Completer<void>();
      final bridge = McpBridge(
        repo,
        repo.root,
        connectionWriter: (path, content) async {
          started.complete();
          await release.future;
          await File(path).writeAsString(content);
        },
      );
      final enabling = bridge.enable(destination, write: false);
      final failed = expectLater(enabling, throwsA(isA<WorkspaceException>()));
      await started.future;
      final disabling = bridge.disable();
      release.complete();
      await failed;
      await disabling;
      expect(bridge.enabled, false);
      expect(
        await File('${destination.path}/para-mcp-connection.json').exists(),
        false,
      );
      bridge.dispose();
      final afterClose = McpBridge(
        repo,
        repo.root,
        connectionWriter: (path, text) =>
            File(path).writeAsString(text).then((_) {}),
      );
      await afterClose.enable(destination, write: false);
      await repo.close();
      await afterClose.disable();
      afterClose.dispose();
    },
  );
  test(
    'MCP preference survives independent backup; copied roots never enable a connection',
    () async {
      await repo.writeSetting(
        'mcp.v1',
        jsonEncode({'version': 1, 'write': true, 'archive': false}),
      );
      final original = await note('Backup note', body: 'preserved');
      final backupParent = await Directory('${temp.path}/backup').create();
      final backupPath = await repo.exportBackup(backupParent.path);
      final recovered = await LocalWorkspaceRepository.open(
        Directory(backupPath),
        create: false,
      );
      try {
        expect(
          (await recovered.readSnapshot(original.id)).note.text,
          'preserved',
        );
        expect(
          jsonDecode((await recovered.readSetting('mcp.v1'))!)['version'],
          1,
        );
        final recoveredBridge = McpBridge(recovered, recovered.root);
        expect(recoveredBridge.enabled, false);
        recoveredBridge.dispose();
        expect(
          await File('$backupPath/para-mcp-connection.json').exists(),
          false,
        );
      } finally {
        await recovered.close();
      }
    },
  );
  test(
    'manager root change revokes old bridge and never activates copied preference',
    () async {
      final manager = WorkspaceManager(
        configurationDirectory: Directory('${temp.path}/manager-config'),
        defaultRoot: Directory('${temp.path}/manager-source'),
      );
      await manager.initialize();
      final source = manager.repository!;
      manager.mcp!.dispose();
      final bridge = McpBridge(
        source,
        source.root,
        connectionWriter: (path, content) =>
            File(path).writeAsString(content).then((_) {}),
      );
      manager.mcp = bridge;
      final connection = await Directory(
        '${temp.path}/manager-connection',
      ).create();
      try {
        await bridge.enable(connection, write: true);
        final credentialPath = bridge.connectionPath!;
        final destination = await Directory(
          '${temp.path}/manager-copy',
        ).create();
        await manager.switchTo(
          WorkspaceLocation(destination.path),
          WorkspaceOpenMode.copyCurrent,
        );
        expect(bridge.enabled, false);
        expect(await File(credentialPath).exists(), false);
        expect(manager.mcp!.enabled, false);
        expect(
          jsonDecode(
            (await manager.repository!.readSetting('mcp.v1'))!,
          )['write'],
          true,
        );
      } finally {
        await manager.close();
        manager.dispose();
      }
    },
  );
  test(
    'rejects oversized text, path input, unknown fields and invalid field types',
    () async {
      expect(
        () => access.call('read_text', {'id': '../../secret'}),
        code('invalid_input'),
      );
      expect(
        () => access.call('list_entries', {'limit': 101}),
        code('invalid_input'),
      );
      expect(
        () => access.call('list_entries', {'include_archive': 'true'}),
        code('invalid_input'),
      );
      expect(
        () => access.call('workspace_info', {'path': '/etc/passwd'}),
        code('invalid_input'),
      );
      expect(
        () => access.call('create_note', {
          'title': 'Large',
          'text': 'ä' * 600000,
          'request_id': 'large',
        }),
        code('invalid_input'),
      );
      expect(await repo.getEntries(), isEmpty);
    },
  );
  test('search preserves relevance rather than alphabetic ordering', () async {
    await note('AAAA fuzzy', body: 'other content');
    final exact = await note('fuzzy');
    final result = await access.call('search', {'query': 'fuzzy', 'limit': 1});
    expect((result['items'] as List).single['id'], exact.id);
  });
  test(
    'closing repository drains admitted writes and refuses new operations',
    () async {
      final entry = await note('Closing', body: 'before');
      final snapshot = await repo.readSnapshot(entry.id);
      final release = Completer<void>(), started = Completer<void>();
      final holding = repo.exclusive(() async {
        started.complete();
        await release.future;
      });
      await started.future;
      final save = repo.saveSnapshot(
        id: entry.id,
        expectedRevision: entry.revision,
        expectedBodyHash: snapshot.note.hash,
        draft: const EntryDraft(title: 'Closing', body: 'after'),
      );
      final closing = repo.close();
      await expectLater(
        repo.exclusive(() async {}),
        throwsA(isA<WorkspaceException>()),
      );
      release.complete();
      await holding;
      await save;
      await closing;
      repo = await LocalWorkspaceRepository.open(
        Directory('${temp.path}/workspace'),
        create: false,
      );
      expect((await repo.readSnapshot(entry.id)).note.text, 'after');
    },
  );
}
