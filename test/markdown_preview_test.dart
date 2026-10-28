import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/ui/markdown_preview.dart';

void main() {
  testWidgets(
    'overview preview renders safely, opens links and accepts updated text',
    (t) async {
      String? opened;
      Widget app(String text) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarkdownPreview(text: text, onLink: (href) => opened = href),
          ),
        ),
      );
      await t.pumpWidget(
        app('# Titel\n\n- [ ] Vorschau\n\n[Ziel](para://entry/123)'),
      );
      await t.pumpAndSettle();
      expect(find.text('Titel'), findsOneWidget);
      expect(t.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.text('Ziel'));
      expect(opened, 'para://entry/123');
      await t.pumpWidget(app('## Neuer Titel\n\n**Geändert**'));
      await t.pumpAndSettle();
      expect(find.text('Titel'), findsNothing);
      expect(find.text('Neuer Titel'), findsOneWidget);
      expect(find.text('Geändert'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
