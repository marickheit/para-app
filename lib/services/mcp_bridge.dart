import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../domain/workspace.dart';
import 'mcp_access_service.dart';

const mcpMaxBytes = 2 * 1024 * 1024;

/// Owns one ephemeral, explicitly enabled connection for one repository opening.
class McpBridge extends ChangeNotifier {
  McpBridge(this.repository, this.root, {this.connectionWriter});
  final WorkspaceRepository repository;
  final Directory root;
  final Future<void> Function(String path, String content)? connectionWriter;
  HttpServer? _server;
  McpAccessService? _access;
  String? _token;
  String? connectionPath;
  String? lastAction;
  bool get enabled => _access?.active == true;
  bool get canWrite => _access?.canWrite ?? false;
  bool get allowArchive => _access?.allowArchive ?? false;
  int _inFlight = 0;
  bool _changing = false;

  int _generation = 0;
  Future<void>? _pendingEnable;

  Future<void> enable(
    Directory destination, {
    required bool write,
    bool archive = false,
  }) async {
    if (_changing) {
      throw const WorkspaceException('Verbindung wird bereits geändert.');
    }
    _changing = true;
    final generation = ++_generation;
    final pending = _enable(
      destination,
      write: write,
      archive: archive,
      generation: generation,
    );
    _pendingEnable = pending;
    try {
      await pending;
    } finally {
      _pendingEnable = null;
      _changing = false;
    }
  }

  void _checkGeneration(int generation) {
    if (generation != _generation) {
      throw const WorkspaceException('Verbindungsaufbau abgebrochen.');
    }
  }

  Future<void> _enable(
    Directory destination, {
    required bool write,
    required bool archive,
    required int generation,
  }) async {
    await _stop();
    _checkGeneration(generation);
    final folder = await destination.resolveSymbolicLinks();
    final workspace = await root.resolveSymbolicLinks();
    if (folder == workspace || p.isWithin(workspace, folder)) {
      throw const WorkspaceException(
        'Verbindungsdatei außerhalb des Arbeitsbereichs ablegen.',
      );
    }
    var ancestor = folder;
    while (true) {
      if (await Directory(p.join(ancestor, '.git')).exists() ||
          await File(p.join(ancestor, '.git')).exists() ||
          await File(p.join(ancestor, 'workspace.sqlite')).exists() ||
          await File(p.join(ancestor, 'backup.json')).exists()) {
        throw const WorkspaceException(
          'Verbindungsdatei außerhalb von Repository, Arbeitsbereichen und Sicherungen ablegen.',
        );
      }
      final parent = p.dirname(ancestor);
      if (parent == ancestor) break;
      ancestor = parent;
    }
    _checkGeneration(generation);
    final access = McpAccessService(
      repository,
      canWrite: write,
      allowArchive: archive,
    );
    final random = Random.secure();
    final token = base64Url.encode(
      List.generate(32, (_) => random.nextInt(256)),
    );
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: false,
    );
    final path = p.join(folder, 'para-mcp-connection.json');
    try {
      _checkGeneration(generation);
      _server = server;
      _access = access;
      _token = token;
      connectionPath = path;
      await _writeConnection(
        path,
        jsonEncode({
          'version': 1,
          'endpoint': 'http://127.0.0.1:${server.port}/v1/call',
          'token': token,
          'opening_id': access.openingId,
        }),
      );
      _checkGeneration(generation);
      await repository.writeSetting(
        'mcp.v1',
        jsonEncode({'version': 1, 'write': write, 'archive': archive}),
      );
      _checkGeneration(generation);
      server.listen(_handle, onError: (Object _) {});
      notifyListeners();
    } catch (_) {
      access.revoke();
      await server.close(force: true);
      await _removeConnection(path, access.openingId);
      if (identical(_access, access)) {
        _server = null;
        _access = null;
        _token = null;
        connectionPath = null;
      }
      rethrow;
    }
  }

  Future<void> _writeConnection(String path, String content) async {
    if (connectionWriter != null) return connectionWriter!(path, content);
    if (Platform.isMacOS) {
      await const MethodChannel('para.workspace/directory').invokeMethod<void>(
        'writeMcpConnection',
        {'path': path, 'content': content},
      );
    } else {
      throw const WorkspaceException(
        'Sichere Verbindungsdatei derzeit nur unter macOS verfügbar.',
      );
    }
  }

  Future<void> disable() async {
    ++_generation;
    await _stop();
    try {
      await _pendingEnable;
    } catch (_) {
      /* Canceled enable cleans its local resources. */
    }
    notifyListeners();
  }

  Future<void> _stop() async {
    final server = _server, access = _access, path = connectionPath;
    access?.revoke();
    _access = null;
    _server = null;
    _token = null;
    connectionPath = null;
    lastAction = null;
    try {
      await repository.exclusive(() async {});
    } on WorkspaceException {
      // A closed repository has no remaining writes; still release transport.
    } finally {
      await server?.close(force: true);
      if (path != null) await _removeConnection(path, access!.openingId);
    }
  }

  Future<void> _removeConnection(String path, String openingId) async {
    try {
      if (await FileSystemEntity.type(path, followLinks: false) ==
          FileSystemEntityType.file) {
        final value = jsonDecode(await File(path).readAsString());
        if (value['opening_id'] == openingId) await File(path).delete();
      }
    } catch (_) {
      /* Revocation does not depend on deleting the file. */
    }
  }

  Future<void> _handle(HttpRequest request) async {
    var counted = false;
    try {
      final server = _server, access = _access;
      if (server == null ||
          access == null ||
          !access.active ||
          request.headers.value('origin') != null ||
          request.headers.value('host') != '127.0.0.1:${server.port}' ||
          request.headers.value('authorization') != 'Bearer $_token') {
        request.response.statusCode = HttpStatus.forbidden;
        return;
      }
      if (request.method != 'POST' ||
          request.uri.path != '/v1/call' ||
          request.uri.hasQuery) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      if (request.headers.contentType?.mimeType != 'application/json') {
        request.response.statusCode = HttpStatus.unsupportedMediaType;
        return;
      }
      if (_inFlight >= 8) {
        request.response.statusCode = HttpStatus.tooManyRequests;
        return;
      }
      _inFlight++;
      counted = true;
      final bytes = <int>[];
      await for (final chunk in request.timeout(const Duration(seconds: 10))) {
        if (bytes.length + chunk.length > mcpMaxBytes) {
          throw const McpException('too_large', 'Anfrage zu groß.');
        }
        bytes.addAll(chunk);
      }
      final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (payload.keys.any(
            (k) => !{'version', 'opening_id', 'tool', 'arguments'}.contains(k),
          ) ||
          payload['version'] != 1 ||
          payload['opening_id'] != access.openingId) {
        throw const McpException(
          'opening_changed',
          'Verbindung gehört zu einer anderen App-Öffnung.',
        );
      }
      final result = await access.call(
        payload['tool'] as String,
        payload['arguments'] as Map<String, dynamic>,
      );
      if (identical(_access, access)) {
        lastAction = access.lastAction;
        notifyListeners();
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'result': result}));
    } on McpException catch (error) {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': error.toJson()}));
    } catch (_) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(
        '{"error":{"code":"invalid_request","message":"Anfrage nicht lesbar."}}',
      );
    } finally {
      if (counted) _inFlight--;
      try {
        await request.response.close();
      } catch (_) {}
    }
  }
}
