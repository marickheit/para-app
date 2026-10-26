import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

class ExplorerResize extends StatefulWidget {
  const ExplorerResize({
    super.key,
    required this.onDelta,
    required this.onReset,
    required this.onEnd,
    required this.onStart,
  });
  final ValueChanged<double> onDelta;
  final VoidCallback onReset, onStart, onEnd;
  @override
  State<ExplorerResize> createState() => _ExplorerResizeState();
}

class _ExplorerResizeState extends State<ExplorerResize> {
  bool focused = false;
  double _lastX = 0;
  void moveTo(double x) {
    final delta = x - _lastX;
    _lastX = x;
    if (delta != 0) widget.onDelta(delta);
  }

  void adjust(double delta) {
    widget.onStart();
    widget.onDelta(delta);
    widget.onEnd();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Explorer-Breite ändern',
    child: Focus(
      onFocusChange: (value) => setState(() => focused = value),
      onKeyEvent: (_, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          adjust(-10);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          adjust(10);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.home) {
          widget.onReset();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onDoubleTap: widget.onReset,
          onHorizontalDragDown: (e) => _lastX = e.globalPosition.dx,
          onHorizontalDragStart: (e) {
            widget.onStart();
            moveTo(e.globalPosition.dx);
          },
          onHorizontalDragUpdate: (e) => moveTo(e.globalPosition.dx),
          onHorizontalDragEnd: (_) => widget.onEnd(),
          onHorizontalDragCancel: widget.onEnd,
          child: SizedBox(
            width: 8,
            child: Center(
              child: Container(
                width: focused ? 3 : 1,
                color: focused
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
