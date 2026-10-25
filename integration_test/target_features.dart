import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/pdf_content.dart';
import 'compact_explorer_features.dart';

List<int> samplePdf() {
  const stream = 'BT /F1 18 Tf 40 700 Td (Abkleben und Abdecken) Tj ET';
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Count 1 /Kids [3 0 R] >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
  ];
  var data = '%PDF-1.4\n';
  final offsets = [0];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(data.length);
    data += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
  }
  final start = data.length;
  data += 'xref\n0 6\n0000000000 65535 f \n';
  for (final at in offsets.skip(1)) {
    data += '${at.toString().padLeft(10, '0')} 00000 n \n';
  }
  data += 'trailer\n<< /Root 1 0 R /Size 6 >>\nstartxref\n$start\n%%EOF';
  return ascii.encode(data);
}

Future<void> captureSurface(WidgetTester tester, String name) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final render =
      tester.firstRenderObject(find.byType(RepaintBoundary).first)
          as RenderRepaintBoundary;
  final image = await render.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  debugPrint('PARA_SCREENSHOT: ${Directory.systemTemp.path}/$name.png');
  if (data != null) {
    await File(
      '${Directory.systemTemp.path}/$name.png',
    ).writeAsBytes(data.buffer.asUint8List());
  }
}

void registerTargetFeatureTests() {
  testWidgets(
    'next actions group by project and cancellation can be resumed after reopening',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp('para-tasks-ui-');
      var repo = await LocalWorkspaceRepository.open(directory);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      try {
        final p1 = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Wohnung renovieren',
            goal: 'Räume bezugsfertig',
            dueDate: DateTime(2026, 11, 30),
          ),
        );
        final p2 = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Portfolio veröffentlichen',
            goal: 'Portfolio online',
            dueDate: DateTime(2026, 12, 15),
          ),
        );
        final folder = await repo.create(
          kind: EntryKind.folder,
          parentId: p1.id,
          draft: const EntryDraft(title: 'Planung'),
        );
        final next = await repo.create(
          kind: EntryKind.task,
          parentId: folder.id,
          draft: const EntryDraft(
            title: 'Wände ausmessen',
            taskState: TaskState.next,
          ),
        );
        await repo.create(
          kind: EntryKind.task,
          parentId: p2.id,
          draft: const EntryDraft(
            title: 'Arbeitsproben auswählen',
            taskState: TaskState.next,
          ),
        );
        await repo.create(
          kind: EntryKind.task,
          draft: const EntryDraft(
            title: 'Ohne Zuordnung',
            taskState: TaskState.next,
          ),
        );
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: directory.path),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-tasks')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('task-nav-actions')));
        await tester.pumpAndSettle();
        expect(find.text('Wohnung renovieren · 1'), findsOneWidget);
        expect(find.text('Portfolio veröffentlichen · 1'), findsOneWidget);
        expect(find.text('Ohne Projekt · 1'), findsOneWidget);
        await captureSurface(tester, 'para-flutter-tasks');
        final row = find.byKey(ValueKey('task-row-${next.id}'));
        await tester.tapAt(
          tester.getCenter(row),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(PopupMenuItem<String>, 'Nicht mehr relevant'),
        );
        await tester.pumpAndSettle();
        expect(row, findsNothing);
        await tester.tap(find.byKey(const ValueKey('task-nav-cancelled')));
        await tester.pumpAndSettle();
        expect(row, findsOneWidget);
        expect(find.text('Nicht mehr relevant'), findsWidgets);
        await tester.tap(
          find.descendant(
            of: row,
            matching: find.byType(PopupMenuButton<String>),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Wieder aufnehmen'));
        await tester.pumpAndSettle();
        expect(
          (await repo.getEntries())
              .singleWhere((e) => e.id == next.id)
              .taskState,
          TaskState.next,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        repo = await LocalWorkspaceRepository.open(directory);
        expect(
          (await repo.getEntries())
              .singleWhere((e) => e.id == next.id)
              .taskState,
          TaskState.next,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'real file text, PDF preview/text search, metadata, menu and visual reference',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
            'para-real-files-',
          ),
          repo = await LocalWorkspaceRepository.open(
            await Directory.systemTemp.createTemp('para-real-data-'),
            pdfTextExtractor: extractPdfText,
          );
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      try {
        final project = await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Wohnung renovieren',
            goal: 'Räume bezugsfertig',
            dueDate: DateTime(2026, 11, 30),
          ),
        );
        final overview = await repo.create(
          kind: EntryKind.note,
          parentId: project.id,
          draft: const EntryDraft(
            title: 'Überblick',
            body:
                '# Ein Zuhause zum Ankommen\n\nWohnzimmer und Schlafzimmer renovieren, bevor die neuen Möbel kommen.\n\n## Was dazugehört\n\n- Farben und Materialien festlegen\n- Wände vorbereiten und streichen\n- Boden aufarbeiten und Sockelleisten montieren\n\n## Reihenfolge\n\nZuerst das Schlafzimmer, danach das Wohnzimmer. Die Möbel bleiben bis zum Abschluss im Arbeitszimmer.',
          ),
        );
        final planning = await repo.create(
          kind: EntryKind.folder,
          parentId: project.id,
          draft: const EntryDraft(title: 'Planung'),
        );
        await repo.create(
          kind: EntryKind.note,
          parentId: planning.id,
          draft: const EntryDraft(title: 'Raum für Raum', body: 'Raumplanung'),
        );
        await repo.importFile(
          name: 'Budget.csv',
          parentId: planning.id,
          bytes: Stream.value(
            utf8.encode('Posten,Betrag\nFarbe,280 Euro\nReserve,220 Euro'),
          ),
        );
        final materials = await repo.create(
          kind: EntryKind.folder,
          parentId: project.id,
          draft: const EntryDraft(title: 'Unterlagen'),
        );
        final text = await repo.importFile(
          name: 'Farbmuster.txt',
          parentId: materials.id,
          bytes: Stream.value(
            utf8.encode('Salbeigrün bei Tageslicht vergleichen.'),
          ),
        );
        final pdf = await repo.importFile(
          name: 'Angebot Malerbetrieb.pdf',
          parentId: materials.id,
          bytes: Stream.value(samplePdf()),
        );
        await repo.importFile(
          name: 'Materialpaket.zip',
          parentId: materials.id,
          bytes: Stream.value(base64Decode('UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA==')),
        );
        await repo.create(
          kind: EntryKind.project,
          draft: EntryDraft(
            title: 'Portfolio veröffentlichen',
            goal: 'Portfolio online',
            dueDate: DateTime(2026, 12, 15),
          ),
        );
        expect(
          (await repo.getEntries())
              .singleWhere((e) => e.id == pdf.id)
              .searchText,
          contains('Abkleben'),
        );
        await tester.pumpWidget(
          ParaApp(repository: repo, dataDirectory: repo.root.path),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-projects')));
        await tester.pumpAndSettle();
        // Alphabetic project order may select the other project; open the reference explicitly.
        await tester.tap(find.byKey(ValueKey('tree-entry-${project.id}')));
        await tester.pumpAndSettle();
        if (find
            .byKey(ValueKey('tree-entry-${overview.id}'))
            .evaluate()
            .isEmpty) {
          await tester.tap(find.byKey(ValueKey('tree-entry-${project.id}')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(ValueKey('tree-entry-${overview.id}')));
        await tester.pumpAndSettle();
        await captureSurface(tester, 'para-flutter-workspace');
        await tester.tap(find.byKey(ValueKey('tree-entry-${text.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Bearbeiten'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('markdown-body')),
          'Blau und Beige vergleichen.',
        );
        await surfaceShortcut(tester, LogicalKeyboardKey.keyS);
        expect(
          await File(await repo.filePath(text.id)).readAsString(),
          'Blau und Beige vergleichen.',
        );
        await tester.tap(find.byKey(const ValueKey('file-info')));
        await tester.pumpAndSettle();
        expect(find.text('Größe'), findsOneWidget);
        expect(find.text('Ablageort'), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('tree-entry-${pdf.id}')));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(find.byType(PdfViewer), findsOneWidget);
        await surfaceShortcut(tester, LogicalKeyboardKey.keyF);
        await tester.enterText(
          find.byKey(const ValueKey('workspace-search-query')),
          'Abkleben',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('search-result-${pdf.id}')), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('workspace-menu')));
        await tester.pumpAndSettle();
        expect(find.text('Menü'), findsOneWidget);
        expect(find.text('Daten & Sicherung'), findsOneWidget);
        await tester.tap(find.text('Schließen'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await repo.close();
        await repo.root.delete(recursive: true);
        await directory.delete(recursive: true);
      }
    },
  );
}
