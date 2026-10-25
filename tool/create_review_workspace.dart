import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:para_workspace/data/local_workspace_repository.dart';
import 'package:para_workspace/data/workspace_storage.dart';
import 'package:para_workspace/domain/workspace.dart';

/// Synthetic review data only. Never accepts an existing nonempty directory.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError(
      'Bitte einen leeren Review-Konfigurationsordner angeben.',
    );
  }
  final configuration = Directory(arguments.single);
  if (!await WorkspaceStorage.isEmpty(configuration)) {
    throw StateError('Review-Ziel muss leer sein.');
  }
  await configuration.create(recursive: true);
  final root = Directory(p.join(configuration.path, 'workspace'));
  final repo = await LocalWorkspaceRepository.open(root);
  try {
    final work = (await repo.getContexts()).firstWhere(
      (e) => e.name == 'Arbeit',
    );
    final home = (await repo.getContexts()).firstWhere(
      (e) => e.name == 'Zuhause',
    );
    final computer = await repo.saveContext(
      name: 'Computer',
      color: contextColors[1],
    );
    final project = await repo.create(
      kind: EntryKind.project,
      draft: EntryDraft(
        title: 'Portfolio veröffentlichen',
        goal: 'Portfolio online',
        dueDate: DateTime(2026, 12, 1),
      ),
    );
    await repo.create(
      kind: EntryKind.task,
      parentId: project.id,
      draft: EntryDraft(
        title: 'Startseite überarbeiten',
        taskState: TaskState.next,
        contextIds: [work.id, computer.id],
        estimatedMinutes: 30,
        energy: EnergyLevel.medium,
      ),
    );
    await repo.create(
      kind: EntryKind.task,
      draft: EntryDraft(
        title: 'Unterlagen sortieren',
        taskState: TaskState.next,
        contextIds: [home.id],
        estimatedMinutes: 15,
        energy: EnergyLevel.low,
      ),
    );
    await repo.create(
      kind: EntryKind.task,
      draft: const EntryDraft(
        title: 'Noch ohne Angaben',
        taskState: TaskState.next,
      ),
    );
    await repo.create(
      kind: EntryKind.note,
      parentId: project.id,
      draft: const EntryDraft(
        title: 'Review-Hinweise',
        body:
            '# Review 0.6\n\nDieser Arbeitsbereich enthält ausschließlich Beispieldaten.\n\n'
            'Menü → Einstellungen: Kontexte, Farben und Reihenfolge.\n'
            'Daten & Sicherung: vollständige Arbeitsbereiche öffnen, neu anlegen oder kopieren.\n'
            'Nächste Aktionen: Chips anklicken über die Aufgabe bearbeiten; Filter neben der Überschrift.\n',
      ),
    );
    await repo.writeSetting(
      'session.v1',
      jsonEncode({
        'version': 1,
        'view': 'actions',
        'tab': 'tasks',
        'railExpanded': false,
        'sidebarVisible': true,
        'filter': const TaskFilter().toJson(),
      }),
    );
    await File(
      p.join(configuration.path, 'workspace-location.json'),
    ).writeAsString(
      jsonEncode({'version': 1, 'path': repo.root.path, 'bookmark': null}),
      flush: true,
    );
    stdout.writeln('Review-Arbeitsbereich erstellt: ${repo.root.path}');
  } finally {
    await repo.close();
  }
}
