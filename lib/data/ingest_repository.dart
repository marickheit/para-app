part of 'local_workspace_repository.dart';

extension IngestRepository on LocalWorkspaceRepository {
  Directory ingestStage(String jobId) {
    if (entryIdFromLink(entryLink(jobId)) == null) {
      throw const WorkspaceException('Ungültige Importkennung.');
    }
    return Directory(p.join(root.path, 'ingest', jobId));
  }

  Future<List<IngestJob>> ingestJobs() => _write(
    () async => (await database.select(database.ingestJobs).get())
        .map(
          (row) => IngestJob.fromJson(
            jsonDecode(row.payload) as Map<String, dynamic>,
          ),
        )
        .toList(),
  );

  Future<void> saveIngestJob(IngestJob job) => _write(() async {
    await database
        .into(database.ingestJobs)
        .insertOnConflictUpdate(
          IngestJobsCompanion.insert(
            id: job.id,
            payload: jsonEncode(job.toJson()),
          ),
        );
  });

  /// Only verified snapshots enter the visible tree; the journal commit is atomic.
  Future<void> publishIngest(IngestJob job) => _write(() async {
    final stored = await (database.select(
      database.ingestJobs,
    )..where((e) => e.id.equals(job.id))).getSingle();
    final phase = IngestJob.fromJson(jsonDecode(stored.payload)).phase;
    if (phase == 'committed' || phase == 'done' || phase == 'recovered') {
      job.phase = phase;
      return;
    }
    if (phase != 'ready') {
      throw const WorkspaceException('Import ist noch nicht geprüft.');
    }
    final existingIds = (await database.select(database.entries).get())
        .map((e) => e.id)
        .toSet();
    if (job.items.any((e) => existingIds.contains(e.id))) {
      throw const WorkspaceException(
        'Importkennung bereits belegt; vorhandene Inhalte bleiben unverändert.',
      );
    }
    for (final item in job.items) {
      if (item.directory) {
        final existing = _note(item.id);
        if (await existing.exists() && await existing.length() != 0) {
          throw const WorkspaceException(
            'Vorhandene Textdatei nicht als Importordner überschreiben.',
          );
        }
        await _writeBody(item.id, '');
      } else {
        final staged = File(p.join(ingestStage(job.id).path, item.id));
        if (!await staged.exists() ||
            (await sha256.bind(staged.openRead()).first).toString() !=
                item.hash ||
            await staged.length() != item.size) {
          throw const WorkspaceException(
            'Import-Zwischenkopie fehlt oder ist verändert.',
          );
        }
        final folder = await Directory(
          p.join(root.path, 'files', item.id),
        ).create(recursive: true);
        final name = item.path.isEmpty ? job.name : p.basename(item.path);
        final target = File(p.join(folder.path, name));
        if (await target.exists()) {
          if ((await sha256.bind(target.openRead()).first).toString() !=
              item.hash) {
            throw const WorkspaceException(
              'Importziel ist verändert; Quelle bleibt erhalten.',
            );
          }
        } else {
          final temporary = File(p.join(folder.path, '.importing'));
          final sink = temporary.openWrite();
          try {
            await sink.addStream(staged.openRead());
            await sink.flush();
          } finally {
            await sink.close();
          }
          final fd = await temporary.open(mode: FileMode.append);
          try {
            await fd.flush();
          } finally {
            await fd.close();
          }
          await temporary.rename(target.path);
        }
      }
    }
    final now = _now().toUtc();
    await database.transaction(() async {
      for (final item in job.items) {
        final name = item.path.isEmpty ? job.name : p.basename(item.path);
        await database
            .into(database.entries)
            .insert(
              EntriesCompanion.insert(
                id: item.id,
                title: name,
                kind: item.directory ? 'folder' : 'file',
                section: 'inbox',
                parentId: Value(item.parentId),
                fileName: Value(item.directory ? null : name),
                fileSize: Value(item.directory ? null : item.size),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      final committed = job.toJson()..['phase'] = 'committed';
      committed['error'] = null;
      await database
          .into(database.ingestJobs)
          .insertOnConflictUpdate(
            IngestJobsCompanion.insert(
              id: job.id,
              payload: jsonEncode(committed),
            ),
          );
    });
    job.phase = 'committed';
    job.error = null;
    // Derived search data cannot roll back a successful content commit.
    for (final item in job.items.where((e) => !e.directory)) {
      try {
        await _indexFile(await _require(item.id));
      } catch (_) {
        /* Rebuilt on next opening. */
      }
    }
  });
}
