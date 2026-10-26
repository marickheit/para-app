import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/services/mcp_bridge.dart';
import 'package:para_workspace/services/workspace_manager.dart';
import 'package:para_workspace/ui/mcp_settings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native secure connection and external stdio client', (
    tester,
  ) async {
    final temp = await Directory.systemTemp.createTemp('para-native-mcp-');
    const externalRoot = String.fromEnvironment('PARA_MCP_TEST_ROOT');
    var dataRoot = Directory('${temp.path}/workspace');
    if (externalRoot.isNotEmpty) {
      final selected = await NativeWorkspaceDirectoryAccess().choose();
      expect(selected, isNotNull);
      expect(
        await Directory(selected!.path).resolveSymbolicLinks(),
        await Directory(externalRoot).resolveSymbolicLinks(),
      );
      dataRoot = Directory(selected.path);
      expect(
        await dataRoot.list().isEmpty,
        true,
        reason: 'Only an empty, explicitly selected test folder is allowed.',
      );
    }
    final repo = await LocalWorkspaceRepository.open(dataRoot);
    final folder = await Directory('${temp.path}/connection').create();
    final bridge = McpBridge(repo, repo.root);
    try {
      final credentialPath = '${folder.path}/para-mcp-connection.json';
      final link = Link(credentialPath);
      await link.create('${temp.path}/missing-target');
      await expectLater(bridge.enable(folder, write: true), throwsA(anything));
      expect(bridge.enabled, false);
      await link.delete();
      await File(credentialPath).writeAsString('unsafe');
      await expectLater(bridge.enable(folder, write: true), throwsA(anything));
      await File(credentialPath).delete();
      await bridge.enable(folder, write: true);
      final path = bridge.connectionPath!;
      // Deliberately emit only the path, never the token. The external test driver
      // runs mcp/test/app-smoke.mjs and creates this marker on success.
      // ignore: avoid_print
      print('MCP_NATIVE_READY $path');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: McpSettings(bridge: bridge)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aktiv: Lesen und Schreiben'), findsOneWidget);
      final done = File('$path.done');
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (!await done.exists() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(
        await done.exists(),
        true,
        reason: 'External MCP smoke driver did not complete.',
      );
      expect(
        (await repo.getEntries())
            .where((e) => e.title == 'MCP integration')
            .length,
        1,
      );
      await bridge.disable();
      expect(await File(path).exists(), false);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      await bridge.disable();
      bridge.dispose();
      await repo.close();
      if (externalRoot.isNotEmpty) await dataRoot.delete(recursive: true);
      await temp.delete(recursive: true);
    }
  });
}
