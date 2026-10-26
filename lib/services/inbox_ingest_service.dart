import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../data/local_workspace_repository.dart';
import '../domain/ingest.dart';
import '../domain/workspace.dart';
import 'ingest_file_access.dart';
import 'workspace_manager.dart';

/// One active repository and one explicitly approved local source own the worker.
class InboxIngestService extends ChangeNotifier {
  InboxIngestService(
    this.repository,
    this.configurationDirectory, {
    IngestFileAccess? files,
    WorkspaceDirectoryAccess? directoryAccess,
    this.quietPeriod = const Duration(seconds: 3),
    this.scanInterval = const Duration(seconds: 5),
    this.schedule = true,
    this.checkpoint,
  }) : files = files ?? NativeIngestFileAccess(),
       directoryAccess = directoryAccess ?? NativeWorkspaceDirectoryAccess();
  final LocalWorkspaceRepository repository;
  final Directory configurationDirectory;
  final IngestFileAccess files;
  final WorkspaceDirectoryAccess directoryAccess;
  final Duration quietPeriod, scanInterval;
  final bool schedule;
  final Future<void> Function(String phase, IngestJob job)? checkpoint;
  static final _sources = <String>{};
  static const settingKey = 'ingest.sources.v1';
  static const controlName = '.para-ingest';
  Map<String, dynamic>? _configuration;
  String? get sourcePath => _configuration?['path'];
  bool enabled = false, working = false;
  bool get configured => _configuration != null;
  String status = 'Kein Eingangsordner gewählt';
  String? error;
  List<IngestJob> jobs = [];
  final _observed = <String, (String, DateTime)>{};
  RandomAccessFile? _lease;
  String? _leasedPath;
  String? _grantedPath;
  Timer? _timer;
  StreamSubscription<FileSystemEvent>? _watcher;
  Future<void>? _running;
  bool _closed = false;
  String get recoveryPath => p.join(sourcePath!, controlName, 'completed');
  File get _grants =>
      File(p.join(configurationDirectory.path, 'ingest-directory-grants.json'));

  Future<Map<String, dynamic>> _readGrants() async {
    if (!await _grants.exists()) {
      return {'version': 1, 'grants': <String, dynamic>{}};
    }
    final value =
        jsonDecode(await _grants.readAsString()) as Map<String, dynamic>;
    if (value['version'] != 1 || value['grants'] is! Map) {
      throw const WorkspaceException(
        'Lokale Eingangsordnerfreigabe ist unbekannt.',
      );
    }
    return value;
  }

  Future<void> initialize() async {
    try {
      final saved = await repository.readSetting(settingKey);
      if (saved != null) {
        _configuration = jsonDecode(saved) as Map<String, dynamic>;
        if (_configuration!['version'] != 1 ||
            _configuration!['path'] is! String ||
            _configuration!['binding'] is! String) {
          throw const WorkspaceException(
            'Unbekannte Eingangsordner-Einstellung.',
          );
        }
      }
      jobs = await repository.ingestJobs();
      await _recoverCopies();
      if (_configuration?['enabled'] == true) {
        await activate();
      } else if (configured) {
        status = 'Pausiert';
      }
    } catch (failure) {
      error = '$failure';
      status = 'Aufmerksamkeit nötig';
    }
    notifyListeners();
  }

  Future<void> _recoverCopies() async {
    // A backup/copy invalidates source rights, but verified internal bytes remain usable.
    for (final job in jobs.where(
      (j) =>
          j.workspace != repository.root.path ||
          j.binding != _configuration?['binding'],
    )) {
      if (job.phase == 'ready' || job.phase == 'committed') {
        try {
          if (job.phase == 'ready') await repository.publishIngest(job);
          job.phase = 'recovered';
          job.error =
              'Aus Zwischenkopie übernommen; ursprüngliche Quelle wurde nicht angefasst.';
          await repository.saveIngestJob(job);
        } catch (failure) {
          job.error = '$failure';
          await repository.saveIngestJob(job);
        }
      }
    }
  }

  Future<void> configure(WorkspaceLocation selected) async {
    await pause();
    final granted = await directoryAccess.restore(selected);
    try {
      final path = await Directory(granted.path).resolveSymbolicLinks();
      await _validateSource(path);
      final binding = path == sourcePath
          ? _configuration!['binding'] as String
          : const Uuid().v4();
      final grants = await _readGrants();
      (grants['grants'] as Map)[repository.root.path] = {
        'binding': binding,
        'path': path,
        'bookmark': granted.bookmark,
      };
      await configurationDirectory.create(recursive: true);
      final temporary = File('${_grants.path}.tmp');
      await temporary.writeAsString(jsonEncode(grants), flush: true);
      await temporary.rename(_grants.path);
      _configuration = {
        'version': 1,
        'path': path,
        'binding': binding,
        'enabled': false,
      };
      await repository.writeSetting(settingKey, jsonEncode(_configuration));
      error = null;
      status = 'Pausiert';
    } finally {
      await files.releaseDirectory(granted.path);
    }
    notifyListeners();
  }

  Future<void> _validateSource(String source) async {
    final root = await repository.root.resolveSymbolicLinks();
    if (source == root ||
        p.isWithin(root, source) ||
        p.isWithin(source, root)) {
      throw const WorkspaceException(
        'Eingangsordner und Arbeitsbereich dürfen nicht ineinander liegen.',
      );
    }
    var ancestor = source;
    while (true) {
      for (final marker in [
        '.git',
        'workspace.sqlite',
        'backup.json',
        controlName,
      ]) {
        if (marker == controlName && ancestor == source) continue;
        if (await FileSystemEntity.type(
              p.join(ancestor, marker),
              followLinks: false,
            ) !=
            FileSystemEntityType.notFound) {
          throw const WorkspaceException(
            'Kein Repository, Arbeitsbereich, Sicherungs- oder Rückholordner als Eingang.',
          );
        }
      }
      final parent = p.dirname(ancestor);
      if (parent == ancestor) break;
      ancestor = parent;
    }
    final info = await files.stat(source);
    if (!info.directory || info.package) {
      throw const WorkspaceException('Bitte einen Ordner wählen.');
    }
  }

  Future<void> activate() async {
    if (enabled || _closed) return;
    if (!configured) {
      throw const WorkspaceException(
        'Bitte zuerst einen Eingangsordner wählen.',
      );
    }
    final grants = (await _readGrants())['grants'] as Map;
    final grant = grants[repository.root.path] as Map?;
    if (grant == null ||
        grant['binding'] != _configuration!['binding'] ||
        grant['path'] != sourcePath) {
      status = 'Ordner auf diesem Rechner erneut auswählen';
      throw const WorkspaceException(
        'Bitte den Eingangsordner für diesen Arbeitsbereich erneut auswählen.',
      );
    }
    try {
      if (!_sources.add(sourcePath!)) {
        throw const WorkspaceException(
          'Dieser Eingangsordner wird bereits verwendet.',
        );
      }
      _leasedPath = sourcePath;
      final granted = await directoryAccess.restore(
        WorkspaceLocation(sourcePath!, bookmark: grant['bookmark']),
      );
      _grantedPath = granted.path;
      await _validateSource(sourcePath!);
      final control = p.join(sourcePath!, controlName);
      await files.privateDirectory(control);
      final marker = File(p.join(control, 'format.json'));
      if (await marker.exists()) {
        if (jsonDecode(await marker.readAsString())['version'] != 1) {
          throw const WorkspaceException('Unbekannter Rückholbereich.');
        }
      } else {
        if (!await Directory(control).list().isEmpty) {
          throw const WorkspaceException(
            'Vorhandenen fremden Rückholordner nicht übernehmen.',
          );
        }
        await marker.writeAsString(
          '{"format":"para-ingest-source","version":1}',
          flush: true,
        );
      }
      final lockPath = p.join(control, '.lock');
      if (await FileSystemEntity.type(lockPath, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const WorkspaceException('Unsichere Quellensperre.');
      }
      _lease = await File(lockPath).open(mode: FileMode.append);
      await _lease!.lock(FileLock.exclusive);
      enabled = true;
      error = null;
      status = 'Aktiv';
      _configuration!['enabled'] = true;
      await repository.writeSetting(settingKey, jsonEncode(_configuration));
      if (schedule) {
        _timer = Timer.periodic(scanInterval, (_) => unawaited(runOnce()));
        try {
          _watcher = Directory(sourcePath!).watch().listen(
            (_) => unawaited(runOnce()),
            onError: (Object _) {
              status = 'Aktiv – regelmäßiger Ordnerabgleich';
              notifyListeners();
            },
          );
        } catch (_) {
          status = 'Aktiv – regelmäßiger Ordnerabgleich';
        }
        unawaited(runOnce());
      }
    } catch (_) {
      enabled = false;
      await _release();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> pause({bool remember = true}) async {
    enabled = false;
    _timer?.cancel();
    _timer = null;
    await _watcher?.cancel();
    _watcher = null;
    await _running;
    await _release();
    if (remember && _configuration != null) {
      _configuration!['enabled'] = false;
      await repository.writeSetting(settingKey, jsonEncode(_configuration));
    }
    status = configured ? 'Pausiert' : 'Kein Eingangsordner gewählt';
    notifyListeners();
  }

  Future<void> _release() async {
    await _lease?.close();
    _lease = null;
    if (_leasedPath != null) {
      _sources.remove(_leasedPath);
    }
    _leasedPath = null;
    if (_grantedPath != null) await files.releaseDirectory(_grantedPath!);
    _grantedPath = null;
  }

  Future<void> close() async {
    _closed = true;
    await pause(remember: false);
  }

  Future<void> runOnce() async {
    if (!enabled || _closed) return;
    if (_running != null) return _running;
    final pending = _scan();
    _running = pending;
    try {
      await pending;
    } finally {
      _running = null;
    }
  }

  void _checkActive() {
    if (!enabled || _closed) throw const _Paused();
  }

  Future<List<IngestItem>> _manifest(
    String source, {
    List<IngestItem> previous = const [],
  }) async {
    final result = <IngestItem>[];
    Future<void> visit(String path, String relative, String? parent) async {
      _checkActive();
      final name = p.basename(path);
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type != FileSystemEntityType.file &&
          type != FileSystemEntityType.directory) {
        throw WorkspaceException(
          'Verknüpfung oder Spezialdatei nicht übernommen: $name',
        );
      }
      if (name == '.git' ||
          {
            '.app',
            '.photoslibrary',
            '.bundle',
            '.framework',
          }.contains(p.extension(name).toLowerCase())) {
        throw WorkspaceException(
          'Repository oder Dateipaket nicht übernommen: $name',
        );
      }
      if (_unfinished(name)) {
        throw const WorkspaceException(
          'Dateien werden noch geschrieben; später erneut prüfen.',
        );
      }
      final stat = await files.stat(path);
      if (stat.package) {
        throw WorkspaceException('macOS-Dateipaket nicht übernommen: $name');
      }
      final existing = previous.where((e) => e.path == relative).firstOrNull;
      final item = IngestItem(
        id: existing?.id ?? const Uuid().v4(),
        path: relative,
        directory: stat.directory,
        signature: stat.signature,
        parentId: parent,
        size: stat.size,
      );
      result.add(item);
      if (stat.directory) {
        final children = await Directory(
          path,
        ).list(followLinks: false).toList();
        children.sort((a, b) => a.path.compareTo(b.path));
        for (final child in children) {
          if (p.basename(child.path) == '.DS_Store') continue;
          await visit(
            child.path,
            relative.isEmpty
                ? p.basename(child.path)
                : '$relative/${p.basename(child.path)}',
            item.id,
          );
        }
      }
    }

    await visit(source, '', null);
    return result;
  }

  static bool _unfinished(String name) =>
      name.startsWith('.para-') ||
      {
        '.part',
        '.crdownload',
        '.download',
        '.tmp',
      }.contains(p.extension(name).toLowerCase());
  String _fingerprint(List<IngestItem> items) =>
      jsonEncode(items.map((e) => [e.path, e.signature, e.directory]).toList());

  Future<void> _scan() async {
    working = true;
    error = null;
    notifyListeners();
    try {
      final source = sourcePath!;
      await _validateSource(source);
      jobs = await repository.ingestJobs();
      final pending = jobs
          .where(
            (j) =>
                j.binding == _configuration!['binding'] &&
                j.workspace == repository.root.path &&
                j.source == source &&
                j.phase != 'done' &&
                j.phase != 'recovered',
          )
          .toList();
      final children = await Directory(
        source,
      ).list(followLinks: false).toList();
      for (final child in children) {
        _checkActive();
        final name = p.basename(child.path);
        if (name == controlName || name == '.DS_Store' || _unfinished(name)) {
          continue;
        }
        if (pending.any((j) => j.name == name)) continue;
        try {
          final manifest = await _manifest(child.path);
          final fingerprint = _fingerprint(manifest);
          final observed = _observed[name];
          if (observed == null || observed.$1 != fingerprint) {
            _observed[name] = (fingerprint, DateTime.now());
            if (quietPeriod != Duration.zero) continue;
          }
          if (DateTime.now().difference(_observed[name]!.$2) < quietPeriod) {
            continue;
          }
          final job = IngestJob(
            id: const Uuid().v4(),
            binding: _configuration!['binding'],
            workspace: repository.root.path,
            source: source,
            name: name,
            items: manifest,
          );
          await repository.saveIngestJob(job);
          pending.add(job);
        } catch (failure) {
          error = '$failure';
        }
      }
      for (final job in pending) {
        _checkActive();
        try {
          await repository.exclusive(() => _process(job));
        } on _Paused {
          rethrow;
        } catch (failure) {
          job.error = '$failure';
          error = '$failure';
          await repository.saveIngestJob(job);
        }
      }
      jobs = await repository.ingestJobs();
      status = error == null ? 'Aktiv' : 'Aufmerksamkeit nötig';
    } on _Paused {
      /* The journal retains the last durable step. */
    } catch (failure) {
      error = '$failure';
      status = 'Ordner nicht verfügbar / Aufmerksamkeit nötig';
    } finally {
      working = false;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> _process(IngestJob job) async {
    final source = p.join(job.source, job.name);
    if (job.phase == 'preparing') {
      final manifest = await _manifest(source, previous: job.items);
      if (_fingerprint(manifest) != _fingerprint(job.items)) {
        // A changing tree must be stable again before refreshing an unpublished job.
        final fingerprint = _fingerprint(manifest),
            observation = _observed[job.name];
        if (observation == null || observation.$1 != fingerprint) {
          _observed[job.name] = (fingerprint, DateTime.now());
          return;
        }
        if (DateTime.now().difference(observation.$2) < quietPeriod) return;
        job.items = manifest;
        await repository.saveIngestJob(job);
      }
      final stagingRoot = Directory(p.join(repository.root.path, 'ingest'));
      await stagingRoot.create(recursive: true);
      final format = File(p.join(stagingRoot.path, 'format.json'));
      if (await format.exists() &&
          jsonDecode(await format.readAsString())['version'] != 1) {
        throw const WorkspaceException('Unbekanntes Import-Zwischenformat.');
      }
      if (!await format.exists()) {
        await format.writeAsString('{"version":1}', flush: true);
      }
      final stage = await repository.ingestStage(job.id).create();
      for (final item in job.items.where((e) => !e.directory)) {
        _checkActive();
        final copy = File(p.join(stage.path, item.id));
        if (await copy.exists()) await copy.delete();
        final expectedHash = await files.copy(
          item.path.isEmpty ? source : p.join(source, item.path),
          copy.path,
          item.signature,
        );
        item.hash = (await sha256.bind(copy.openRead()).first).toString();
        if (item.hash != expectedHash) {
          throw const WorkspaceException(
            'Prüfsumme der Kopie stimmt nicht mit der Quelle überein; Original bleibt erhalten.',
          );
        }
      }
      if (_fingerprint(await _manifest(source)) != _fingerprint(job.items)) {
        throw const WorkspaceException(
          'Quelle hat sich beim Kopieren geändert; Original bleibt erhalten.',
        );
      }
      job.phase = 'ready';
      job.error = null;
      await repository.saveIngestJob(job);
      await checkpoint?.call('ready', job);
    }
    _checkActive();
    if (job.phase == 'ready') {
      if (_fingerprint(await _manifest(source)) != _fingerprint(job.items)) {
        job.phase = 'preparing';
        job.error = 'Quelle seit der Prüfung verändert; wird erneut geprüft.';
        await repository.saveIngestJob(job);
        return;
      }
      await repository.publishIngest(job);
      await checkpoint?.call('committed', job);
    }
    _checkActive();
    if (job.phase == 'committed') {
      final recovery = Directory(
        p.join(job.source, controlName, 'completed', job.id),
      );
      await recovery.create(recursive: true);
      final original = p.join(recovery.path, job.name);
      if (await FileSystemEntity.type(original, followLinks: false) ==
          FileSystemEntityType.notFound) {
        if (await FileSystemEntity.type(source, followLinks: false) ==
            FileSystemEntityType.notFound) {
          throw const WorkspaceException(
            'Quelle fehlt; Rückholkopie nicht gefunden. Importierte Inhalte bleiben erhalten.',
          );
        }
        if (_fingerprint(await _manifest(source)) != _fingerprint(job.items)) {
          throw const WorkspaceException(
            'Inbox übernommen, Quelle inzwischen verändert: nicht entfernt.',
          );
        }
        await files.move(
          source,
          original,
          job.items.first.signature.split('|').first,
        );
        await checkpoint?.call('moved', job);
      }
      if (_fingerprint(await _manifest(original)) != _fingerprint(job.items)) {
        if (await FileSystemEntity.type(source, followLinks: false) ==
            FileSystemEntityType.notFound) {
          await files.move(
            original,
            source,
            (await files.stat(original)).identity,
          );
        }
        throw const WorkspaceException(
          'Späte Quellenänderung: Original erhalten, Übernahme prüfen.',
        );
      }
      job.phase = 'done';
      job.error = null;
      await repository.saveIngestJob(job);
      final stage = repository.ingestStage(job.id);
      if (await stage.exists()) await stage.delete(recursive: true);
      _observed.remove(job.name);
    }
  }
}

class _Paused implements Exception {
  const _Paused();
}
