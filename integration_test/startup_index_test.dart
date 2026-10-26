import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/services/pdf_content.dart';
import 'target_features.dart' show samplePdf;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native startup, live PDF search and warm cache', (tester) async {
    final root = await Directory.systemTemp.createTemp('para-startup-native-');
    var repo = await LocalWorkspaceRepository.open(root);
    final release = Completer<void>(), started = Completer<void>();
    var calls = 0;
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    try {
      final pdf = await repo.importFile(
        name: 'Suchdokument.pdf',
        bytes: Stream.value(samplePdf()),
      );
      await repo.searchIndexReady;
      await repo.close();
      final cold = Stopwatch()..start();
      repo = await LocalWorkspaceRepository.open(
        root,
        pdfTextExtractor: (path) async {
          calls++;
          started.complete();
          await release.future;
          return extractPdfText(path);
        },
      );
      cold.stop();
      await started.future.timeout(const Duration(seconds: 10));
      await tester.pumpWidget(
        ParaApp(repository: repo, dataDirectory: root.path),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('tree-entry-${pdf.id}')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('workspace-search')));
      await tester.pumpAndSettle();
      expect(find.text('Suchinhalte werden aktualisiert …'), findsOneWidget);
      final query = find.byKey(const ValueKey('workspace-search-query'));
      await tester.enterText(query, 'Suchdokument');
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('search-result-${pdf.id}')), findsOneWidget);
      await tester.enterText(query, 'Abkleben');
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('search-result-${pdf.id}')), findsNothing);
      final extraction = Stopwatch()..start();
      release.complete();
      await repo.searchIndexReady.timeout(const Duration(seconds: 20));
      extraction.stop();
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('search-result-${pdf.id}')), findsOneWidget);
      expect(find.text('Suchinhalte werden aktualisiert …'), findsNothing);
      expect(calls, 1);
      // Dispose search subscriptions before closing this repository.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await repo.close();
      final warm = Stopwatch()..start();
      repo = await LocalWorkspaceRepository.open(
        root,
        pdfTextExtractor: (path) async {
          calls++;
          return extractPdfText(path);
        },
      );
      warm.stop();
      await repo.searchIndexReady;
      expect(calls, 1);
      expect((await repo.getEntries()).single.searchText, contains('Abkleben'));
      debugPrint(
        'PARA_STARTUP: cold-open=${cold.elapsedMilliseconds}ms, '
        'warm-open=${warm.elapsedMilliseconds}ms, '
        'real-PDF-extract-and-commit=${extraction.elapsedMilliseconds}ms, '
        'warm-extractions=0',
      );
    } finally {
      if (!release.isCompleted) release.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await repo.close();
      await root.delete(recursive: true);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
