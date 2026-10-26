import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/inbox_ingest_service.dart';
import 'common.dart';

class IngestSettings extends StatefulWidget {
  const IngestSettings({super.key, required this.service});
  final InboxIngestService service;
  @override
  State<IngestSettings> createState() => _IngestSettingsState();
}

class _IngestSettingsState extends State<IngestSettings> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.service.removeListener(_changed);
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (failure) {
      if (mounted) showMessage(context, errorLabel(failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose() async {
    final selected = await widget.service.directoryAccess.choose();
    if (selected != null) await widget.service.configure(selected);
  }

  Future<void> _activate() async {
    final service = widget.service;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eingangsordner aktivieren?'),
        content: Text(
          'Alle fertigen Dateien und Unterordner aus\n${service.sourcePath}\n\n'
          'werden in die Inbox dieses Arbeitsbereichs übernommen. Die Struktur bleibt erhalten. '
          'Erfolgreiche Eingänge verschwinden aus dem Ordner; Originale bleiben im Rückholbereich erhalten. '
          'Verarbeitung nur während die App läuft, übrige Eingänge beim nächsten Start.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const ValueKey('ingest-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aktivieren'),
          ),
        ],
      ),
    );
    if (accepted == true) await service.activate();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final failures = service.jobs.where((j) => j.error != null).toList();
    final completed = service.jobs
        .where((j) => j.phase == 'done' || j.phase == 'recovered')
        .length;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Automatischer Eingang',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dateien und verschachtelte Ordner automatisch in die Inbox übernehmen. '
          'Ein eigener lokaler Ordner ist empfohlen. Keine Verarbeitung bei beendeter App.',
        ),
        const SizedBox(height: 12),
        if (service.sourcePath != null) SelectableText(service.sourcePath!),
        Text(service.status, key: const ValueKey('ingest-status')),
        if (service.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(service.error!),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('ingest-choose'),
              onPressed: _busy ? null : () => _run(_choose),
              child: const Text('Ordner auswählen …'),
            ),
            if (service.configured)
              FilledButton(
                key: const ValueKey('ingest-toggle'),
                onPressed: _busy
                    ? null
                    : () => _run(service.enabled ? service.pause : _activate),
                child: Text(service.enabled ? 'Pausieren' : 'Aktivieren …'),
              ),
            if (service.enabled)
              OutlinedButton(
                key: const ValueKey('ingest-scan'),
                onPressed: _busy || service.working
                    ? null
                    : () => _run(service.runOnce),
                child: const Text('Jetzt prüfen'),
              ),
            if (service.configured)
              TextButton(
                onPressed: () => _run(() async {
                  if (!await launchUrl(Uri.directory(service.sourcePath!))) {
                    throw StateError('Ordner konnte nicht geöffnet werden.');
                  }
                }),
                child: const Text('Ordner öffnen'),
              ),
            if (completed > 0)
              TextButton(
                onPressed: () => _run(() async {
                  if (!await launchUrl(Uri.directory(service.recoveryPath))) {
                    throw StateError(
                      'Rückholbereich konnte nicht geöffnet werden.',
                    );
                  }
                }),
                child: const Text('Originale öffnen'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '$completed Eingänge übernommen. Originale werden nicht automatisch gelöscht.',
        ),
        if (service.working || _busy) const LinearProgressIndicator(),
        for (final job in failures.reversed.take(20))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(job.name),
            subtitle: Text(job.error!),
          ),
        const SizedBox(height: 12),
        const Text(
          'Unfertige Kopien warten auf einen stabilen Stand. Symlinks, Spezialdateien, '
          'Repositories und macOS-Dateipakete werden nicht übernommen. '
          'Offene Schreibprogramme können nach einer Ruhepause weiter schreiben; '
          'für zuverlässige Übergaben Dateien zuerst fertig schreiben und dann in den Eingang verschieben.',
        ),
      ],
    );
  }
}
