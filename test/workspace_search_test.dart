import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/ui/workspace_search.dart';

class _SearchRepository implements WorkspaceRepository {
  final entries = StreamController<List<Entry>>.broadcast(sync: true);
  final status = StreamController<SearchIndexStatus>.broadcast(sync: true);

  @override
  SearchIndexStatus searchIndexStatus = const SearchIndexStatus(updating: true);

  @override
  Stream<List<Entry>> watchEntries() => entries.stream;

  @override
  Stream<SearchIndexStatus> watchSearchIndex() => status.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Entry _entry(String id, String text) => Entry(
  id: id,
  title: 'Datei $id',
  kind: EntryKind.file,
  section: ParaSection.inbox,
  archived: false,
  completed: false,
  taskState: TaskState.inbox,
  context: '',
  goal: '',
  revision: 1,
  updatedAt: DateTime(2026),
  searchText: text,
  fileName: '$id.pdf',
);

void main() {
  late _SearchRepository repository;

  setUp(() => repository = _SearchRepository());
  tearDown(() async {
    await repository.entries.close();
    await repository.status.close();
  });

  Future<void> open(
    WidgetTester tester,
    List<Entry> initial, {
    bool filesOnly = false,
    void Function(Entry?)? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await showWorkspaceSearch(
                  context,
                  initial,
                  repository: repository,
                  filesOnly: filesOnly,
                );
                onResult?.call(result);
              },
              child: const Text('Suche öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Suche öffnen'));
    await tester.pumpAndSettle();
  }

  testWidgets('open search receives new content hits and indexing status', (
    tester,
  ) async {
    await open(tester, [_entry('eins', 'alter Inhalt')]);
    expect(find.text('Suchinhalte werden aktualisiert …'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('workspace-search-query')),
      'Sternenstaub',
    );
    await tester.pump();
    expect(find.text('Keine passenden Inhalte'), findsOneWidget);

    repository.entries.add([_entry('eins', 'Sternenstaub')]);
    repository.status.add(const SearchIndexStatus());
    await tester.pump();
    expect(find.byKey(const ValueKey('search-result-eins')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-index-status')), findsNothing);

    repository.status.add(const SearchIndexStatus(failures: 1));
    await tester.pump();
    expect(
      find.text('Einige Suchinhalte konnten nicht aktualisiert werden.'),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(repository.entries.hasListener, isFalse);
    expect(repository.status.hasListener, isFalse);
  });

  testWidgets(
    'keyboard selection follows live entries and submits current hit',
    (tester) async {
      Entry? opened;
      await open(tester, [
        _entry('eins', 'alt'),
        _entry('zwei', 'alt'),
      ], onResult: (entry) => opened = entry);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('search-result-zwei')))
            .selected,
        isTrue,
      );

      // A stream event can arrive between a frame and the submit callback.
      final submit = tester
          .widget<TextField>(
            find.byKey(const ValueKey('workspace-search-query')),
          )
          .onSubmitted!;
      repository.entries.add([_entry('zwei', 'neuer Inhalt')]);
      submit('');
      await tester.pumpAndSettle();
      expect(opened?.id, 'zwei');
      expect(opened?.searchText, 'neuer Inhalt');
    },
  );

  testWidgets('file switcher updates names without indexing status', (
    tester,
  ) async {
    await open(tester, [], filesOnly: true);
    expect(find.byKey(const ValueKey('search-index-status')), findsNothing);
    expect(repository.status.hasListener, isFalse);
    repository.entries.add([_entry('eins', 'Inhalt')]);
    await tester.pump();
    expect(find.byKey(const ValueKey('search-result-eins')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });
}
