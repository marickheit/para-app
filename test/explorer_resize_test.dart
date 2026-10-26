import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/ui/explorer_resize.dart';

void main() {
  testWidgets(
    'resize follows full pointer movement and supports keyboard and reset',
    (tester) async {
      double width = 270;
      int starts = 0, ends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => Row(
                children: [
                  SizedBox(width: width),
                  ExplorerResize(
                    key: const ValueKey('handle'),
                    onStart: () => starts++,
                    onEnd: () => ends++,
                    onDelta: (delta) =>
                        update(() => width = (width + delta).clamp(220, 520)),
                    onReset: () => update(() => width = 270),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final handle = find.byKey(const ValueKey('handle'));
      await tester.drag(handle, const Offset(130, 0));
      await tester.pumpAndSettle();
      expect(width, 400);
      expect(starts, 1);
      expect(ends, 1);
      final mouse = find
          .descendant(of: handle, matching: find.byType(MouseRegion))
          .first;
      Focus.of(tester.element(mouse)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(width, 410);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(width, 270);
      await tester.drag(handle, const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(width, 220);
      await tester.tap(handle);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(handle);
      await tester.pumpAndSettle();
      expect(width, 270);
    },
  );
}
