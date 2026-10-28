import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/workspace.dart';
import 'common.dart';

Future<void> openWorkspaceLink(
  BuildContext context,
  String? href, {
  required List<Entry> entries,
  required Future<void> Function(Entry) onOpen,
}) async {
  if (href == null) return;
  final id = entryIdFromLink(href);
  if (id != null) {
    final target = entries.where((e) => e.id == id).firstOrNull;
    if (target == null) {
      showMessage(context, 'Der verknüpfte Inhalt ist nicht verfügbar.');
    } else {
      await onOpen(target);
    }
    return;
  }
  final uri = Uri.tryParse(href);
  if (uri == null || !{'https', 'http', 'mailto'}.contains(uri.scheme)) {
    showMessage(context, 'Dieser Link wird nicht unterstützt.');
    return;
  }
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showMessage(context, 'Der Link konnte nicht geöffnet werden.');
    }
  } catch (error) {
    if (context.mounted) showMessage(context, errorLabel(error));
  }
}
