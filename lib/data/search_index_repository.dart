part of 'local_workspace_repository.dart';

// Only derived data: old workspaces/exports need no authoritative migration.
// Bump the key/version when extraction or link parsing changes.
extension _SearchIndex on LocalWorkspaceRepository {
  static const _indexPrefix = 'search-index.v1.';
  String _indexKey(String id) => '$_indexPrefix$id';
  File _indexSource(EntryRow row) =>
      row.kind == EntryKind.file.name ? _attachment(row) : _note(row.id);
  bool _pdf(EntryRow row) =>
      row.kind == EntryKind.file.name &&
      p.extension(row.fileName ?? '').toLowerCase() == '.pdf';
  bool _markdown(EntryRow row) =>
      row.kind != EntryKind.file.name || isMarkdownName(row.fileName ?? '');

  Future<String> _indexSignature(EntryRow row) async {
    final file = _indexSource(row);
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw const FileSystemException('Inhaltsdatei nicht verfügbar');
    }
    // Root-independent for exports/copies. ctime catches ordinary same-size
    // rewrites with restored mtime; signatures are not content hashes.
    return jsonEncode({
      'version': 1,
      'path': p.relative(file.path, from: root.path),
      'size': stat.size,
      'modified': stat.modified.microsecondsSinceEpoch,
      'changed': stat.changed.microsecondsSinceEpoch,
      if (_pdf(row))
        'pdf': _pdfTextExtractor != null ? 'pdfrx-text-100-v1' : 'none',
    });
  }

  Future<void> _storeSignature(String id, String signature) => database
      .into(database.workspaceSettings)
      .insertOnConflictUpdate(
        WorkspaceSettingsCompanion.insert(key: _indexKey(id), value: signature),
      );

  void _indexNotify(bool updating) {
    _indexStatus = SearchIndexStatus(
      updating: updating,
      failures: _indexFailures.length,
    );
    if (!_indexChanges.isClosed) _indexChanges.add(_indexStatus);
  }

  void _startIndex() {
    _indexScan = true;
    _scheduleIndex();
  }

  void _scheduleIndex([String? id]) {
    if (_closed) return;
    if (id != null) _indexRequests.add(id);
    if (_indexFuture != null) return;
    _indexNotify(true);
    // Yield so open() and the first UI build do not wait for extraction.
    // Import/save callers run inside the mutation zone. The worker must not
    // inherit that zone, otherwise its later _write could bypass serialization.
    _indexFuture = runZoned(
      () => Future<void>.delayed(Duration.zero, _drainIndex),
      zoneValues: {_operationZone: null},
    );
  }

  Future<void> _drainIndex() async {
    final attempts = <String, int>{};
    try {
      if (_indexScan && !_closed) {
        _indexScan = false;
        final rows = await database.select(database.entries).get();
        if (_closed) return;
        _indexRequests.addAll(rows.map((row) => row.id));
      }
      while (!_closed && _indexRequests.isNotEmpty) {
        final id = _indexRequests.first;
        _indexRequests.remove(id);
        attempts[id] = (attempts[id] ?? 0) + 1;
        try {
          final stale = await _reconcileEntry(id);
          if (_closed) return;
          if (stale) {
            if (attempts[id]! < 2) {
              _indexRequests.add(id);
            } else {
              _indexFailures.add(id);
            }
          } else {
            _indexFailures.remove(id);
          }
        } catch (_) {
          if (_closed) return;
          _indexFailures.add(id);
        }
        _indexNotify(true);
        await Future<void>.delayed(Duration.zero);
      }
    } catch (_) {
      if (!_closed) _indexFailures.add('scan');
    } finally {
      _indexFuture = null;
      if (!_closed) _indexNotify(false);
    }
  }

  Future<EntryRow?> _indexRow(String id) => (database.select(
    database.entries,
  )..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<String> _extractIndexText(EntryRow row) async {
    final file = _indexSource(row);
    if (row.kind != EntryKind.file.name) return file.readAsString();
    if (isSearchableTextName(row.fileName ?? '')) {
      // null means a deliberately unsupported encoding/size, not an IO error.
      return await readSmallTextFile(file) ?? '';
    }
    if (_pdf(row) && _pdfTextExtractor == null) return row.searchText;
    if (_pdf(row) &&
        _pdfTextExtractor != null &&
        await file.length() <= 100 * 1024 * 1024) {
      final text = await _pdfTextExtractor(file.path);
      if (text == null) {
        throw const FileSystemException('PDF-Text konnte nicht gelesen werden');
      }
      return text;
    }
    return '';
  }

  Future<void> _commitIndex(EntryRow row, String body, String signature) =>
      database.transaction(() async {
        if (body != row.searchText) {
          await (database.update(database.entries)
                ..where((e) => e.id.equals(row.id)))
              .write(EntriesCompanion(searchText: Value(body)));
        }
        if (_markdown(row)) {
          await _indexLinks(row.id, body);
        } else {
          // Renaming Markdown to another format must remove its old links.
          await (database.delete(
            database.entryLinks,
          )..where((e) => e.sourceId.equals(row.id))).go();
        }
        await _storeSignature(row.id, signature);
      });

  /// Returns true when a concurrent change requires a fresh attempt.
  Future<bool> _reconcileEntry(String id) async {
    if (_closed) return false;
    final row = await _indexRow(id);
    if (_closed || row == null) return false;
    final signature = await _indexSignature(row);
    if (_closed) return false;
    final cached = await readSetting(_indexKey(id));
    if (_closed) return false;
    final fromCache = cached == signature;
    String? body;
    if (fromCache) {
      if (!_markdown(row)) return false;
      // Re-resolve cached Markdown links: a previously missing target may now
      // exist. This reads no file and never drops links of another source.
      body = row.searchText;
    } else {
      // Closing cancels the consumer. The native extractor may finish later;
      // its result has no database access and cannot commit into another root.
      final cancelled = Completer<String?>();
      final subscription = _indexCancel.stream.listen((_) {
        if (!cancelled.isCompleted) cancelled.complete(null);
      });
      try {
        body = await Future.any<String?>([
          _extractIndexText(row),
          cancelled.future,
        ]);
      } finally {
        // Release each cancellation listener after its job; do not retain every
        // completed document/text until this repository is eventually closed.
        await subscription.cancel();
      }
    }
    if (_closed || body == null) return false;
    return _write(() async {
      if (_closed) return false;
      final current = await _indexRow(id);
      if (current == null) return false;
      if (current.revision != row.revision ||
          current.fileName != row.fileName ||
          current.kind != row.kind ||
          await _indexSignature(current) != signature) {
        return true;
      }
      // An import may have populated the cached text after our row snapshot,
      // without changing its authoritative revision. Re-resolve live cached
      // text rather than restoring the older snapshot in that case.
      await _commitIndex(
        current,
        fromCache ? current.searchText : body!,
        signature,
      );
      return false;
    });
  }

  /// Text edits/imports stay immediately searchable. PDFs use the same worker
  /// as startup, so extraction never occupies the exclusive mutation queue.
  Future<void> _indexFile(EntryRow row) async {
    if (_pdf(row)) {
      _scheduleIndex(row.id);
      return;
    }
    try {
      final signature = await _indexSignature(row);
      final body = await _extractIndexText(row);
      if (await _indexSignature(row) == signature) {
        await _commitIndex(row, body, signature);
        _indexFailures.remove(row.id);
      } else {
        _scheduleIndex(row.id);
      }
    } catch (_) {
      _indexFailures.add(row.id);
      _scheduleIndex(row.id);
    }
  }
}
