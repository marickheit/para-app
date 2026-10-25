import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';

Future<void> surfaceShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pumpAndSettle();
}

void registerCompactExplorerTests() {
  testWidgets(
    'target rail, one explorer, explicit editor save and fuzzy search preserve drafts',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp('para-surface-'),
          repo = await LocalWorkspaceRepository.open(
            await Directory.systemTemp.createTemp('para-repo-'),
          );
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      try {
        final project = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Arbeitszimmer',
            goal: 'Ein fertiger Arbeitsplatz',
            dueDate: DateTime(2026, 12, 15),
          ),
        );
        final folder = await repo.create(
          kind: EntryKind.folder,
          parentId: project.id,
          draft: const EntryDraft(title: 'Unterlagen'),
        );
        final note = await repo.create(
          kind: EntryKind.note,
          parentId: folder.id,
          draft: const EntryDraft(
            title: 'Raumnotiz',
            body: 'Direkt beim Inhalt beginnen.',
          ),
        );
        final other = await repo.create(
          kind: EntryKind.note,
          draft: const EntryDraft(
            title: 'Andere Notiz',
            body: 'Einzigartiger Suchinhalt.',
          ),
        );
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: repo.root.path),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-projects')));
        await tester.pumpAndSettle();
        final row = find.byKey(ValueKey('tree-entry-${note.id}'));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('explorer-sidebar')),
            matching: row,
          ),
          findsOneWidget,
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('navigation-rail'))).width,
          56,
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('workspace-header'))).height,
          60,
        );
        expect(tester.getTopLeft(find.byType(MarkdownBody)).dy, lessThan(175));
        await tester.tap(find.byKey(const ValueKey('rail-expand')));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('navigation-rail'))).width,
          164,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Bearbeiten'));
        await tester.pumpAndSettle();
        final body = find.byKey(const ValueKey('markdown-body'));
        await tester.enterText(body, 'Noch nicht gespeicherte Gedanken.');
        await tester.pumpAndSettle();
        final before = tester
            .getSize(find.byKey(const ValueKey('entry-editor-scroll')))
            .width;
        await surfaceShortcut(tester, LogicalKeyboardKey.backslash);
        expect(find.byKey(const ValueKey('explorer-sidebar')), findsNothing);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('entry-editor-scroll')))
              .width,
          greaterThan(before + 200),
        );
        expect(
          tester.widget<TextField>(body).controller!.text,
          'Noch nicht gespeicherte Gedanken.',
        );
        await tester.tap(body);
        await surfaceShortcut(tester, LogicalKeyboardKey.keyF);
        final query = find.byKey(const ValueKey('workspace-search-query'));
        await tester.enterText(query, 'Einzigartiger Suchinhalt');
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('search-result-${other.id}')),
          findsOneWidget,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('Änderungen speichern?'), findsOneWidget);
        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(body).controller!.text,
          'Noch nicht gespeicherte Gedanken.',
        );
        await tester.tap(find.byKey(const ValueKey('editor-save')));
        await tester.pumpAndSettle();
        expect(
          (await repo.readNote(note.id)).text,
          'Noch nicht gespeicherte Gedanken.',
        );
        await tester.tap(body);
        await surfaceShortcut(tester, LogicalKeyboardKey.keyO);
        await tester.enterText(query, 'Einzigartiger Suchinhalt');
        await tester.pumpAndSettle();
        expect(find.text('Keine passenden Inhalte'), findsOneWidget);
        await tester.enterText(query, 'AndrNtz');
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('search-result-${other.id}')),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('Einzigartiger Suchinhalt.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await repo.close();
        await repo.root.delete(recursive: true);
        await directory.delete(recursive: true);
      }
    },
  );
}
