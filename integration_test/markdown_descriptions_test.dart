import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/mcp_editor_guard.dart';
import 'package:para_workspace/ui/entry_editor.dart';
import 'package:para_workspace/ui/markdown_preview.dart';
import 'target_features.dart' show captureSurface;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native container descriptions preserve text, fields, links and locks',
    (t) async {
      final temp = await Directory.systemTemp.createTemp(
        'para-description-native-',
      );
      final repo = await LocalWorkspaceRepository.open(temp);
      t.view.physicalSize = const Size(1440, 1000);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      Future<void> settle() async {
        for (var i = 0; i < 3; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          await t.pumpAndSettle();
        }
      }

      Future<void> tap(Finder finder) async {
        await t.ensureVisible(finder);
        await t.tap(finder);
        await settle();
      }

      Future<void> unmount() async {
        await t.pumpWidget(const SizedBox.shrink());
        await settle();
      }

      Future<void> boot(Map<String, Object?> session) async {
        await unmount();
        await repo.writeSetting(
          'session.v2',
          jsonEncode({'version': 2, ...session}),
        );
        await t.pumpWidget(
          RepaintBoundary(
            child: ParaApp(repository: repo, dataDirectory: temp.path),
          ),
        );
        await settle();
      }

      try {
        final target = await repo.create(
          kind: EntryKind.note,
          draft: const EntryDraft(title: 'Interne Notiz', body: 'Zielinhalt'),
        );
        final source =
            '# Beschreibungstitel\r\n\r\n**Wichtiger Zusammenhang**\r\n\r\n'
            '- Erster Punkt\r\n- Zweiter Punkt\r\n\r\n## Prüfung\r\n\r\n- [ ] Prüfen\r\n\r\n'
            '| Thema | Stand |\r\n| --- | --- |\r\n| Planung | Offen |\r\n\r\n'
            '[Interne Notiz](para://entry/${target.id})\r\n';
        final containers = <Entry>[];
        for (final kind in [
          EntryKind.project,
          EntryKind.area,
          EntryKind.resource,
          EntryKind.folder,
        ]) {
          containers.add(
            await repo.create(
              kind: kind,
              parentId: kind == EntryKind.folder ? containers[1].id : null,
              draft: EntryDraft(
                title: 'Test ${kind.name}',
                body: source,
                goal: kind == EntryKind.project ? 'Nachprüfbares Ergebnis' : '',
                dueDate: kind == EntryKind.project
                    ? DateTime(2027, 1, 15)
                    : null,
              ),
            ),
          );
        }
        for (final container in containers) {
          await boot({
            'view': container.section.name,
            'root': container.id,
            'tab': 'overview',
          });
          expect(find.byType(MarkdownPreview), findsOneWidget);
          expect(find.text('Beschreibungstitel'), findsOneWidget);
          expect(t.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
          expect((await repo.readSnapshot(container.id)).note.text, source);
          if (container.kind == EntryKind.project) {
            await captureSurface(t, 'para-description-overview-0110');
            await tap(find.text('Interne Notiz').last);
            expect(find.text('Zielinhalt'), findsOneWidget);
            await boot({
              'view': 'projects',
              'root': container.id,
              'tab': 'overview',
            });
          }
          await tap(
            find.widgetWithText(
              TextButton,
              container.kind == EntryKind.project
                  ? 'Ergebnis, Datum & Beschreibung'
                  : 'Beschreibung öffnen',
            ),
          );
          expect(find.byType(EntryEditor), findsOneWidget);
          expect(
            find.byKey(ValueKey('document-tab-${container.id}')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('markdown-mode-live')),
            findsOneWidget,
          );
          await tap(find.byKey(const ValueKey('markdown-mode-raw')));
          final body = find.byKey(const ValueKey('markdown-body'));
          expect(t.widget<TextField>(body).controller!.text, source);
          await t.enterText(body, '$source\r\n**Ergänzung**');
          await settle();
          expect(
            McpEditorGuard.forRepository(repo).acquire(container.id),
            isFalse,
          );
          await tap(find.byKey(const ValueKey('markdown-mode-read')));
          await tap(find.text('Interne Notiz').last);
          expect(find.text('Änderungen speichern?'), findsOneWidget);
          await tap(find.text('Abbrechen'));
          await tap(find.byType(Checkbox));
          await tap(find.byKey(const ValueKey('editor-save')));
          final snapshot = await repo.readSnapshot(container.id);
          expect(
            snapshot.note.text,
            '${source.replaceFirst('[ ]', '[x]')}\r\n**Ergänzung**',
          );
          expect(snapshot.entry.id, container.id);
          expect(snapshot.entry.goal, container.goal);
          expect(snapshot.entry.dueDate, container.dueDate);
          await tap(find.byKey(const ValueKey('markdown-mode-live')));
          await tap(find.text('Planung'));
          await t.enterText(
            find.byKey(const ValueKey('markdown-cell-input')),
            'Umsetzung',
          );
          await settle();
          await tap(find.byKey(const ValueKey('editor-save')));
          expect(
            (await repo.readSnapshot(container.id)).note.text,
            contains('| Umsetzung | Offen |'),
          );
          if (container.kind == EntryKind.project) {
            // Finish cell editing before inspecting the whole form.
            await tap(find.text('Fertig'));
            await captureSurface(t, 'para-description-editor-0110');
            t.view.physicalSize = const Size(520, 850);
            await settle();
            expect(t.takeException(), isNull);
            await captureSurface(t, 'para-description-narrow-0110');
            t.view.physicalSize = const Size(1440, 1000);
            await settle();
          }
          await tap(find.widgetWithText(TextButton, 'Übersicht'));
          expect(find.text('Ergänzung'), findsOneWidget);
          expect(find.text('Umsetzung'), findsOneWidget);
        }
        // A normal nested-folder selection still opens its contents. Description
        // editing is a distinct action and folder renaming remains available.
        final folder = containers.last;
        await boot({
          'view': 'areas',
          'root': containers[1].id,
          'selected': folder.id,
          'tab': 'content',
        });
        await tap(find.byKey(ValueKey('folder-description-${folder.id}')));
        expect(
          find.byKey(const ValueKey('markdown-mode-live')),
          findsOneWidget,
        );
        await tap(find.byTooltip('Aktionen für ${folder.title}').last);
        expect(find.text('Ordner umbenennen'), findsOneWidget);
        await unmount();
        // Archive and trash expose the same renderer with all editing disabled.
        await repo.archive(containers.first.id, true);
        await repo.trash(containers[2].id);
        for (final item in [
          (containers.first, 'archive'),
          (containers[2], 'trash'),
        ]) {
          await boot({'view': item.$2, 'selected': item.$1.id});
          expect(t.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
          expect(find.byKey(const ValueKey('editor-save')), findsNothing);
          await tap(find.byKey(const ValueKey('markdown-mode-raw')));
          expect(
            t
                .widget<TextField>(find.byKey(const ValueKey('markdown-body')))
                .readOnly,
            isTrue,
          );
        }
        expect(t.takeException(), isNull);
      } finally {
        await unmount();
        await repo.close();
        await temp.delete(recursive: true);
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
        t.platformDispatcher.clearPlatformBrightnessTestValue();
      }
    },
  );
}
