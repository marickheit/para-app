import 'package:flutter/material.dart';
import '../domain/workspace.dart';
import '../services/file_formats.dart';

class EntryAction {
  const EntryAction(this.id, this.label);
  final String id;
  final String label;
}

List<EntryAction> availableEntryActions(Entry entry, List<Entry> entries) {
  if (entry.inTrash) {
    return const [
      EntryAction('copy', 'Link kopieren'),
      EntryAction('trash-restore', 'Wiederherstellen'),
      EntryAction('purge', 'Endgültig entfernen …'),
    ];
  }
  final archived = isArchived(entry, entries);
  return [
    const EntryAction('copy', 'Link kopieren'),
    if (!archived && entry.kind.isContainer) ...[
      const EntryAction('new-note', 'Neue Notiz …'),
      const EntryAction('new-text', 'Neue Textdatei …'),
      const EntryAction('new-folder', 'Neuer Ordner …'),
      const EntryAction('new-task', 'Neue Aufgabe …'),
      const EntryAction('import-files', 'Dateien hinzufügen …'),
      const EntryAction('import-folder', 'Ordner hinzufügen …'),
    ],
    if (!archived &&
        !entry.kind.isContainer &&
        (entry.kind != EntryKind.file ||
            isEditableTextName(entry.fileName ?? '')))
      const EntryAction('edit', 'Bearbeiten'),
    if (!archived &&
        (entry.kind == EntryKind.note || entry.kind == EntryKind.file))
      const EntryAction('rename', 'Umbenennen …'),
    if (!archived && entry.kind == EntryKind.task) ...[
      if (entry.taskState.isClosed)
        const EntryAction('task-resume', 'Wieder aufnehmen')
      else ...[
        const EntryAction('task-done', 'Erledigt'),
        const EntryAction('task-cancel', 'Nicht mehr relevant'),
      ],
    ],
    if (!archived && entry.kind.isContainer)
      EntryAction(
        'edit',
        entry.kind == EntryKind.folder
            ? 'Ordner umbenennen'
            : 'Beschreibung bearbeiten',
      ),
    if (!archived &&
        !{
          EntryKind.project,
          EntryKind.area,
          EntryKind.resource,
          EntryKind.idea,
        }.contains(entry.kind))
      const EntryAction('move', 'Verschieben …'),
    if (!archived &&
        (entry.kind == EntryKind.idea ||
            entry.kind == EntryKind.task &&
                entry.taskState == TaskState.someday))
      const EntryAction('convert', 'In Projekt umwandeln …'),
    if (!archived && entry.kind == EntryKind.project)
      const EntryAction('complete', 'Projekt abschließen'),
    if (!archived) const EntryAction('archive', 'Archivieren'),
    if (archived) const EntryAction('restore', 'Wiederherstellen'),
    const EntryAction('trash', 'In Papierkorb'),
  ];
}

List<PopupMenuEntry<String>> actionMenuItems(List<EntryAction> actions) =>
    actions
        .map(
          (action) => PopupMenuItem<String>(
            value: action.id,
            child: Text(action.label),
          ),
        )
        .toList();

class EntryContextMenu extends StatelessWidget {
  const EntryContextMenu({
    super.key,
    required this.actions,
    required this.onSelected,
    required this.child,
    this.enabled = true,
  });
  final List<EntryAction> actions;
  final Future<void> Function(String) onSelected;
  final Widget child;
  final bool enabled;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onSecondaryTapDown: !enabled
        ? null
        : (details) async {
            final overlay =
                Overlay.of(context).context.findRenderObject()! as RenderBox;
            final position = overlay.globalToLocal(details.globalPosition);
            final selected = await showMenu<String>(
              context: context,
              position: RelativeRect.fromRect(
                Rect.fromLTWH(position.dx, position.dy, 0, 0),
                Offset.zero & overlay.size,
              ),
              items: actionMenuItems(actions),
            );
            if (selected != null && context.mounted) await onSelected(selected);
          },
    child: child,
  );
}
