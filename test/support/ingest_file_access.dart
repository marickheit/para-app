import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:para_workspace/services/ingest_file_access.dart';

/// Unit tests use real temporary files; native implementations are covered by
/// the desktop integration test, not by a method-channel mock.
class TestIngestFileAccess implements IngestFileAccess {
  Future<void> Function(String source)? afterCopy;
  bool corruptCopy = false;
  @override
  Future<IngestFileInfo> stat(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.directory) {
      throw StateError('Not a regular file/directory');
    }
    final result = await Process.run(
      '/usr/bin/stat',
      Platform.isMacOS ? ['-f', '%d:%i', path] : ['-c', '%d:%i', '--', path],
    );
    if (result.exitCode != 0) throw StateError('stat failed');
    final identity = (result.stdout as String).trim();
    final value = await FileStat.stat(path);
    return IngestFileInfo(
      identity,
      '$identity|${value.modified.microsecondsSinceEpoch}|${value.size}|${value.type}',
      type == FileSystemEntityType.directory,
      value.size,
    );
  }

  @override
  Future<String> copy(
    String source,
    String destination,
    String signature,
  ) async {
    if ((await stat(source)).signature != signature) {
      throw StateError('Changed before copy');
    }
    final expectedHash = (await sha256.bind(File(source).openRead()).first)
        .toString();
    await File(source).copy(destination);
    await afterCopy?.call(source);
    if ((await stat(source)).signature != signature) {
      throw StateError('Changed while copying');
    }
    if (corruptCopy) await File(destination).writeAsString('corrupt');
    return expectedHash;
  }

  @override
  Future<void> move(String source, String destination, String identity) async {
    final value = await stat(source);
    if (value.identity != identity ||
        await FileSystemEntity.type(destination, followLinks: false) !=
            FileSystemEntityType.notFound) {
      throw StateError('Move rejected');
    }
    if (value.directory) {
      await Directory(source).rename(destination);
    } else {
      await File(source).rename(destination);
    }
  }

  @override
  Future<void> privateDirectory(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.directory) {
      throw StateError('Unsafe directory');
    }
    await Directory(path).create(recursive: true);
  }

  @override
  Future<void> releaseDirectory(String path) async {}
}
