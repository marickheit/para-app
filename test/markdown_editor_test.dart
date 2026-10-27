import "dart:ui" show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/ui/markdown_editor.dart';

class Harness {
  Harness(String text) : source = TextEditingController(text: text);
  final TextEditingController source;
  final key = GlobalKey<MarkdownEditorState>();
  final view = ValueNotifier((MarkdownEditorMode.live, false));
  int changes = 0, edits = 0;
  bool immediateLock = false;
  Widget app() => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder(
            valueListenable: view,
            builder: (context, value, _) => MarkdownEditor(
              key: key,
              controller: source,
              mode: value.$1,
              locked: value.$2,
              canMutate: () => !immediateLock,
              epoch: 1,
              onChanged: () => changes++,
              onEditing: () => edits++,
              onModeChanged: (mode) => view.value = (mode, view.value.$2),
              onLink: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    source.dispose();
    view.dispose();
  }
}

Future<void> activate(WidgetTester t, String text) async {
  await t.tap(find.text(text));
  await t.pumpAndSettle();
}

Future<void> modifiedKey(
  WidgetTester t,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(key);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await t.pumpAndSettle();
}

void main() {
  for (final mode in [MarkdownEditorMode.live, MarkdownEditorMode.read]) {
    testWidgets('tables use bounded content width and scroll in $mode', (
      t,
    ) async {
      final longText = List.filled(30, 'Long cell text').join(' ');
      final h = Harness('| A | B |\n| --- | --- |\n| one | two |');
      h.view.value = (mode, false);
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      final table = find.byType(Table);
      expect(t.getSize(table).width, lessThan(300));
      if (mode == MarkdownEditorMode.live) {
        await t.tap(find.text('one'));
        await t.pumpAndSettle();
        expect(t.getSize(table).width, lessThan(300));
        await t.enterText(
          find.byKey(const ValueKey('markdown-cell-input')),
          longText,
        );
        await t.pumpAndSettle();
        expect(t.getSize(table).width, lessThanOrEqualTo(640));
        expect(t.takeException(), isNull);
      }
      await h.close(t);

      final wide = Harness(
        '| A | B | C |\n| --- | --- | --- |\n| $longText | $longText | $longText |',
      );
      wide.view.value = (mode, false);
      t.view.physicalSize = const Size(400, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(wide.app());
      await t.pumpAndSettle();
      expect(t.getSize(table).width, lessThanOrEqualTo(960));
      expect(t.getSize(table).height, greaterThan(60));
      final horizontal = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
      );
      expect(horizontal, findsOneWidget);
      final scroll = t.state<ScrollableState>(horizontal).position;
      expect(scroll.maxScrollExtent, greaterThan(0));
      await t.drag(horizontal, const Offset(-250, 0));
      await t.pumpAndSettle();
      expect(scroll.pixels, greaterThan(0));
      expect(wide.changes, 0);
      expect(t.takeException(), isNull);
      await wide.close(t);
    });
  }
  testWidgets('opening and mode changes preserve original text without editing', (
    t,
  ) async {
    const text =
        '# Titel\r\n\r\n\r\nAlpha  \r\nBeta\r\n\r\n[x][ref]\r\n\r\n[ref]: https://example.com\r\n';
    final h = Harness(text);
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    expect(h.source.text, text);
    expect(h.edits, 0);
    expect(h.changes, 0);
    for (final mode in MarkdownEditorMode.values) {
      h.view.value = (mode, false);
      await t.pumpAndSettle();
      expect(h.source.text, text);
    }
    await h.close(t);
  });
  testWidgets(
    'Return renders previous paragraph and focuses new source immediately',
    (t) async {
      final h = Harness('Alpha');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await activate(t, 'Alpha');
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(h.source.text, 'Alpha\n\n');
      expect(find.text('Alpha'), findsOneWidget);
      final live = find.byKey(const ValueKey('markdown-live-block'));
      expect(t.widget<TextField>(live).controller!.text, '');
      await t.enterText(live, 'Beta');
      await t.pump();
      expect(h.source.text, 'Alpha\n\nBeta');
      expect(h.key.currentState!.canUndo, true);
      await h.close(t);
    },
  );
  testWidgets(
    'Return splits at selection while Shift Return stays a visible hard break',
    (t) async {
      final h = Harness('AlphaBeta');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await activate(t, 'AlphaBeta');
      final field = find.byKey(const ValueKey('markdown-live-block'));
      t.widget<TextField>(field).controller!.selection =
          const TextSelection.collapsed(offset: 5);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(h.source.text, 'Alpha\n\nBeta');
      expect(t.widget<TextField>(field).controller!.text, 'Beta');
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pumpAndSettle();
      expect(h.source.text, 'Alpha\n\n  \nBeta');
      expect(t.widget<TextField>(field).controller!.text, '  \nBeta');
      await h.close(t);
    },
  );
  testWidgets('code Return stays code and composing text is not split', (
    t,
  ) async {
    final h = Harness('```\ncode\n```');
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    h.key.currentState!.focusEditor();
    await t.pumpAndSettle();
    final field = find.byKey(const ValueKey('markdown-live-block'));
    final c = t.widget<TextField>(field).controller!;
    c.selection = const TextSelection.collapsed(offset: 8);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(h.source.text, '```\ncode\n\n```');
    c.value = TextEditingValue(
      text: c.text,
      selection: const TextSelection.collapsed(offset: 7),
      composing: const TextRange(start: 4, end: 8),
    );
    final before = h.source.text;
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(h.source.text, before);
    await h.close(t);
  });
  testWidgets(
    'Undo Redo crosses mode changes and select all uses canonical source',
    (t) async {
      final h = Harness('Alpha\n\nBeta');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await activate(t, 'Alpha');
      await t.enterText(
        find.byKey(const ValueKey('markdown-live-block')),
        'Changed',
      );
      await t.pump();
      h.view.value = (MarkdownEditorMode.raw, false);
      await t.pumpAndSettle();
      h.key.currentState!.undo();
      await t.pumpAndSettle();
      expect(h.source.text, 'Alpha\n\nBeta');
      h.key.currentState!.redo();
      await t.pumpAndSettle();
      expect(h.source.text, 'Changed\n\nBeta');
      h.view.value = (MarkdownEditorMode.live, false);
      await t.pumpAndSettle();
      await activate(t, 'Beta');
      await modifiedKey(t, LogicalKeyboardKey.keyA);
      expect(h.view.value.$1, MarkdownEditorMode.raw);
      expect(
        h.source.selection,
        TextSelection(baseOffset: 0, extentOffset: h.source.text.length),
      );
      await h.close(t);
    },
  );
  testWidgets(
    'read checkbox edits only true task marker and obeys current lock',
    (t) async {
      final h = Harness('- [ ] real\n\n```\n- [ ] code\n```');
      h.view.value = (MarkdownEditorMode.read, false);
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await t.tap(find.byType(Checkbox).first);
      await t.pumpAndSettle();
      expect(h.source.text, '- [x] real\n\n```\n- [ ] code\n```');
      h.key.currentState!.undo();
      await t.pumpAndSettle();
      expect(h.source.text.startsWith('- [ ]'), true);
      h.view.value = (MarkdownEditorMode.read, true);
      await t.pumpAndSettle();
      expect(t.widget<Checkbox>(find.byType(Checkbox).first).onChanged, null);
      final before = h.source.text;
      h.key.currentState!.insertTable(2, 2);
      h.key.currentState!.format('bold');
      h.key.currentState!.undo();
      expect(h.source.text, before);
      await h.close(t);
    },
  );
  testWidgets('table cells write synchronously and row column changes undo', (
    t,
  ) async {
    const original =
        'Before\r\n\r\n| A | B |\r\n| :--- | ---: |\r\n| one | two |\r\n\r\nAfter';
    final h = Harness(original);
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    await t.tap(find.text('one'));
    await t.pumpAndSettle();
    final input = find.byKey(const ValueKey('markdown-cell-input'));
    await t.enterText(input, 'edited');
    await t.pumpAndSettle();
    expect(h.source.text, original.replaceFirst('one', 'edited'));
    await t.tap(find.text('Spalte +'));
    await t.pumpAndSettle();
    expect(find.text('Spalte −'), findsOneWidget);
    h.key.currentState!.undo();
    await t.pumpAndSettle();
    expect(h.source.text, original.replaceFirst('one', 'edited'));
    expect(find.byKey(const ValueKey('markdown-cell-input')), findsOneWidget);
    await t.tap(find.text('Zeile +'));
    await t.pumpAndSettle();
    h.key.currentState!.undo();
    await t.pumpAndSettle();
    expect(h.source.text, original.replaceFirst('one', 'edited'));
    h.key.currentState!.undo();
    await t.pumpAndSettle();
    expect(h.source.text, original);
    await h.close(t);
  });
  testWidgets('picker hover and click choose dimensions', (t) async {
    (int, int)? chosen;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownTablePicker(onSelected: (c, r) => chosen = (c, r)),
        ),
      ),
    );
    final cell = find.byKey(const ValueKey('table-grid-4-3'));
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(t.getCenter(cell));
    await t.pump();
    expect(find.text('4 Spalten × 3 Zeilen'), findsOneWidget);
    await t.tap(cell);
    expect(chosen, (4, 3));
    await mouse.removePointer();
  });
  testWidgets('nested checkbox callbacks address their own source markers', (
    t,
  ) async {
    final h = Harness('- [ ] parent\n  - [x] child');
    h.view.value = (MarkdownEditorMode.read, false);
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    expect(t.widget<Checkbox>(find.byType(Checkbox).at(0)).value, false);
    await t.tap(find.byType(Checkbox).at(0));
    await t.pumpAndSettle();
    expect(h.source.text, '- [x] parent\n  - [x] child');
    await t.tap(find.byType(Checkbox).at(1));
    await t.pumpAndSettle();
    expect(h.source.text, '- [x] parent\n  - [ ] child');
    await h.close(t);
  });
  testWidgets(
    'table rapid input and multiline paste preserve following source',
    (t) async {
      const original = '| A | B |\n| --- | --- |\n| one | two |\n\nAfter';
      final h = Harness(original);
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await t.tap(find.text('one'));
      await t.pumpAndSettle();
      final field = t.widget<TextField>(
        find.byKey(const ValueKey('markdown-cell-input')),
      );
      field.controller!.text = 'first longer';
      field.onChanged!('first longer');
      field.controller!.text = 'second much longer';
      field.onChanged!('second much longer');
      expect(h.source.text, original.replaceFirst('one', 'second much longer'));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('markdown-cell-input')),
        'a\r\nb',
      );
      await t.pumpAndSettle();
      expect(h.source.text, original.replaceFirst('one', 'a b'));
      expect(t.takeException(), null);
      await h.close(t);
    },
  );
  testWidgets('table inline syntax cannot expose task or block mutation', (
    t,
  ) async {
    final h = Harness('| A | B |\n| --- | --- |\n| - [ ] inline | ## plain |');
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('- [ ] inline'), findsOneWidget);
    expect(find.text('## plain'), findsOneWidget);
    await h.close(t);
  });
  testWidgets(
    'block format changes current line and undo preserves selection',
    (t) async {
      final h = Harness('Alpha Beta');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await activate(t, 'Alpha Beta');
      final field = find.byKey(const ValueKey('markdown-live-block'));
      t.widget<TextField>(field).controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      h.key.currentState!.format('bold');
      await t.pumpAndSettle();
      expect(h.source.text, '**Alpha** Beta');
      h.key.currentState!.undo();
      await t.pumpAndSettle();
      expect(h.source.text, 'Alpha Beta');
      expect(
        h.source.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      expect(
        t.widget<TextField>(field).controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      t.widget<TextField>(field).controller!.selection =
          const TextSelection.collapsed(offset: 10);
      h.key.currentState!.format('heading');
      await t.pumpAndSettle();
      expect(h.source.text, '## Alpha Beta');
      h.key.currentState!.format('check');
      await t.pumpAndSettle();
      expect(h.source.text, '- [ ] Alpha Beta');
      await h.close(t);
    },
  );
  testWidgets(
    'new list marker is continued and paragraph boundary can be removed',
    (t) async {
      final h = Harness('Alpha');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await activate(t, 'Alpha');
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.backspace);
      await t.pumpAndSettle();
      expect(h.source.text, 'Alpha');
      final field = find.byKey(const ValueKey('markdown-live-block'));
      await t.enterText(field, '- new');
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(h.source.text, '- new\n- ');
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(h.source.text, contains('- new\n'));
      expect(h.source.text.endsWith('- '), false);
      await h.close(t);
    },
  );
  testWidgets('table undo restores cell text selection', (t) async {
    final h = Harness('| A |\n| --- |\n| value |');
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    await t.tap(find.text('value'));
    await t.pumpAndSettle();
    final field = find.byKey(const ValueKey('markdown-cell-input'));
    final c = t.widget<TextField>(field).controller!;
    c.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
    c.value = const TextEditingValue(
      text: 'vXe',
      selection: TextSelection.collapsed(offset: 2),
    );
    t.widget<TextField>(field).onChanged!('vXe');
    await t.pumpAndSettle();
    h.key.currentState!.undo();
    await t.pumpAndSettle();
    expect(h.source.text, '| A |\n| --- |\n| value |');
    expect(
      t.widget<TextField>(field).controller!.selection,
      const TextSelection(baseOffset: 1, extentOffset: 4),
    );
    await h.close(t);
  });
  testWidgets('loose task cannot steal a subsequent tight checkbox offset', (
    t,
  ) async {
    const source = '- [ ] loose\n\n  continuation\n\nParagraph\n\n- [x] tight';
    final h = Harness(source);
    h.view.value = (MarkdownEditorMode.read, false);
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    expect(find.byType(Checkbox), findsOneWidget);
    await t.tap(find.byType(Checkbox));
    await t.pumpAndSettle();
    expect(h.source.text, source.replaceFirst('[x] tight', '[ ] tight'));
    await h.close(t);
  });
  testWidgets(
    'Undo then Tab uses destination cell and its own Undo selection',
    (t) async {
      final h = Harness('| A | B |\n| --- | --- |\n| one | two |');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await t.tap(find.text('one'));
      await t.pumpAndSettle();
      final field = find.byKey(const ValueKey('markdown-cell-input'));
      await t.enterText(field, 'changed');
      await t.pumpAndSettle();
      h.key.currentState!.undo();
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(t.widget<TextField>(field).controller!.text, 'two');
      await t.enterText(field, 'other');
      await t.pumpAndSettle();
      h.key.currentState!.undo();
      await t.pumpAndSettle();
      expect(t.widget<TextField>(field).controller!.text, 'two');
      expect(h.source.text, contains('| one | two |'));
      await t.tap(find.text('Spalte +'));
      await t.pumpAndSettle();
      expect(t.widget<TextField>(field).controller!.text, '');
      await h.close(t);
    },
  );
  testWidgets('table inline entities and reference links render as text', (
    t,
  ) async {
    final h = Harness(
      '| A | B |\n| --- | --- |\n| A & B | [Link][ref] |\n\n[ref]: https://example.com',
    );
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    expect(find.text('A & B'), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
    expect(find.text('A &amp; B'), findsNothing);
    await h.close(t);
  });
  testWidgets(
    'format and internal link insertion stay in selected table cell',
    (t) async {
      final h = Harness('| A | B |\n| --- | --- |\n| one | two |');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await t.tap(find.text('one'));
      await t.pumpAndSettle();
      final field = find.byKey(const ValueKey('markdown-cell-input'));
      t.widget<TextField>(field).controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 3,
      );
      h.key.currentState!.format('bold');
      await t.pumpAndSettle();
      expect(h.source.text, '| A | B |\n| --- | --- |\n| **one** | two |');
      h.key.currentState!.insertText('[Ref](para://entry/123)');
      await t.pumpAndSettle();
      expect(h.source.text.startsWith('| A | B |\n| --- | --- |'), true);
      expect(h.source.text, contains('**one**[Ref](para://entry/123)'));
      await h.close(t);
    },
  );
  testWidgets('keyboard Undo Redo uses shared history in live and raw modes', (
    t,
  ) async {
    final h = Harness('Alpha');
    await t.pumpWidget(h.app());
    await t.pumpAndSettle();
    await activate(t, 'Alpha');
    await t.enterText(
      find.byKey(const ValueKey('markdown-live-block')),
      'Beta',
    );
    await t.pumpAndSettle();
    await modifiedKey(t, LogicalKeyboardKey.keyZ);
    expect(h.source.text, 'Alpha');
    expect(h.key.currentState!.canRedo, true);
    await modifiedKey(t, LogicalKeyboardKey.keyZ, shift: true);
    expect(h.source.text, 'Beta');
    h.view.value = (MarkdownEditorMode.raw, false);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('markdown-body')));
    await modifiedKey(t, LogicalKeyboardKey.keyZ);
    expect(h.source.text, 'Alpha');
    await h.close(t);
  });
  testWidgets(
    'current lock rejects old input and command callbacks before rebuild',
    (t) async {
      final h = Harness('Alpha');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await activate(t, 'Alpha');
      h.immediateLock = true;
      await t.enterText(
        find.byKey(const ValueKey('markdown-live-block')),
        'blocked',
      );
      h.key.currentState!.format('bold');
      h.key.currentState!.insertTable(2, 2);
      h.key.currentState!.undo();
      expect(h.source.text, 'Alpha');
      h.immediateLock = false;
      h.view.value = (MarkdownEditorMode.raw, false);
      await t.pumpAndSettle();
      h.immediateLock = true;
      await t.enterText(
        find.byKey(const ValueKey('markdown-body')),
        'also blocked',
      );
      expect(h.source.text, 'Alpha');
      await h.close(t);
    },
  );
  testWidgets(
    'arrow navigation respects visual wrapping before changing blocks',
    (t) async {
      t.view.physicalSize = const Size(360, 600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final long = List.filled(18, 'Long paragraph').join(' ');
      final h = Harness('$long\n\nTail');
      await t.pumpWidget(h.app());
      await t.pumpAndSettle();
      await activate(t, long);
      final field = find.byKey(const ValueKey('markdown-live-block'));
      t.widget<TextField>(field).controller!.selection =
          const TextSelection.collapsed(offset: 0);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pumpAndSettle();
      expect(t.widget<TextField>(field).controller!.text, long);
      expect(
        t.widget<TextField>(field).controller!.selection.extentOffset,
        greaterThan(0),
      );
      t.widget<TextField>(field).controller!.selection =
          TextSelection.collapsed(offset: long.length);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pumpAndSettle();
      expect(t.widget<TextField>(field).controller!.text, 'Tail');
      await h.close(t);
    },
  );
}
