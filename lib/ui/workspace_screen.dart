import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:math' as math;
import 'dart:ui' show AppExitResponse;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/workspace.dart';
import '../services/workspace_manager.dart';
import 'task_details.dart';
import 'workspace_settings.dart';
import '../services/workspace_importer.dart';
import '../domain/archive.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'workspace_style.dart';
import 'entry_actions.dart';
import 'file_drop.dart';
import 'common.dart';
import 'dialogs.dart';
import 'entry_editor.dart';
import 'workspace_search.dart';

enum WorkspaceView {
  inbox,
  projects,
  areas,
  resources,
  archive,
  actions,
  waiting,
  someday,
  allTasks,
  clarify,
  done,
  cancelled,
  trash,
}

extension on WorkspaceView {
  String get label => switch (this) {
    WorkspaceView.inbox => 'Inbox',
    WorkspaceView.projects => 'Projekte',
    WorkspaceView.areas => 'Bereiche',
    WorkspaceView.resources => 'Ressourcen',
    WorkspaceView.archive => 'Archiv',
    WorkspaceView.trash => 'Papierkorb',
    WorkspaceView.actions => 'Nächste Aktionen',
    WorkspaceView.waiting => 'Warten auf',
    WorkspaceView.someday => 'Irgendwann / Vielleicht',
    WorkspaceView.allTasks => 'Alle Aufgaben',
    WorkspaceView.clarify => 'Noch zu klären',
    WorkspaceView.done => 'Erledigt',
    WorkspaceView.cancelled => 'Nicht mehr relevant',
  };
  IconData get icon => switch (this) {
    WorkspaceView.inbox => LucideIcons.inbox,
    WorkspaceView.projects => LucideIcons.flag,
    WorkspaceView.areas => LucideIcons.layoutGrid,
    WorkspaceView.resources => LucideIcons.library,
    WorkspaceView.archive => LucideIcons.archive,
    WorkspaceView.trash => LucideIcons.trash2,
    WorkspaceView.actions => LucideIcons.circleArrowRight,
    WorkspaceView.waiting => LucideIcons.clock3,
    WorkspaceView.someday => LucideIcons.cloud,
    WorkspaceView.allTasks => LucideIcons.listTodo,
    WorkspaceView.clarify => LucideIcons.circleHelp,
    WorkspaceView.done => LucideIcons.circleCheck,
    WorkspaceView.cancelled => LucideIcons.circleSlash,
  };
}

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({
    super.key,
    required this.repository,
    required this.dataDirectory,
    this.workspaceManager,
  });
  final WorkspaceRepository repository;
  final String dataDirectory;
  final WorkspaceManager? workspaceManager;
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  static const _nativeMenu = MethodChannel('para.workspace/menu');
  static _WorkspaceScreenState? _menuOwner;
  final _workspaceFocus = FocusNode(debugLabel: 'workspace-shortcuts');
  final _editor = GlobalKey<EntryEditorState>();
  final _collapsed = <String>{};
  final _dropController = WorkspaceDropController();
  final _archiveCollapsed = <String>{};
  final _expandedRoots = <String>{};
  bool _railExpanded = false;
  String? _creationFolderId;
  bool _acceptingDrop = false;
  late StreamSubscription<List<Entry>> _subscription;
  late StreamSubscription<List<Entry>> _trashSubscription;
  late AppLifecycleListener _lifecycle;
  List<Entry> _entries = [];
  List<TaskContext> _contexts = [];
  late StreamSubscription<List<TaskContext>> _contextSubscription;
  TaskFilter _taskFilter = const TaskFilter();
  Timer? _sessionTimer;
  bool _sessionLoaded = false;
  String? _lastSavedSession;
  List<Entry> _trashEntries = [];
  bool _loading = true;
  bool _busy = false;
  String _busyLabel = '';
  Object? _loadError;
  WorkspaceView _view = WorkspaceView.inbox;
  String? _rootId;
  String? _selectedId;
  String _tab = 'content';
  bool _sidebarVisible = true;
  final _contentSelection = <String, String>{};

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (!mounted || !_sessionLoaded || _busy) return;
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(milliseconds: 250), _flushSession);
  }

  Map<String, dynamic> _session() => {
    'version': 1,
    'view': _view.name,
    'root': _rootId,
    'selected': _selectedId,
    'tab': _tab,
    'railExpanded': _railExpanded,
    'sidebarVisible': _sidebarVisible,
    'collapsed': _collapsed.toList(),
    'archiveCollapsed': _archiveCollapsed.toList(),
    'expandedRoots': _expandedRoots.toList(),
    'contentSelection': _contentSelection,
    'filter': _taskFilter.toJson(),
  };

  Future<void> _flushSession() async {
    _sessionTimer?.cancel();
    if (!_sessionLoaded) return;
    final encoded = jsonEncode(_session());
    if (encoded == _lastSavedSession) return;
    try {
      await widget.repository.writeSetting('session.v1', encoded);
      _lastSavedSession = encoded;
    } catch (error) {
      if (mounted) {
        showMessage(
          context,
          'Die Ansicht konnte nicht gespeichert werden: ${errorLabel(error)}',
        );
      }
    }
  }

  Future<void> _restoreSession() async {
    try {
      final stored = await widget.repository.readSetting('session.v1');
      final entries = [
        ...await widget.repository.getEntries(),
        ...await widget.repository.getTrash(),
      ];
      if (!mounted) return;
      if (stored != null) {
        final data = jsonDecode(stored) as Map<String, dynamic>;
        if (data['version'] != 1) {
          throw const WorkspaceException(
            'Unbekannte Version der gespeicherten Ansicht.',
          );
        }
        setState(() {
          _entries = entries.where((e) => !e.inTrash).toList();
          _trashEntries = entries.where((e) => e.inTrash).toList();
          _view =
              WorkspaceView.values
                  .where((e) => e.name == data['view'])
                  .firstOrNull ??
              WorkspaceView.inbox;
          _rootId = entries.any((e) => e.id == data['root'] && !e.inTrash)
              ? data['root'] as String?
              : null;
          _selectedId = entries.any((e) => e.id == data['selected'])
              ? data['selected'] as String?
              : null;
          _tab = ['content', 'tasks', 'overview'].contains(data['tab'])
              ? data['tab'] as String
              : 'content';
          _railExpanded = data['railExpanded'] == true;
          _sidebarVisible = data['sidebarVisible'] != false;
          _collapsed.addAll((data['collapsed'] as List? ?? []).cast<String>());
          _archiveCollapsed.addAll(
            (data['archiveCollapsed'] as List? ?? []).cast<String>(),
          );
          _expandedRoots.addAll(
            (data['expandedRoots'] as List? ?? []).cast<String>(),
          );
          _contentSelection.addAll(
            (data['contentSelection'] as Map? ?? {}).cast<String, String>(),
          );
          _taskFilter = TaskFilter.fromJson(
            (data['filter'] as Map? ?? {}).cast<String, dynamic>(),
          );
          _loading = false;
        });
        _lastSavedSession = jsonEncode(_session());
      }
    } catch (error) {
      if (mounted) {
        showMessage(
          context,
          'Die gespeicherte Ansicht konnte nicht geladen werden. Inhalte bleiben erhalten.',
        );
      }
    } finally {
      _sessionLoaded = true;
    }
  }

  Entry? _find(String? id) =>
      [..._entries, ..._trashEntries].where((e) => e.id == id).firstOrNull;
  Entry? get _root => _find(_rootId);
  Entry? get _selected => _find(_selectedId);
  @override
  void initState() {
    super.initState();
    _menuOwner = this;
    _nativeMenu.setMethodCallHandler((call) async {
      if (call.method == 'showSearch' && mounted) await _showSearch();
      if (call.method == 'showSettings' &&
          mounted &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        await _showData();
      }
    });
    _subscription = widget.repository.watchEntries().listen(
      (entries) {
        if (mounted) {
          setState(() {
            _entries = entries;
            _loading = false;
            _loadError = null;
          });
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _loadError = error;
            _loading = false;
          });
        }
      },
    );
    _trashSubscription = widget.repository.watchTrash().listen(
      (entries) {
        if (mounted) setState(() => _trashEntries = entries);
      },
      onError: (Object error) {
        if (mounted) setState(() => _loadError = error);
      },
    );
    _contextSubscription = widget.repository.watchContexts().listen((values) {
      if (mounted) setState(() => _contexts = values);
    });
    _restoreSession();
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        if (!await _canLeave()) return AppExitResponse.cancel;
        await widget.workspaceManager?.mcp?.disable();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    if (_menuOwner == this) {
      _menuOwner = null;
      _nativeMenu.setMethodCallHandler(null);
    }
    _sessionTimer?.cancel();
    _contextSubscription.cancel();
    _workspaceFocus.dispose();
    _subscription.cancel();
    _trashSubscription.cancel();
    _dropController.dispose();
    _lifecycle.dispose();
    super.dispose();
  }

  void _focusWorkspace() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        _workspaceFocus.requestFocus();
      }
    });
  }

  Future<bool> _canLeave() async {
    if (_busy || !(await _editor.currentState?.canLeave() ?? true)) {
      return false;
    }
    await _flushSession();
    return true;
  }

  Future<void> _refresh() async {
    final rows = await widget.repository.getEntries();
    final trash = await widget.repository.getTrash();
    if (mounted) {
      setState(() {
        _entries = rows;
        _trashEntries = trash;
      });
    }
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyLabel = label;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = '';
        });
      }
    }
  }

  Future<void> _navigate(WorkspaceView view) async {
    if (!await _canLeave() || !mounted) return;
    _scaffold.currentState?.closeDrawer();
    setState(() {
      _view = view;
      _rootId = null;
      _selectedId = null;
      _creationFolderId = null;
      _tab = 'content';
    });
    _focusWorkspace();
    if (!_taskNavigation &&
        view != WorkspaceView.archive &&
        view != WorkspaceView.trash) {
      final roots = _explorerRoots;
      final first =
          roots.where((e) => !e.kind.isContainer).firstOrNull ??
          roots.firstOrNull;
      if (first != null && first.kind != EntryKind.folder) {
        await _open(first, guarded: false);
      }
    }
  }

  Future<void> _open(Entry entry, {bool guarded = true}) async {
    if (guarded && !await _canLeave()) return;
    if (!mounted) return;
    _scaffold.currentState?.closeDrawer();
    _focusWorkspace();
    final current = _find(entry.id) ?? entry;
    if (current.inTrash) {
      setState(() {
        _rootId = null;
        _selectedId = current.id;
        _view = WorkspaceView.trash;
      });
      return;
    }
    if (isArchived(current, _entries)) {
      setState(() {
        _rootId = null;
        _selectedId = current.id;
        _view = WorkspaceView.archive;
      });
      return;
    }
    _creationFolderId = current.kind == EntryKind.folder ? current.id : null;
    if (current.kind == EntryKind.folder && current.parentId == null) {
      _expandedRoots.add(current.id);
    }
    final ancestors = ancestorsOf(current, _entries);
    for (final ancestor in ancestors) {
      _collapsed.remove(ancestor.id);
      _expandedRoots.add(ancestor.id);
    }
    final root = current.kind.isContainer && current.kind != EntryKind.folder
        ? current
        : ancestors
                  .where(
                    (e) => e.kind.isContainer && e.kind != EntryKind.folder,
                  )
                  .firstOrNull ??
              (current.kind == EntryKind.folder
                  ? current
                  : ancestors.lastOrNull);
    setState(() {
      _rootId = root?.id;
      _selectedId = root?.id == current.id ? null : current.id;
      _view = isArchived(current, _entries)
          ? WorkspaceView.archive
          : switch (current.section) {
              ParaSection.projects => WorkspaceView.projects,
              ParaSection.areas => WorkspaceView.areas,
              ParaSection.resources => WorkspaceView.resources,
              ParaSection.inbox =>
                current.kind == EntryKind.idea ||
                        current.taskState == TaskState.someday
                    ? WorkspaceView.someday
                    : current.kind == EntryKind.task &&
                          current.taskState == TaskState.next
                    ? WorkspaceView.actions
                    : current.kind == EntryKind.task &&
                          current.taskState == TaskState.waiting
                    ? WorkspaceView.waiting
                    : WorkspaceView.inbox,
            };
      if (root == null) {
        _selectedId = current.id;
      }
      if (root != null &&
          !current.kind.isContainer &&
          current.kind != EntryKind.task) {
        _contentSelection[root.id] = current.id;
      }
      _tab = current.kind == EntryKind.task ? 'tasks' : 'content';
      if (current.kind.isContainer && current.kind != EntryKind.folder) {
        _expandedRoots.add(current.id);
        final docs = _sorted(
          _descendants(current)
              .where(
                (e) => e.kind == EntryKind.note || e.kind == EntryKind.file,
              )
              .toList(),
        );
        final remembered = _find(_contentSelection[current.id]);
        _selectedId =
            remembered != null && docs.any((e) => e.id == remembered.id)
            ? remembered.id
            : (docs
                          .where(
                            (e) =>
                                e.parentId == current.id &&
                                e.kind == EntryKind.note,
                          )
                          .firstOrNull ??
                      docs.firstOrNull)
                  ?.id;
      }
    });
  }

  Future<void> _select(Entry? entry) async {
    if (!await _canLeave() || !mounted) return;
    if (entry != null) _scaffold.currentState?.closeDrawer();
    setState(() {
      _selectedId = entry?.id;
      if (_root != null && entry != null) {
        _tab = entry.kind == EntryKind.task ? 'tasks' : 'content';
        if (entry.kind != EntryKind.task) {
          _contentSelection[_rootId!] = entry.id;
        }
      }
    });
  }

  Future<void> _openTask(Entry entry) async {
    if (!await _canLeave() || !mounted) return;
    final key = GlobalKey<EntryEditorState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future<void> close() async {
          if (await key.currentState?.canLeave() ?? true) {
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
                key.currentState?.save(),
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
                key.currentState?.save(),
          },
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) close();
            },
            child: Dialog(
              child: SizedBox(
                width: 680,
                height: math.min(
                  690,
                  MediaQuery.sizeOf(dialogContext).height - 70,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: close,
                        tooltip: 'Aufgabe schließen',
                        icon: const Icon(LucideIcons.x, size: 18),
                      ),
                    ),
                    Expanded(
                      child: EntryEditor(
                        key: key,
                        entry: _find(entry.id) ?? entry,
                        entries: [..._entries, ..._trashEntries],
                        repository: widget.repository,
                        onOpen: (target) async {
                          if (await key.currentState?.canLeave() ?? true) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            await _open(target);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    await _refresh();
  }

  Future<void> _switchTab(String tab) async {
    if (!await _canLeave() || !mounted) return;
    Entry? selection;
    if (tab == 'content' && _root != null) {
      final previous = _find(_contentSelection[_rootId]);
      final candidates = _descendants(_root!);
      selection = previous != null && candidates.any((e) => e.id == previous.id)
          ? previous
          : candidates
                .where(
                  (e) => e.kind == EntryKind.note || e.kind == EntryKind.file,
                )
                .firstOrNull;
      if (selection != null) {
        for (final ancestor in ancestorsOf(selection, _entries)) {
          _collapsed.remove(ancestor.id);
        }
      }
    }
    setState(() {
      _tab = tab;
      _selectedId = selection?.id;
    });
    _focusWorkspace();
  }

  Future<void> _showSearch({bool filesOnly = false}) async {
    if (_busy || _loading) return;
    _scaffold.currentState?.closeDrawer();
    final result = await showWorkspaceSearch(
      context,
      _entries,
      filesOnly: filesOnly,
    );
    if (result != null && mounted) {
      if (result.kind == EntryKind.task || result.kind == EntryKind.idea) {
        await _openTask(result);
      } else {
        await _open(result);
      }
    }
  }

  void _toggleSidebar() {
    if (MediaQuery.sizeOf(context).width < 760) {
      _scaffold.currentState?.openDrawer();
    } else {
      setState(() => _sidebarVisible = !_sidebarVisible);
    }
  }

  Future<void> _showRootDetails(Entry root) async {
    if (_busy) return;
    final edit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(root.title),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  root.kind.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (root.goal.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(root.goal),
                ],
                if (root.dueDate != null) ...[
                  const SizedBox(height: 12),
                  Text('Fällig am ${dateLabel(root.dueDate!)}'),
                ],
                if (root.completed) const Text('Abgeschlossen'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
          if (!isArchived(root, _entries))
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Details bearbeiten'),
            ),
        ],
      ),
    );
    if (edit == true && mounted) await _entryAction(root, 'edit');
  }

  (ParaSection, String?) _creationLocation(EntryKind kind) {
    if ({
      EntryKind.project,
      EntryKind.area,
      EntryKind.resource,
      EntryKind.idea,
    }.contains(kind)) {
      return (ParaSection.inbox, null);
    }
    final selected = _find(_creationFolderId) ?? _selected;
    if (selected != null &&
        selected.kind == EntryKind.folder &&
        !isArchived(selected, _entries)) {
      return (selected.section, selected.id);
    }
    if (_root != null && !isArchived(_root!, _entries)) {
      final parent = _find(selected?.parentId);
      return (
        _root!.section,
        parent?.kind == EntryKind.folder ? parent!.id : _rootId,
      );
    }
    return (
      _view == WorkspaceView.resources
          ? ParaSection.resources
          : _view == WorkspaceView.areas
          ? ParaSection.areas
          : ParaSection.inbox,
      null,
    );
  }

  Future<void> _create(
    EntryKind kind, {
    bool capture = false,
    DropDestination? destination,
  }) async {
    if (!await _canLeave() || !mounted) return;
    final location =
        destination != null &&
            !{
              EntryKind.project,
              EntryKind.area,
              EntryKind.resource,
              EntryKind.idea,
            }.contains(kind)
        ? (destination.section, destination.parentId)
        : capture
        ? (ParaSection.inbox, null)
        : _creationLocation(kind);
    final taskState = _view == WorkspaceView.someday
        ? TaskState.someday
        : _view == WorkspaceView.waiting
        ? TaskState.waiting
        : _view == WorkspaceView.clarify ||
              _view == WorkspaceView.inbox && location.$2 == null
        ? TaskState.inbox
        : TaskState.next;
    final draft = await showEntryDialog(
      context,
      kind,
      taskState: kind == EntryKind.task ? taskState : TaskState.inbox,
      contexts: _contexts,
    );
    if (draft == null || !mounted) return;
    await _run('Inhalt wird angelegt …', () async {
      final entry = await widget.repository.create(
        kind: kind,
        draft: draft,
        section: location.$1,
        parentId: location.$2,
      );
      await _refresh();
      if (kind == EntryKind.task) {
        if (mounted) {
          setState(() {
            _selectedId = null;
            if (_root != null && belongsTo(entry, _root!.id, _entries)) {
              _tab = 'tasks';
            } else {
              _rootId = null;
              _view = entry.taskState == TaskState.someday
                  ? WorkspaceView.someday
                  : entry.taskState == TaskState.waiting
                  ? WorkspaceView.waiting
                  : WorkspaceView.actions;
            }
          });
        }
      } else {
        await _open(entry, guarded: false);
      }
    });
  }

  Future<void> _createText({DropDestination? destination}) async {
    if (!await _canLeave() || !mounted) return;
    final name = await showRenameDialog(
      context,
      'Neue Textdatei.txt',
      heading: 'Neue Textdatei',
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final filename = name.toLowerCase().endsWith('.txt')
        ? name.trim()
        : '${name.trim()}.txt';
    final location = _creationLocation(EntryKind.file);
    await _run('Textdatei wird angelegt …', () async {
      final entry = await widget.repository.importFile(
        name: filename,
        bytes: const Stream.empty(),
        section: destination?.section ?? location.$1,
        parentId: destination?.parentId ?? location.$2,
      );
      await _refresh();
      await _open(entry, guarded: false);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _editor.currentState?.startEditing(),
      );
    });
  }

  Future<void> _importFolder({DropDestination? destination}) async {
    if (!await _canLeave() || !mounted) return;
    final location = _creationLocation(EntryKind.file);
    try {
      final path = await getDirectoryPath(
        confirmButtonText: 'Ordner hinzufügen',
      );
      if (path != null && mounted) {
        await _receiveFiles(
          [XFile(path)],
          destination ??
              DropDestination(location.$1, location.$2, 'Ordner hinzufügen'),
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, errorLabel(e));
    }
  }

  bool _canMoveDrop(Entry entry, DropDestination destination) {
    if (_busy ||
        isArchived(entry, _entries) ||
        {
          EntryKind.project,
          EntryKind.area,
          EntryKind.resource,
          EntryKind.idea,
        }.contains(entry.kind)) {
      return false;
    }
    if (entry.parentId == destination.parentId &&
        entry.section == destination.section) {
      return false;
    }
    final target = _find(destination.parentId);
    return target == null ||
        target.id != entry.id &&
            !ancestorsOf(target, _entries).any((e) => e.id == entry.id);
  }

  Future<void> _moveDrop(Entry entry, DropDestination destination) async {
    if (!_canMoveDrop(entry, destination) || !await _canLeave() || !mounted) {
      return;
    }
    await _run('Inhalt wird verschoben …', () async {
      await widget.repository.move(
        entry.id,
        destination.section,
        parentId: destination.parentId,
      );
      await _refresh();
      await _open(_find(entry.id)!, guarded: false);
    });
  }

  Widget _dropRegion(
    String id,
    DropDestination destination,
    Widget child, {
    int priority = 20,
    bool enabled = true,
  }) => WorkspaceDropRegion(
    key: ValueKey('drop-$id'),
    id: id,
    controller: _dropController,
    destination: destination,
    priority: priority,
    enabled: enabled && !_busy,
    canMove: _canMoveDrop,
    onMove: _moveDrop,
    child: child,
  );

  Widget _entryContext(Entry entry, Widget child) => EntryContextMenu(
    actions: availableEntryActions(entry, _entries),
    enabled: !_busy,
    onSelected: (action) => _entryAction(entry, action),
    child: child,
  );

  Widget _entrySurface(
    Entry entry,
    Widget child, {
    required String surface,
    bool draggable = true,
  }) {
    Widget result = _entryContext(entry, child);
    result = entryDragSource(
      entry,
      child: result,
      enabled: draggable && !_busy && !isArchived(entry, _entries),
    );
    if (entry.kind.isContainer &&
        !isArchived(entry, _entries) &&
        !entry.completed) {
      result = _dropRegion(
        '$surface-${entry.id}',
        DropDestination(
          entry.section,
          entry.id,
          'Hinzufügen zu: ${entry.title}',
        ),
        result,
        priority: surface == 'tree' || surface == 'folder-content' ? 40 : 20,
      );
    }
    return result;
  }

  Future<void> _receiveFiles(
    List<XFile> files,
    DropDestination destination,
  ) async {
    if (files.isEmpty || !await _canLeave() || !mounted) return;
    await _run('Dateien werden importiert …', () async {
      final importer = WorkspaceImporter(widget.repository);
      Entry? last;
      for (final file in files) {
        last = await importer.importPath(
          file,
          section: destination.section,
          parentId: destination.parentId,
        );
      }
      await _refresh();
      if (last != null) await _open(last, guarded: false);
      if (mounted) showMessage(context, 'Import abgeschlossen.');
    });
  }

  Future<void> _receiveDrop(
    DropDestination destination,
    List<DropItem> files,
  ) async {
    if (_acceptingDrop ||
        _busy ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    setState(() => _acceptingDrop = true);
    final bookmarks = <Uint8List>[];
    try {
      if (Platform.isMacOS) {
        for (final file in files) {
          final bookmark = file.extraAppleBookmark;
          if (bookmark != null &&
              bookmark.isNotEmpty &&
              await DesktopDrop.instance.startAccessingSecurityScopedResource(
                bookmark: bookmark,
              )) {
            bookmarks.add(bookmark);
          }
        }
      }
      await _receiveFiles(files, destination);
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
    } finally {
      for (final bookmark in bookmarks.reversed) {
        try {
          await DesktopDrop.instance.stopAccessingSecurityScopedResource(
            bookmark: bookmark,
          );
        } catch (_) {
          // A cleanup failure must not mask the outcome of an import.
        }
      }
      if (mounted) setState(() => _acceptingDrop = false);
    }
  }

  Future<void> _importFiles({DropDestination? destination}) async {
    if (!await _canLeave() || !mounted) return;
    final location = _creationLocation(EntryKind.file);
    try {
      final files = await openFiles();
      if (!mounted) return;
      await _receiveFiles(
        files,
        destination ??
            DropDestination(location.$1, location.$2, 'Dateien hinzufügen'),
      );
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
    }
  }

  Future<void> _entryAction(Entry entry, String action) async {
    if (!await _canLeave() || !mounted) return;
    if (action == 'trash') {
      await _run('Inhalt wird in den Papierkorb verschoben …', () async {
        await widget.repository.trash(entry.id);
        await _refresh();
        if (mounted) {
          setState(() {
            _rootId = null;
            _selectedId = null;
          });
        }
      });
      return;
    }
    if (action == 'trash-restore') {
      await _restoreTrashed(entry);
      return;
    }
    if (action == 'purge') {
      await _purgeTrash(entry: entry);
      return;
    }
    final destination = DropDestination(entry.section, entry.id, entry.title);
    if (action.startsWith('new-')) {
      if (action == 'new-text') {
        await _createText(destination: destination);
      } else {
        await _create(switch (action) {
          'new-folder' => EntryKind.folder,
          'new-task' => EntryKind.task,
          _ => EntryKind.note,
        }, destination: destination);
      }
      return;
    }
    if (action == 'import-files') {
      await _importFiles(destination: destination);
      return;
    }
    if (action == 'import-folder') {
      await _importFolder(destination: destination);
      return;
    }
    if ({'task-done', 'task-cancel', 'task-resume'}.contains(action)) {
      await _run('Aufgabe wird aktualisiert …', () async {
        await widget.repository.setTaskState(
          entry.id,
          action == 'task-done'
              ? TaskState.done
              : action == 'task-cancel'
              ? TaskState.cancelled
              : entry.previousTaskState ?? TaskState.next,
        );
        await _refresh();
      });
      return;
    }
    if (action == 'rename') {
      final title = await showRenameDialog(
        context,
        entry.title,
        heading: 'Umbenennen',
      );
      if (title != null && mounted) {
        await _run('Inhalt wird umbenannt …', () async {
          final snapshot = await widget.repository.readNote(entry.id);
          await widget.repository.save(
            id: entry.id,
            expectedRevision: entry.revision,
            expectedBodyHash: snapshot.hash,
            draft: EntryDraft(
              title: title,
              body: snapshot.text,
              goal: entry.goal,
              dueDate: entry.dueDate,
              taskState: entry.taskState,
              context: entry.context,
            ),
          );
          await _refresh();
        });
      }
      return;
    }
    if (action == 'convert') {
      final current = _find(entry.id) ?? entry;
      final draft = await showEntryDialog(
        context,
        EntryKind.project,
        initialDraft: EntryDraft(
          title: current.title,
          goal: current.goal,
          dueDate: current.dueDate,
        ),
        heading: 'In Projekt umwandeln',
        submitLabel: 'Umwandeln',
      );
      if (draft == null || !mounted) return;
      await _run('Projekt wird angelegt …', () async {
        final project = await widget.repository.convertToProject(
          current.id,
          draft: draft,
          expectedRevision: current.revision,
        );
        await _refresh();
        await _open(project, guarded: false);
      });
      return;
    }
    if (action == 'restore' &&
        ancestorsOf(entry, _entries).any((e) => e.archived)) {
      final destination = await showMoveDialog(context, entry, _entries);
      if (destination == null || !mounted) return;
      await _run('Inhalt wird wiederhergestellt …', () async {
        await widget.repository.restoreTo(
          entry.id,
          destination.section,
          parentId: destination.parentId,
        );
        await _refresh();
        await _open(_find(entry.id)!, guarded: false);
      });
      return;
    }
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: markdownLink(entry)));
      if (mounted) showMessage(context, 'Markdown-Link kopiert.');
      return;
    }
    if (action == 'edit') {
      if (entry.kind == EntryKind.task || entry.kind == EntryKind.idea) {
        await _openTask(entry);
        return;
      }
      if (entry.kind == EntryKind.note || entry.kind == EntryKind.file) {
        await _open(entry, guarded: false);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _editor.currentState?.startEditing(),
        );
        return;
      }
      if (entry.kind == EntryKind.folder) {
        final title = await showRenameDialog(context, entry.title);
        if (title != null && mounted) {
          await _run('Ordner wird umbenannt …', () async {
            final body = await widget.repository.readNote(entry.id);
            await widget.repository.save(
              id: entry.id,
              expectedRevision: entry.revision,
              expectedBodyHash: body.hash,
              draft: EntryDraft(title: title, body: body.text),
            );
            await _refresh();
          });
        }
        return;
      }
      await _open(_find(entry.id) ?? entry, guarded: false);
      if (!mounted) return;
      setState(() {
        _selectedId = entry.id;
        _tab = 'overview';
      });
      return;
    }
    if (action == 'move') {
      final target = await showMoveDialog(context, entry, _entries);
      if (target == null || !mounted) return;
      await _run('Inhalt wird verschoben …', () async {
        await widget.repository.move(
          entry.id,
          target.section,
          parentId: target.parentId,
        );
        await _refresh();
        await _open(_find(entry.id)!, guarded: false);
      });
      return;
    }
    await _run('Arbeitsbereich wird aktualisiert …', () async {
      if (action == 'complete') {
        await widget.repository.completeProject(entry.id);
      }
      if (action == 'archive') await widget.repository.archive(entry.id, true);
      if (action == 'restore') await widget.repository.archive(entry.id, false);
      await _refresh();
      if (mounted) {
        setState(() {
          _rootId = null;
          _selectedId = null;
        });
      }
    });
  }

  Future<void> _toggleTask(Entry entry) async {
    if (!await _canLeave() || !mounted) return;
    await _run('Aufgabe wird aktualisiert …', () async {
      await widget.repository.setTaskState(
        entry.id,
        entry.taskState.isClosed
            ? entry.previousTaskState ?? TaskState.next
            : TaskState.done,
      );
      await _refresh();
    });
  }

  Future<void> _restoreTrashed(Entry entry) async {
    MoveTarget? target;
    final originalParent = _entries
        .where((e) => e.id == entry.parentId)
        .firstOrNull;
    if (entry.parentId != null && originalParent == null) {
      target = await showMoveDialog(context, entry, _entries);
      if (target == null || !mounted) return;
    }
    await _run('Inhalt wird wiederhergestellt …', () async {
      await widget.repository.restoreTrash(
        entry.id,
        section: target?.section,
        parentId: target?.parentId,
      );
      await _refresh();
      final restored = _find(entry.id);
      if (restored != null && mounted) await _open(restored, guarded: false);
    });
  }

  Future<void> _purgeTrash({Entry? entry}) async {
    if (!await _canLeave() || !mounted) return;
    final affected = _trashEntries
        .where(
          (e) =>
              entry == null ||
              e.id == entry.id ||
              belongsTo(e, entry.id, _trashEntries),
        )
        .toList();
    if (affected.isEmpty) return;
    final ids = affected.map((e) => e.id).toSet(), references = <String>{};
    try {
      for (final item in affected) {
        references.addAll(
          (await widget.repository.backlinks(
            item.id,
          )).where((e) => !ids.contains(e.id)).map((e) => e.id),
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          entry == null ? 'Papierkorb leeren?' : 'Endgültig entfernen?',
        ),
        content: Text(
          '${affected.length} ${affected.length == 1 ? 'Inhalt' : 'Inhalte'}${entry?.kind.isContainer == true ? ' einschließlich enthaltener Inhalte' : ''} '
          'und ihre Textversionen werden endgültig entfernt. '
          'Das lässt sich in der App nicht rückgängig machen.\n\n'
          '${references.isEmpty ? 'Keine gespeicherten Rückverweise gefunden.' : '${references.length} ${references.length == 1 ? 'anderer Inhalt verweist' : 'andere Inhalte verweisen'} darauf; diese Links verlieren ihr Ziel.'}\n\n'
          'Bereits erstellte Sicherungen bleiben unverändert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const ValueKey('confirm-purge'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              entry == null ? 'Papierkorb leeren' : 'Endgültig entfernen',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run('Inhalte werden endgültig entfernt …', () async {
      if (entry == null) {
        await widget.repository.emptyTrash();
      } else {
        await widget.repository.permanentlyDelete(entry.id);
      }
      await _refresh();
      if (mounted && _selected == null) setState(() => _selectedId = null);
    });
  }

  Widget _trashExplorer() {
    final byId = {for (final e in _trashEntries) e.id: e};
    final roots = _trashEntries
        .where(
          (e) =>
              byId[e.parentId]?.trashBatchId != e.trashBatchId ||
              !byId.containsKey(e.parentId),
        )
        .toList();
    List<Widget> rows(Entry entry, int depth) {
      final children = _trashEntries
          .where(
            (e) =>
                e.parentId == entry.id && e.trashBatchId == entry.trashBatchId,
          )
          .toList();
      final expanded = !_collapsed.contains('trash-${entry.id}');
      return [
        _entryContext(
          entry,
          Padding(
            padding: EdgeInsets.only(left: math.min(depth, 8) * 12.0),
            child: ListTile(
              key: ValueKey('trash-entry-${entry.id}'),
              dense: true,
              contentPadding: const EdgeInsets.only(left: 3),
              minLeadingWidth: 18,
              leading: children.isEmpty
                  ? Icon(fileIcon(entry), size: 16)
                  : IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 20,
                        height: 24,
                      ),
                      tooltip: expanded ? 'Zuklappen' : 'Aufklappen',
                      onPressed: () => setState(() {
                        if (!_collapsed.add('trash-${entry.id}')) {
                          _collapsed.remove('trash-${entry.id}');
                        }
                      }),
                      icon: Icon(
                        expanded
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: 15,
                      ),
                    ),
              title: Text(
                entryFileLabel(entry),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              subtitle: Text(
                entry.kind.label,
                style: const TextStyle(fontSize: 10),
              ),
              selected: _selectedId == entry.id,
              trailing: _entryMenu(entry),
              onTap: () async {
                await _open(entry);
                if (children.isNotEmpty && mounted) {
                  setState(() {
                    if (!_collapsed.add('trash-${entry.id}')) {
                      _collapsed.remove('trash-${entry.id}');
                    }
                  });
                }
              },
            ),
          ),
        ),
        if (expanded)
          for (final child in children) ...rows(child, depth + 1),
      ];
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 6, 14),
      children: [
        if (roots.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Der Papierkorb ist leer.'),
          ),
        for (final root in roots) ...rows(root, 0),
      ],
    );
  }

  Widget _trashView() {
    final selected = _trashEntries
        .where((e) => e.id == _selectedId)
        .firstOrNull;
    if (selected == null) {
      return const EmptyState(
        icon: LucideIcons.trash2,
        title: 'Papierkorb',
        description:
            'Entfernte Inhalte bleiben hier bis zum Leeren erhalten. '
            'Wähle links einen Inhalt zum Ansehen oder Wiederherstellen.',
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Im Papierkorb · ${dateLabel(selected.deletedAt!)}\n'
                  'Bisheriger Ort: ${selected.trashLocation ?? selected.section.label}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('restore-trash'),
                onPressed: _busy ? null : () => _restoreTrashed(selected),
                icon: const Icon(LucideIcons.undo2, size: 15),
                label: const Text('Wiederherstellen'),
              ),
            ],
          ),
        ),
        Expanded(child: _editorFor(selected)),
      ],
    );
  }

  Future<void> _backup() async {
    if (!await _canLeave() || !mounted) return;
    try {
      final destination = await getDirectoryPath(
        confirmButtonText: 'Sicherung hier speichern',
      );
      if (destination == null || !mounted) return;
      await _run('Sicherung wird erstellt …', () async {
        final result = await widget.repository.exportBackup(destination);
        if (mounted) showMessage(context, 'Sicherung gespeichert: $result');
      });
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
    }
  }

  Future<void> _showData({int tab = 0}) async {
    if (!await _canLeave() || !mounted) return;
    final manager = widget.workspaceManager;
    final action = await showWorkspaceSettings(
      context,
      widget.repository,
      widget.dataDirectory,
      canChangeRoot: manager != null && !manager.testOverride,
      tab: tab,
      mcp: manager?.mcp,
    );
    if (action == null || !mounted) return;
    if (action == SettingsAction.backup) {
      await _backup();
      return;
    }
    if (manager == null) return;
    try {
      final selected = await manager.access.choose();
      if (selected == null || !mounted) return;
      final mode = action == SettingsAction.open
          ? WorkspaceOpenMode.open
          : action == SettingsAction.create
          ? WorkspaceOpenMode.create
          : WorkspaceOpenMode.copyCurrent;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            action == SettingsAction.copy
                ? 'Arbeitsbereich kopieren und öffnen?'
                : action == SettingsAction.create
                ? 'Neuen Arbeitsbereich anlegen?'
                : 'Arbeitsbereich öffnen?',
          ),
          content: Text(
            '${selected.path}\n\n${action == SettingsAction.copy
                ? 'Alle Inhalte und Einstellungen werden vollständig kopiert und geprüft. Der bisherige Ordner bleibt als Rückfallkopie erhalten.'
                : action == SettingsAction.create
                ? 'Ein leerer Arbeitsbereich mit eigenen Einstellungen wird angelegt. Der bisherige Bestand bleibt erhalten.'
                : 'Inhalte und Einstellungen dieses Ordners werden geladen. Der bisherige Bestand bleibt erhalten; beide werden nicht zusammengeführt.'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              key: const ValueKey('confirm-workspace-change'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Fortfahren'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _flushSession();
      await _run(
        'Arbeitsbereich wird vorbereitet …',
        () => manager.switchTo(selected, mode),
      );
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
    }
  }

  List<Entry> _rowsFor(WorkspaceView view) => _entries.where((e) {
    final archived = isArchived(e, _entries);
    if (view == WorkspaceView.archive) {
      return e.archived &&
          !ancestorsOf(e, _entries).any((parent) => parent.archived);
    }
    if (archived) return false;
    return switch (view) {
      WorkspaceView.inbox =>
        e.kind == EntryKind.task
            ? e.taskState == TaskState.inbox
            : e.section == ParaSection.inbox &&
                  e.parentId == null &&
                  e.kind != EntryKind.idea,
      WorkspaceView.projects => e.kind == EntryKind.project,
      WorkspaceView.areas =>
        e.section == ParaSection.areas && e.parentId == null,
      WorkspaceView.resources =>
        e.section == ParaSection.resources && e.parentId == null,
      WorkspaceView.actions =>
        isActiveTask(e, _entries) && e.taskState == TaskState.next,
      WorkspaceView.waiting =>
        isActiveTask(e, _entries) && e.taskState == TaskState.waiting,
      WorkspaceView.someday =>
        e.kind == EntryKind.idea ||
            isActiveTask(e, _entries) && e.taskState == TaskState.someday,
      WorkspaceView.allTasks => isActiveTask(e, _entries),
      WorkspaceView.clarify =>
        isActiveTask(e, _entries) && e.taskState == TaskState.inbox,
      WorkspaceView.done =>
        isActiveTask(e, _entries) && e.taskState == TaskState.done,
      WorkspaceView.cancelled =>
        isActiveTask(e, _entries) && e.taskState == TaskState.cancelled,
      WorkspaceView.archive || WorkspaceView.trash => false,
    };
  }).toList();

  bool get _taskNavigation => {
    WorkspaceView.allTasks,
    WorkspaceView.actions,
    WorkspaceView.waiting,
    WorkspaceView.someday,
    WorkspaceView.clarify,
    WorkspaceView.done,
    WorkspaceView.cancelled,
  }.contains(_view);

  Widget _railButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool selected = false,
    Key? key,
  }) {
    final c = WorkspaceColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: label,
        child: Material(
          color: selected ? c.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(6),
            onTap: _busy ? null : onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: selected ? c.accent : c.ink),
                  if (_railExpanded) ...[
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? c.accent : c.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rail() {
    final c = WorkspaceColors(context);
    Widget nav(WorkspaceView view) {
      Widget row = _railButton(
        view.label,
        view.icon,
        () => _navigate(view),
        selected: !_taskNavigation && _view == view,
        key: ValueKey('nav-${view.name}'),
      );
      if ({
        WorkspaceView.inbox,
        WorkspaceView.areas,
        WorkspaceView.resources,
      }.contains(view)) {
        final section = view == WorkspaceView.inbox
            ? ParaSection.inbox
            : view == WorkspaceView.areas
            ? ParaSection.areas
            : ParaSection.resources;
        row = _dropRegion(
          'nav-${view.name}',
          DropDestination(section, null, 'Hinzufügen zu: ${section.label}'),
          row,
        );
      }
      return row;
    }

    return Container(
      key: const ValueKey('navigation-rail'),
      width: _railExpanded ? 164 : 56,
      decoration: BoxDecoration(
        color: c.rail,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 10, 7, 10),
        child: Column(
          children: [
            _railButton(
              _railExpanded ? 'Einklappen' : 'Navigationsnamen einblenden',
              _railExpanded
                  ? LucideIcons.panelLeftClose
                  : LucideIcons.panelLeftOpen,
              () => setState(() => _railExpanded = !_railExpanded),
              key: const ValueKey('rail-expand'),
            ),
            const SizedBox(height: 9),
            _railButton(
              'Suche',
              LucideIcons.search,
              _showSearch,
              key: const ValueKey('workspace-search'),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final view in WorkspaceView.values.take(5)) nav(view),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Divider(height: 1, color: c.line),
                    ),
                    _railButton(
                      'Alle Aufgaben',
                      LucideIcons.listTodo,
                      () => _navigate(WorkspaceView.allTasks),
                      selected: _taskNavigation,
                      key: const ValueKey('nav-tasks'),
                    ),
                    nav(WorkspaceView.trash),
                  ],
                ),
              ),
            ),
            _railButton(
              'Menü',
              LucideIcons.menu,
              _showMenu,
              key: const ValueKey('workspace-menu'),
            ),
            Tooltip(
              message: 'Lokal · Daten & Sicherung',
              child: InkWell(
                onTap: _showData,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: c.accent),
                      if (_railExpanded) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Lokal auf dem Mac',
                            style: TextStyle(fontSize: 11, color: c.soft),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenu() async {
    final data = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menü'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.database, size: 19),
                title: const Text('Daten & Sicherung'),
                subtitle: const Text(
                  'Arbeitsbereiche öffnen, kopieren und sichern',
                ),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.settings, size: 19),
                title: const Text('Einstellungen'),
                subtitle: const Text('Aufgaben und Kontexte'),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
    if (data != null && mounted) await _showData(tab: data ? 0 : 1);
  }

  Widget _sidebar() => Row(
    children: [
      _rail(),
      Expanded(child: _explorer()),
    ],
  );

  Widget _explorer() {
    final c = WorkspaceColors(context),
        location = _creationLocation(EntryKind.note);
    final folder = _find(location.$2);
    final caption = _view == WorkspaceView.trash
        ? '${_trashEntries.length} ${_trashEntries.length == 1 ? 'Inhalt' : 'Inhalte'} · bleiben bis zum Leeren erhalten'
        : _view == WorkspaceView.archive
        ? 'Archivierte Inhalte'
        : _taskNavigation
        ? 'Aufgaben verwalten'
        : 'Neu in: ${folder?.title ?? location.$1.label}';
    return Container(
      key: const ValueKey('explorer-sidebar'),
      decoration: BoxDecoration(
        color: c.sidebar,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 10, 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _taskNavigation ? 'Alle Aufgaben' : _view.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _newMenu(),
                if (!_taskNavigation && _view != WorkspaceView.trash)
                  IconButton(
                    tooltip: 'Alles ein-/ausklappen',
                    onPressed: () => setState(() {
                      if (_view == WorkspaceView.archive) {
                        final keys = <String>[];
                        void collect(List<ArchiveNode> nodes) {
                          for (final node in nodes) {
                            keys.add(node.key);
                            collect(node.children);
                          }
                        }

                        collect(buildArchiveTree(_entries));
                        if (keys.any(
                          (key) => !_archiveCollapsed.contains(key),
                        )) {
                          _archiveCollapsed.addAll(keys);
                        } else {
                          _archiveCollapsed.clear();
                        }
                        return;
                      }
                      final roots = _explorerRoots;
                      if (roots.any((e) => _expandedRoots.contains(e.id))) {
                        _expandedRoots.clear();
                      } else {
                        _expandedRoots.addAll(roots.map((e) => e.id));
                        _collapsed.clear();
                        _archiveCollapsed.clear();
                      }
                    }),
                    icon: const Icon(LucideIcons.chevronsDownUp, size: 15),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 9),
            child: Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: c.soft),
            ),
          ),
          Expanded(
            child: _view == WorkspaceView.trash
                ? _trashExplorer()
                : _view == WorkspaceView.archive
                ? _archiveTree()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                    children: _taskNavigation
                        ? [
                            for (final view in [
                              WorkspaceView.allTasks,
                              WorkspaceView.actions,
                              WorkspaceView.waiting,
                              WorkspaceView.clarify,
                              WorkspaceView.someday,
                              WorkspaceView.done,
                              WorkspaceView.cancelled,
                            ])
                              Material(
                                color: _view == view
                                    ? c.selected
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                child: ListTile(
                                  key: ValueKey('task-nav-${view.name}'),
                                  dense: true,
                                  minTileHeight: 34,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                  ),
                                  horizontalTitleGap: 8,
                                  minLeadingWidth: 16,
                                  leading: Icon(view.icon, size: 15),
                                  title: Text(
                                    view.label,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  selected: _view == view,
                                  selectedTileColor: c.selected,
                                  selectedColor: c.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onTap: () => _navigate(view),
                                ),
                              ),
                          ]
                        : [
                            for (final entry in _explorerRoots) ...[
                              _treeRow(entry, 0, root: true),
                              if (entry.kind.isContainer &&
                                  _expandedRoots.contains(entry.id))
                                ..._treeRows(entry.id, 1),
                            ],
                            if (_view == WorkspaceView.projects)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(7, 24, 0, 0),
                                child: Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.flag,
                                      size: 13,
                                      color: c.soft,
                                    ),
                                    Text(
                                      'Projekt  ·',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.soft,
                                      ),
                                    ),
                                    Icon(
                                      LucideIcons.folder,
                                      size: 13,
                                      color: c.soft,
                                    ),
                                    Text(
                                      'Ordner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.soft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Entry> get _explorerRoots {
    final section = switch (_view) {
      WorkspaceView.projects => ParaSection.projects,
      WorkspaceView.areas => ParaSection.areas,
      WorkspaceView.resources => ParaSection.resources,
      _ => ParaSection.inbox,
    };
    return _sorted(
      _entries
          .where(
            (e) =>
                e.section == section &&
                e.parentId == null &&
                !isArchived(e, _entries) &&
                e.kind != EntryKind.task &&
                e.kind != EntryKind.idea,
          )
          .toList(),
    );
  }

  List<Entry> _sorted(List<Entry> rows) => rows
    ..sort((a, b) {
      final order = (a.kind.isContainer ? 0 : 1).compareTo(
        b.kind.isContainer ? 0 : 1,
      );
      return order != 0
          ? order
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

  Widget _treeRow(Entry entry, int depth, {bool root = false}) {
    final c = WorkspaceColors(context), container = entry.kind.isContainer;
    final expanded = root
        ? _expandedRoots.contains(entry.id)
        : !_collapsed.contains(entry.id);
    final selected = _selectedId == entry.id && _tab != 'tasks';
    return _entrySurface(
      entry,
      Container(
        key: ValueKey('tree-entry-${entry.id}'),
        decoration: BoxDecoration(
          color: selected ? c.selected : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () async {
                  if (entry.kind == EntryKind.folder) {
                    setState(() {
                      _creationFolderId = entry.id;
                      if (root) {
                        if (!_expandedRoots.add(entry.id)) {
                          _expandedRoots.remove(entry.id);
                        }
                      } else if (!_collapsed.add(entry.id)) {
                        _collapsed.remove(entry.id);
                      }
                    });
                  } else if (container) {
                    final wasOpen = expanded;
                    await _open(entry);
                    if (mounted && wasOpen) {
                      setState(() => _expandedRoots.remove(entry.id));
                    }
                  } else {
                    await _open(entry);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    5 + math.min(depth, 8) * 14,
                    5,
                    2,
                    5,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 24),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          child: container
                              ? Icon(
                                  expanded
                                      ? LucideIcons.chevronDown
                                      : LucideIcons.chevronRight,
                                  size: 12,
                                  color: c.soft,
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          entry.kind == EntryKind.folder && expanded
                              ? LucideIcons.folderOpen
                              : fileIcon(entry),
                          size: 15,
                          color: entry.kind == EntryKind.project || selected
                              ? c.accent
                              : c.soft,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Tooltip(
                            message: entryFileLabel(entry),
                            child: Text(
                              entryFileLabel(entry),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.55,
                                fontWeight: entry.kind == EntryKind.project
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: selected ? c.accent : c.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _entryMenu(entry),
          ],
        ),
      ),
      surface: 'tree',
      draggable: !container || entry.kind == EntryKind.folder,
    );
  }

  Widget _archiveTree() {
    List<Widget> rows(List<ArchiveNode> nodes, int depth) => [
      for (final node in nodes) ...[
        if (node.entry != null)
          _entryContext(node.entry!, _archiveNodeRow(node, depth))
        else
          _archiveNodeRow(node, depth),
        if (!_archiveCollapsed.contains(node.key))
          ...rows(node.children, depth + 1),
      ],
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
      children: rows(buildArchiveTree(_entries), 0),
    );
  }

  Widget _archiveNodeRow(ArchiveNode node, int depth) {
    final c = WorkspaceColors(context),
        branch = node.children.isNotEmpty || node.isFolder,
        open = !_archiveCollapsed.contains(node.key);
    return Container(
      key: ValueKey('archive-node-${node.key}'),
      color: _selectedId == node.entry?.id ? c.selected : null,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                if (branch) {
                  setState(() {
                    if (!_archiveCollapsed.add(node.key)) {
                      _archiveCollapsed.remove(node.key);
                    }
                  });
                }
                if (node.entry != null && !branch) await _open(node.entry!);
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  5 + math.min(depth, 8) * 14,
                  6,
                  2,
                  6,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      child: branch
                          ? Icon(
                              open
                                  ? LucideIcons.chevronDown
                                  : LucideIcons.chevronRight,
                              size: 12,
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      node.kind == EntryKind.project
                          ? LucideIcons.flag
                          : branch
                          ? LucideIcons.folder
                          : fileIcon(node.entry!),
                      size: 15,
                      color: c.soft,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        node.entry == null
                            ? node.title
                            : entryFileLabel(node.entry!),
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (node.entry != null) _entryMenu(node.entry!),
        ],
      ),
    );
  }

  List<EntryKind> get _newKinds {
    if (_root != null) {
      return [EntryKind.note, EntryKind.task, EntryKind.folder, EntryKind.file];
    }
    return switch (_view) {
      WorkspaceView.projects => [EntryKind.project],
      WorkspaceView.areas => [
        EntryKind.area,
        EntryKind.note,
        EntryKind.folder,
        EntryKind.file,
      ],
      WorkspaceView.resources => [
        EntryKind.resource,
        EntryKind.note,
        EntryKind.folder,
        EntryKind.file,
      ],
      WorkspaceView.someday => [EntryKind.idea, EntryKind.task],
      WorkspaceView.actions ||
      WorkspaceView.waiting ||
      WorkspaceView.allTasks ||
      WorkspaceView.clarify ||
      WorkspaceView.done ||
      WorkspaceView.cancelled => [EntryKind.task],
      _ => [
        EntryKind.note,
        EntryKind.task,
        EntryKind.idea,
        EntryKind.folder,
        EntryKind.file,
      ],
    };
  }

  Widget _newMenu() => PopupMenuButton<String>(
    enabled:
        !_busy &&
        _view != WorkspaceView.archive &&
        _view != WorkspaceView.trash,
    tooltip: 'Neuen Inhalt anlegen',
    onSelected: (action) {
      if (action == 'text') {
        _createText();
      } else if (action == 'folder-import') {
        _importFolder();
      } else if (action == EntryKind.file.name) {
        _importFiles();
      } else {
        _create(EntryKind.values.byName(action));
      }
    },
    itemBuilder: (_) => [
      for (final kind in _newKinds)
        PopupMenuItem(
          value: kind.name,
          child: Row(
            children: [
              Icon(entryIcon(kind), size: 16),
              const SizedBox(width: 9),
              Text(
                kind == EntryKind.file
                    ? 'Dateien hinzufügen …'
                    : '${kind.label} anlegen',
              ),
            ],
          ),
        ),
      if (!_taskNavigation &&
          (_root != null ||
              _view == WorkspaceView.inbox ||
              _view == WorkspaceView.areas ||
              _view == WorkspaceView.resources)) ...[
        const PopupMenuItem(value: 'text', child: Text('Neue Textdatei …')),
        const PopupMenuItem(
          value: 'folder-import',
          child: Text('Ordner hinzufügen …'),
        ),
      ],
      if (_view == WorkspaceView.projects && _root != null)
        const PopupMenuItem(value: 'project', child: Text('Projekt anlegen')),
    ],
    icon: const Icon(LucideIcons.plus, size: 18),
    padding: EdgeInsets.zero,
  );

  Widget _projectTabs({bool compact = false}) {
    final c = WorkspaceColors(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.sidebar,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tab in [
            ('content', 'Inhalte', LucideIcons.files),
            ('tasks', 'Aufgaben', LucideIcons.listTodo),
          ])
            TextButton.icon(
              onPressed: () => _switchTab(tab.$1),
              style: TextButton.styleFrom(
                backgroundColor: (_tab == 'tasks') == (tab.$1 == 'tasks')
                    ? c.selected
                    : null,
                foregroundColor: (_tab == 'tasks') == (tab.$1 == 'tasks')
                    ? c.accent
                    : c.ink,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 5 : 8,
                  vertical: 4,
                ),
                minimumSize: const Size(0, 27),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              icon: Icon(tab.$3, size: 14),
              label: Text(tab.$2, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _workspaceHeader({
    required bool wide,
    required bool sidebarShown,
    required double width,
  }) {
    final c = WorkspaceColors(context), root = _root;
    final selected = _selected;
    final archivedRoot =
        _view != WorkspaceView.trash &&
            selected != null &&
            isArchived(selected, _entries)
        ? ancestorsOf(
            selected,
            _entries,
          ).where((e) => e.kind == EntryKind.project).firstOrNull
        : null;
    final heading = root ?? archivedRoot;
    final title =
        heading?.title ?? (_taskNavigation ? 'Alle Aufgaben' : _view.label);
    final meta = heading != null
        ? '${isArchived(heading, _entries) ? 'Archiviert · ' : ''}${heading.goal.isEmpty ? heading.kind.label : 'Ergebnis: ${heading.goal}'}${heading.dueDate == null ? '' : ' · ${dateLabel(heading.dueDate!)}'}'
        : _taskNavigation
        ? 'Projektübergreifend · dieselben Aufgaben'
        : _view == WorkspaceView.trash
        ? '${_trashEntries.length} ${_trashEntries.length == 1 ? 'Inhalt' : 'Inhalte'} · keine automatische Leerung'
        : _view == WorkspaceView.archive
        ? 'Nach Jahr und Herkunft'
        : 'Notizen und Dateien';
    return Container(
      key: const ValueKey('workspace-header'),
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final label = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading == null
                  ? Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Tooltip(
                      message: 'Projektdetails',
                      child: InkWell(
                        onTap: () => _showRootDetails(heading),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
              Text(
                meta,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.soft),
              ),
            ],
          );
          final controls = _view == WorkspaceView.trash
              ? TextButton.icon(
                  key: const ValueKey('empty-trash'),
                  onPressed: _busy || _trashEntries.isEmpty
                      ? null
                      : () => _purgeTrash(),
                  icon: const Icon(LucideIcons.trash2, size: 15),
                  label: const Text('Papierkorb leeren'),
                )
              : heading != null
              ? _projectTabs(compact: bounds.maxWidth < 420)
              : null;
          return Row(
            children: [
              if (!sidebarShown) ...[
                IconButton(
                  key: const ValueKey('sidebar-toggle'),
                  tooltip: !wide
                      ? 'Navigation öffnen'
                      : 'Seitenleiste einblenden',
                  onPressed: _toggleSidebar,
                  icon: const Icon(LucideIcons.panelLeftOpen, size: 18),
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: bounds.maxWidth < 440 && controls != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [label, const SizedBox(height: 7), controls],
                      )
                    : label,
              ),
              if (controls != null && bounds.maxWidth >= 440) ...[
                const SizedBox(width: 12),
                controls,
              ],
              if (!sidebarShown) _newMenu(),
            ],
          );
        },
      ),
    );
  }

  Widget _statusBar() {
    final c = WorkspaceColors(context), entry = _selected;
    final text = _tab == 'tasks' && _root != null
        ? 'Projektaufgaben · ${_root!.title}'
        : entry == null
        ? _view.label
        : [
            entry.section.label,
            ...ancestorsOf(entry, _entries).reversed.map((e) => e.title),
            entryFileLabel(entry),
          ].join(' / ');
    return Container(
      height: 37,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: c.soft),
      ),
    );
  }

  Widget _entryMenu(Entry entry) => SizedBox(
    width: 25,
    height: 30,
    child: PopupMenuButton<String>(
      enabled: !_busy,
      padding: EdgeInsets.zero,
      icon: const Icon(LucideIcons.ellipsis, size: 16),
      tooltip: 'Aktionen für ${entry.title}',
      onSelected: (action) => _entryAction(entry, action),
      itemBuilder: (_) =>
          actionMenuItems(availableEntryActions(entry, _entries)),
    ),
  );

  String _entrySubtitle(Entry entry) {
    final parent = _find(entry.parentId);
    return [
      entry.kind.label,
      if (parent != null) parent.title,
      if (entry.kind == EntryKind.project && entry.dueDate != null)
        'Bis ${dateLabel(entry.dueDate!)}',
      if (entry.kind == EntryKind.task) entry.taskState.label,
      if (isArchived(entry, _entries)) 'Archiviert',
    ].join(' · ');
  }

  Widget _entryTile(Entry entry) => _entrySurface(
    entry,
    ListTile(
      key: ValueKey('entry-${entry.id}'),
      leading: Icon(entryIcon(entry.kind), size: 21),
      title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _entrySubtitle(entry),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: isOverdue(entry) ? Theme.of(context).colorScheme.error : null,
        ),
      ),
      selected: _selectedId == entry.id,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      trailing: _entryMenu(entry),
      onTap: () => entry.kind.isContainer ? _open(entry) : _select(entry),
    ),
    surface: 'list',
  );
  Widget _editorFor(Entry entry, {VoidCallback? onBack}) => _entryContext(
    entry,
    EntryEditor(
      key: _editor,
      entry: entry,
      entries: [..._entries, ..._trashEntries],
      repository: widget.repository,
      busy: _busy,
      onOpen: _open,
      onBack: onBack,
      actionMenu: _entryMenu(entry),
    ),
  );

  Widget _globalView(BoxConstraints constraints) {
    if (_view == WorkspaceView.trash) return _trashView();
    if (_view == WorkspaceView.archive) return _archiveView(constraints);
    if (_taskNavigation) return _buildGlobalView(constraints);
    final entry = _selected;
    final content = entry != null && !entry.kind.isContainer
        ? _editorFor(entry)
        : EmptyState(
            icon: _view.icon,
            title: _view.label,
            description:
                'Öffne einen Inhalt im Explorer oder füge etwas hinzu.',
            action: TextButton.icon(
              onPressed: () => _create(_newKinds.first),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('${_newKinds.first.label} anlegen'),
            ),
          );
    final section = _view == WorkspaceView.areas
        ? ParaSection.areas
        : _view == WorkspaceView.resources
        ? ParaSection.resources
        : ParaSection.inbox;
    if (_view == WorkspaceView.projects) return content;
    return _dropRegion(
      'section-content',
      DropDestination(section, null, 'Hinzufügen zu: ${section.label}'),
      content,
      priority: 0,
    );
  }

  Widget _archiveView(BoxConstraints constraints) => _selected == null
      ? const EmptyState(
          icon: LucideIcons.archive,
          title: 'Archiv',
          description:
              'Öffne einen Inhalt links. Die ursprüngliche Struktur bleibt erhalten.',
        )
      : _editorFor(_selected!);

  Widget _buildGlobalView(BoxConstraints constraints) {
    final rows = _rowsFor(_view);
    final taskView = _taskNavigation;
    final description = switch (_view) {
      WorkspaceView.inbox => 'Dateien oder Markdown hierher ziehen',
      WorkspaceView.projects =>
        'Ein konkretes Ergebnis und ein Fälligkeitsdatum.',
      WorkspaceView.areas => 'Deine laufenden Verantwortungsbereiche.',
      WorkspaceView.resources => 'Notizen, Dateien und Wissen sammeln.',
      WorkspaceView.someday => 'Ideen und zurückgestellte Aufgaben sammeln.',
      _ => 'Hier ist gerade nichts offen.',
    };
    final Widget list = rows.isEmpty
        ? EmptyState(
            icon: _view.icon,
            title: switch (_view) {
              WorkspaceView.projects => 'Dein erstes Projekt',
              WorkspaceView.inbox => 'Platz für deine Gedanken',
              WorkspaceView.someday => 'Ideen für später',
              _ => _view.label,
            },
            description: description,
            action:
                {
                  WorkspaceView.archive,
                  WorkspaceView.actions,
                  WorkspaceView.waiting,
                }.contains(_view)
                ? null
                : TextButton.icon(
                    onPressed: () => _create(_newKinds.first),
                    icon: const Icon(Icons.add, size: 17),
                    label: Text('${_newKinds.first.label} anlegen'),
                  ),
          )
        : taskView
        ? _taskList(rows)
        : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: rows.length,
            itemBuilder: (_, index) => _entryTile(rows[index]),
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
          );
    final selected = _selected;
    if (selected == null) return list;
    if (constraints.maxWidth < 780) {
      return _editorFor(selected, onBack: () => _select(null));
    }
    return Row(
      children: [
        SizedBox(width: 270, child: list),
        const VerticalDivider(width: 1),
        Expanded(child: _editorFor(selected, onBack: () => _select(null))),
      ],
    );
  }

  List<Entry> _descendants(Entry root) => _entries
      .where(
        (e) =>
            belongsTo(e, root.id, _entries) &&
            (isArchived(root, _entries) || !isArchived(e, _entries)),
      )
      .toList();

  Widget _overview(Entry root) {
    if (_selectedId == root.id) {
      return _editorFor(root, onBack: () => _select(null));
    }
    final descendants = _descendants(root);
    final tasks = descendants
        .where((e) => e.kind == EntryKind.task && e.taskState == TaskState.next)
        .toList();
    final notes = descendants
        .where((e) => e.kind == EntryKind.note || e.kind == EntryKind.file)
        .take(8)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(
              root.completed
                  ? 'Abgeschlossen'
                  : isArchived(root, _entries)
                  ? 'Archiviert'
                  : root.kind == EntryKind.project
                  ? 'Aktiv'
                  : root.kind.label,
            ),
            if (root.dueDate != null)
              Text(
                'Bis ${dateLabel(root.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue(root)
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (root.goal.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GEWÜNSCHTES ERGEBNIS',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(root.goal),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _entryAction(root, 'edit'),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: Text(
              root.kind == EntryKind.project
                  ? 'Ergebnis, Datum & Beschreibung'
                  : 'Beschreibung öffnen',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Nächste Aktionen',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Noch keine nächste Aktion festgelegt.'),
          ),
        for (final task in tasks.take(6)) _taskTile(task),
        if (!isArchived(root, _entries))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _create(EntryKind.task),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Aufgabe anlegen'),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Notizen & Unterlagen',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (notes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Hier können mehrere Notizen, Dateien und Ordner entstehen.',
            ),
          ),
        for (final note in notes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(entryIcon(note.kind), size: 20),
            title: Text(note.title),
            onTap: () async {
              if (await _canLeave() && mounted) {
                setState(() {
                  _tab = 'content';
                  _selectedId = note.id;
                });
              }
            },
          ),
      ],
    );
  }

  List<Widget> _treeRows(String parentId, int depth) {
    final rows = _sorted(
      _entries
          .where(
            (e) =>
                e.parentId == parentId &&
                e.kind != EntryKind.task &&
                !isArchived(e, _entries),
          )
          .toList(),
    );
    return [
      for (final row in rows) ...[
        _treeRow(row, depth),
        if (row.kind.isContainer && !_collapsed.contains(row.id))
          ..._treeRows(row.id, depth + 1),
      ],
    ];
  }

  Widget _folderContents(Entry folder) {
    final children = _entries
        .where(
          (e) =>
              e.parentId == folder.id &&
              e.kind != EntryKind.task &&
              (isArchived(_root!, _entries) || !isArchived(e, _entries)),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _select(
                  _find(folder.parentId)?.kind == EntryKind.folder
                      ? _find(folder.parentId)
                      : null,
                ),
                tooltip: 'Übergeordneter Ordner',
                icon: const Icon(Icons.arrow_back, size: 18),
              ),
              Expanded(
                child: Text(
                  folder.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _entryMenu(folder),
            ],
          ),
        ),
        Expanded(
          child: children.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'Dieser Ordner ist noch leer',
                  description:
                      'Neue Notizen und Dateien werden in diesem Ordner angelegt.',
                )
              : ListView(
                  children: [
                    for (final child in children)
                      _entrySurface(
                        child,
                        ListTile(
                          leading: Icon(entryIcon(child.kind), size: 20),
                          title: Text(child.title),
                          trailing: _entryMenu(child),
                          onTap: () => _select(child),
                        ),
                        surface: 'folder-content',
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _contents(Entry root, double width) {
    final selected = _selected;
    if (selected != null) {
      return selected.kind == EntryKind.folder
          ? _folderContents(selected)
          : _editorFor(
              selected,
              onBack: width < 550 ? () => _select(null) : null,
            );
    }
    final hasSidebar =
        MediaQuery.sizeOf(context).width >= 760 && _sidebarVisible;
    if (!hasSidebar) return ListView(children: _treeRows(root.id, 0));
    return EmptyState(
      icon: Icons.description_outlined,
      title: 'Notizen und Unterlagen',
      description:
          'Öffne einen Inhalt links oder ziehe Dateien in das Projekt.',
      action: isArchived(root, _entries)
          ? null
          : TextButton.icon(
              onPressed: () => _create(EntryKind.note),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Notiz anlegen'),
            ),
    );
  }

  Widget _taskTile(Entry task) {
    final c = WorkspaceColors(context),
        closed = task.taskState.isClosed,
        archived = isArchived(task, _entries),
        idea = task.kind == EntryKind.idea;
    return _entrySurface(
      task,
      Container(
        key: ValueKey('task-row-${task.id}'),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 24,
              child: task.taskState == TaskState.cancelled
                  ? Tooltip(
                      message: 'Nicht mehr relevant',
                      child: Icon(
                        LucideIcons.circleSlash,
                        size: 18,
                        color: c.soft,
                      ),
                    )
                  : idea
                  ? Icon(LucideIcons.lightbulb, size: 18, color: c.soft)
                  : Checkbox(
                      value: task.taskState == TaskState.done,
                      onChanged: _busy || archived
                          ? null
                          : (_) => _toggleTask(task),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: c.soft),
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: InkWell(
                onTap: () => _openTask(task),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 13,
                        decoration: closed ? TextDecoration.lineThrough : null,
                        color: closed ? c.soft : c.ink,
                      ),
                    ),
                    if (task.contextIds.isNotEmpty ||
                        task.context.isNotEmpty ||
                        task.estimatedMinutes != null ||
                        task.energy != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: TaskMetadataChips(
                          entry: task,
                          contexts: _contexts,
                        ),
                      ),
                    if (closed)
                      Text(
                        task.taskState.label,
                        style: TextStyle(fontSize: 11, color: c.soft),
                      ),
                  ],
                ),
              ),
            ),
            if (task.dueDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  dateLabel(task.dueDate!),
                  style: TextStyle(
                    fontSize: 11,
                    color: isOverdue(task)
                        ? Theme.of(context).colorScheme.error
                        : c.soft,
                  ),
                ),
              ),
            _entryMenu(task),
          ],
        ),
      ),
      surface: 'task',
    );
  }

  Widget _taskList(List<Entry> tasks) {
    final total = tasks.length;
    tasks = tasks
        .where(
          (e) => _taskFilter.matches(
            contexts: e.contextIds,
            minutes: e.estimatedMinutes,
            energy: e.energy,
          ),
        )
        .toList();
    final c = WorkspaceColors(context), global = _taskNavigation;
    String group(Entry task) => global
        ? ancestorsOf(
                task,
                _entries,
              ).where((e) => e.kind == EntryKind.project).firstOrNull?.id ??
              '_none'
        : task.kind == EntryKind.idea
        ? '_ideas'
        : task.taskState.name;
    String label(String group) => global
        ? _find(group)?.title ?? 'Ohne Projekt'
        : group == '_ideas'
        ? 'Ideen'
        : TaskState.values.byName(group).label;
    const order = [
      'next',
      'waiting',
      'inbox',
      'someday',
      'done',
      'cancelled',
      '_ideas',
    ];
    final groups = tasks.map(group).toSet().toList()
      ..sort(
        (a, b) => global
            ? a == '_none'
                  ? 1
                  : b == '_none'
                  ? -1
                  : label(a).compareTo(label(b))
            : order.indexOf(a).compareTo(order.indexOf(b)),
      );
    return LayoutBuilder(
      builder: (context, bounds) => ListView(
        padding: EdgeInsets.fromLTRB(
          34 + math.max(0, (bounds.maxWidth - 760) / 2),
          29,
          34 + math.max(0, (bounds.maxWidth - 760) / 2),
          28,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  global ? _view.label : 'Aufgaben',
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('task-filter'),
                tooltip: 'Aufgaben filtern',
                isSelected: _taskFilter.active,
                onPressed: () async {
                  if (!await _canLeave() || !context.mounted) return;
                  final filter = await showTaskFilterDialog(
                    context,
                    _contexts,
                    _taskFilter,
                  );
                  if (filter != null && mounted) {
                    setState(() => _taskFilter = filter);
                  }
                },
                icon: const Icon(LucideIcons.listFilter, size: 17),
              ),
              if (_root == null || !isArchived(_root!, _entries))
                TextButton.icon(
                  onPressed: () => _create(EntryKind.task),
                  icon: const Icon(LucideIcons.plus, size: 15),
                  label: const Text('Aufgabe', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          if (_taskFilter.active)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${tasks.length} von $total Aufgaben · Filter aktiv',
                    style: TextStyle(fontSize: 11, color: c.soft),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _taskFilter = const TaskFilter()),
                    child: const Text('Zurücksetzen'),
                  ),
                ],
              ),
            ),
          if (tasks.isEmpty && _taskFilter.active)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'Keine passenden Aufgaben. Filter anpassen oder zurücksetzen.',
              ),
            ),
          const SizedBox(height: 22),
          for (final title in groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 4),
              child: Text(
                '${label(title)} · ${tasks.where((e) => group(e) == title).length}',
                style: TextStyle(fontSize: 11, color: c.soft),
              ),
            ),
            for (final task in tasks.where((e) => group(e) == title))
              _taskTile(task),
            const SizedBox(height: 23),
          ],
        ],
      ),
    );
  }

  Widget _tasks(Entry root, double width) {
    final tasks = _descendants(
      root,
    ).where((e) => e.kind == EntryKind.task).toList();
    final selected = _selected?.kind == EntryKind.task ? _selected : null;
    final list = tasks.isEmpty
        ? EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Was ist der nächste Schritt?',
            description:
                'Aufgaben können mit Notizen und Dateien verknüpft werden.',
            action: isArchived(root, _entries)
                ? null
                : FilledButton.icon(
                    onPressed: () => _create(EntryKind.task),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Aufgabe anlegen'),
                  ),
          )
        : _taskList(tasks);
    return selected == null
        ? list
        : width < 800
        ? _editorFor(selected, onBack: () => _select(null))
        : Row(
            children: [
              SizedBox(width: 280, child: list),
              const VerticalDivider(width: 1),
              Expanded(
                child: _editorFor(selected, onBack: () => _select(null)),
              ),
            ],
          );
  }

  Widget _rootView(Entry root, BoxConstraints constraints) {
    final location = _creationLocation(EntryKind.file);
    return _dropRegion(
      'container-${root.id}',
      DropDestination(
        location.$1,
        location.$2,
        'Hinzufügen zu: ${_find(location.$2)?.title ?? root.title}',
      ),
      _buildRootView(root, constraints),
      priority: 0,
      enabled: !isArchived(root, _entries),
    );
  }

  Widget _buildRootView(Entry root, BoxConstraints constraints) =>
      root.kind == EntryKind.folder || _tab == 'content'
      ? _contents(root, constraints.maxWidth)
      : _tab == 'tasks'
      ? _tasks(root, constraints.maxWidth)
      : _overview(root);

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.comma, meta: true): _showData,
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _showSearch,
      const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          _showSearch,
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _showSearch,
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          _showSearch,
      const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () =>
          _showSearch(filesOnly: true),
      const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
          _showSearch(filesOnly: true),
      const SingleActivator(LogicalKeyboardKey.backslash, meta: true):
          _toggleSidebar,
      const SingleActivator(LogicalKeyboardKey.backslash, control: true):
          _toggleSidebar,
      const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
          _editor.currentState?.save(),
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
          _editor.currentState?.save(),
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
          _create(EntryKind.note),
      const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
          _create(EntryKind.note),
    },
    child: Focus(
      focusNode: _workspaceFocus,
      autofocus: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final sidebarShown = wide && _sidebarVisible;
          return Scaffold(
            key: _scaffold,
            drawer: wide
                ? null
                : Drawer(
                    width: math.min(364, constraints.maxWidth - 16),
                    child: _sidebar(),
                  ),
            body: WorkspaceDropHost(
              controller: _dropController,
              enabled:
                  !_busy &&
                  !_loading &&
                  !_acceptingDrop &&
                  (ModalRoute.of(context)?.isCurrent ?? true),
              onDrop: _receiveDrop,
              child: SafeArea(
                child: Row(
                  children: [
                    if (sidebarShown) ...[
                      SizedBox(
                        width: (_railExpanded ? 164 : 56) + 270,
                        child: _sidebar(),
                      ),
                    ],
                    Expanded(
                      child: Column(
                        children: [
                          _workspaceHeader(
                            wide: wide,
                            sidebarShown: sidebarShown,
                            width:
                                constraints.maxWidth -
                                (sidebarShown
                                    ? (_railExpanded ? 164 : 56) + 270
                                    : 0),
                          ),
                          if (_busy) ...[
                            const LinearProgressIndicator(minHeight: 2),
                            Text(
                              _busyLabel,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                          Expanded(
                            child: _loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _loadError != null
                                ? EmptyState(
                                    icon: Icons.error_outline,
                                    title: 'Arbeitsbereich nicht lesbar',
                                    description: errorLabel(_loadError!),
                                  )
                                : LayoutBuilder(
                                    builder: (context, bounds) => _root == null
                                        ? _globalView(bounds)
                                        : _rootView(_root!, bounds),
                                  ),
                          ),
                          _statusBar(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
