import 'package:flutter/material.dart';
import '../domain/workspace.dart';
import 'common.dart';

Future<EntryDraft?> showEntryDialog(
  BuildContext context,
  EntryKind kind, {
  TaskState taskState = TaskState.inbox,
  EntryDraft? initialDraft,
  String? heading,
  String? submitLabel,
}) => showDialog<EntryDraft>(
  context: context,
  builder: (_) => _EntryDialog(
    kind: kind,
    taskState: taskState,
    initialDraft: initialDraft,
    heading: heading,
    submitLabel: submitLabel,
  ),
);

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({
    required this.kind,
    required this.taskState,
    this.initialDraft,
    this.heading,
    this.submitLabel,
  });
  final EntryKind kind;
  final TaskState taskState;
  final EntryDraft? initialDraft;
  final String? heading;
  final String? submitLabel;
  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialDraft?.title);
  late final _goal = TextEditingController(text: widget.initialDraft?.goal);
  late final _context = TextEditingController(
    text: widget.initialDraft?.context,
  );
  late TaskState _taskState = widget.taskState;
  late DateTime? _due = widget.initialDraft?.dueDate;
  bool _missingDate = false;
  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    _context.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: widget.kind == EntryKind.project
          ? 'Projekt abschließen bis'
          : 'Fälligkeitsdatum',
    );
    if (date != null && mounted) {
      setState(() {
        _due = date;
        _missingDate = false;
      });
    }
  }

  void _submit() {
    final valid = _form.currentState!.validate();
    if (widget.kind == EntryKind.project && _due == null) {
      setState(() => _missingDate = true);
      return;
    }
    if (!valid) return;
    Navigator.pop(
      context,
      EntryDraft(
        title: _title.text.trim(),
        goal: _goal.text.trim(),
        dueDate: _due,
        taskState: _taskState,
        context: _context.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.heading ?? '${widget.kind.label} anlegen'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Titel'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Bitte einen Titel eingeben.'
                    : null,
                onFieldSubmitted: (_) {
                  if (widget.kind != EntryKind.project) _submit();
                },
              ),
              if (widget.kind == EntryKind.project) ...[
                const SizedBox(height: 18),
                TextFormField(
                  controller: _goal,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Gewünschtes Ergebnis',
                    hintText:
                        'Woran erkennst du, dass das Projekt abgeschlossen ist?',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bitte das Ergebnis beschreiben.'
                      : null,
                ),
              ],
              if (widget.kind == EntryKind.project ||
                  widget.kind == EntryKind.task) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      _due == null
                          ? (widget.kind == EntryKind.project
                                ? 'Fälligkeitsdatum wählen *'
                                : 'Fälligkeitsdatum (optional)')
                          : dateLabel(_due!),
                    ),
                  ),
                ),
                if (_missingDate)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ein Projekt braucht ein Fälligkeitsdatum.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
              if (widget.kind == EntryKind.task) ...[
                const SizedBox(height: 18),
                DropdownButtonFormField<TaskState>(
                  initialValue: _taskState,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Einordnung'),
                  items: TaskState.values
                      .map(
                        (state) => DropdownMenuItem(
                          value: state,
                          child: Text(state.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _taskState = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _context,
                  decoration: const InputDecoration(
                    labelText: 'Kontext (optional)',
                    hintText: 'z. B. Telefon, Zu Hause, Computer',
                  ),
                ),
              ],
              if (widget.kind == EntryKind.idea) ...[
                const SizedBox(height: 12),
                const Text(
                  'Eine Idee ist noch kein Projekt. Du kannst hier erst einmal Gedanken sammeln.',
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.submitLabel ?? 'Anlegen'),
      ),
    ],
  );
}

Future<Entry?> showLinkPicker(
  BuildContext context,
  List<Entry> entries,
  String sourceId,
) => showDialog<Entry>(
  context: context,
  builder: (_) => _LinkPicker(
    entries: entries.where((e) => e.id != sourceId && !e.inTrash).toList(),
  ),
);

class _LinkPicker extends StatefulWidget {
  const _LinkPicker({required this.entries});
  final List<Entry> entries;
  @override
  State<_LinkPicker> createState() => _LinkPickerState();
}

class _LinkPickerState extends State<_LinkPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final rows = widget.entries
        .where((e) => e.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return AlertDialog(
      title: const Text('Verknüpfung einfügen'),
      content: SizedBox(
        width: 470,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Inhalte durchsuchen',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('Keine passenden Inhalte.'))
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final entry = rows[index];
                        return ListTile(
                          leading: Icon(entryIcon(entry.kind), size: 20),
                          title: Text(entry.title),
                          subtitle: Text(entry.kind.label),
                          onTap: () => Navigator.pop(context, entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}

class MoveTarget {
  const MoveTarget(this.section, this.parentId);
  final ParaSection section;
  final String? parentId;
}

Future<String?> showRenameDialog(
  BuildContext context,
  String title, {
  String heading = 'Ordner umbenennen',
}) => showDialog<String>(
  context: context,
  builder: (_) => _RenameDialog(title, heading),
);

class _RenameDialog extends StatefulWidget {
  const _RenameDialog(this.title, this.heading);
  final String heading;
  final String title;
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.title);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.heading),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Name'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Speichern'),
      ),
    ],
  );
}

Future<MoveTarget?> showMoveDialog(
  BuildContext context,
  Entry source,
  List<Entry> entries,
) {
  final targets =
      entries
          .where(
            (e) =>
                e.kind.isContainer &&
                !e.inTrash &&
                !isArchived(e, entries) &&
                !e.completed &&
                e.id != source.id &&
                !belongsTo(e, source.id, entries),
          )
          .toList()
        ..sort((a, b) => a.title.compareTo(b.title));
  return showDialog<MoveTarget>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Verschieben nach'),
      content: SizedBox(
        width: 450,
        height: 390,
        child: ListView(
          children: [
            for (final section in [
              ParaSection.inbox,
              ParaSection.areas,
              ParaSection.resources,
            ])
              ListTile(
                leading: Icon(
                  section == ParaSection.inbox
                      ? Icons.inbox_outlined
                      : Icons.local_library_outlined,
                ),
                title: Text(section.label),
                subtitle: const Text('Oberste Ebene'),
                onTap: () => Navigator.pop(context, MoveTarget(section, null)),
              ),
            const Divider(),
            for (final target in targets)
              ListTile(
                leading: Icon(entryIcon(target.kind), size: 20),
                title: Text(target.title),
                subtitle: Text(
                  [
                    target.section.label,
                    ...ancestorsOf(
                      target,
                      entries,
                    ).reversed.map((e) => e.title),
                  ].join(' / '),
                ),
                onTap: () => Navigator.pop(
                  context,
                  MoveTarget(target.section, target.id),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    ),
  );
}
