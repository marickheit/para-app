import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/mcp_bridge.dart';
import 'package:para_workspace/services/mcp_connection.dart';
import 'package:para_workspace/ui/mcp_settings.dart';

class _SettingsRepository implements WorkspaceRepository {
  @override
  Future<String?> readSetting(String key) async =>
      '{"version":1,"write":true,"archive":false}';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SettingsBridge extends McpBridge {
  _SettingsBridge() : super(_SettingsRepository(), Directory('/unused'));
  bool active = false, write = false;
  final calls = <String>[];
  @override
  bool get enabled => active;
  @override
  bool get canWrite => write;
  @override
  Future<void> enableAutomatic({
    required bool write,
    bool archive = false,
  }) async {
    calls.add(write ? 'write' : 'read');
    active = true;
    this.write = write;
    notifyListeners();
  }

  @override
  Future<void> disable() async {
    active = false;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'access choice immediately enables and revokes without a picker',
    (tester) async {
      final bridge = _SettingsBridge();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: McpSettings(bridge: bridge)),
        ),
      );
      await tester.pumpAndSettle();
      // A remembered write preference never activates a new opening.
      expect(find.text('Zugriff aus'), findsOneWidget);
      Future<void> select(String label) async {
        await tester.tap(find.byKey(const ValueKey('mcp-permission')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      await select('Nur lesen');
      expect(bridge.enabled, true);
      expect(bridge.canWrite, false);
      expect(find.text('Aktiv: Nur lesen'), findsOneWidget);
      await select('Lesen und Schreiben');
      expect(bridge.canWrite, true);
      expect(find.text('Aktiv: Lesen und Schreiben'), findsOneWidget);
      await select('Aus');
      expect(bridge.enabled, false);
      expect(bridge.calls, ['read', 'write']);
      expect(find.textContaining('Verbindungsdatei ablegen'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      bridge.dispose();
    },
  );

  test(
    'revocation while automatic preparation waits prevents activation',
    () async {
      final temp = await Directory.systemTemp.createTemp('para-mcp-prepare-');
      final repo = await LocalWorkspaceRepository.open(
        Directory('${temp.path}/workspace'),
      );
      final started = Completer<void>(), release = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(mcpDirectoryChannel, (call) async {
            started.complete();
            await release.future;
            return null;
          });
      final bridge = McpBridge(
        repo,
        repo.root,
        automaticDirectory: Directory('${temp.path}/connection'),
      );
      try {
        final enabling = bridge.enableAutomatic(write: true);
        final failed = expectLater(enabling, throwsA(anything));
        await started.future;
        await bridge.disable();
        release.complete();
        await failed;
        expect(bridge.enabled, false);
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(mcpDirectoryChannel, null);
        await bridge.disable();
        bridge.dispose();
        await repo.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
