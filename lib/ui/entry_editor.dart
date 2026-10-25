import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/file_formats.dart';
import 'file_preview.dart';
import 'workspace_style.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../domain/workspace.dart';
import 'common.dart';
import 'dialogs.dart';
import 'note_history.dart';

class EntryEditor extends StatefulWidget {
  const EntryEditor({
    super.key,
    required this.entry,
    required this.entries,
    required this.repository,
    required this.onOpen,
    this.onBack,
    this.busy = false,
    this.actionMenu,
  });
  final Entry entry;
  final List<Entry> entries;
  final WorkspaceRepository repository;
  final Future<void> Function(Entry) onOpen;
  final VoidCallback? onBack;
  final bool busy;
  final Widget? actionMenu;
  @override
  State<EntryEditor> createState() => EntryEditorState();
}

class EntryEditorState extends State<EntryEditor> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _bodyFocus = FocusNode();
  final _goal = TextEditingController();
  final _context = TextEditingController();
  TaskState _taskState = TaskState.inbox;
  DateTime? _due;
  String _bodyHash = '';
  int _revision = 0;
  bool _dirty = false;
  bool _loading = true;
  bool _saving = false;
  bool _preview = true;
  bool _bodyEditable = true;
  bool _showInfo = false;
  bool _editRequested = false;
  bool get _plainText =>
      widget.entry.kind == EntryKind.file &&
      !isMarkdownName(widget.entry.fileName ?? '');
  Object? _error;
  late Future<List<List<Entry>>> _relations;
  bool get _readOnly =>
      widget.entry.inTrash || isArchived(widget.entry, widget.entries);
  bool get _locked => _readOnly || _saving || widget.busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EntryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        (!_dirty && !_saving && widget.entry.revision != _revision)) {
      _load();
    } else {
      _loadRelations();
    }
  }

  void _loadRelations() {
    _relations = Future.wait([
      widget.repository.backlinks(widget.entry.id),
      widget.repository.outgoingLinks(widget.entry.id),
    ]);
  }

  Future<void> _load() async {
    _loadRelations();
    final id = widget.entry.id;
    _loading = true;
    _error = null;
    try {
      final snapshot = await widget.repository.readNote(id);
      final latest = widget.entry.inTrash
          ? await widget.repository.getTrash()
          : await widget.repository.getEntries();
      if (!mounted || widget.entry.id != id) return;
      final entry = latest.where((e) => e.id == id).firstOrNull ?? widget.entry;
      setState(() {
        _title.text = entry.title;
        _body.text = snapshot.text;
        _bodyEditable = snapshot.editable;
        _goal.text = entry.goal;
        _context.text = entry.context;
        _due = entry.dueDate;
        _taskState = entry.taskState;
        _bodyHash = snapshot.hash;
        _revision = entry.revision;
        _preview =
            !_editRequested &&
            (snapshot.text.isNotEmpty ||
                entry.kind == EntryKind.file ||
                _readOnly);
        _showInfo = false;
        _dirty = false;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _bodyFocus.dispose();
    _body.dispose();
    _goal.dispose();
    _context.dispose();
    super.dispose();
  }

  void _changed([String? _]) {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> save() async {
    if (_saving) return false;
    if (!_dirty) return true;
    if (_readOnly || widget.busy || _loading || _error != null) return false;
    setState(() => _saving = true);
    try {
      await widget.repository.save(
        id: widget.entry.id,
        expectedRevision: _revision,
        expectedBodyHash: _bodyHash,
        draft: EntryDraft(
          title: _title.text,
          body: _body.text,
          goal: _goal.text,
          dueDate: _due,
          taskState: _taskState,
          context: _context.text,
        ),
      );
      final latest = (await widget.repository.getEntries()).firstWhere(
        (e) => e.id == widget.entry.id,
      );
      final snapshot = await widget.repository.readNote(widget.entry.id);
      if (!mounted) return true;
      setState(() {
        _revision = latest.revision;
        _bodyHash = snapshot.hash;
        _dirty = false;
        _loadRelations();
      });
      return true;
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> canLeave() async {
    if (_saving) return false;
    if (!_dirty) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen speichern?'),
        content: Text('„${_title.text}“ enthält ungespeicherte Änderungen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Verwerfen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (result == 'save') return save();
    if (result == 'discard') {
      _dirty = false;
      return true;
    }
    return false;
  }

  Future<void> _insertLink() async {
    final entry = await showLinkPicker(
      context,
      widget.entries,
      widget.entry.id,
    );
    if (entry == null || !mounted) return;
    final selection = _body.selection;
    final start = selection.isValid ? selection.start : _body.text.length;
    final end = selection.isValid ? selection.end : start;
    final value = markdownLink(entry);
    _body.value = TextEditingValue(
      text: _body.text.replaceRange(start, end, value),
      selection: TextSelection.collapsed(offset: start + value.length),
    );
    setState(() {
      _dirty = true;
      _preview = false;
    });
  }

  Future<void> _showHistory() async {
    if (!await canLeave() || !mounted) return;
    // "Discard" resolves the pending draft while this editor stays on screen.
    await _load();
    if (!mounted) return;
    final changed = await showNoteHistory(
      context,
      widget.repository,
      widget.entry,
      readOnly: _readOnly,
      onSavingChanged: (busy) {
        if (mounted) setState(() => _saving = busy);
      },
    );
    if (changed && mounted) await _load();
  }

  Future<void> _tapLink(String? href) async {
    if (href == null) return;
    final id = entryIdFromLink(href);
    if (id != null) {
      final target = widget.entries.where((e) => e.id == id).firstOrNull;
      if (target == null) {
        showMessage(context, 'Der verknüpfte Inhalt ist nicht verfügbar.');
      } else {
        await widget.onOpen(target);
      }
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri == null || !{'https', 'http', 'mailto'}.contains(uri.scheme)) {
      showMessage(context, 'Dieser Link wird nicht unterstützt.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        showMessage(context, 'Der Link konnte nicht geöffnet werden.');
      }
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
    }
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() {
        _due = date;
        _dirty = true;
      });
    }
  }

  Widget _linkRelations() => FutureBuilder<List<List<Entry>>>(
    future: _relations,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Text('Verknüpfungen konnten nicht geladen werden.'),
        );
      }
      if (!snapshot.hasData) return const SizedBox.shrink();
      final incoming = snapshot.data![0];
      final outgoing = snapshot.data![1];
      if (incoming.isEmpty && outgoing.isEmpty) return const SizedBox.shrink();
      Widget group(String label, List<Entry> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 5),
          for (final row in rows)
            Builder(
              builder: (context) {
                final current =
                    widget.entries.where((e) => e.id == row.id).firstOrNull ??
                    row;
                return TextButton.icon(
                  onPressed: () => widget.onOpen(current),
                  icon: Icon(entryIcon(current.kind), size: 16),
                  label: Text(
                    '${current.title}${current.inTrash ? ' · Im Papierkorb' : ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                );
              },
            ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: ExpansionTile(
          key: ValueKey('relations-${widget.entry.id}'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 4),
          dense: true,
          visualDensity: VisualDensity.compact,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(Icons.link, size: 17),
          title: Text(
            'Verknüpfungen (${incoming.length + outgoing.length})',
            style: const TextStyle(fontSize: 11),
          ),
          children: [
            if (outgoing.isNotEmpty) group('Verknüpft mit', outgoing),
            if (incoming.isNotEmpty) group('Erwähnt in', incoming),
          ],
        ),
      );
    },
  );

  List<Widget> _detailFields() => [
    if (widget.entry.kind == EntryKind.project) ...[
      TextField(
        controller: _goal,
        readOnly: _locked,
        onChanged: _changed,
        decoration: const InputDecoration(labelText: 'Gewünschtes Ergebnis'),
        minLines: 2,
        maxLines: 5,
      ),
      const SizedBox(height: 16),
    ],
    if (widget.entry.kind == EntryKind.task) ...[
      DropdownButtonFormField<TaskState>(
        key: ValueKey(_taskState),
        initialValue: _taskState,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Einordnung'),
        items: TaskState.values
            .map(
              (state) =>
                  DropdownMenuItem(value: state, child: Text(state.label)),
            )
            .toList(),
        onChanged: _locked
            ? null
            : (value) => setState(() {
                _taskState = value!;
                _dirty = true;
              }),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _context,
        readOnly: _locked,
        onChanged: _changed,
        decoration: const InputDecoration(
          labelText: 'Kontext',
          hintText: 'z. B. Telefon, Computer, Zu Hause',
        ),
      ),
      const SizedBox(height: 14),
    ],
    if (widget.entry.kind == EntryKind.project ||
        widget.entry.kind == EntryKind.task)
      Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _locked ? null : _pickDueDate,
              icon: const Icon(Icons.event_outlined, size: 17),
              label: Text(
                _due == null
                    ? 'Fälligkeitsdatum (optional)'
                    : 'Fällig am ${dateLabel(_due!)}',
              ),
            ),
            if (widget.entry.kind == EntryKind.task &&
                _due != null &&
                !_readOnly)
              TextButton(
                onPressed: () => setState(() {
                  _due = null;
                  _dirty = true;
                }),
                child: const Text('Entfernen'),
              ),
          ],
        ),
      ),
  ];

  void startEditing() {
    _editRequested = true;
    if (!_loading && !_bodyEditable) {
      showMessage(
        context,
        'Diese Datei ist nicht als kleine UTF-8-Textdatei bearbeitbar.',
      );
      return;
    }
    if (!_loading && _bodyEditable && !_readOnly) {
      setState(() => _preview = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bodyFocus.requestFocus();
      });
    }
  }

  Widget _metadata() {
    final entry = widget.entry, colors = WorkspaceColors(context);
    final location = [
      entry.section.label,
      ...ancestorsOf(entry, widget.entries).reversed.map((e) => e.title),
    ].join(' / ');
    final items = <String, String>{
      'Typ': entry.kind == EntryKind.file
          ? p
                .extension(entry.fileName ?? '')
                .replaceFirst('.', '')
                .toUpperCase()
          : entry.kind == EntryKind.note
          ? 'Markdown'
          : entry.kind.label,
      if (entry.fileSize != null) 'Größe': fileSizeLabel(entry.fileSize!),
      'Geändert':
          '${dateLabel(entry.updatedAt.toLocal())}, ${entry.updatedAt.toLocal().hour.toString().padLeft(2, '0')}:${entry.updatedAt.toLocal().minute.toString().padLeft(2, '0')}',
      'Ablageort': location,
      'Inhaltssuche':
          entry.kind != EntryKind.file || entry.searchText.isNotEmpty
          ? 'Text indiziert'
          : 'Nur Name / kein auslesbarer Text indiziert',
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 77,
                    child: Text(
                      item.key,
                      style: TextStyle(fontSize: 11, color: colors.soft),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      item.value,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bodyView() {
    if (widget.entry.kind == EntryKind.file && !_bodyEditable) {
      return FilePreview(entry: widget.entry, repository: widget.repository);
    }
    if (!_preview) {
      return TextField(
        key: const ValueKey('markdown-body'),
        focusNode: _bodyFocus,
        controller: _body,
        readOnly: _locked,
        onChanged: _changed,
        minLines: 18,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.7,
        ),
        decoration: InputDecoration(
          hintText: _plainText
              ? 'Text schreiben …'
              : 'Gedanken, Entscheidungen und Verknüpfungen …',
          filled: true,
          fillColor: WorkspaceColors(context).sidebar,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: WorkspaceColors(context).line),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      );
    }
    if (_plainText) {
      return SelectableText(
        _body.text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.7,
        ),
      );
    }
    return MarkdownBody(
      data: _body.text.isEmpty ? '_Noch kein Text._' : _body.text,
      selectable: true,
      onTapLink: (_, href, _) => _tapLink(href),
      imageBuilder: (uri, title, alt) => TextButton.icon(
        onPressed: () => _tapLink(uri.toString()),
        icon: const Icon(LucideIcons.image, size: 16),
        label: Text(alt ?? title ?? 'Bildverweis'),
      ),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(
          fontSize: 13,
          height: 1.55,
          color: WorkspaceColors(context).ink,
        ),
        h1: const TextStyle(
          fontSize: 25,
          height: 1.3,
          fontWeight: FontWeight.w500,
          letterSpacing: -.5,
        ),
        h2: const TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        h3: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        h1Padding: EdgeInsets.zero,
        h2Padding: const EdgeInsets.only(top: 11, bottom: 0),
        blockSpacing: 13,
        listBullet: const TextStyle(fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = WorkspaceColors(context), entry = widget.entry;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EmptyState(
        icon: LucideIcons.circleAlert,
        title: 'Inhalt nicht lesbar',
        description: errorLabel(_error!),
        action: OutlinedButton(
          onPressed: _load,
          child: const Text('Erneut laden'),
        ),
      );
    }
    final document =
        entry.kind == EntryKind.note || entry.kind == EntryKind.file;
    final actions = <Widget>[
      if (document && _bodyEditable)
        IconButton(
          key: const ValueKey('note-history'),
          tooltip: 'Versionsverlauf',
          icon: const Icon(LucideIcons.history, size: 15),
          onPressed: _saving || widget.busy ? null : _showHistory,
        ),
      if (_dirty)
        Text(
          'Ungespeichert',
          style: TextStyle(fontSize: 11, color: colors.accent),
        ),
      if (!_readOnly && _bodyEditable)
        TextButton.icon(
          onPressed: _locked
              ? null
              : () => setState(() => _preview = !_preview),
          icon: Icon(_preview ? LucideIcons.pencil : LucideIcons.eye, size: 15),
          label: Text(
            _preview ? 'Bearbeiten' : 'Vorschau',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      if (!_readOnly && (!_preview || _dirty))
        TextButton.icon(
          key: const ValueKey('editor-save'),
          onPressed: _dirty && !_locked ? save : null,
          icon: const Icon(LucideIcons.save, size: 15),
          label: Text(
            _saving ? 'Speichert …' : 'Speichern',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      if (!_readOnly && !_preview && !_plainText && _bodyEditable)
        IconButton(
          onPressed: _locked ? null : _insertLink,
          tooltip: 'Verknüpfung einfügen',
          icon: const Icon(LucideIcons.link, size: 15),
        ),
    ];
    return SingleChildScrollView(
      key: const ValueKey('entry-editor-scroll'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 650 ? 20 : 34,
              29,
              MediaQuery.sizeOf(context).width < 650 ? 20 : 34,
              28,
            ),
            child: LayoutBuilder(
              builder: (context, bounds) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.onBack != null)
                        IconButton(
                          onPressed: widget.onBack,
                          tooltip: 'Zurück zu den Inhalten',
                          icon: const Icon(LucideIcons.arrowLeft, size: 16),
                        ),
                      Icon(fileIcon(entry), size: 16, color: colors.soft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: document
                            ? Text(
                                entryFileLabel(entry),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : TextField(
                                key: const ValueKey('entry-title'),
                                controller: _title,
                                readOnly: _locked,
                                onChanged: _changed,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                      ),
                      if (bounds.maxWidth > 490) ...actions,
                      IconButton(
                        key: const ValueKey('file-info'),
                        tooltip: 'Dateiinformationen',
                        isSelected: _showInfo,
                        onPressed: () => setState(() => _showInfo = !_showInfo),
                        icon: Icon(
                          LucideIcons.info,
                          size: 15,
                          color: colors.soft,
                        ),
                      ),
                      if (widget.actionMenu != null) widget.actionMenu!,
                    ],
                  ),
                  if (bounds.maxWidth <= 490 && actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: actions,
                      ),
                    ),
                  if (_readOnly)
                    Text(
                      entry.inTrash
                          ? 'Im Papierkorb · schreibgeschützt'
                          : 'Archiviert',
                      style: TextStyle(fontSize: 11, color: colors.soft),
                    ),
                  const SizedBox(height: 22),
                  if (_showInfo) _metadata(),
                  ..._detailFields(),
                  _bodyView(),
                  _linkRelations(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
