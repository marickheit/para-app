import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/domain/workspace.dart';
import 'package:para_workspace/services/inbox_ingest_service.dart';
import 'package:para_workspace/services/ingest_file_access.dart';
import 'package:para_workspace/services/workspace_manager.dart';
import 'package:para_workspace/ui/ingest_settings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native recursive ingest, permission controls, safe copies and source recovery',
    (tester) async {
      final temp = await Directory.systemTemp.createTemp('para-native-ingest-');
      final source = await Directory(p.join(temp.path, 'input')).create();
      final repo = await LocalWorkspaceRepository.open(
        Directory(p.join(temp.path, 'workspace')),
      );
      final native = NativeIngestFileAccess();
      var service = InboxIngestService(
        repo,
        Directory(p.join(temp.path, 'config')),
        quietPeriod: Duration.zero,
        schedule: false,
      );
      try {
        final folder = await Directory(
          p.join(source.path, 'Unterlagen', '2026', 'Leer'),
        ).create(recursive: true);
        final original = File(p.join(folder.parent.path, 'Änderung.md'));
        const bytes = [239, 187, 191, 35, 32, 65, 13, 10];
        await original.writeAsBytes(bytes);
        await service.configure(WorkspaceLocation(source.path));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: IngestSettings(service: service)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pausiert'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('ingest-toggle')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Eingangsordner aktivieren?'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('ingest-confirm')));
        await tester.pumpAndSettle();
        expect(service.enabled, true);
        await service.runOnce();
        await tester.pumpAndSettle();
        final entries = await repo.getEntries();
        expect(entries, hasLength(4));
        final file = entries.singleWhere((e) => e.kind == EntryKind.file);
        expect(ancestorsOf(file, entries).map((e) => e.title), [
          '2026',
          'Unterlagen',
        ]);
        expect(await File(await repo.filePath(file.id)).readAsBytes(), bytes);
        final job = service.jobs.single;
        expect(job.phase, 'done');
        expect(await original.exists(), false);
        expect(
          await File(
            p.join(
              service.recoveryPath,
              job.id,
              'Unterlagen',
              '2026',
              'Änderung.md',
            ),
          ).readAsBytes(),
          bytes,
        );
        await tester.tap(find.byKey(const ValueKey('ingest-toggle')));
        await tester.pumpAndSettle();
        expect(service.enabled, false);
        await File(p.join(source.path, 'later.txt')).writeAsString('queued');
        await service.runOnce();
        expect(await repo.getEntries(), hasLength(4));

        // The native copy rejects replaced sources and the move never overwrites.
        final one = await File(
          p.join(temp.path, 'one.txt'),
        ).writeAsString('one');
        final info = await native.stat(one.path);
        await one.writeAsString('changed');
        await expectLater(
          native.copy(one.path, p.join(temp.path, 'copy.txt'), info.signature),
          throwsA(isA<PlatformException>()),
        );
        final two = await File(
          p.join(temp.path, 'two.txt'),
        ).writeAsString('two');
        await expectLater(
          native.move(
            one.path,
            two.path,
            (await native.stat(one.path)).identity,
          ),
          throwsA(isA<PlatformException>()),
        );
        expect(await two.readAsString(), 'two');
        final link = await Link(p.join(temp.path, 'link')).create(one.path);
        await expectLater(
          native.stat(link.path),
          throwsA(isA<PlatformException>()),
        );
        await expectLater(
          native.copy(
            link.path,
            p.join(temp.path, 'copy-link.txt'),
            (await native.stat(one.path)).signature,
          ),
          throwsA(isA<PlatformException>()),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await service.activate();
        await service.close();
        service.dispose();
        service = InboxIngestService(
          repo,
          Directory(p.join(temp.path, 'config')),
          quietPeriod: Duration.zero,
          schedule: false,
        );
        await service.initialize();
        expect(service.enabled, true);
        await service.runOnce();
        expect(await repo.getEntries(), hasLength(5));
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await service.close();
        service.dispose();
        await repo.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
