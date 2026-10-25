import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/workspace_manager.dart';
import 'target_features.dart' show captureSurface;

class ScriptedDirectoryAccess implements WorkspaceDirectoryAccess {
  WorkspaceLocation? selected;
  @override
  Future<WorkspaceLocation?> choose() async => selected;
  @override
  Future<WorkspaceLocation> restore(WorkspaceLocation location) async =>
      location;
}

Future<void> _settings(WidgetTester tester, {bool contexts = false}) async {
  await tester.tap(find.byKey(const ValueKey('workspace-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(contexts ? 'Einstellungen' : 'Daten & Sicherung'));
  await tester.pumpAndSettle();
}

void registerWorkspaceSettingsTests() {
  testWidgets(
    'multiple context chips, time and energy edit, filter and settings preserve tasks',
    (tester) async {
      final root = await Directory.systemTemp.createTemp(
        'para-task-settings-ui-',
      );
      final repo = await LocalWorkspaceRepository.open(root);
      tester.view.physicalSize = const Size(1220, 850);
      tester.view.devicePixelRatio = 1;
      try {
        final definitions = await repo.getContexts();
        final work = definitions.firstWhere((e) => e.name == 'Arbeit');
        final home = definitions.firstWhere((e) => e.name == 'Zuhause');
        final computer = await repo.saveContext(
          name: 'Computer',
          color: contextColors[1],
        );
        final project = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Portfolio veröffentlichen',
            goal: 'Portfolio online',
            dueDate: DateTime(2026, 12, 1),
          ),
        );
        final task = await repo.create(
          kind: EntryKind.task,
          parentId: project.id,
          draft: EntryDraft(
            title: 'Startseite überarbeiten',
            taskState: TaskState.next,
            contextIds: [computer.id, work.id],
            estimatedMinutes: 30,
            energy: EnergyLevel.medium,
          ),
        );
        await repo.create(
          kind: EntryKind.task,
          draft: EntryDraft(
            title: 'Unterlagen sortieren',
            taskState: TaskState.next,
            contextIds: [home.id],
            estimatedMinutes: 15,
            energy: EnergyLevel.low,
          ),
        );
        await repo.create(
          kind: EntryKind.task,
          draft: const EntryDraft(
            title: 'Noch ohne Angaben',
            taskState: TaskState.next,
          ),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            child: ParaApp(repository: repo, dataDirectory: root.path),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-tasks')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('task-nav-actions')));
        await tester.pumpAndSettle();
        final row = find.byKey(ValueKey('task-row-${task.id}'));
        for (final text in ['Computer', 'Arbeit', '30 Min', 'Mittel']) {
          expect(
            find.descendant(of: row, matching: find.text(text)),
            findsOneWidget,
          );
        }
        await captureSurface(tester, 'para-0.6-task-chips');
        await tester.tap(find.text('Startseite überarbeiten'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('task-contexts')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('context-choice-${home.id}')));
        await tester.tap(find.byKey(const ValueKey('apply-contexts')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('duration-30')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15 Min').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('energy-medium')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Niedrig').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('editor-save')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Aufgabe schließen'));
        await tester.pumpAndSettle();
        final saved = (await repo.getEntries()).firstWhere(
          (e) => e.id == task.id,
        );
        expect(saved.contextIds.toSet(), {work.id, home.id, computer.id});
        expect(saved.estimatedMinutes, 15);
        expect(saved.energy, EnergyLevel.low);
        await tester.tap(find.byKey(const ValueKey('task-filter')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('task-contexts')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('context-choice-${computer.id}')));
        await tester.tap(find.byKey(ValueKey('context-choice-${work.id}')));
        await tester.tap(find.byKey(const ValueKey('apply-contexts')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(
            SwitchListTile,
            'Alle gewählten Kontexte erforderlich',
          ),
        );
        await tester.tap(
          find.widgetWithText(SwitchListTile, 'Ohne Angaben einbeziehen'),
        );
        await tester.tap(find.byKey(const ValueKey('apply-task-filter')));
        await tester.pumpAndSettle();
        expect(find.text('Startseite überarbeiten'), findsOneWidget);
        expect(find.text('Unterlagen sortieren'), findsNothing);
        expect(find.text('Noch ohne Angaben'), findsNothing);
        expect(find.textContaining('1 von 3 Aufgaben'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Zurücksetzen'));
        await tester.pumpAndSettle();
        await _settings(tester, contexts: true);
        await tester.tap(
          find.byKey(ValueKey('settings-context-${computer.id}')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('context-name')),
          'Laptop',
        );
        await tester.tap(
          find.byKey(ValueKey('context-color-${contextColors[3]}')),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
        await tester.pumpAndSettle();
        final workRow = find.byKey(ValueKey('settings-context-${work.id}'));
        await tester.tap(
          find.descendant(of: workRow, matching: find.byType(Switch)),
        );
        await tester.pumpAndSettle();
        await captureSurface(tester, 'para-0.6-context-settings');
        await tester.tap(find.widgetWithText(TextButton, 'Schließen'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: row, matching: find.text('Laptop')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: row, matching: find.text('Arbeit')),
          findsOneWidget,
        );
        expect(
          (await repo.getContexts()).firstWhere((e) => e.id == work.id).active,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close().timeout(const Duration(seconds: 5));
        await root.delete(recursive: true);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );

  testWidgets(
    'workspace settings copy and open complete sessions and persist selected root across restart',
    (tester) async {
      final base = await Directory.systemTemp.createTemp(
        'para-workspace-settings-ui-',
      );
      final access = ScriptedDirectoryAccess();
      WorkspaceManager makeManager() => WorkspaceManager(
        configurationDirectory: Directory(p.join(base.path, 'config')),
        defaultRoot: Directory(p.join(base.path, 'original')),
        access: access,
      );
      var manager = makeManager();
      tester.view.physicalSize = const Size(1220, 850);
      tester.view.devicePixelRatio = 1;
      try {
        await manager.initialize();
        final original = manager.repository!.root;
        final definition = await manager.repository!.saveContext(
          name: 'Computer',
          color: contextColors.first,
        );
        await manager.repository!.create(
          kind: EntryKind.task,
          draft: EntryDraft(
            title: 'Review vorbereiten',
            taskState: TaskState.next,
            contextIds: [definition.id],
            estimatedMinutes: 30,
            energy: EnergyLevel.medium,
          ),
        );
        await tester.pumpWidget(
          RepaintBoundary(child: WorkspaceHost(manager: manager)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-tasks')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('task-nav-actions')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('rail-expand')));
        await tester.pumpAndSettle();
        final copy = await Directory(p.join(base.path, 'copy')).create();
        access.selected = WorkspaceLocation(copy.path);
        await _settings(tester);
        await captureSurface(tester, 'para-0.6-workspace-settings');
        await tester.tap(find.byKey(const ValueKey('copy-workspace')));
        await tester.pumpAndSettle();
        expect(
          find.text('Arbeitsbereich kopieren und öffnen?'),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('confirm-workspace-change')),
        );
        await tester.pumpAndSettle();
        expect(
          manager.repository!.root.path,
          await copy.resolveSymbolicLinks(),
        );
        expect(find.text('Review vorbereiten'), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('navigation-rail'))).width,
          164,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await manager.close();
        manager.dispose();
        manager = makeManager();
        await tester.pumpWidget(
          RepaintBoundary(child: WorkspaceHost(manager: manager)),
        );
        await tester.pumpAndSettle();
        expect(
          manager.repository!.root.path,
          await copy.resolveSymbolicLinks(),
        );
        expect(find.text('Review vorbereiten'), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('navigation-rail'))).width,
          164,
        );
        await manager.repository!.saveContext(
          id: definition.id,
          name: 'Nur in Kopie',
          color: contextColors[1],
        );
        await tester.pumpAndSettle();
        access.selected = WorkspaceLocation(original.path);
        await _settings(tester);
        await tester.tap(find.byKey(const ValueKey('open-workspace')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('confirm-workspace-change')),
        );
        await tester.pumpAndSettle();
        expect(manager.repository!.root.path, original.path);
        expect(find.text('Computer'), findsOneWidget);
        expect(find.text('Nur in Kopie'), findsNothing);
        final fresh = await Directory(p.join(base.path, 'fresh')).create();
        access.selected = WorkspaceLocation(fresh.path);
        await _settings(tester);
        await tester.tap(find.byKey(const ValueKey('create-workspace')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('confirm-workspace-change')),
        );
        await tester.pumpAndSettle();
        expect(await manager.repository!.getEntries(), isEmpty);
        expect(find.text('Review vorbereiten'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await manager.close();
        manager.dispose();
        await fresh.rename('${fresh.path}-unavailable');
        manager = makeManager();
        await tester.pumpWidget(WorkspaceHost(manager: manager));
        await tester.pumpAndSettle();
        expect(find.text('Arbeitsbereich nicht verfügbar'), findsOneWidget);
        expect(await fresh.exists(), isFalse);
        access.selected = WorkspaceLocation(original.path);
        await tester.tap(
          find.widgetWithText(FilledButton, 'Arbeitsbereich auswählen …'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Review vorbereiten'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await manager.close();
        manager.dispose();
        await base.delete(recursive: true);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );

  testWidgets(
    'native directory channel handles an app-container path and rejects invalid bookmark data',
    (tester) async {
      final root = await Directory.systemTemp.createTemp(
        'para-directory-bridge-',
      );
      try {
        final value = await NativeWorkspaceDirectoryAccess.channel
            .invokeMapMethod<String, dynamic>('bookmarkDirectory', {
              'path': root.path,
            });
        expect(value!['path'], root.path);
        final selected = WorkspaceLocation(
          value['path'] as String,
          bookmark: value['bookmark'] as String?,
        );
        final restored = await NativeWorkspaceDirectoryAccess().restore(
          selected,
        );
        expect(restored.path, root.path);
        await expectLater(
          NativeWorkspaceDirectoryAccess.channel.invokeMethod(
            'resolveDirectory',
            {'bookmark': 'invalid'},
          ),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'workspace-directory',
            ),
          ),
        );
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}
