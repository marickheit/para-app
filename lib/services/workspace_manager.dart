import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../data/local_workspace_repository.dart';
import '../data/workspace_storage.dart';
import '../domain/workspace.dart';
import 'mcp_bridge.dart';

class WorkspaceLocation {
  const WorkspaceLocation(this.path, {this.bookmark});
  final String path;
  final String? bookmark;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'path': path,
    'bookmark': bookmark,
  };
}

abstract class WorkspaceDirectoryAccess {
  Future<WorkspaceLocation?> choose();
  Future<WorkspaceLocation> restore(WorkspaceLocation location);
}

class NativeWorkspaceDirectoryAccess implements WorkspaceDirectoryAccess {
  static const channel = MethodChannel('para.workspace/directory');
  @override
  Future<WorkspaceLocation?> choose() async {
    final path = await getDirectoryPath(
      confirmButtonText: 'Arbeitsbereich auswählen',
    );
    if (path == null) return null;
    if (!Platform.isMacOS) return WorkspaceLocation(path);
    final result = await channel.invokeMapMethod<String, dynamic>(
      'bookmarkDirectory',
      {'path': path},
    );
    return WorkspaceLocation(
      result!['path'] as String,
      bookmark: result['bookmark'] as String?,
    );
  }

  @override
  Future<WorkspaceLocation> restore(WorkspaceLocation location) async {
    if (!Platform.isMacOS || location.bookmark == null) return location;
    final result = await channel.invokeMapMethod<String, dynamic>(
      'resolveDirectory',
      {'bookmark': location.bookmark},
    );
    return WorkspaceLocation(
      result!['path'] as String,
      bookmark: result['bookmark'] as String?,
    );
  }
}

enum WorkspaceOpenMode { open, create, copyCurrent }

class WorkspaceManager extends ChangeNotifier {
  WorkspaceManager({
    required this.configurationDirectory,
    required this.defaultRoot,
    this.overrideRoot,
    WorkspaceDirectoryAccess? access,
    this.pdfTextExtractor,
  }) : access = access ?? NativeWorkspaceDirectoryAccess();
  final Directory configurationDirectory;
  final Directory defaultRoot;
  final Directory? overrideRoot;
  final WorkspaceDirectoryAccess access;
  final Future<String?> Function(String)? pdfTextExtractor;
  LocalWorkspaceRepository? repository;
  McpBridge? mcp;
  WorkspaceLocation? location;
  Object? error;
  bool loading = true;
  bool _working = false;
  bool get testOverride => overrideRoot != null;
  File get _preferences =>
      File(p.join(configurationDirectory.path, 'workspace-location.json'));

  Future<void> initialize() async {
    if (_working || repository != null) return;
    _working = true;
    loading = true;
    error = null;
    notifyListeners();
    try {
      var create = true;
      if (overrideRoot != null) {
        location = WorkspaceLocation(overrideRoot!.path);
      } else if (await _preferences.exists()) {
        final data =
            jsonDecode(await _preferences.readAsString())
                as Map<String, dynamic>;
        if (data['version'] != 1 || data['path'] is! String) {
          throw const WorkspaceException(
            'Die gespeicherte Ordnerauswahl ist unbekannt. Bitte den Arbeitsbereich erneut auswählen.',
          );
        }
        location = WorkspaceLocation(
          data['path'] as String,
          bookmark: data['bookmark'] as String?,
        );
        create = false;
      } else {
        location = WorkspaceLocation(defaultRoot.path);
      }
      final selected = await access.restore(location!);
      final next = await LocalWorkspaceRepository.open(
        Directory(selected.path),
        create: create,
        pdfTextExtractor: pdfTextExtractor,
      );
      final resolved = WorkspaceLocation(
        next.root.path,
        bookmark: selected.bookmark,
      );
      try {
        if (!testOverride) await _remember(resolved);
      } catch (_) {
        await next.close();
        rethrow;
      }
      repository = next;
      mcp = McpBridge(next, next.root);
      location = resolved;
    } catch (value) {
      error = value;
    } finally {
      _working = false;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _remember(WorkspaceLocation selected) async {
    await configurationDirectory.create(recursive: true);
    final temporary = File('${_preferences.path}.tmp');
    await temporary.writeAsString(jsonEncode(selected.toJson()), flush: true);
    await temporary.rename(_preferences.path);
  }

  Future<void> switchTo(
    WorkspaceLocation selected,
    WorkspaceOpenMode mode,
  ) async {
    if (testOverride) {
      throw const WorkspaceException(
        'Dieser Start verwendet einen festen Test-Datenpfad. Die normale Ordnerauswahl bleibt unverändert.',
      );
    }
    if (_working) {
      throw const WorkspaceException(
        'Ein Arbeitsbereich wird bereits geöffnet.',
      );
    }
    _working = true;
    LocalWorkspaceRepository? next;
    try {
      final granted = await access.restore(selected);
      final target = Directory(granted.path);
      if (!await target.exists()) {
        throw const WorkspaceException(
          'Der gewählte Ordner ist nicht verfügbar.',
        );
      }
      final destination = await target.resolveSymbolicLinks();
      final source = repository == null
          ? null
          : await repository!.root.resolveSymbolicLinks();
      if (source == destination) return;
      if (source != null &&
          (p.isWithin(source, destination) ||
              p.isWithin(destination, source))) {
        throw const WorkspaceException(
          'Arbeitsbereiche dürfen für die Übernahme nicht ineinander liegen.',
        );
      }
      if (mode != WorkspaceOpenMode.open &&
          !await WorkspaceStorage.isEmpty(target)) {
        throw const WorkspaceException(
          'Bitte einen leeren Zielordner wählen. Vorhandene Inhalte werden nicht überschrieben.',
        );
      }
      await mcp?.disable();
      loading = true;
      error = null;
      notifyListeners();
      if (mode == WorkspaceOpenMode.copyCurrent) {
        final current = repository;
        if (current == null) {
          throw const WorkspaceException(
            'Es ist kein Arbeitsbereich zum Kopieren geöffnet.',
          );
        }
        await _copy(current, target);
      }
      next = await LocalWorkspaceRepository.open(
        target,
        create: mode == WorkspaceOpenMode.create,
        pdfTextExtractor: pdfTextExtractor,
      );
      await verifyContents(next);
      await _remember(
        WorkspaceLocation(destination, bookmark: granted.bookmark),
      );
      final previous = repository;
      repository = next;
      mcp?.dispose();
      mcp = McpBridge(next, next.root);
      location = WorkspaceLocation(destination, bookmark: granted.bookmark);
      next = null;
      await previous?.close();
    } catch (_) {
      await next?.close();
      rethrow;
    } finally {
      _working = false;
      loading = false;
      notifyListeners();
    }
  }

  static Future<void> verifyContents(LocalWorkspaceRepository repo) async {
    for (final entry in [
      ...await repo.getEntries(),
      ...await repo.getTrash(),
    ]) {
      if (entry.kind == EntryKind.file) {
        await repo.filePath(entry.id);
      } else if (!await File(
        p.join(repo.root.path, 'notes', '${entry.id}.md'),
      ).exists()) {
        throw WorkspaceException(
          'Eine Notizdatei fehlt: ${entry.title}. Der bisherige Arbeitsbereich bleibt erhalten.',
        );
      }
    }
  }

  Future<void> _copy(LocalWorkspaceRepository current, Directory target) async {
    final temporary = await Directory.systemTemp.createTemp('para-transfer-');
    final marker = File(p.join(target.path, '.para-transfer'));
    try {
      final snapshot = Directory(await current.exportBackup(temporary.path));
      await marker.writeAsString(
        jsonEncode({'version': 1, 'source': current.root.path}),
        flush: true,
      );
      await WorkspaceStorage.copyTree(snapshot, target);
      await for (final source in snapshot.list(
        recursive: true,
        followLinks: false,
      )) {
        if (source is! File) continue;
        final copied = File(
          p.join(target.path, p.relative(source.path, from: snapshot.path)),
        );
        final before = await sha256.bind(source.openRead()).first;
        final after = await sha256.bind(copied.openRead()).first;
        if (before.toString() != after.toString()) {
          throw const WorkspaceException(
            'Die Dateiprüfung der Übernahme ist fehlgeschlagen. Die Quelle bleibt erhalten.',
          );
        }
      }
      await marker.delete();
    } finally {
      await temporary.delete(recursive: true);
    }
  }

  Future<void> close() async {
    await mcp?.disable();
    mcp?.dispose();
    mcp = null;
    await repository?.close();
    repository = null;
  }
}
