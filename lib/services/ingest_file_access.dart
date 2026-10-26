import 'dart:io';
import 'package:flutter/services.dart';

class IngestFileInfo {
  const IngestFileInfo(
    this.identity,
    this.signature,
    this.directory,
    this.size, {
    this.package = false,
  });
  final String identity, signature;
  final bool directory;
  final int size;
  final bool package;
}

abstract class IngestFileAccess {
  Future<IngestFileInfo> stat(String path);
  Future<String> copy(String source, String destination, String signature);
  Future<void> move(String source, String destination, String identity);
  Future<void> privateDirectory(String path);
  Future<void> releaseDirectory(String path);
}

class NativeIngestFileAccess implements IngestFileAccess {
  static const channel = MethodChannel('para.workspace/directory');
  @override
  Future<IngestFileInfo> stat(String path) async {
    final value = (await channel.invokeMapMethod<String, dynamic>(
      'ingestStat',
      {'path': path},
    ))!;
    return IngestFileInfo(
      value['identity'],
      value['signature'],
      value['directory'],
      value['size'],
      package: value['package'] == true,
    );
  }

  @override
  Future<String> copy(
    String source,
    String destination,
    String signature,
  ) async => (await channel.invokeMethod<String>('ingestCopy', {
    'source': source,
    'destination': destination,
    'signature': signature,
  }))!;
  @override
  Future<void> move(String source, String destination, String identity) =>
      channel.invokeMethod('ingestMove', {
        'source': source,
        'destination': destination,
        'identity': identity,
      });
  @override
  Future<void> privateDirectory(String path) =>
      channel.invokeMethod('preparePrivateDirectory', {'path': path});
  @override
  Future<void> releaseDirectory(String path) async {
    if (Platform.isMacOS) {
      await channel.invokeMethod('releaseDirectory', {'path': path});
    }
  }
}
