import 'dart:convert';
import 'package:path/path.dart' as p;
import '../domain/workspace.dart';

/// Versioned view settings, kept in the root's existing settings table.
class WorkspaceSession {
  static Map<String, dynamic> decode(String encoded, int expectedVersion) {
    final value = jsonDecode(encoded);
    if (value is! Map<String, dynamic> || value['version'] != expectedVersion) {
      throw const WorkspaceException(
        'Unbekannte Version der gespeicherten Ansicht.',
      );
    }
    for (final key in ['view', 'root', 'selected', 'tab']) {
      if (value[key] != null && value[key] is! String) {
        throw const WorkspaceException('Ungültige gespeicherte Auswahl.');
      }
    }
    for (final key in [
      'railExpanded',
      'sidebarVisible',
      'explorerVisible',
      'readable',
    ]) {
      if (value[key] != null && value[key] is! bool) {
        throw const WorkspaceException('Ungültige Ansichtseinstellung.');
      }
    }
    for (final key in [
      'collapsed',
      'archiveCollapsed',
      'expandedRoots',
      'documentTabs',
    ]) {
      final list = value[key];
      if (list != null && (list is! List || list.any((id) => id is! String))) {
        throw const WorkspaceException('Ungültige gespeicherte Dateiliste.');
      }
    }
    final width = value['explorerWidth'];
    if (width != null &&
        (width is! num || !width.isFinite || width < 220 || width > 520)) {
      throw const WorkspaceException('Ungültige Explorer-Breite.');
    }
    final selection = value['contentSelection'];
    if (selection != null &&
        (selection is! Map ||
            selection.entries.any(
              (e) => e.key is! String || e.value is! String,
            ))) {
      throw const WorkspaceException('Ungültige gespeicherte Inhaltsauswahl.');
    }
    if (value['filter'] != null && value['filter'] is! Map<String, dynamic>) {
      throw const WorkspaceException('Ungültiger Aufgabenfilter.');
    }
    return value;
  }

  static Future<Map<String, dynamic>?> load(
    WorkspaceRepository repository,
    String root,
  ) async {
    final current = await repository.readSetting('session.v2');
    if (current != null) return decode(current, 2);
    final legacy = await repository.readSetting('session.v1');
    if (legacy == null) return null;
    final data = decode(legacy, 1);
    // Export is consistent with active writers and preserves the original session.
    await repository.exportBackup(
      p.join(root, '.migration-backups'),
      forSessionMigration: true,
    );
    return {...data, 'version': 2};
  }
}
