import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import '../domain/workspace.dart';

IconData entryIcon(EntryKind kind) => switch (kind) {
  EntryKind.project => LucideIcons.flag,
  EntryKind.area => LucideIcons.layoutGrid,
  EntryKind.resource => LucideIcons.library,
  EntryKind.folder => LucideIcons.folder,
  EntryKind.note => LucideIcons.fileText,
  EntryKind.task => LucideIcons.circleCheck,
  EntryKind.file => LucideIcons.file,
  EntryKind.idea => LucideIcons.lightbulb,
};

String entryFileLabel(Entry entry) =>
    entry.kind == EntryKind.note &&
        !{'.md', '.markdown'}.contains(p.extension(entry.title).toLowerCase())
    ? '${entry.title}.md'
    : entry.title;

IconData fileIcon(Entry entry) {
  if (entry.kind != EntryKind.file) return entryIcon(entry.kind);
  return switch (p.extension(entry.fileName ?? entry.title).toLowerCase()) {
    '.png' ||
    '.jpg' ||
    '.jpeg' ||
    '.gif' ||
    '.webp' ||
    '.bmp' ||
    '.svg' => LucideIcons.image,
    '.csv' => LucideIcons.sheet,
    '.pdf' || '.txt' || '.md' || '.markdown' => LucideIcons.fileText,
    '.zip' || '.gz' || '.7z' => LucideIcons.fileArchive,
    _ => LucideIcons.file,
  };
}

String dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

bool isOverdue(Entry entry) {
  final now = DateTime.now();
  return entry.dueDate != null &&
      !entry.completed &&
      !entry.taskState.isClosed &&
      entry.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
}

String fileSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String errorLabel(Object error) {
  if (error is WorkspaceException) return error.message;
  if (error is FileSystemException) {
    return 'Eine lokale Datei konnte nicht gelesen oder geschrieben werden. '
        'Bitte prüfe den Speicherort und die Zugriffsrechte.';
  }
  return 'Der Vorgang konnte nicht abgeschlossen werden: $error';
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: warning ? colors.errorContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: warning
              ? colors.onErrorContainer
              : colors.onSecondaryContainer,
        ),
      ),
    );
  }
}
