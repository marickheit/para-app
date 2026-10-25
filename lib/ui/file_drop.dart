import 'dart:async';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../domain/workspace.dart';
import 'common.dart';

class DropDestination {
  const DropDestination(this.section, this.parentId, this.label);
  final ParaSection section;
  final String? parentId;
  final String label;
}

class _DropRegion {
  const _DropRegion(this.destination, this.box, this.priority, this.clip);
  final DropDestination destination;
  final RenderBox? Function() box;
  final int priority;
  final Rect? Function() clip;
}

class WorkspaceDropController extends ChangeNotifier {
  final _regions = <String, _DropRegion>{};
  String? activeId;
  DropDestination? at(Offset position) {
    final id = _idAt(position);
    return _regions[id]?.destination;
  }

  String? _idAt(Offset position) {
    String? result;
    var priority = -1;
    var area = double.infinity;
    for (final entry in _regions.entries) {
      final box = entry.value.box();
      if (box == null || !box.attached || !box.hasSize) continue;
      final clip = entry.value.clip();
      if (clip != null && !clip.contains(position)) continue;
      final local = box.globalToLocal(position);
      if (!box.size.contains(local)) continue;
      final candidateArea = box.size.width * box.size.height;
      if (entry.value.priority > priority ||
          entry.value.priority == priority && candidateArea < area) {
        result = entry.key;
        priority = entry.value.priority;
        area = candidateArea;
      }
    }
    return result;
  }

  void hover(Offset position) {
    final next = _idAt(position);
    if (next != activeId) {
      activeId = next;
      notifyListeners();
    }
  }

  void clear() {
    if (activeId != null) {
      activeId = null;
      notifyListeners();
    }
  }
}

/// One native target avoids duplicate imports across overlapping 0.8 targets.
class WorkspaceDropHost extends StatelessWidget {
  const WorkspaceDropHost({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onDrop,
    required this.child,
  });
  final WorkspaceDropController controller;
  final bool enabled;
  final Future<void> Function(DropDestination, List<DropItem>) onDrop;
  final Widget child;
  @override
  Widget build(BuildContext context) => DropTarget(
    enable: enabled,
    onDragEntered: (details) => controller.hover(details.globalPosition),
    onDragUpdated: (details) => controller.hover(details.globalPosition),
    onDragExited: (_) => controller.clear(),
    onDragDone: (details) {
      final destination = controller.at(details.globalPosition);
      controller.clear();
      if (destination != null && enabled) {
        unawaited(onDrop(destination, details.files));
      }
    },
    child: child,
  );
}

class WorkspaceDropRegion extends StatefulWidget {
  const WorkspaceDropRegion({
    super.key,
    required this.id,
    required this.controller,
    required this.destination,
    required this.child,
    required this.onMove,
    required this.canMove,
    this.priority = 20,
    this.enabled = true,
  });
  final String id;
  final WorkspaceDropController controller;
  final DropDestination destination;
  final Widget child;
  final bool enabled;
  final int priority;
  final bool Function(Entry, DropDestination) canMove;
  final Future<void> Function(Entry, DropDestination) onMove;
  @override
  State<WorkspaceDropRegion> createState() => _WorkspaceDropRegionState();
}

class _WorkspaceDropRegionState extends State<WorkspaceDropRegion> {
  @override
  void initState() {
    super.initState();
    _register();
  }

  void _register() {
    if (widget.enabled) {
      widget.controller._regions[widget.id] = _DropRegion(
        widget.destination,
        () => mounted ? context.findRenderObject() as RenderBox? : null,
        widget.priority,
        () {
          if (!mounted) return Rect.zero;
          final RenderObject? viewport = context
              .findAncestorRenderObjectOfType<RenderAbstractViewport>();
          if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
            return viewport.localToGlobal(Offset.zero) & viewport.size;
          }
          return null;
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant WorkspaceDropRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller._regions.remove(oldWidget.id);
    _register();
  }

  @override
  void dispose() {
    widget.controller._regions.remove(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DragTarget<Entry>(
    onWillAcceptWithDetails: (details) =>
        widget.enabled && widget.canMove(details.data, widget.destination),
    onAcceptWithDetails: (details) =>
        widget.onMove(details.data, widget.destination),
    builder: (context, candidates, rejected) => ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final hovered =
            widget.enabled &&
            (widget.controller.activeId == widget.id || candidates.isNotEmpty);
        final colors = Theme.of(context).colorScheme;
        return Stack(
          children: [
            widget.child,
            if (hovered)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .12),
                      border: Border.all(color: colors.primary, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: colors.surface,
                        child: Text(
                          widget.destination.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.primary, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

Widget entryDragSource(
  Entry entry, {
  required Widget child,
  required bool enabled,
}) {
  if (!enabled ||
      {
        EntryKind.project,
        EntryKind.area,
        EntryKind.resource,
        EntryKind.idea,
      }.contains(entry.kind)) {
    return child;
  }
  final feedback = Material(
    elevation: 6,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 240,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(entryIcon(entry.kind), size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return Draggable<Entry>(
    data: entry,
    feedback: feedback,
    dragAnchorStrategy: pointerDragAnchorStrategy,
    allowedButtonsFilter: (buttons) => buttons == kPrimaryMouseButton,
    childWhenDragging: Opacity(opacity: .35, child: child),
    child: child,
  );
}
