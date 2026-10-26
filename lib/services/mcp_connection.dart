import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../domain/workspace.dart';

const mcpDirectoryChannel = MethodChannel('para.workspace/directory');

Future<Directory> defaultMcpDirectory() async {
  const config = String.fromEnvironment('PARA_CONFIG_DIR');
  const data = String.fromEnvironment('PARA_DATA_DIR');
  if (config.isNotEmpty || data.isNotEmpty) {
    throw const WorkspaceException(
      'Entwicklungsstarts verwenden eine explizite, getrennte MCP-Testablage.',
    );
  }
  if (Platform.isMacOS) {
    return Directory(
      (await mcpDirectoryChannel.invokeMethod<String>('defaultMcpDirectory'))!,
    );
  }
  if (Platform.isLinux) {
    final state = Platform.environment['XDG_STATE_HOME'];
    final home = Platform.environment['HOME'];
    if ((state == null || !p.isAbsolute(state)) &&
        (home == null || !p.isAbsolute(home))) {
      throw const WorkspaceException('Lokaler MCP-Ablageort nicht verfügbar.');
    }
    return Directory(
      p.join(
        state != null && p.isAbsolute(state)
            ? state
            : p.join(home!, '.local', 'state'),
        'para-mcp',
      ),
    );
  }
  throw const WorkspaceException('MCP unterstützt macOS und Linux.');
}
