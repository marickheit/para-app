import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'desktop_features.dart';
import 'compact_explorer_features.dart';
import 'target_features.dart';
import 'recovery_features.dart';
import 'workspace_settings_features.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerDesktopFeatureTests();
  registerCompactExplorerTests();
  registerTargetFeatureTests();
  registerRecoveryFeatureTests();
  registerWorkspaceSettingsTests();
  testWidgets(
    'project content, stable links, task switch, save and reopening',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'para-workspace-',
      );
      var repo = await LocalWorkspaceRepository.open(directory);
      try {
        final project = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Arbeitszimmer',
            goal: 'Ein fertiger Arbeitsplatz',
            dueDate: DateTime(2026, 12, 15),
          ),
        );
        final target = await repo.create(
          kind: EntryKind.note,
          parentId: project.id,
          draft: const EntryDraft(
            title: 'Raumideen',
            body: 'Eine zweite Notiz.',
          ),
        );
        final source = await repo.create(
          kind: EntryKind.note,
          parentId: project.id,
          draft: EntryDraft(
            title: 'Projektüberblick',
            body: '# Planung\n\n${markdownLink(target)}',
          ),
        );
        await repo.create(
          kind: EntryKind.task,
          parentId: project.id,
          draft: const EntryDraft(
            title: 'Tisch ausmessen',
            taskState: TaskState.next,
          ),
        );
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: directory.path),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-projects')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('tree-entry-${project.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('tree-toggle-${project.id}')));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('workspace-header')),
            matching: find.textContaining('Ein fertiger Arbeitsplatz'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('workspace-header')),
            matching: find.textContaining('15.12.2026'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('tree-entry-${source.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Raumideen').last);
        await tester.pumpAndSettle();
        expect(find.text('Eine zweite Notiz.'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('markdown-mode-raw')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('markdown-body')),
          'Neue Gedanken.',
        );
        await tester.tap(find.byKey(ValueKey('tree-entry-${project.id}')));
        await tester.pumpAndSettle();
        expect(find.text('Änderungen speichern?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Speichern'),
          ),
        );
        await tester.pumpAndSettle();
        expect((await repo.readNote(target.id)).text, 'Neue Gedanken.');
        await tester.tap(find.widgetWithText(TextButton, 'Aufgaben'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(
          (await repo.getEntries())
              .firstWhere((e) => e.kind == EntryKind.task)
              .taskState,
          TaskState.done,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        repo = await LocalWorkspaceRepository.open(directory);
        expect((await repo.readNote(target.id)).text, 'Neue Gedanken.');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'narrow navigation, project validation and folder row interaction',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp('para-narrow-'),
          repo = await LocalWorkspaceRepository.open(
            await Directory.systemTemp.createTemp('para-narrow-data-'),
          );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      try {
        final project = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Kleines Projekt',
            goal: 'Klares Ergebnis',
            dueDate: DateTime(2026, 12, 31),
          ),
        );
        final folder = await repo.create(
          kind: EntryKind.folder,
          parentId: project.id,
          draft: const EntryDraft(title: 'Planung'),
        );
        final note = await repo.create(
          kind: EntryKind.note,
          parentId: folder.id,
          draft: const EntryDraft(
            title: 'Erste Notiz',
            body: '# Hallo\n\nEin Gedanke.',
          ),
        );
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: repo.root.path),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Navigation öffnen'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-projects')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Neuen Inhalt anlegen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Projekt anlegen'));
        await tester.pumpAndSettle();
        final fields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(fields.at(0), 'Begrenzt');
        await tester.enterText(fields.at(1), 'Ein Ergebnis');
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Anlegen'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Ein Projekt braucht ein Fälligkeitsdatum.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Navigation öffnen'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('tree-toggle-${project.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('tree-entry-${folder.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Navigation öffnen'));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('tree-entry-${note.id}')), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('tree-entry-${note.id}')));
        await tester.pumpAndSettle();
        expect(find.text('Ein Gedanke.'), findsOneWidget);
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
