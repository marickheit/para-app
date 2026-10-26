import 'dart:async';
import '../services/mcp_editor_guard.dart';
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
import 'task_details.dart';
import 'note_history.dart';

class EditorViewMemory {
  final views = <String, ({bool preview, double offset})>{};
  final previews = FilePreviewMemory();
}

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
    this.memory,
    this.readable = false,
    this.onToggleReadable,
    this.onEditorState,
  });
  final Entry entry;
  final List<Entry> entries;
  final WorkspaceRepository repository;
  final Future<void> Function(Entry) onOpen;
  final VoidCallback? onBack;
  final bool busy;
  final Widget? actionMenu;
  final EditorViewMemory? memory;
  final bool readable;
  final VoidCallback? onToggleReadable;
  final void Function(String id, bool dirty, bool editing)? onEditorState;
  @override
  State<EntryEditor> createState() => EntryEditorState();
}

class EntryEditorState extends State<EntryEditor> {
  final _scroll = ScrollController();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _bodyFocus = FocusNode();
  final _goal = TextEditingController();
  final _context = TextEditingController();
  TaskState _taskState = TaskState.inbox;
  DateTime? _due;
  String _bodyHash = '';
  int _revision = 0;
  bool _dirtyValue = false;
  bool get _dirty => _dirtyValue;
  set _dirty(bool value) {
    _dirtyValue = value;
    _reportEditor();
  }

  List<TaskContext> _contexts = [];
  TaskDetailsValue _taskDetails = const TaskDetailsValue();
  StreamSubscription<List<TaskContext>>? _contextSubscription;
  bool _loadingValue = true, _savingValue = false;
  bool get _loading => _loadingValue;
  set _loading(bool value) {
    _loadingValue = value;
    _reportEditor();
  }

  bool get _saving => _savingValue;
  set _saving(bool value) {
    _savingValue = value;
    _reportEditor();
  }

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
  late final McpEditorGuard _mcpGuard;
  int _loadGeneration = 0;
  bool get _locked =>
      _readOnly ||
      _saving ||
      _loading ||
      widget.busy ||
      _mcpGuard.isWriting(widget.entry.id);
  void _reportEditor() {
    _mcpGuard.report(
      this,
      widget.entry.id,
      blocked: _dirty || _loading || _saving,
    );
    final id = widget.entry.id,
        dirty = _dirty,
        editing = !_preview && !_loading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.entry.id == id) {
        widget.onEditorState?.call(id, dirty, editing);
      }
    });
  }

  void _remember(String id) {
    widget.memory?.views[id] = (
      preview: _preview,
      offset: _scroll.hasClients ? _scroll.offset : 0,
    );
  }

  void _mcpChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _mcpGuard = McpEditorGuard.forRepository(widget.repository);
    _mcpGuard.addListener(_mcpChanged);
    _reportEditor();
    _contextSubscription = widget.repository.watchContexts().listen((values) {
      if (mounted) setState(() => _contexts = values);
    });
    _load();
  }

  @override
  void didUpdateWidget(covariant EntryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _remember(oldWidget.entry.id);
      _loadingValue = true;
      _editRequested = false;
      _dirty = false;
    }
    if (oldWidget.entry.id != widget.entry.id ||
        (!_dirty && !_saving && widget.entry.revision > _revision)) {
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
    final generation = ++_loadGeneration;
    _loading = true;
    _reportEditor();
    _error = null;
    try {
      final value = await widget.repository.readSnapshot(id);
      if (!mounted || widget.entry.id != id || generation != _loadGeneration) {
        return;
      }
      final snapshot = value.note;
      final entry = value.entry;
      if (_dirty) {
        _loading = false;
        _reportEditor();
        return;
      }
      setState(() {
        _title.text = entry.title;
        _body.text = snapshot.text;
        _bodyEditable = snapshot.editable;
        _goal.text = entry.goal;
        _context.text = entry.context;
        _due = entry.dueDate;
        _taskState = entry.taskState;
        _taskDetails = TaskDetailsValue(
          contextIds: entry.contextIds,
          minutes: entry.estimatedMinutes,
          energy: entry.energy,
        );
        _bodyHash = snapshot.hash;
        _revision = entry.revision;
        _preview =
            !_editRequested &&
            (snapshot.text.isNotEmpty ||
                entry.kind == EntryKind.file ||
                _readOnly);
        final remembered = widget.memory?.views[id];
        if (remembered != null && !_editRequested && !_readOnly) {
          _preview = remembered.preview;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.entry.id == id && _scroll.hasClients) {
            _scroll.jumpTo(
              (remembered?.offset ?? 0).clamp(
                0.0,
                _scroll.position.maxScrollExtent,
              ),
            );
          }
        });
        _showInfo = false;
        _dirty = false;
        _loading = false;
        _reportEditor();
      });
    } catch (error) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _error = error;
          _loading = false;
          _reportEditor();
        });
      }
    }
  }

  @override
  void dispose() {
    _remember(widget.entry.id);
    _scroll.dispose();
    _mcpGuard.removeListener(_mcpChanged);
    _mcpGuard.remove(this);
    _contextSubscription?.cancel();
    _title.dispose();
    _bodyFocus.dispose();
    _body.dispose();
    _goal.dispose();
    _context.dispose();
    super.dispose();
  }

  void _changed([String? _]) {
    if (!_dirty) setState(() => _dirty = true);
    _reportEditor();
  }

  Future<bool> save() async {
    if (_saving) return false;
    if (!_dirty) return true;
    if (_locked || _error != null) return false;
    setState(() => _saving = true);
    _reportEditor();
    try {
      final saved = await widget.repository.saveSnapshot(
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
          contextIds: widget.entry.kind == EntryKind.task
              ? _taskDetails.contextIds
              : null,
          estimatedMinutes: _taskDetails.minutes,
          energy: _taskDetails.energy,
          updateTaskDetails: widget.entry.kind == EntryKind.task,
        ),
      );
      if (!mounted) return true;
      setState(() {
        _revision = saved.entry.revision;
        _bodyHash = saved.note.hash;
        _dirty = false;
        _loadRelations();
      });
      return true;
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
      return false;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _reportEditor();
        if (!_dirty && widget.entry.revision > _revision) _load();
      }
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
      await _load();
      return _error == null;
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
      TaskDetailsFields(
        definitions: _contexts,
        value: _taskDetails,
        readOnly: _locked,
        onChanged: (value) => setState(() {
          _taskDetails = value;
          _dirty = true;
        }),
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
                onPressed: _locked
                    ? null
                    : () => setState(() {
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
      _reportEditor();
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
      if (document && _bodyEditable && widget.onToggleReadable != null)
        TextButton.icon(
          key: const ValueKey('readable-toggle'),
          onPressed: widget.onToggleReadable,
          icon: const Icon(LucideIcons.moveHorizontal, size: 15),
          label: Text(
            widget.readable ? 'Volle Breite' : 'Lesebreite',
            style: const TextStyle(fontSize: 11),
          ),
        ),
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
              : () => setState(() {
                  _editRequested = _preview;
                  _preview = !_preview;
                  _reportEditor();
                }),
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
    final path = [
      entry.section.label,
      ...ancestorsOf(entry, widget.entries).reversed.map((e) => e.title),
    ].join(' / ');
    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, bounds) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.onBack != null && !document)
                  IconButton(
                    onPressed: widget.onBack,
                    tooltip: 'Zurück zu den Inhalten',
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  ),
                Expanded(
                  child: Tooltip(
                    message: path,
                    child: Text(
                      document ? path : entry.kind.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: colors.soft),
                    ),
                  ),
                ),
                if (bounds.maxWidth > 620) ...actions,
                IconButton(
                  key: const ValueKey('file-info'),
                  tooltip: 'Dateiinformationen',
                  isSelected: _showInfo,
                  onPressed: () => setState(() => _showInfo = !_showInfo),
                  icon: Icon(LucideIcons.info, size: 15, color: colors.soft),
                ),
                if (widget.actionMenu != null) widget.actionMenu!,
              ],
            ),
            if (bounds.maxWidth <= 620 && actions.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            if (_readOnly)
              Text(
                entry.inTrash
                    ? 'Im Papierkorb · schreibgeschützt'
                    : 'Archiviert · schreibgeschützt',
                style: TextStyle(fontSize: 11, color: colors.soft),
              ),
          ],
        ),
      ),
    );
    final binary = entry.kind == EntryKind.file && !_bodyEditable;
    final content = binary
        ? FilePreview(
            key: ValueKey(entry.id),
            entry: entry,
            repository: widget.repository,
            memory: widget.memory?.previews,
          )
        : SingleChildScrollView(
            key: const ValueKey('entry-editor-scroll'),
            controller: _scroll,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: !document || widget.readable
                      ? 760
                      : double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (entry.kind != EntryKind.file) ...[
                        TextField(
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
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                          minLines: 1,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 18),
                      ],
                      ..._detailFields(),
                      _bodyView(),
                      _linkRelations(),
                    ],
                  ),
                ),
              ),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (_showInfo)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _metadata(),
              ),
            ),
          ),
        Expanded(child: content),
      ],
    );
  }
}
