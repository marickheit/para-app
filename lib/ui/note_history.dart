import 'package:flutter/material.dart';
import '../domain/workspace.dart';
import 'common.dart';

String versionTime(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${dateLabel(local)} · ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

Future<bool> showNoteHistory(
  BuildContext context,
  WorkspaceRepository repository,
  Entry entry, {
  required bool readOnly,
  ValueChanged<bool>? onSavingChanged,
}) async {
  try {
    final versions = await repository.noteVersions(entry.id);
    final snapshot = await repository.readNote(entry.id);
    final current = readOnly
        ? entry
        : (await repository.getEntries()).firstWhere((e) => e.id == entry.id);
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (_) => _NoteHistory(
            repository: repository,
            entry: current,
            versions: versions,
            snapshot: snapshot,
            readOnly: readOnly,
            onSavingChanged: onSavingChanged,
          ),
        ) ??
        false;
  } catch (error) {
    if (context.mounted) showMessage(context, errorLabel(error));
    return false;
  }
}

class _NoteHistory extends StatefulWidget {
  const _NoteHistory({
    required this.repository,
    required this.entry,
    required this.versions,
    required this.snapshot,
    required this.readOnly,
    this.onSavingChanged,
  });
  final WorkspaceRepository repository;
  final Entry entry;
  final List<NoteVersion> versions;
  final NoteSnapshot snapshot;
  final bool readOnly;
  final ValueChanged<bool>? onSavingChanged;
  @override
  State<_NoteHistory> createState() => _NoteHistoryState();
}

class _NoteHistoryState extends State<_NoteHistory> {
  late NoteVersion? _selected = widget.versions.firstOrNull;
  bool _busy = false;
  String? _error;

  Future<void> _restore() async {
    final version = _selected;
    if (_busy || version == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Textversion wiederherstellen?'),
        content: const Text(
          'Der ausgewählte Text wird als neuer Stand gespeichert. '
          'Der bisherige Text bleibt im Verlauf. Name, Ablage und weitere Angaben bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onSavingChanged?.call(true);
    try {
      await widget.repository.restoreNoteVersion(
        widget.entry.id,
        version.id,
        expectedRevision: widget.entry.revision,
        expectedBodyHash: widget.snapshot.hash,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = errorLabel(error);
          _busy = false;
        });
      }
    } finally {
      widget.onSavingChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Versionsverlauf'),
      content: SizedBox(
        width: 650,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            if (widget.versions.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Noch keine Textversionen. '
                    'Beim nächsten Speichern einer Textänderung wird auch der bisherige Stand gesichert.',
                  ),
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                key: const ValueKey('version-picker'),
                initialValue: _selected!.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Gespeicherter Textstand',
                ),
                items: [
                  for (var i = 0; i < widget.versions.length; i++)
                    DropdownMenuItem(
                      value: widget.versions[i].id,
                      child: Text(
                        '${versionTime(widget.versions[i].createdAt)} · Stand ${widget.versions.length - i}'
                        '${i == 0 && widget.versions[i].bodyHash == widget.snapshot.hash ? ' · Aktuell' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (id) => setState(() {
                        _selected = widget.versions.firstWhere(
                          (e) => e.id == id,
                        );
                      }),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SizedBox.expand(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: SelectableText(
                        _selected!.body.isEmpty
                            ? '(Leerer Text)'
                            : _selected!.body,
                        key: ValueKey('version-body-${_selected!.id}'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              widget.readOnly
                  ? 'Zum Wiederherstellen den Inhalt zuerst aus Archiv oder Papierkorb zurückholen.'
                  : 'Nur gespeicherte Texte · keine automatische Bereinigung.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Schließen'),
        ),
        FilledButton(
          key: const ValueKey('restore-version'),
          onPressed:
              _busy ||
                  widget.readOnly ||
                  _selected == null ||
                  _selected!.bodyHash == widget.snapshot.hash
              ? null
              : _restore,
          child: Text(_busy ? 'Speichert …' : 'Text wiederherstellen'),
        ),
      ],
    ),
  );
}
