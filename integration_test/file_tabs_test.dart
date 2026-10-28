import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/mcp_editor_guard.dart';
import 'package:para_workspace/ui/entry_editor.dart';
import 'target_features.dart' show captureSurface, samplePdf;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late LocalWorkspaceRepository repo;
  late Entry note, second, third, pdf, csv, svg, image, other;
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await tester.pumpAndSettle();
    }
  }

  Finder tree(Entry e) => find.byKey(ValueKey('tree-entry-${e.id}'));
  Finder tab(Entry e) => find.byKey(ValueKey('document-tab-${e.id}'));
  Future<void> tap(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.tap(finder);
    await settle(t);
  }

  Future<void> boot(WidgetTester t) async {
    await t.pumpWidget(
      ParaApp(repository: repo, dataDirectory: '${temp.path}/root'),
    );
    await settle(t);
  }

  Future<void> start(WidgetTester t, {String? legacy}) async {
    t.view.physicalSize = const Size(1440, 1000);
    t.view.devicePixelRatio = 1;
    temp = await Directory.systemTemp.createTemp('para-tabs-native-');
    repo = await LocalWorkspaceRepository.open(Directory('${temp.path}/root'));
    note = await repo.create(
      kind: EntryKind.note,
      draft: const EntryDraft(
        title: 'Gartenplanung',
        body: '# Garten\n\nEin ruhiger Garten.',
      ),
    );
    second = await repo.create(
      kind: EntryKind.note,
      draft: const EntryDraft(title: 'Pflanzliste', body: 'Stauden und Gräser'),
    );
    third = await repo.create(
      kind: EntryKind.note,
      draft: const EntryDraft(title: 'Budget', body: 'Budgettext'),
    );
    other = await repo.create(
      kind: EntryKind.note,
      section: ParaSection.resources,
      draft: const EntryDraft(title: 'Andere Ablage', body: 'Ressourcentext'),
    );
    pdf = await repo.importFile(
      name: 'Pflanzkonzept.pdf',
      bytes: Stream.value(samplePdf()),
    );
    csv = await repo.importFile(
      name: 'Kosten.csv',
      bytes: Stream.value(
        utf8.encode('Position,Menge,Preis\nStauden,12,55\nGräser,3,15'),
      ),
    );
    svg = await repo.importFile(
      name: 'Plan.svg',
      bytes: Stream.value(
        utf8.encode(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 200"><rect width="300" height="200" fill="#8ba37a"/></svg>',
        ),
      ),
    );
    image = await repo.importFile(
      name: 'Bild.png',
      bytes: Stream.value(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9N8AAAAASUVORK5CYII=',
        ),
      ),
    );
    if (legacy != null) {
      await repo.writeSetting(
        'session.v1',
        jsonEncode({
          'version': 1,
          'view': 'inbox',
          'selected': note.id,
          'filter': {},
        }),
      );
    }
    await boot(t);
  }

  Future<void> finish(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    await settle(t);
    await repo.close();
    await temp.delete(recursive: true);
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  }

  testWidgets(
    'tabs protect drafts, keep previews and survive resize and focus',
    (t) async {
      await start(t);
      try {
        await tap(t, tree(note));
        final editor = t.state<EntryEditorState>(find.byType(EntryEditor));
        await tap(t, find.byKey(const ValueKey('markdown-mode-raw')));
        final draft = List.generate(
          40,
          (i) => 'Zeile $i: Entwurf erhalten',
        ).join('\n');
        await t.enterText(find.byKey(const ValueKey('markdown-body')), draft);
        await settle(t);
        expect(McpEditorGuard.forRepository(repo).acquire(note.id), false);
        final field = t.widget<TextField>(
          find.byKey(const ValueKey('markdown-body')),
        );
        field.controller!.selection = const TextSelection.collapsed(offset: 12);
        final handle = find.byKey(const ValueKey('explorer-resize'));
        await t.drag(handle, const Offset(130, 0));
        await settle(t);
        expect(
          t.getSize(find.byKey(const ValueKey('explorer-sidebar'))).width,
          closeTo(400, 2),
        );
        await tap(t, find.byKey(const ValueKey('explorer-toggle')));
        expect(
          t.getSize(find.byKey(const ValueKey('navigation-rail'))).width,
          56,
        );
        expect(find.byKey(const ValueKey('explorer-resize')), findsNothing);
        await tap(t, find.byKey(const ValueKey('explorer-toggle')));
        expect(
          t.state<EntryEditorState>(find.byType(EntryEditor)),
          same(editor),
        );
        expect(field.controller!.text, draft);
        expect(field.controller!.selection.baseOffset, 12);
        await tap(t, tree(second));
        expect(find.text('Änderungen speichern?'), findsOneWidget);
        await tap(t, find.widgetWithText(TextButton, 'Abbrechen'));
        expect(tab(second), findsNothing);
        expect(field.controller!.text, draft);
        await tap(t, tree(second));
        await tap(t, find.widgetWithText(FilledButton, 'Speichern'));
        expect((await repo.readNote(note.id)).text, draft);
        expect(tab(note), findsOneWidget);
        expect(tab(second), findsOneWidget);
        await tap(t, tree(third));
        expect(tab(second), findsNothing);
        await tap(t, find.byTooltip('Offene Dateien'));
        await tap(t, find.text('Tab behalten'));
        await tap(t, tree(second));
        expect(tab(third), findsOneWidget);
        await tap(t, tab(note));
        expect(McpEditorGuard.forRepository(repo).acquire(note.id), true);
        McpEditorGuard.forRepository(repo).release(note.id);
        await captureSurface(t, 'para-tabs-native-editor');
        await tap(t, find.byKey(ValueKey('close-document-${second.id}')));
        await tap(t, find.byKey(ValueKey('close-document-${third.id}')));
        await tap(t, find.byKey(ValueKey('close-document-${note.id}')));
        expect(find.byType(EntryEditor), findsNothing);
      } finally {
        await finish(t);
      }
    },
  );

  testWidgets(
    'session v1 migrates with backup, persistent tabs and width restore',
    (t) async {
      await start(t, legacy: 'yes');
      try {
        expect(tab(note), findsOneWidget);
        expect(await repo.readSetting('session.v1'), isNotNull);
        expect(
          Directory('${temp.path}/root/.migration-backups').existsSync(),
          true,
        );
        await tap(t, tree(second));
        await t.drag(
          find.byKey(const ValueKey('explorer-resize')),
          const Offset(110, 0),
        );
        await settle(t);
        await tap(t, find.byKey(const ValueKey('explorer-toggle')));
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await settle(t);
        await t.pumpWidget(const SizedBox.shrink());
        await settle(t);
        await boot(t);
        expect(tab(note), findsOneWidget);
        expect(tab(second), findsNothing);
        await tap(t, find.byKey(const ValueKey('explorer-toggle')));
        expect(
          t.getSize(find.byKey(const ValueKey('explorer-sidebar'))).width,
          closeTo(380, 2),
        );
        t.view.physicalSize = const Size(800, 800);
        await settle(t);
        t.view.physicalSize = const Size(1440, 1000);
        await settle(t);
        expect(
          t.getSize(find.byKey(const ValueKey('explorer-sidebar'))).width,
          closeTo(380, 2),
        );
        expect(t.takeException(), isNull);
      } finally {
        await finish(t);
      }
    },
  );

  testWidgets('PDF SVG CSV and images use available preview area', (t) async {
    await start(t);
    try {
      await tap(t, tree(pdf));
      final editor = t.getRect(find.byType(EntryEditor));
      expect(editor.width, greaterThan(1000));
      expect(editor.height, greaterThan(750));
      await captureSurface(t, 'para-tabs-native-pdf');
      await tap(t, tree(svg));
      expect(t.takeException(), isNull);
      await tap(t, tree(csv));
      expect(find.text('Stauden'), findsOneWidget);
      await tap(t, tree(image));
      expect(t.takeException(), isNull);
      await tap(t, tree(note));
      await tap(t, find.byTooltip('Weitere Dateiaktionen'));
      await tap(t, find.text('Volle Breite'));
      await tap(t, find.byTooltip('Weitere Dateiaktionen'));
      expect(find.text('Lesebreite'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(t);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyO);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(t);
      expect(find.byType(Dialog), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(t);
    } finally {
      await finish(t);
    }
  });

  testWidgets('future session stays untouched while content remains usable', (
    t,
  ) async {
    await start(t);
    try {
      await t.pumpWidget(const SizedBox.shrink());
      await settle(t);
      await repo.writeSetting('session.v2', '{"version":99,"retain":"future"}');
      await boot(t);
      await tap(t, tree(note));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await settle(t);
      expect(
        await repo.readSetting('session.v2'),
        '{"version":99,"retain":"future"}',
      );
      expect((await repo.readNote(note.id)).text, contains('Garten'));
    } finally {
      await finish(t);
    }
  });
  testWidgets(
    'many tabs, category changes, renaming, archive and trash keep identity',
    (t) async {
      await start(t);
      try {
        final many = <Entry>[];
        for (var i = 0; i < 30; i++) {
          many.add(
            await repo.create(
              kind: EntryKind.note,
              draft: EntryDraft(title: 'Datei $i', body: 'Text $i'),
            ),
          );
        }
        await t.pumpWidget(const SizedBox.shrink());
        await settle(t);
        await repo.writeSetting(
          'session.v2',
          jsonEncode({
            'version': 2,
            'view': 'inbox',
            'selected': many.last.id,
            'documentTabs': many.map((e) => e.id).toList(),
            'explorerWidth': 350,
            'filter': {},
          }),
        );
        await boot(t);
        expect(find.byType(EntryEditor), findsOneWidget);
        await tap(t, find.byTooltip('Offene Dateien'));
        await tap(t, find.text('Datei 0.md · Inbox'));
        expect(tab(many.first), findsOneWidget);
        await tap(t, find.byKey(const ValueKey('nav-resources')));
        expect(find.byType(EntryEditor), findsNothing);
        await tap(t, tree(other));
        await tap(t, find.byTooltip('Offene Dateien'));
        await tap(t, find.text('Tab behalten'));
        final snap = await repo.readSnapshot(other.id);
        await repo.saveSnapshot(
          id: other.id,
          expectedRevision: snap.entry.revision,
          expectedBodyHash: snap.note.hash,
          draft: const EntryDraft(title: 'Umbenannt', body: 'Ressourcentext'),
        );
        await repo.move(other.id, ParaSection.inbox);
        await settle(t);
        expect(find.text('Umbenannt.md'), findsWidgets);
        await repo.archive(other.id, true);
        await settle(t);
        expect(find.text('Archiviert · schreibgeschützt'), findsOneWidget);
        await repo.trash(other.id);
        await settle(t);
        expect(find.text('Im Papierkorb · schreibgeschützt'), findsOneWidget);
        await repo.permanentlyDelete(other.id);
        await settle(t);
        expect(tab(other), findsNothing);
        expect(t.takeException(), isNull);
        t.view.physicalSize = const Size(600, 700);
        await settle(t);
        await tap(t, find.byKey(const ValueKey('sidebar-toggle')));
        expect(find.byType(Drawer), findsOneWidget);
        expect(t.takeException(), isNull);
      } finally {
        await finish(t);
      }
    },
  );
}
