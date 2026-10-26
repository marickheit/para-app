import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/app.dart';
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'target_features.dart' show captureSurface;

void registerRecoveryFeatureTests() {
  testWidgets(
    'text history restores safely and linked trash is recoverable and can be emptied',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'para-recovery-ui-',
      );
      var repo = await LocalWorkspaceRepository.open(directory);
      tester.view.physicalSize = const Size(1220, 850);
      tester.view.devicePixelRatio = 1;
      try {
        final target = await repo.create(
          kind: EntryKind.note,
          draft: const EntryDraft(
            title: 'Raumideen',
            body: 'Ursprüngliche Ideen.',
          ),
        );
        final source = await repo.create(
          kind: EntryKind.note,
          draft: EntryDraft(
            title: 'Überblick',
            body: '# Übersicht\n\n${markdownLink(target)}',
          ),
        );
        final snapshot = await repo.readNote(target.id);
        await repo.save(
          id: target.id,
          expectedRevision: target.revision,
          expectedBodyHash: snapshot.hash,
          draft: const EntryDraft(title: 'Raumideen', body: 'Neuere Ideen.'),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            child: ParaApp(repository: repo, dataDirectory: directory.path),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(find.byKey(const ValueKey('nav-trash'))).dy,
          greaterThan(
            tester.getCenter(find.byKey(const ValueKey('nav-tasks'))).dy,
          ),
        );
        await tester.tap(find.byKey(ValueKey('tree-entry-${target.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Bearbeiten'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('markdown-body')),
          'Ungespeicherter Entwurf.',
        );
        await tester.tap(find.byKey(const ValueKey('note-history')));
        await tester.pumpAndSettle();
        expect(find.text('Änderungen speichern?'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Verwerfen'));
        await tester.pumpAndSettle();
        expect(find.text('Versionsverlauf'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Schließen'));
        await tester.pumpAndSettle();
        expect(find.text('Ungespeicherter Entwurf.'), findsNothing);
        expect((await repo.readNote(target.id)).text, 'Neuere Ideen.');
        await tester.tap(find.byKey(const ValueKey('note-history')));
        await tester.pumpAndSettle();
        expect(find.text('Versionsverlauf'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('version-picker')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Stand 1').last);
        await tester.pumpAndSettle();
        expect(find.text('Ursprüngliche Ideen.'), findsOneWidget);
        await captureSurface(tester, 'para-0.5-note-history');
        await tester.tap(find.byKey(const ValueKey('restore-version')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Wiederherstellen'));
        await tester.pumpAndSettle();
        expect((await repo.readNote(target.id)).text, 'Ursprüngliche Ideen.');
        expect((await repo.noteVersions(target.id)).map((e) => e.body), [
          'Ursprüngliche Ideen.',
          'Neuere Ideen.',
          'Ursprüngliche Ideen.',
        ]);
        expect(find.text('Ursprüngliche Ideen.'), findsOneWidget);

        final row = find.byKey(ValueKey('tree-entry-${target.id}'));
        await tester.tapAt(
          tester.getCenter(row),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        expect(find.text('In Papierkorb'), findsOneWidget);
        expect(find.text('Löschen'), findsNothing);
        await tester.tap(find.text('In Papierkorb'));
        await tester.pumpAndSettle();
        expect((await repo.getTrash()).single.id, target.id);
        await tester.tap(find.byKey(ValueKey('tree-entry-${source.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Raumideen').last);
        await tester.pumpAndSettle();
        expect(find.text('Im Papierkorb · schreibgeschützt'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Bearbeiten'), findsNothing);
        await captureSurface(tester, 'para-0.5-trash');
        await tester.tap(find.byKey(const ValueKey('note-history')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('restore-version')),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Schließen'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('restore-trash')));
        await tester.pumpAndSettle();
        expect(await repo.getTrash(), isEmpty);
        expect(find.byKey(ValueKey('tree-entry-${target.id}')), findsOneWidget);

        await repo.trash(target.id);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-trash')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('empty-trash')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('1 anderer Inhalt verweist darauf'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
        await tester.pumpAndSettle();
        expect(await repo.getTrash(), hasLength(1));
        await tester.tap(find.byKey(const ValueKey('empty-trash')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-purge')));
        await tester.pumpAndSettle();
        expect(await repo.getTrash(), isEmpty);
        expect(
          tester
              .widget<TextButton>(find.byKey(const ValueKey('empty-trash')))
              .onPressed,
          isNull,
        );
        expect(find.text('Der Papierkorb ist leer.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        repo = await LocalWorkspaceRepository.open(directory);
        expect((await repo.getEntries()).single.id, source.id);
        expect(await repo.getTrash(), isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
        await directory.delete(recursive: true);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );

  testWidgets('restoring a nested trash item offers another destination', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'para-trash-destination-ui-',
    );
    final repo = await LocalWorkspaceRepository.open(directory);
    tester.view.physicalSize = const Size(1220, 850);
    tester.view.devicePixelRatio = 1;
    try {
      final folder = await repo.create(
        kind: EntryKind.folder,
        draft: const EntryDraft(title: 'Unterlagen'),
      );
      final child = await repo.create(
        kind: EntryKind.note,
        parentId: folder.id,
        draft: const EntryDraft(title: 'Brief', body: 'Wichtiger Text.'),
      );
      await repo.trash(folder.id);
      await tester.pumpWidget(
        RepaintBoundary(
          child: ParaApp(repository: repo, dataDirectory: directory.path),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-trash')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('trash-entry-${child.id}')), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('trash-toggle-${folder.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('trash-entry-${child.id}')), findsNothing);
      await tester.tap(find.byKey(ValueKey('trash-toggle-${folder.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('trash-entry-${child.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('restore-trash')));
      await tester.pumpAndSettle();
      expect(find.text('Verschieben nach'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Ressourcen'));
      await tester.pumpAndSettle();
      final restored = (await repo.getEntries()).single;
      expect(restored.id, child.id);
      expect(restored.section, ParaSection.resources);
      expect(restored.parentId, isNull);
      expect((await repo.getTrash()).single.id, folder.id);
      expect(find.text('Wichtiger Text.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.close();
      await directory.delete(recursive: true);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
