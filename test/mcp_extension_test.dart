import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/mcp_access_service.dart';
import 'package:para_workspace/services/mcp_editor_guard.dart';

void main() {
  late Directory temp;
  late LocalWorkspaceRepository repo;
  late McpAccessService access;
  var serial = 0;
  String request() => 'extension-${serial++}';
  Matcher code(String value) =>
      throwsA(isA<McpException>().having((e) => e.code, 'code', value));
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('para-mcp-extension-');
    repo = await LocalWorkspaceRepository.open(Directory('${temp.path}/root'));
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
  Future<Map<String, dynamic>> read(String id, {int? length, int? offset}) =>
      access.call('read_text', {
        'id': id,
        'length': ?length,
        'offset': ?offset,
      });
  Future<Map<String, dynamic>> edit(
    String id,
    String text, {
    String operation = 'append',
    String? oldText,
  }) async {
    final before = await read(id);
    return access.call('edit_text', {
      'id': id,
      'expected_revision': before['revision'],
      'expected_body_hash': before['body_hash'],
      'operation': operation,
      'text': text,
      'old_text': ?oldText,
      'request_id': request(),
    });
  }

  test(
    'new containers have fixed sections and folders use explicit locations',
    () async {
      for (final kind in ['area', 'resource']) {
        final created = await access.call('create_$kind', {
          'title': 'Container $kind',
          'text': 'Description $kind',
          'request_id': request(),
        });
        expect(created['kind'], kind);
        expect(created['section'], '${kind}s');
        expect(created['parent_id'], isNull);
        expect((await read(created['id']))['text'], 'Description $kind');
        final child = await access.call('create_folder', {
          'title': 'Folder',
          'parent_id': created['id'],
          'request_id': request(),
        });
        expect(child['parent_id'], created['id']);
        expect(child['section'], '${kind}s');
        for (final forbidden in [
          {'section': 'inbox'},
          {'parent_id': child['id']},
          {'state': 'next'},
        ]) {
          await expectLater(
            Future.sync(
              () => access.call('create_$kind', {
                'title': 'Invalid',
                'request_id': request(),
                ...forbidden,
              }),
            ),
            code('invalid_input'),
          );
        }
      }
      await expectLater(
        Future.sync(
          () => access.call('create_folder', {
            'title': 'No target',
            'request_id': request(),
          }),
        ),
        code('invalid_input'),
      );
      await expectLater(
        access.call('create_folder', {
          'title': 'No project root folders',
          'section': 'projects',
          'request_id': request(),
        }),
        throwsA(isA<McpException>()),
      );
      final rootFolder = await access.call('create_folder', {
        'title': 'Inbox folder',
        'section': 'inbox',
        'request_id': request(),
      });
      expect(rootFolder['section'], 'inbox');
    },
  );

  test(
    'entry edits preserve text, links and omitted project and task fields',
    () async {
      final target = await note('Reference');
      final project = await access.call('create_project', {
        'title': 'Release',
        'goal': 'First result',
        'due_date': '2026-12-01',
        'text': 'Keep ${markdownLink(target)}',
        'request_id': request(),
      });
      final before = await read(project['id']);
      final updated = await access.call('update_entry', {
        'id': project['id'],
        'expected_revision': project['revision'],
        'title': 'New title',
        'goal': 'New result',
        'request_id': request(),
      });
      final current = await access.call('get_entry', {'id': project['id']});
      expect(current['id'], project['id']);
      expect(current['link'], project['link']);
      expect(current['title'], 'New title');
      expect(current['goal'], 'New result');
      expect(current['due_date'], '2026-12-01');
      expect((await read(project['id']))['text'], before['text']);
      expect(updated['body_hash'], before['body_hash']);
      expect((await repo.outgoingLinks(project['id'])).single.id, target.id);
      await expectLater(
        access.call('update_entry', {
          'id': project['id'],
          'expected_revision': project['revision'],
          'title': 'Stale',
          'request_id': request(),
        }),
        code('conflict'),
      );
      for (final invalid in [
        <String, dynamic>{},
        {'goal': ''},
        {'due_date': null},
        {'due_date': '2026-02-29'},
        {'state': 'done'},
      ]) {
        await expectLater(
          Future.sync(
            () => access.call('update_entry', {
              'id': project['id'],
              'expected_revision': updated['revision'],
              'request_id': request(),
              ...invalid,
            }),
          ),
          throwsA(isA<McpException>()),
        );
      }
      final task = await access.call('create_task', {
        'title': 'Task',
        'text': 'Task description',
        'parent_id': project['id'],
        'state': 'waiting',
        'energy': 'high',
        'estimated_minutes': 45,
        'request_id': request(),
      });
      final renamed = await access.call('update_entry', {
        'id': task['id'],
        'expected_revision': task['revision'],
        'title': 'Task renamed',
        'request_id': request(),
      });
      expect(renamed['state'], 'waiting');
      expect(renamed['energy'], 'high');
      expect(renamed['estimated_minutes'], 45);
      expect((await read(task['id']))['text'], 'Task description');
      await expectLater(
        access.call('update_entry', {
          'id': task['id'],
          'expected_revision': renamed['revision'],
          'goal': 'Not a project',
          'request_id': request(),
        }),
        throwsA(isA<McpException>()),
      );
    },
  );

  test(
    'binary attachment rename retains exact bytes and internal links',
    () async {
      final bytes = [0, 255, 128, 10, 3, 77];
      final attachment = await repo.importFile(
        name: 'original.bin',
        bytes: Stream.value(bytes),
      );
      final linking = await note('Link', body: markdownLink(attachment));
      final updated = await access.call('update_entry', {
        'id': attachment.id,
        'expected_revision': attachment.revision,
        'title': 'renamed.bin',
        'request_id': request(),
      });
      expect(updated['id'], attachment.id);
      expect(updated['title'], 'renamed.bin');
      expect(
        await File(await repo.filePath(attachment.id)).readAsBytes(),
        bytes,
      );
      expect((await repo.outgoingLinks(linking.id)).single.id, attachment.id);
      await expectLater(edit(attachment.id, 'text'), code('unsupported'));
    },
  );

  test(
    'append and unique replace preserve history and duplicate append is applied once',
    () async {
      final entry = await note('Text', body: 'Alpha\nBeta');
      final before = await read(entry.id);
      final append = {
        'id': entry.id,
        'expected_revision': before['revision'],
        'expected_body_hash': before['body_hash'],
        'operation': 'append',
        'text': '\nGamma',
        'request_id': request(),
      };
      final receipts = await Future.wait([
        access.call('edit_text', append),
        access.call('edit_text', append),
      ]);
      expect(receipts[0], receipts[1]);
      expect((await read(entry.id))['text'], 'Alpha\nBeta\nGamma');
      final changed = await edit(
        entry.id,
        'Delta',
        operation: 'replace',
        oldText: 'Beta',
      );
      expect((await read(entry.id))['text'], 'Alpha\nDelta\nGamma');
      expect(changed['revision'], (receipts[0]['revision'] as int) + 1);
      expect(
        (await repo.noteVersions(entry.id)).map((v) => v.body),
        containsAll([
          'Alpha\nBeta',
          'Alpha\nBeta\nGamma',
          'Alpha\nDelta\nGamma',
        ]),
      );
      await expectLater(
        access.call('edit_text', {...append, 'request_id': request()}),
        code('conflict'),
      );
      final latest = await read(entry.id);
      await expectLater(
        access.call('edit_text', {
          ...append,
          'expected_revision': latest['revision'],
          'request_id': request(),
        }),
        code('conflict'),
      );
      expect((await read(entry.id))['text'], 'Alpha\nDelta\nGamma');
    },
  );

  test(
    'text edits reject ambiguous, missing, invalid and oversized changes without mutation',
    () async {
      final entry = await note('Repeated', body: 'same same');
      for (final oldText in ['same', 'missing', '']) {
        await expectLater(
          edit(entry.id, 'replacement', operation: 'replace', oldText: oldText),
          throwsA(isA<McpException>()),
        );
        expect((await read(entry.id))['text'], 'same same');
      }
      final before = await read(entry.id);
      await expectLater(
        Future.sync(
          () => access.call('edit_text', {
            'id': entry.id,
            'expected_revision': before['revision'],
            'expected_body_hash': before['body_hash'],
            'operation': 'append',
            'text': 'end',
            'old_text': 'same',
            'request_id': request(),
          }),
        ),
        throwsA(isA<McpException>()),
      );
      final overlapping = await note('Overlap', body: 'aaa');
      await expectLater(
        edit(overlapping.id, 'x', operation: 'replace', oldText: 'aa'),
        throwsA(isA<McpException>()),
      );
      expect((await read(overlapping.id))['text'], 'aaa');
      final large = await note('Large', body: 'ä' * 524280);
      await edit(large.id, 'ä' * 8);
      final snapshot = await repo.readSnapshot(large.id);
      expect(utf8.encode(snapshot.note.text).length, 1048576);
      await expectLater(edit(large.id, 'ä'), throwsA(isA<McpException>()));
      final after = await repo.readSnapshot(large.id);
      expect(after.entry.revision, snapshot.entry.revision);
      expect(after.note.hash, snapshot.note.hash);
    },
  );

  test(
    'malformed Unicode input cannot split or corrupt saved characters',
    () async {
      final entry = await note('Unicode integrity', body: 'Keep 😀 intact');
      final original = await repo.readSnapshot(entry.id);
      for (final surrogate in [
        String.fromCharCode(0xd83d),
        String.fromCharCode(0xde00),
      ]) {
        await expectLater(edit(entry.id, surrogate), code('invalid_input'));
        await expectLater(
          edit(
            entry.id,
            'replacement',
            operation: 'replace',
            oldText: surrogate,
          ),
          code('invalid_input'),
        );
      }
      final after = await repo.readSnapshot(entry.id);
      expect(after.entry.revision, original.entry.revision);
      expect(after.note.text, original.note.text);
      expect(after.note.hash, original.note.hash);
    },
  );

  test(
    'new writes honor read-only, dirty editor and archive/trash restrictions',
    () async {
      final entry = await note('Guarded', body: 'saved');
      final snapshot = await read(entry.id);
      final rename = {
        'id': entry.id,
        'expected_revision': entry.revision,
        'title': 'Changed',
        'request_id': request(),
      };
      final readonly = McpAccessService(repo, canWrite: false);
      for (final tool in ['create_area', 'create_resource', 'create_folder']) {
        await expectLater(
          Future.sync(
            () => readonly.call(tool, {
              'title': 'No',
              if (tool == 'create_folder') 'section': 'inbox',
              'request_id': request(),
            }),
          ),
          code('read_only'),
        );
      }
      await expectLater(
        Future.sync(() => readonly.call('update_entry', rename)),
        code('read_only'),
      );
      await expectLater(
        Future.sync(
          () => readonly.call('edit_text', {
            'id': entry.id,
            'expected_revision': entry.revision,
            'expected_body_hash': snapshot['body_hash'],
            'operation': 'append',
            'text': 'No',
            'request_id': request(),
          }),
        ),
        code('read_only'),
      );
      readonly.revoke();
      final guard = McpEditorGuard.forRepository(repo), owner = Object();
      guard.report(owner, entry.id, blocked: true);
      await expectLater(
        access.call('update_entry', rename),
        code('editor_busy'),
      );
      await expectLater(edit(entry.id, 'No'), code('editor_busy'));
      guard.remove(owner);
      expect((await read(entry.id))['text'], 'saved');
      await repo.archive(entry.id, true);
      await expectLater(
        access.call('update_entry', {...rename, 'request_id': request()}),
        throwsA(isA<McpException>()),
      );
      await repo.archive(entry.id, false);
      await repo.trash(entry.id);
      await expectLater(
        access.call('update_entry', {...rename, 'request_id': request()}),
        code('not_found'),
      );
    },
  );

  test(
    'compact default and full listing paginate within byte budget and invalidate hidden changes',
    () async {
      for (var i = 0; i < 23; i++) {
        await note('Note ${i.toString().padLeft(2, '0')}');
      }
      final first = await access.call('list_entries', {});
      expect((first['items'] as List).length, 20);
      expect(first['next_cursor'], isNotNull);
      final compact = (first['items'] as List).first as Map;
      expect(compact.containsKey('goal'), false);
      expect(compact.containsKey('file_size'), false);
      final detailed = await access.call('list_entries', {
        'detail': 'full',
        'limit': 1,
      });
      expect((detailed['items'] as List).first.containsKey('file_size'), true);
      final next = await access.call('list_entries', {
        'cursor': first['next_cursor'],
      });
      expect((next['items'] as List).length, 3);
      final snapshot = await repo.readSnapshot(compact['id']);
      await repo.saveSnapshot(
        id: snapshot.entry.id,
        expectedRevision: snapshot.entry.revision,
        expectedBodyHash: snapshot.note.hash,
        draft: EntryDraft(
          title: snapshot.entry.title,
          body: 'Changed hidden text',
        ),
      );
      await expectLater(
        access.call('list_entries', {'cursor': first['next_cursor']}),
        code('stale_cursor'),
      );
      for (var i = 0; i < 24; i++) {
        await note('Long $i ${'ä' * 3500}');
      }
      var cursor = <String, dynamic>{'limit': 100};
      final seen = <String>{};
      do {
        final result = await access.call('list_entries', cursor);
        expect(
          utf8.encode(jsonEncode(result)).length,
          lessThanOrEqualTo(65536),
        );
        final items = result['items'] as List;
        expect(items, isNotEmpty);
        for (final item in items) {
          expect(seen.add(item['id']), true);
        }
        cursor = {
          'limit': 100,
          if (result['next_cursor'] != null) 'cursor': result['next_cursor'],
        };
      } while (cursor.containsKey('cursor'));
      expect(seen.length, 47);
    },
  );

  test(
    'text chunks reconstruct Unicode exactly within JSON budget and default to 4000 units',
    () async {
      final body = '${'a' * 3999}😀${'ä\n"😀' * 10000}';
      final entry = await note('Unicode', body: body);
      final initial = await read(entry.id);
      expect((initial['text'] as String).length, lessThanOrEqualTo(4000));
      expect(initial['next_offset'], isNotNull);
      await expectLater(read(entry.id, offset: 4000), code('invalid_input'));
      final reconstructed = StringBuffer();
      var offset = 0;
      String? hash;
      while (true) {
        final chunk = await read(entry.id, offset: offset, length: 262144);
        expect(utf8.encode(jsonEncode(chunk)).length, lessThanOrEqualTo(65536));
        final text = chunk['text'] as String;
        expect(text, isNotEmpty);
        expect(utf8.decode(utf8.encode(text)), text);
        expect(chunk['body_hash'], hash ??= chunk['body_hash'] as String);
        reconstructed.write(text);
        if (chunk['next_offset'] == null) break;
        expect(chunk['next_offset'] as int, greaterThan(offset));
        offset = chunk['next_offset'] as int;
      }
      expect(reconstructed.toString(), body);
      final emoji = await note('Emoji', body: '😀!');
      final short = await read(emoji.id, length: 1);
      expect(short['text'], '😀');
      expect(short['next_offset'], 2);
    },
  );

  test(
    'search filters select only direct matching children in requested section and kind',
    () async {
      final area = await access.call('create_area', {
        'title': 'Area',
        'request_id': request(),
      });
      final resource = await access.call('create_resource', {
        'title': 'Resources',
        'request_id': request(),
      });
      final direct = await note('Matching direct', parentId: area['id']);
      final folder = await access.call('create_folder', {
        'title': 'Matching folder',
        'parent_id': area['id'],
        'request_id': request(),
      });
      await note('Matching nested', parentId: folder['id']);
      await note('Matching resource', parentId: resource['id']);
      final result = await access.call('search', {
        'query': 'Matching',
        'parent_id': area['id'],
        'section': 'areas',
        'kind': 'note',
      });
      expect((result['items'] as List).map((e) => e['id']), [direct.id]);
      expect(
        (await access.call('search', {
          'query': 'Matching',
          'section': 'resources',
        }))['total'],
        1,
      );
    },
  );

  test(
    'new containers and edits survive independent backup recovery and reopening',
    () async {
      final area = await access.call('create_area', {
        'title': 'Area',
        'text': 'Original description',
        'request_id': request(),
      });
      final resource = await access.call('create_resource', {
        'title': 'Reference',
        'text': 'Resource description',
        'request_id': request(),
      });
      final child = await access.call('create_folder', {
        'title': 'Subfolder',
        'parent_id': area['id'],
        'request_id': request(),
      });
      final document = await note(
        'Document',
        body: 'Keep ${resource['link']}',
        parentId: child['id'],
      );
      await edit(document.id, '\nNew paragraph');
      final renamed = await access.call('update_entry', {
        'id': area['id'],
        'expected_revision': area['revision'],
        'title': 'Renamed area',
        'request_id': request(),
      });
      final backupParent = await Directory('${temp.path}/backup').create();
      final backupPath = await repo.exportBackup(backupParent.path);
      final recovered = await LocalWorkspaceRepository.open(
        Directory(backupPath),
        create: false,
      );
      try {
        final copy = await recovered.readSnapshot(area['id']);
        expect(copy.entry.title, 'Renamed area');
        expect(copy.entry.revision, renamed['revision']);
        expect(copy.note.text, 'Original description');
        expect(
          (await recovered.readSnapshot(resource['id'])).note.text,
          'Resource description',
        );
        expect(
          (await recovered.readSnapshot(document.id)).entry.parentId,
          child['id'],
        );
        expect(
          (await recovered.readSnapshot(document.id)).note.text,
          'Keep ${resource['link']}\nNew paragraph',
        );
        expect(
          (await recovered.noteVersions(document.id)).length,
          greaterThanOrEqualTo(2),
        );
      } finally {
        await recovered.close();
      }
      access.revoke();
      await repo.close();
      repo = await LocalWorkspaceRepository.open(
        Directory('${temp.path}/root'),
        create: false,
      );
      access = McpAccessService(repo, canWrite: true);
      expect(
        (await access.call('get_entry', {'id': area['id']}))['title'],
        'Renamed area',
      );
      expect(
        (await read(document.id))['text'],
        'Keep ${resource['link']}\nNew paragraph',
      );
    },
  );
}
