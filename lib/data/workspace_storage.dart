import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import '../domain/workspace.dart';
import '../domain/workspace_format.dart';
export '../domain/workspace_format.dart';

class WorkspaceLease {
  WorkspaceLease(this.root, this._file, this._key);
  final Directory root;
  final RandomAccessFile _file;
  final String _key;
  String? migrationBackup;
  bool _closed = false;
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _file.unlock();
    } finally {
      await _file.close();
      WorkspaceStorage._open.remove(_key);
    }
  }
}

class WorkspaceStorage {
  static final _open = <String>{};

  static Future<bool> isEmpty(Directory root) async {
    if (!await root.exists()) return true;
    await for (final entity in root.list()) {
      if (p.basename(entity.path) == '.DS_Store') continue;
      return false;
    }
    return true;
  }

  static Future<WorkspaceLease> acquire(
    Directory root, {
    bool create = true,
  }) async {
    if (!await root.exists()) {
      if (!create) {
        throw const WorkspaceException(
          'Der Arbeitsbereich ist nicht verfügbar. Bitte Laufwerk verbinden oder den Ordner erneut auswählen.',
        );
      }
      await root.create(recursive: true);
    }
    final canonical = await root.resolveSymbolicLinks();
    if (await File(p.join(canonical, '.para-transfer')).exists()) {
      throw const WorkspaceException(
        'Dieser Ordner enthält eine unvollständige Übernahme. Bitte den ursprünglichen Arbeitsbereich oder eine vollständige Sicherung öffnen.',
      );
    }
    final dbFile = File(p.join(canonical, 'workspace.sqlite'));
    if (!await dbFile.exists()) {
      if (!create) {
        throw const WorkspaceException(
          'Dieser Ordner enthält keinen P.A.R.A.-Arbeitsbereich.',
        );
      }
      await for (final entity in Directory(canonical).list()) {
        final name = p.basename(entity.path);
        if ({'.DS_Store', '.para.lock'}.contains(name)) continue;
        if (entity is Directory &&
            {'notes', 'files'}.contains(name) &&
            await entity.list().isEmpty) {
          continue;
        }
        throw const WorkspaceException(
          'Der Ordner ist nicht leer und enthält keine Arbeitsbereichsdatenbank. Vorhandene Dateien bleiben unverändert.',
        );
      }
    }
    if (!_open.add(canonical)) {
      throw const WorkspaceException(
        'Dieser Arbeitsbereich ist bereits geöffnet.',
      );
    }
    RandomAccessFile? file;
    try {
      file = await File(
        p.join(canonical, '.para.lock'),
      ).open(mode: FileMode.append);
      await file.lock(FileLock.exclusive);
      final lease = WorkspaceLease(Directory(canonical), file, canonical);
      final manifest = File(p.join(canonical, 'backup.json'));
      if (await manifest.exists()) {
        final value = jsonDecode(await manifest.readAsString());
        if (value['format'] != 'para-workspace' ||
            ![1, 2, 3].contains(value['version'])) {
          throw const WorkspaceException(
            'Unbekanntes Sicherungsformat; keine Daten verändert.',
          );
        }
      }
      final ingest = Directory(p.join(canonical, 'ingest'));
      if (await FileSystemEntity.type(ingest.path, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const WorkspaceException(
          'Verknüpfter Import-Zwischenordner nicht zulässig.',
        );
      }
      if (await ingest.exists() && !await ingest.list().isEmpty) {
        final format = File(p.join(ingest.path, 'format.json'));
        if (!await format.exists() ||
            jsonDecode(await format.readAsString())['version'] != 1) {
          throw const WorkspaceException(
            'Unbekanntes Import-Zwischenformat; keine Daten verändert.',
          );
        }
      }
      if (await dbFile.exists()) {
        final db = sqlite3.open(dbFile.path, mode: OpenMode.readOnly);
        try {
          final version =
              db.select('PRAGMA user_version').single.values.single as int;
          if (version < 1 || version > workspaceSchemaVersion) {
            throw WorkspaceException(
              'Dieser Arbeitsbereich verwendet Datenformat $version. Diese App unterstützt 1–$workspaceSchemaVersion; es wurden keine Inhalte zurückgesetzt.',
            );
          }
          if (db
              .select('PRAGMA quick_check')
              .any((r) => r.values.single != 'ok')) {
            throw const WorkspaceException(
              'Die Datenbank ist beschädigt. Bitte eine Sicherung auswählen.',
            );
          }
          db.select('SELECT id, kind, file_name FROM entries LIMIT 1');
          for (final row in db.select(
            'SELECT id, kind, file_name, task_state, section FROM entries',
          )) {
            final id = row['id'] as String;
            final name = row['file_name'] as String?;
            if (entryIdFromLink(entryLink(id)) == null ||
                !EntryKind.values.any((e) => e.name == row['kind']) ||
                !TaskState.values.any((e) => e.name == row['task_state']) ||
                !ParaSection.values.any((e) => e.name == row['section']) ||
                row['kind'] == 'file' &&
                    (name == null ||
                        name.isEmpty ||
                        p.basename(name) != name ||
                        name.contains('\\'))) {
              throw const WorkspaceException(
                'Der Arbeitsbereich enthält unbekannte Inhaltsdaten oder ungültige Dateipfade.',
              );
            }
            final stored = File(
              row['kind'] == 'file'
                  ? p.join(canonical, 'files', id, name!)
                  : p.join(canonical, 'notes', '$id.md'),
            );
            if (await stored.exists() &&
                !p.isWithin(canonical, await stored.resolveSymbolicLinks())) {
              throw const WorkspaceException(
                'Eine Inhaltsdatei verweist aus dem Arbeitsbereich heraus. Externe Verknüpfungen werden nicht automatisch übernommen.',
              );
            }
          }
          if (version < workspaceSchemaVersion) {
            lease.migrationBackup = await _backupBeforeMigration(
              Directory(canonical),
              db,
              version,
            );
          }
        } finally {
          db.close();
        }
      }
      return lease;
    } catch (error) {
      if (file != null) {
        await file.close();
      }
      _open.remove(canonical);
      if (error is WorkspaceException) rethrow;
      if (error is FileSystemException) {
        throw const WorkspaceException(
          'Der Arbeitsbereich ist gesperrt oder nicht beschreibbar. Bitte andere App-Instanzen schließen und Ordnerrechte prüfen.',
        );
      }
      throw WorkspaceException(
        'Der Arbeitsbereich konnte nicht geprüft werden: $error',
      );
    }
  }

  static Future<void> copyTree(Directory source, Directory target) async {
    await target.create(recursive: true);
    if (!await source.exists()) return;
    await for (final entity in source.list(followLinks: false)) {
      final destination = p.join(target.path, p.basename(entity.path));
      if (entity is File) {
        await entity.copy(destination);
      } else if (entity is Directory) {
        await copyTree(entity, Directory(destination));
      } else {
        throw const WorkspaceException(
          'Verknüpfte Dateisystempfade können nicht automatisch übernommen werden.',
        );
      }
    }
  }

  static Future<String> _backupBeforeMigration(
    Directory root,
    Database db,
    int schema,
  ) async {
    final parent = await Directory(
      p.join(root.path, '.migration-backups'),
    ).create();
    final id = const Uuid().v4();
    final temporary = await Directory(
      p.join(parent.path, '.preparing-$id'),
    ).create();
    try {
      final destination = sqlite3.open(
        p.join(temporary.path, 'workspace.sqlite'),
      );
      try {
        await db.backup(destination).drain<void>();
      } finally {
        destination.close();
      }
      for (final name in ['notes', 'files', 'ingest']) {
        await copyTree(
          Directory(p.join(root.path, name)),
          Directory(p.join(temporary.path, name)),
        );
      }
      for (final row in db.select('SELECT id, kind, file_name FROM entries')) {
        final id = row['id'] as String;
        if (entryIdFromLink(entryLink(id)) == null) {
          throw const WorkspaceException(
            'Eine Inhaltskennung ist ungültig. Migration abgebrochen.',
          );
        }
        final name = row['file_name'] as String?;
        if (name != null && (p.basename(name) != name || name.contains('\\'))) {
          throw const WorkspaceException('Ungültiger gespeicherter Dateipfad.');
        }
        final path = row['kind'] == 'file'
            ? p.join('files', id, name!)
            : p.join('notes', '$id.md');
        if (!await File(p.join(temporary.path, path)).exists()) {
          throw const WorkspaceException(
            'Eine Inhaltsdatei fehlt. Vor der Migration bitte den Arbeitsbereich oder eine vollständige Sicherung prüfen.',
          );
        }
      }
      await File(p.join(temporary.path, 'backup.json')).writeAsString(
        jsonEncode({
          'format': 'para-workspace',
          'version': 2,
          'schemaVersion': schema,
          'beforeAppVersion': workspaceAppVersion,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        ':',
        '-',
      );
      return (await temporary.rename(
        p.join(parent.path, 'Schema-$schema-$stamp-$id'),
      )).path;
    } catch (_) {
      if (await temporary.exists()) await temporary.delete(recursive: true);
      rethrow;
    }
  }
}
