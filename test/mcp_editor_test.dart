import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/mcp_access_service.dart';
import 'package:para_workspace/services/mcp_editor_guard.dart';
import 'package:para_workspace/ui/entry_editor.dart';
import 'package:para_workspace/ui/task_details.dart';

// Controlled async boundary: real repository/stdio behavior is exercised in
// mcp_test.dart. Here delays and UI-only edits can be reproduced deterministically.
class _EditorRepository implements WorkspaceRepository {
  _EditorRepository(this.entry);
  final Entry entry;
  Completer<EntrySnapshot>? delayed;
  int snapshotReads = 0;
  @override
  Future<T> exclusive<T>(Future<T> Function() operation) => operation();
  @override
  Future<List<Entry>> getEntries() async => [entry];
  @override
  Future<EntrySnapshot> readSnapshot(String id) async {
    snapshotReads++;
    return delayed == null
        ? EntrySnapshot(entry, const NoteSnapshot('saved text', 'hash'))
        : delayed!.future;
  }

  @override
  Future<EntrySnapshot> saveSnapshot({
    required String id,
    required int expectedRevision,
    required String expectedBodyHash,
    required EntryDraft draft,
  }) async => EntrySnapshot(
    _entry(entry.kind, revision: 2),
    NoteSnapshot(draft.body, 'saved-hash'),
  );
  @override
  Stream<List<TaskContext>> watchContexts() => Stream.value([]);
  @override
  Future<List<Entry>> backlinks(String id) async => [];
  @override
  Future<List<Entry>> outgoingLinks(String id) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Entry _entry(EntryKind kind, {int revision = 1}) => Entry(
  id: '00000000-0000-4000-8000-000000000001',
  title: 'Draft',
  kind: kind,
  section: ParaSection.inbox,
  archived: false,
  completed: false,
  taskState: TaskState.next,
  context: '',
  goal: '',
  revision: revision,
  updatedAt: DateTime.utc(2026),
  searchText: 'saved text',
);
Widget _editor(_EditorRepository repo) => MaterialApp(
  home: Scaffold(
    body: EntryEditor(
      entry: repo.entry,
      entries: [repo.entry],
      repository: repo,
      onOpen: (_) async {},
    ),
  ),
);
Future<void> _assertBlocked(_EditorRepository repo, String request) async {
  final access = McpAccessService(repo, canWrite: true);
  await expectLater(
    access.call('update_text', {
      'id': repo.entry.id,
      'expected_revision': 1,
      'expected_body_hash': '0' * 64,
      'text': 'remote',
      'request_id': request,
    }),
    throwsA(isA<McpException>().having((e) => e.code, 'code', 'editor_busy')),
  );
}

void main() {
  testWidgets('unsaved text blocks MCP without replacing the draft', (
    tester,
  ) async {
    final repo = _EditorRepository(_entry(EntryKind.note));
    await tester.pumpWidget(_editor(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('markdown-mode-raw')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'unsaved draft');
    await _assertBlocked(repo, 'text');
    expect(find.text('unsaved draft'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('task-only fields report draft and prevent MCP writes', (
    tester,
  ) async {
    final repo = _EditorRepository(_entry(EntryKind.task));
    await tester.pumpWidget(_editor(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bearbeiten').first);
    await tester.pumpAndSettle();
    final details = tester.widget<TaskDetailsFields>(
      find.byType(TaskDetailsFields),
    );
    details.onChanged(
      const TaskDetailsValue(minutes: 15, energy: EnergyLevel.low),
    );
    await tester.pump();
    await _assertBlocked(repo, 'metadata');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'loading is locked and holds write exclusion until snapshot arrives',
    (tester) async {
      final repo = _EditorRepository(_entry(EntryKind.note));
      repo.delayed = Completer<EntrySnapshot>();
      await tester.pumpWidget(_editor(repo));
      expect(McpEditorGuard.forRepository(repo).acquire(repo.entry.id), false);
      repo.delayed!.complete(
        EntrySnapshot(repo.entry, const NoteSnapshot('saved text', 'hash')),
      );
      await tester.pumpAndSettle();
      final guard = McpEditorGuard.forRepository(repo);
      expect(guard.acquire(repo.entry.id), true);
      guard.release(repo.entry.id);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'saving keeps text and edit mode when parent still has old revision',
    (tester) async {
      final repo = _EditorRepository(_entry(EntryKind.note));
      await tester.pumpWidget(_editor(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('markdown-mode-raw')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('markdown-body')),
        'changed text',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('editor-save')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('markdown-body')))
            .controller!
            .text,
        'changed text',
      );
      expect(repo.snapshotReads, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
