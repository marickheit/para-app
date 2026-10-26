import 'package:path/path.dart' as p;
import 'workspace.dart';

class IngestItem {
  IngestItem({
    required this.id,
    required this.path,
    required this.directory,
    required this.signature,
    this.parentId,
    this.hash,
    this.size = 0,
  });
  final String id, path, signature;
  final bool directory;
  final String? parentId;
  String? hash;
  final int size;
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'directory': directory,
    'signature': signature,
    'parent_id': parentId,
    'hash': hash,
    'size': size,
  };
  factory IngestItem.fromJson(Map<String, dynamic> value) {
    final path = value['path'] as String;
    if (p.isAbsolute(path) ||
        path.split('/').any((s) => s == '..' || s == '.') ||
        path.contains(r'\') ||
        entryIdFromLink(entryLink(value['id'] as String)) == null) {
      throw const WorkspaceException('Ungültiger Import-Zwischenstand.');
    }
    return IngestItem(
      id: value['id'],
      path: path,
      directory: value['directory'],
      signature: value['signature'],
      parentId: value['parent_id'],
      hash: value['hash'],
      size: value['size'],
    );
  }
}

class IngestJob {
  IngestJob({
    required this.id,
    required this.binding,
    required this.workspace,
    required this.source,
    required this.name,
    required this.items,
    this.phase = 'preparing',
    this.error,
  });
  final String id, binding, workspace, source, name;
  List<IngestItem> items;
  String phase;
  String? error;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'binding': binding,
    'workspace': workspace,
    'source': source,
    'name': name,
    'phase': phase,
    'error': error,
    'items': items.map((e) => e.toJson()).toList(),
  };
  factory IngestJob.fromJson(Map<String, dynamic> value) {
    if (value['version'] != 1 ||
        entryIdFromLink(entryLink(value['id'] as String)) == null ||
        p.basename(value['name'] as String) != value['name'] ||
        {'', '.', '..'}.contains(value['name']) ||
        (value['name'] as String).contains(r'\') ||
        !{
          'preparing',
          'ready',
          'committed',
          'done',
          'recovered',
        }.contains(value['phase'])) {
      throw const WorkspaceException('Unbekanntes Importjournal.');
    }
    final items = (value['items'] as List)
        .map((e) => IngestItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (items.isEmpty ||
        items.first.path != '' ||
        items.map((e) => e.id).toSet().length != items.length ||
        items.map((e) => e.path).toSet().length != items.length) {
      throw const WorkspaceException('Unvollständiges Importjournal.');
    }
    final ids = <String>{};
    for (final item in items) {
      if (item.parentId != null && !ids.contains(item.parentId)) {
        throw const WorkspaceException('Ungültige Importhierarchie.');
      }
      ids.add(item.id);
    }
    return IngestJob(
      id: value['id'],
      binding: value['binding'],
      workspace: value['workspace'],
      source: value['source'],
      name: value['name'],
      items: items,
      phase: value['phase'],
      error: value['error'],
    );
  }
}
