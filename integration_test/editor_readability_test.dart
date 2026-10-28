import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/ui/markdown_editor.dart';
import 'target_features.dart' show captureSurface;

const recipe = '''---
type: recipe
tags: [recipe, vegetarian, pasta, one-pot]
custom: Diese Eigenschaft bleibt unverändert erhalten.
---

# One Pot Feta Pasta

## Übersicht

| | |
| --- | --- |
| Portionen | 4 |
| Vorbereitung | 20 min |
| Koch-/Backzeit | 25 min |
| Gesamtzeit | 45 min |
| Schwierigkeit | leicht |
| Bewertung | ★★★★ |

## Nährwerte

pro Portion

| Nährwert | Menge |
| --- | --- |
| Kalorien | 864 kcal |
| Kohlenhydrate | 104 g |
| Ballaststoffe | 5,5 g |
| Fett | 38 g |
| Protein | 33 g |

## Zutaten

- 250 g Spaghetti
- 200 g Feta
- 2 Knoblauchzehen
- 250 g Mini-Tomaten
- 1 rote Zwiebel
- Salz, Pfeffer, Olivenöl und Basilikum

## Zubereitung

1. Ofen auf 200 °C Ober- und Unterhitze vorheizen. Spaghetti in eine große Auflaufform geben und den Feta in die Mitte setzen.
2. Knoblauch pressen und auf dem Feta verteilen. Tomaten halbieren, Zwiebel fein hacken und in die Form geben.
3. Mit Wasser auffüllen, würzen und für 25 Minuten backen. Anschließend vermischen und mit Basilikum servieren.
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native reading layout, themes, modes and saved width choice', (
    t,
  ) async {
    final temp = await Directory.systemTemp.createTemp('para-reading-native-');
    final repo = await LocalWorkspaceRepository.open(temp);
    t.view.physicalSize = const Size(1500, 1040);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await t.pumpAndSettle();
      }
    }

    Future<void> tap(Finder finder) async {
      await t.ensureVisible(finder);
      await t.tap(finder);
      await settle();
    }

    Future<void> boot() async {
      await t.pumpWidget(
        RepaintBoundary(
          child: ParaApp(repository: repo, dataDirectory: temp.path),
        ),
      );
      await settle();
    }

    try {
      final cooking = await repo.create(
        kind: EntryKind.resource,
        section: ParaSection.resources,
        draft: const EntryDraft(title: 'Kochen'),
      );
      final folder = await repo.create(
        kind: EntryKind.folder,
        parentId: cooking.id,
        draft: const EntryDraft(title: 'Rezepte'),
      );
      final note = await repo.create(
        kind: EntryKind.note,
        parentId: folder.id,
        draft: const EntryDraft(title: 'One Pot Feta Pasta.md', body: recipe),
      );
      final session = {
        'version': 2,
        'view': 'resources',
        'selected': note.id,
        'root': folder.id,
        'documentTabs': [note.id],
        'expandedRoots': [cooking.id, folder.id],
      };
      await repo.writeSetting('session.v2', jsonEncode(session));
      await boot();
      expect(t.getSize(find.byType(MarkdownEditor)).width, closeTo(680, 1));
      expect(
        t
            .widget<ColoredBox>(
              find.byKey(const ValueKey('markdown-document-surface')),
            )
            .color,
        const Color(0xff202020),
      );
      expect(
        t.getTopLeft(find.text('One Pot Feta Pasta')).dy,
        lessThan(
          t.getTopLeft(find.text('recipe · vegetarian · pasta · one-pot')).dy,
        ),
      );
      await captureSurface(t, 'para-editor-reading-dark-0102');
      final documentScroll = t
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('entry-editor-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      documentScroll.jumpTo(documentScroll.maxScrollExtent);
      await settle();
      expect(
        t.getTopLeft(find.text('200 g Feta')).dy -
            t.getTopLeft(find.text('250 g Spaghetti')).dy,
        inInclusiveRange(28, 30),
      );
      await captureSurface(t, 'para-editor-lists-0102');
      documentScroll.jumpTo(0);
      await settle();
      for (final mode in ['read', 'raw', 'live']) {
        await tap(find.byKey(ValueKey('markdown-mode-$mode')));
        expect((await repo.readSnapshot(note.id)).note.text, recipe);
      }
      await tap(find.byKey(const ValueKey('markdown-properties-toggle')));
      expect(find.textContaining('Diese Eigenschaft bleibt'), findsOneWidget);
      await tap(find.byKey(const ValueKey('markdown-properties-toggle')));
      t.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await settle();
      await captureSurface(t, 'para-editor-reading-light-0102');
      t.view.physicalSize = const Size(520, 850);
      await settle();
      expect(t.getSize(find.byType(MarkdownEditor)).width, lessThan(520));
      expect(t.takeException(), isNull);
      final scrollable = find
          .descendant(
            of: find.byKey(const ValueKey('entry-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      t.state<ScrollableState>(scrollable).position.jumpTo(0);
      await settle();
      await captureSurface(t, 'para-editor-reading-narrow-0102');
      t.view.physicalSize = const Size(1500, 1040);
      await settle();
      await tap(find.byTooltip('Weitere Dateiaktionen'));
      await tap(find.text('Volle Breite'));
      expect(t.getSize(find.byType(MarkdownEditor)).width, greaterThan(900));
      await t.pumpWidget(const SizedBox.shrink());
      await settle();
      // Existing explicit full-width sessions must retain their choice.
      await repo.writeSetting(
        'session.v2',
        jsonEncode({...session, 'readable': false}),
      );
      await boot();
      expect(t.getSize(find.byType(MarkdownEditor)).width, greaterThan(900));
      expect((await repo.readSnapshot(note.id)).note.text, recipe);
      expect(t.takeException(), isNull);
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      await settle();
      await repo.close();
      await temp.delete(recursive: true);
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
      t.platformDispatcher.clearPlatformBrightnessTestValue();
    }
  });
}
