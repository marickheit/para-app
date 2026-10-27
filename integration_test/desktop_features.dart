import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/domain/archive.dart';

Future<void> nativeDropFiles(
  WidgetTester tester,
  Offset position,
  List<String> paths,
) async {
  Future<void> send(String method, Object arguments) async {
    final done = Completer<void>();
    tester.binding.channelBuffers.push(
      'desktop_drop',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) => done.complete(),
    );
    await done.future;
  }

  await send('entered', [position.dx, position.dy]);
  await tester.pump();
  await send('performOperation', paths);
  await tester.pumpAndSettle();
}

Future<void> dragSurfaceEntry(
  WidgetTester tester,
  Finder source,
  Finder target,
) async {
  final start = tester.getCenter(source), end = tester.getCenter(target);
  final gesture = await tester.startGesture(
    start,
    kind: PointerDeviceKind.mouse,
  );
  for (var i = 1; i <= 12; i++) {
    await gesture.moveTo(Offset.lerp(start, end, i / 12)!);
    await tester.pump(const Duration(milliseconds: 20));
  }
  await gesture.moveTo(end);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void registerDesktopFeatureTests() {
  testWidgets(
    'native drop imports once, shared menus and file/folder moves preserve identity',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp('para-drop-'),
          repo = await LocalWorkspaceRepository.open(
            await Directory.systemTemp.createTemp('para-drop-data-'),
          );
      try {
        final project = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Zielprojekt',
            goal: 'Ein Ergebnis',
            dueDate: DateTime(2026, 12, 31),
          ),
        );
        final folder = await repo.create(
          kind: EntryKind.folder,
          parentId: project.id,
          draft: const EntryDraft(title: 'Unterlagen'),
        );
        final md = File('${directory.path}/Dropnotiz.md'),
            binary = File('${directory.path}/Datei.bin');
        await md.writeAsString('# Dropnotiz\n\nEin importierter Gedanke.');
        await binary.writeAsBytes([1, 2, 3, 4]);
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: repo.root.path),
        );
        await tester.pumpAndSettle();
        await nativeDropFiles(
          tester,
          tester.getCenter(find.byKey(const ValueKey('nav-inbox'))),
          [md.path, binary.path],
        );
        var entries = await repo.getEntries();
        expect(entries.where((e) => e.title == 'Dropnotiz'), hasLength(1));
        final imported = entries.singleWhere((e) => e.kind == EntryKind.file);
        final row = find.byKey(ValueKey('tree-entry-${imported.id}'));
        await tester.tapAt(
          tester.getCenter(row),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        final right = tester
            .widgetList<PopupMenuItem<String>>(
              find.byType(PopupMenuItem<String>),
            )
            .map((e) => e.value)
            .toList();
        await tester.tapAt(const Offset(600, 30));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: row,
            matching: find.byType(PopupMenuButton<String>),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<PopupMenuItem<String>>(
                find.byType(PopupMenuItem<String>),
              )
              .map((e) => e.value)
              .toList(),
          right,
        );
        expect(right, containsAll(['copy', 'move', 'archive']));
        await tester.tap(find.text('Verschieben …'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, 'Zielprojekt'));
        await tester.pumpAndSettle();
        expect(
          (await repo.getEntries())
              .singleWhere((e) => e.id == imported.id)
              .parentId,
          project.id,
        );
        final destination = find.byKey(ValueKey('tree-entry-${folder.id}'));
        await dragSurfaceEntry(tester, row, destination);
        expect(
          (await repo.getEntries())
              .singleWhere((e) => e.id == imported.id)
              .parentId,
          folder.id,
        );
        await tester.tap(destination);
        await tester.pumpAndSettle();
        final nested = File('${directory.path}/Projektdatei.md');
        await nested.writeAsString('# Projektdatei\n\nIm Unterordner.');
        await nativeDropFiles(tester, tester.getCenter(destination), [
          nested.path,
        ]);
        entries = await repo.getEntries();
        final note = entries.singleWhere((e) => e.title == 'Projektdatei');
        expect(note.parentId, folder.id);
        expect(find.byKey(ValueKey('tree-entry-${note.id}')), findsOneWidget);
        expect(find.text('Im Unterordner.'), findsOneWidget);
        await dragSurfaceEntry(
          tester,
          destination,
          find.byKey(const ValueKey('nav-areas')),
        );
        entries = await repo.getEntries();
        expect(
          entries.singleWhere((e) => e.id == folder.id).section,
          ParaSection.areas,
        );
        expect(
          entries.singleWhere((e) => e.id == note.id).section,
          ParaSection.areas,
        );
        expect(await binary.readAsBytes(), [1, 2, 3, 4]);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        await repo.root.delete(recursive: true);
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'Someday retains context actions and converts ideas without losing their body',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp('para-idea-'),
          repo = await LocalWorkspaceRepository.open(
            await Directory.systemTemp.createTemp('para-idea-data-'),
          );
      try {
        final idea = await repo.create(
          kind: EntryKind.idea,
          draft: const EntryDraft(
            title: 'Dateien organisieren',
            body: 'Bestehende Gedanken.',
          ),
        );
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: repo.root.path),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-tasks')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('task-nav-someday')));
        await tester.pumpAndSettle();
        final row = find.byKey(ValueKey('task-row-${idea.id}'));
        await tester.tapAt(
          tester.getCenter(row),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('In Projekt umwandeln …'));
        await tester.pumpAndSettle();
        final fields = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(
          fields.at(1),
          'Dateien sind zuverlässig erreichbar',
        );
        await tester.tap(find.text('Fälligkeitsdatum wählen *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Umwandeln'));
        await tester.pumpAndSettle();
        final project = (await repo.getEntries()).singleWhere(
          (e) => e.id == idea.id,
        );
        expect(project.kind, EntryKind.project);
        expect(project.dueDate, isNotNull);
        expect((await repo.readNote(project.id)).text, 'Bestehende Gedanken.');
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey('tree-entry-${project.id}')),
            matching: find.byType(PopupMenuButton<String>),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beschreibung bearbeiten'));
        await tester.pumpAndSettle();
        expect(find.text('Bestehende Gedanken.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        await repo.root.delete(recursive: true);
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'archive tree keeps provenance and restores individual descendants',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
            'para-archive-ui-',
          ),
          repo = await LocalWorkspaceRepository.open(
            await Directory.systemTemp.createTemp('para-archive-data-'),
            now: () => DateTime(2025, 8, 1),
          );
      try {
        final project = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Altprojekt',
            goal: 'Abgeschlossen',
            dueDate: DateTime(2025, 9, 1),
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
            title: 'Referenz',
            body: 'Wichtige Referenz.',
          ),
        );
        final resource = await repo.create(
          kind: EntryKind.resource,
          draft: const EntryDraft(title: 'Wissen'),
        );
        final target = await repo.create(
          kind: EntryKind.folder,
          parentId: resource.id,
          draft: const EntryDraft(title: 'Aktiver Ordner'),
        );
        await repo.completeProject(project.id);
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: repo.root.path),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-archive')));
        await tester.pumpAndSettle();
        String? key(List<ArchiveNode> nodes) {
          for (final n in nodes) {
            if (n.entry?.id == note.id) return n.key;
            final found = key(n.children);
            if (found != null) return found;
          }
          return null;
        }

        final row = find.byKey(
          ValueKey(
            'archive-node-${key(buildArchiveTree(await repo.getEntries()))}',
          ),
        );
        expect(row, findsOneWidget);
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(find.text('Wichtige Referenz.'), findsOneWidget);
        expect(find.byKey(const ValueKey('editor-save')), findsNothing);
        expect(
          find.byKey(const ValueKey('markdown-table-insert')),
          findsNothing,
        );
        await tester.tapAt(
          tester.getCenter(row),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Wiederherstellen'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, 'Aktiver Ordner'));
        await tester.pumpAndSettle();
        final restored = (await repo.getEntries()).singleWhere(
          (e) => e.id == note.id,
        );
        expect(restored.parentId, target.id);
        expect(isArchived(restored, await repo.getEntries()), isFalse);
        expect((await repo.readNote(note.id)).text, 'Wichtige Referenz.');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        await repo.root.delete(recursive: true);
        await directory.delete(recursive: true);
      }
    },
  );
}
