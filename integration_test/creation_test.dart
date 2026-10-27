import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/domain/archive.dart';
import 'package:para_workspace/ui/workspace_style.dart';
import 'target_features.dart' show captureSurface;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerCreationTests();
}

void registerCreationTests() {
  late Directory temp;
  late LocalWorkspaceRepository repo;
  late Entry area, resource, project, folder, note;
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pumpAndSettle();
    }
  }

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 850);
    tester.view.devicePixelRatio = 1;
    await (() async {
      temp = await Directory.systemTemp.createTemp('para-creation-');
      repo = await LocalWorkspaceRepository.open(temp);
      area = await repo.create(
        kind: EntryKind.area,
        draft: const EntryDraft(title: 'Gesundheit', body: 'Mein Bereichstext'),
      );
      resource = await repo.create(
        kind: EntryKind.resource,
        draft: const EntryDraft(title: 'Wissen', body: 'Meine Sammlung'),
      );
      project = await repo.create(
        kind: EntryKind.project,
        draft: EntryDraft(
          title: 'Umzug',
          body: 'Projektbeschreibung',
          goal: 'Wohnung bezogen',
          dueDate: DateTime(2027, 1, 15),
        ),
      );
      folder = await repo.create(
        kind: EntryKind.folder,
        parentId: area.id,
        draft: const EntryDraft(title: 'Unterlagen'),
      );
      note = await repo.create(
        kind: EntryKind.note,
        parentId: folder.id,
        draft: const EntryDraft(title: 'Befund', body: 'Gespeicherter Text'),
      );
      await repo.create(
        kind: EntryKind.task,
        parentId: project.id,
        draft: const EntryDraft(
          title: 'Kartons bestellen',
          taskState: TaskState.next,
        ),
      );
    })();
    await tester.pumpWidget(
      ParaApp(repository: repo, dataDirectory: temp.path),
    );
    await settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await (() async {
      await repo.close();
      await temp.delete(recursive: true);
    })();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  Finder tree(Entry e) => find.byKey(ValueKey('tree-entry-${e.id}'));
  Finder nav(String name) => find.byKey(ValueKey('nav-$name'));
  Finder toggle(Entry e) => find.byKey(ValueKey('tree-toggle-${e.id}'));
  Future<void> expand(WidgetTester tester, Entry entry) async {
    if (tester.widget<IconButton>(toggle(entry)).tooltip == 'Aufklappen') {
      await tap(tester, toggle(entry));
    }
  }

  Future<void> shortcut(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  Future<void> createNamed(WidgetTester tester, String title) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Titel'), title);
    await tap(tester, find.widgetWithText(FilledButton, 'Anlegen'));
  }

  testWidgets(
    'container selection and disclosure are independent for all root kinds',
    (tester) async {
      await start(tester);
      try {
        await tap(tester, nav('areas'));
        expect(find.byKey(ValueKey('overview-${area.id}')), findsNothing);
        await shortcut(tester);
        expect(
          find.widgetWithText(SimpleDialogOption, 'Bereich anlegen'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SimpleDialogOption, 'Notiz anlegen'),
          findsNothing,
        );
        await tap(tester, find.text('Bereich anlegen').last);
        expect(find.text('Ablage: Bereiche'), findsOneWidget);
        await tap(tester, find.text('Abbrechen'));
        await tap(tester, tree(area));
        expect(find.byKey(ValueKey('overview-${area.id}')), findsOneWidget);
        expect(find.text('Mein Bereichstext'), findsOneWidget);
        expect(tree(folder), findsNothing);
        expect(tester.widget<IconButton>(toggle(area)).tooltip, 'Aufklappen');
        final container = tester.widget<Container>(tree(area));
        final color = (container.decoration! as BoxDecoration).color;
        expect(color, WorkspaceColors(tester.element(tree(area))).selection);
        await tap(tester, tree(area));
        expect(find.byKey(ValueKey('overview-${area.id}')), findsNothing);
        expect(find.text('Keine Ablage ausgewählt'), findsOneWidget);
        expect(find.byKey(ValueKey('tree-entry-${folder.id}')), findsNothing);
        // The arrow opens the tree without selecting its container.
        await tap(tester, toggle(area));
        expect(tree(folder), findsOneWidget);
        expect(find.byKey(ValueKey('overview-${area.id}')), findsNothing);
        await tap(tester, tree(area));
        expect(find.byKey(ValueKey('overview-${area.id}')), findsOneWidget);
        expect(tree(folder), findsOneWidget);
        await tap(tester, toggle(area));
        expect(tree(folder), findsNothing);
        expect(find.byKey(ValueKey('overview-${area.id}')), findsOneWidget);
        for (final item in [('projects', project), ('resources', resource)]) {
          await tap(tester, nav(item.$1));
          await tap(tester, tree(item.$2));
          expect(
            tester.widget<IconButton>(toggle(item.$2)).tooltip,
            'Aufklappen',
          );
          await tap(tester, toggle(item.$2));
          expect(
            find.byKey(ValueKey('overview-${item.$2.id}')),
            findsOneWidget,
          );
          await tap(tester, tree(item.$2));
          expect(
            tester.widget<IconButton>(toggle(item.$2)).tooltip,
            'Zuklappen',
          );
          expect(find.byKey(ValueKey('overview-${item.$2.id}')), findsNothing);
        }
      } finally {
        await finish(tester);
      }
    },
  );

  testWidgets(
    'second area and resource can be created while a container is selected',
    (tester) async {
      await start(tester);
      try {
        for (final item in [
          (
            'areas',
            area,
            'Weiteren Bereich anlegen …',
            'Zweiter Bereich',
            EntryKind.area,
          ),
          (
            'resources',
            resource,
            'Weitere Ressourcensammlung anlegen …',
            'Zweites Wissen',
            EntryKind.resource,
          ),
        ]) {
          await tap(tester, nav(item.$1));
          await tap(tester, tree(item.$2));
          await shortcut(tester);
          expect(find.text('Notiz anlegen'), findsOneWidget);
          await tap(tester, find.text(item.$3));
          await createNamed(tester, item.$4);
          final entries = await repo.getEntries();
          final created = entries.singleWhere((e) => e.title == item.$4);
          expect(created.kind, item.$5);
          expect(created.parentId, isNull);
          expect(
            find.byKey(ValueKey('overview-${created.id}')),
            findsOneWidget,
          );
        }
      } finally {
        await finish(tester);
      }
    },
  );

  testWidgets(
    'folder selection, disclosure and file parent targets remain independent',
    (tester) async {
      await start(tester);
      try {
        await tap(tester, nav('areas'));
        await tap(tester, tree(area));
        await expand(tester, area);
        await tap(tester, tree(folder));
        expect(
          find.text('Neu in: Bereiche / Gesundheit / Unterlagen'),
          findsOneWidget,
        );
        await tap(tester, toggle(folder));
        expect(tree(note), findsNothing);
        expect(
          find.text('Neu in: Bereiche / Gesundheit / Unterlagen'),
          findsOneWidget,
        );
        await tap(tester, tree(folder));
        expect(tree(note), findsNothing);
        expect(find.byKey(ValueKey('overview-${area.id}')), findsOneWidget);
        await tap(tester, tree(folder));
        expect(tree(note), findsNothing);
        await tap(tester, toggle(folder));
        expect(
          find.text('Neu in: Bereiche / Gesundheit / Unterlagen'),
          findsOneWidget,
        );
        await tap(tester, tree(note));
        await shortcut(tester);
        await tap(tester, find.text('Notiz anlegen'));
        expect(
          find.text('Ablage: Bereiche / Gesundheit / Unterlagen'),
          findsOneWidget,
        );
        await createNamed(tester, 'Nachbar');
        final entries = await repo.getEntries();
        expect(
          entries.singleWhere((e) => e.title == 'Nachbar').parentId,
          folder.id,
        );
        await tap(tester, tree(folder));
        await tap(tester, tree(folder));
        expect(find.byKey(ValueKey('overview-${area.id}')), findsOneWidget);
        expect(find.text('Neu in: Bereiche / Gesundheit'), findsOneWidget);
      } finally {
        await finish(tester);
      }
    },
  );

  testWidgets(
    'explicit context target and change to section root override current selection',
    (tester) async {
      await start(tester);
      try {
        await tap(tester, nav('areas'));
        await tap(tester, tree(area));
        await expand(tester, area);
        await tap(tester, tree(folder));
        final menu = find.descendant(
          of: tree(area),
          matching: find.byTooltip('Aktionen für Gesundheit'),
        );
        await tap(tester, menu);
        await tap(tester, find.text('Neue Notiz …'));
        expect(find.text('Ablage: Bereiche / Gesundheit'), findsOneWidget);
        await tap(tester, find.text('Ablage ändern …'));
        await tap(tester, find.widgetWithText(ListTile, 'Bereiche'));
        expect(find.text('Ablage: Bereiche'), findsOneWidget);
        await createNamed(tester, 'Freie Wurzelnotiz');
        final entries = await repo.getEntries();
        final created = entries.singleWhere(
          (e) => e.title == 'Freie Wurzelnotiz',
        );
        expect(created.parentId, isNull);
        expect(created.section, ParaSection.areas);
      } finally {
        await finish(tester);
      }
    },
  );

  testWidgets(
    'project overview shows description, result, next actions and top-level creation',
    (tester) async {
      await start(tester);
      try {
        await tap(tester, nav('projects'));
        await tap(tester, tree(project));
        await captureSurface(tester, 'para-073-project-overview');
        // The capture helper deliberately removes keyboard focus. Restore it
        // before testing the shortcut.
        await tap(tester, find.widgetWithText(TextButton, 'Übersicht'));
        expect(find.text('Projektbeschreibung'), findsOneWidget);
        expect(find.text('Wohnung bezogen'), findsOneWidget);
        expect(find.text('Kartons bestellen'), findsOneWidget);
        await shortcut(tester);
        await tap(tester, find.text('Weiteres Projekt anlegen …'));
        expect(find.text('Ablage: Projekte'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Titel'),
          'Zweites Projekt',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Gewünschtes Ergebnis'),
          'Ergebnis',
        );
        await tap(tester, find.widgetWithText(FilledButton, 'Anlegen'));
        expect(
          find.text('Ein Projekt braucht ein Fälligkeitsdatum.'),
          findsOneWidget,
        );
        await tap(tester, find.text('Fälligkeitsdatum wählen *'));
        await tap(tester, find.text('OK'));
        await tap(tester, find.widgetWithText(FilledButton, 'Anlegen'));
        final created = (await repo.getEntries()).singleWhere(
          (e) => e.title == 'Zweites Projekt',
        );
        expect(created.parentId, isNull);
        expect(created.kind, EntryKind.project);
        expect(created.dueDate, isNotNull);
        await tap(tester, find.byTooltip('Zur Kategorieübersicht'));
        await shortcut(tester);
        expect(find.text('Projekt anlegen'), findsOneWidget);
        expect(find.text('Notiz anlegen'), findsNothing);
      } finally {
        await finish(tester);
      }
    },
  );

  testWidgets(
    'deselect protects unsaved text and archive/trash block keyboard creation',
    (tester) async {
      await start(tester);
      try {
        await tap(tester, nav('areas'));
        await tap(tester, tree(area));
        await expand(tester, area);
        await tap(tester, tree(folder));
        await tap(tester, tree(note));
        await tap(tester, find.byKey(const ValueKey('markdown-mode-raw')));
        await tester.enterText(
          find.byKey(const ValueKey('markdown-body')),
          'Offener Entwurf',
        );
        await tap(tester, toggle(area));
        expect(tree(note), findsNothing);
        expect(find.text('Offener Entwurf'), findsOneWidget);
        expect(find.text('Änderungen speichern?'), findsNothing);
        await tap(tester, toggle(area));
        expect(tree(note), findsOneWidget);
        expect(find.text('Offener Entwurf'), findsOneWidget);
        await tap(tester, tree(area));
        expect(find.text('Änderungen speichern?'), findsOneWidget);
        await tap(tester, find.text('Abbrechen'));
        expect(find.text('Offener Entwurf'), findsOneWidget);
        await tap(tester, nav('archive'));
        await tap(tester, find.text('Verwerfen'));
        await shortcut(tester);
        expect(find.byType(SimpleDialog), findsNothing);
        await tap(tester, nav('trash'));
        await shortcut(tester);
        expect(find.byType(SimpleDialog), findsNothing);
        expect((await repo.readNote(note.id)).text, 'Gespeicherter Text');
        await repo.archive(area.id, true);
        await settle(tester);
        await tap(tester, nav('archive'));
        String? keyFor(List<ArchiveNode> nodes, String id) {
          for (final node in nodes) {
            if (node.entry?.id == id) return node.key;
            final found = keyFor(node.children, id);
            if (found != null) return found;
          }
          return null;
        }

        final archive = buildArchiveTree(await repo.getEntries());
        final areaKey = keyFor(archive, area.id)!;
        final folderKey = keyFor(archive, folder.id)!;
        final archivedArea = find.byKey(ValueKey('archive-node-$areaKey'));
        final archivedFolder = find.byKey(ValueKey('archive-node-$folderKey'));
        final archiveToggle = find.byKey(ValueKey('archive-toggle-$areaKey'));
        await tap(tester, archivedArea);
        expect(archivedFolder, findsOneWidget);
        await tap(tester, archiveToggle);
        expect(archivedFolder, findsNothing);
        await tap(tester, archivedArea);
        expect(archivedFolder, findsNothing);
        await tap(tester, archiveToggle);
        expect(archivedFolder, findsOneWidget);
        final trashChild = await repo.create(
          kind: EntryKind.note,
          parentId: resource.id,
          draft: const EntryDraft(title: 'Entfernte Unterlage'),
        );
        await repo.trash(resource.id);
        await settle(tester);
        await tap(tester, nav('trash'));
        final trashRoot = find.byKey(ValueKey('trash-entry-${resource.id}'));
        final childRow = find.byKey(ValueKey('trash-entry-${trashChild.id}'));
        final trashToggle = find.byKey(ValueKey('trash-toggle-${resource.id}'));
        await tap(tester, trashRoot);
        expect(childRow, findsOneWidget);
        await tap(tester, trashToggle);
        expect(childRow, findsNothing);
        await tap(tester, trashRoot);
        expect(childRow, findsNothing);
        await tap(tester, trashToggle);
        expect(childRow, findsOneWidget);
      } finally {
        await finish(tester);
      }
    },
  );
  testWidgets(
    'TXT creation changes explicit root destination and imports show full target',
    (tester) async {
      await start(tester);
      try {
        await tap(tester, nav('areas'));
        await tap(tester, tree(area));
        await expand(tester, area);
        await tap(tester, tree(folder));
        await shortcut(tester);
        await tap(tester, find.text('Neue Textdatei …'));
        expect(
          find.text('Ablage: Bereiche / Gesundheit / Unterlagen'),
          findsOneWidget,
        );
        await tap(tester, find.text('Ablage ändern …'));
        await tap(tester, find.widgetWithText(ListTile, 'Bereiche'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Name'),
          'Root.txt',
        );
        await tap(tester, find.widgetWithText(FilledButton, 'Speichern'));
        final created = (await repo.getEntries()).singleWhere(
          (e) => e.title == 'Root.txt',
        );
        expect(created.parentId, isNull);
        expect(created.section, ParaSection.areas);
        // Leave the untouched TXT editor before changing the selection.
        await tap(tester, tree(area));
        await tap(tester, find.byTooltip('Neuen Inhalt anlegen'));
        await tap(tester, find.text('Dateien hinzufügen …'));
        expect(find.text('Ablage: Bereiche / Gesundheit'), findsOneWidget);
        await tap(tester, find.text('Abbrechen'));
      } finally {
        await finish(tester);
      }
    },
  );

  testWidgets(
    'task creation follows view status and new tasks remain visible despite filters',
    (tester) async {
      await start(tester);
      try {
        await tap(tester, nav('projects'));
        await tap(tester, tree(project));
        await tap(tester, find.widgetWithText(TextButton, 'Aufgaben'));
        await tap(tester, find.byKey(const ValueKey('task-filter')));
        await tap(tester, find.byKey(const ValueKey('duration-null')));
        await tap(tester, find.text('15 Min').last);
        await tap(
          tester,
          find.widgetWithText(SwitchListTile, 'Ohne Angaben einbeziehen'),
        );
        await tap(tester, find.byKey(const ValueKey('apply-task-filter')));
        expect(find.text('Kartons bestellen'), findsNothing);
        await shortcut(tester);
        await tap(tester, find.text('Aufgabe anlegen'));
        await createNamed(tester, 'Neue Projektaktion');
        final created = (await repo.getEntries()).singleWhere(
          (e) => e.title == 'Neue Projektaktion',
        );
        expect(created.parentId, project.id);
        expect(created.taskState, TaskState.next);
        expect(find.byKey(ValueKey('task-row-${created.id}')), findsOneWidget);
        for (final state in [TaskState.waiting, TaskState.someday]) {
          await tap(tester, nav('tasks'));
          await tap(tester, find.byKey(ValueKey('task-nav-${state.name}')));
          await shortcut(tester);
          await tap(
            tester,
            find.widgetWithText(SimpleDialogOption, 'Aufgabe anlegen'),
          );
          await createNamed(tester, 'Neu ${state.name}');
          final task = (await repo.getEntries()).singleWhere(
            (e) => e.title == 'Neu ${state.name}',
          );
          expect(task.parentId, isNull);
          expect(task.section, ParaSection.inbox);
          expect(task.taskState, state);
        }
        await tap(tester, nav('tasks'));
        for (final view in ['done', 'cancelled']) {
          await tap(tester, find.byKey(ValueKey('task-nav-$view')));
          await shortcut(tester);
          expect(find.byType(SimpleDialog), findsNothing);
        }
      } finally {
        await finish(tester);
      }
    },
  );

  testWidgets(
    'saved folder selection restores the same visible creation target',
    (tester) async {
      await start(tester);
      try {
        await tap(tester, nav('areas'));
        await tap(tester, tree(area));
        await expand(tester, area);
        await tap(tester, tree(folder));
        await tap(tester, toggle(area));
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        repo = await LocalWorkspaceRepository.open(temp);
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: temp.path),
        );
        await settle(tester);
        expect(tree(folder), findsNothing);
        expect(tester.widget<IconButton>(toggle(area)).tooltip, 'Aufklappen');
        expect(
          find.text('Neu in: Bereiche / Gesundheit / Unterlagen'),
          findsOneWidget,
        );
        await shortcut(tester);
        await tap(tester, find.text('Notiz anlegen'));
        await createNamed(tester, 'Nach Neustart');
        expect(
          (await repo.getEntries())
              .singleWhere((e) => e.title == 'Nach Neustart')
              .parentId,
          folder.id,
        );
      } finally {
        await finish(tester);
      }
    },
  );
  testWidgets(
    'top-level folders retain their own task list and creation target',
    (tester) async {
      await start(tester);
      try {
        final rootFolder = await repo.create(
          kind: EntryKind.folder,
          draft: const EntryDraft(title: 'Inboxordner'),
        );
        await settle(tester);
        await tap(tester, tree(rootFolder));
        await shortcut(tester);
        await tap(tester, find.text('Aufgabe anlegen'));
        await createNamed(tester, 'Ordneraktion');
        final created = (await repo.getEntries()).singleWhere(
          (e) => e.title == 'Ordneraktion',
        );
        expect(created.parentId, rootFolder.id);
        await tap(tester, find.widgetWithText(TextButton, 'Aufgaben'));
        expect(find.byKey(ValueKey('task-row-${created.id}')), findsOneWidget);
        expect(find.text('Neu in: Inbox / Inboxordner'), findsOneWidget);
      } finally {
        await finish(tester);
      }
    },
  );
}
