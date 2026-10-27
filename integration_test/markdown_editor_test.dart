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
import 'target_features.dart' show captureSurface;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native compact editor saves live paragraphs, tasks and table changes',
    (t) async {
      final temp = await Directory.systemTemp.createTemp(
        'para-markdown-native-',
      );
      final repo = await LocalWorkspaceRepository.open(temp);
      t.view.physicalSize = const Size(1440, 1000);
      t.view.devicePixelRatio = 1;
      Future<void> settle() async {
        for (var i = 0; i < 3; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          await t.pumpAndSettle();
        }
      }

      Future<void> tap(Finder f) async {
        await t.ensureVisible(f);
        await t.tap(f);
        await settle();
      }

      try {
        final note = await repo.create(
          kind: EntryKind.note,
          draft: const EntryDraft(
            title: 'Editorprüfung',
            body:
                '# Besprechung\n\nErster Absatz\n\n- [ ] Rückmeldung einholen\n\n| Seite | Stand |\n| :--- | ---: |\n| Startseite | Offen |',
          ),
        );
        final second = await repo.create(
          kind: EntryKind.note,
          draft: const EntryDraft(title: 'Zweite Notiz', body: 'Anderer Text'),
        );
        await t.pumpWidget(
          RepaintBoundary(
            child: ParaApp(repository: repo, dataDirectory: temp.path),
          ),
        );
        await settle();
        await tap(find.byKey(ValueKey('tree-entry-${note.id}')));
        expect(
          find.byKey(const ValueKey('markdown-mode-live')),
          findsOneWidget,
        );
        final strip = t.getRect(find.byKey(const ValueKey('document-tabs')));
        expect(
          t.getRect(find.byKey(const ValueKey('markdown-mode-live'))).top,
          lessThan(strip.bottom),
        );
        expect(find.byKey(const ValueKey('entry-title')), findsNothing);
        final guard = McpEditorGuard.forRepository(repo);
        expect(guard.acquire(note.id), true);
        guard.release(note.id);
        expect(t.getSize(find.byType(Table)).width, lessThan(400));
        await captureSurface(t, 'para-markdown-live-0100');
        await tap(find.text('Erster Absatz'));
        await t.sendKeyEvent(LogicalKeyboardKey.enter);
        await settle();
        await t.enterText(
          find.byKey(const ValueKey('markdown-live-block')),
          'Neuer Absatz',
        );
        await settle();
        expect(guard.acquire(note.id), false);
        await tap(find.byKey(const ValueKey('markdown-mode-read')));
        await tap(find.byType(Checkbox).first);
        await tap(find.byKey(const ValueKey('editor-save')));
        var saved = (await repo.readSnapshot(note.id)).note.text;
        expect(saved, contains('Erster Absatz\n\nNeuer Absatz'));
        expect(saved, contains('- [x] Rückmeldung einholen'));
        await tap(find.byKey(const ValueKey('markdown-mode-live')));
        await tap(find.text('Startseite'));
        await t.enterText(
          find.byKey(const ValueKey('markdown-cell-input')),
          'Neue Startseite',
        );
        await settle();
        await tap(find.text('Spalte +'));
        await tap(find.text('Zeile +'));
        await tap(find.byKey(const ValueKey('editor-save')));
        saved = (await repo.readSnapshot(note.id)).note.text;
        expect(saved, contains('Neue Startseite'));
        expect(saved, contains('| :--- | --- | ---: |'));
        await captureSurface(t, 'para-markdown-table-0100');
        await tap(find.byKey(const ValueKey('markdown-table-insert')));
        expect(find.byKey(const ValueKey('table-grid-3-4')), findsOneWidget);
        await captureSurface(t, 'para-markdown-picker-0100');
        await tap(find.byKey(const ValueKey('table-grid-3-4')));
        await tap(find.byKey(const ValueKey('editor-save')));
        saved = (await repo.readSnapshot(note.id)).note.text;
        expect(saved, contains('| Spalte 1 | Spalte 2 | Spalte 3 |'));
        await tap(find.byKey(const ValueKey('markdown-mode-raw')));
        await t.enterText(
          find.byKey(const ValueKey('markdown-body')),
          '$saved\n\nUngespeichert',
        );
        await settle();
        await tap(find.byKey(ValueKey('tree-entry-${second.id}')));
        expect(find.text('Änderungen speichern?'), findsOneWidget);
        await tap(find.text('Abbrechen'));
        expect(
          t
              .widget<TextField>(find.byKey(const ValueKey('markdown-body')))
              .controller!
              .text,
          endsWith('Ungespeichert'),
        );
        await tap(find.byKey(const ValueKey('editor-save')));
        t.view.physicalSize = const Size(520, 850);
        await settle();
        expect(t.takeException(), null);
        await tap(find.byKey(const ValueKey('markdown-mode-live')));
        await captureSurface(t, 'para-markdown-narrow-0100');
        expect(find.byType(EntryEditor), findsOneWidget);
        expect(t.takeException(), null);
      } finally {
        await t.pumpWidget(const SizedBox.shrink());
        await settle();
        await repo.close();
        await temp.delete(recursive: true);
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      }
    },
  );
}
