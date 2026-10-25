import 'package:flutter/material.dart';
import '../domain/archive.dart';
import '../domain/workspace.dart';
import 'common.dart';

class ArchiveBrowser extends StatefulWidget {
  const ArchiveBrowser({
    super.key,
    required this.entries,
    required this.onSelect,
    required this.canNavigate,
    required this.menuFor,
    required this.decorate,
    required this.initialPath,
    required this.onPathChanged,
    this.selectedId,
  });
  final List<Entry> entries;
  final Future<void> Function(Entry?) onSelect;
  final Future<bool> Function() canNavigate;
  final Widget Function(Entry) menuFor;
  final Widget Function(Entry, Widget) decorate;
  final List<String> initialPath;
  final ValueChanged<List<String>> onPathChanged;
  final String? selectedId;
  @override
  State<ArchiveBrowser> createState() => _ArchiveBrowserState();
}

class _ArchiveBrowserState extends State<ArchiveBrowser> {
  late List<String> _path = List.of(widget.initialPath);
  List<ArchiveNode>? _findPath(List<ArchiveNode> nodes, String id) {
    for (final node in nodes) {
      if (node.entry?.id == id) return [node];
      final children = _findPath(node.children, id);
      if (children != null) return [node, ...children];
    }
    return null;
  }

  void _reveal() {
    if (widget.selectedId == null) return;
    final path = _findPath(
      buildArchiveTree(widget.entries),
      widget.selectedId!,
    );
    if (path == null) return;
    _path = (path.last.isFolder ? path : path.take(path.length - 1))
        .map((e) => e.key)
        .toList();
    widget.onPathChanged(_path);
  }

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(covariant ArchiveBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _reveal();
  }

  Future<void> _navigate(List<String> path) async {
    if (!await widget.canNavigate() || !mounted) return;
    await widget.onSelect(null);
    if (!mounted) return;
    setState(() => _path = path);
    widget.onPathChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    final roots = buildArchiveTree(widget.entries);
    var rows = roots;
    final ancestors = <ArchiveNode>[];
    for (final key in _path) {
      final node = rows.where((e) => e.key == key).firstOrNull;
      if (node == null) break;
      ancestors.add(node);
      rows = node.children;
    }
    if (roots.isEmpty) {
      return const EmptyState(
        icon: Icons.archive_outlined,
        title: 'Ein Archiv für alle Inhalte',
        description:
            'Archivierte Projekte, Bereiche, Ressourcen, Notizen und Dateien '
            'erscheinen hier nach Jahr und Herkunft.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: () => _navigate([]),
                child: const Text('Archiv'),
              ),
              for (var index = 0; index < ancestors.length; index++) ...[
                const Icon(Icons.chevron_right, size: 14),
                TextButton(
                  onPressed: () => _navigate(
                    ancestors.take(index + 1).map((e) => e.key).toList(),
                  ),
                  child: Text(
                    ancestors[index].title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        if (ancestors.lastOrNull?.entry != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () => widget.onSelect(ancestors.last.entry),
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('Beschreibung ansehen'),
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'Dieser Archivordner ist leer',
                  description: 'Über die Ordnerleiste kannst du zurückgehen.',
                )
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (context, index) {
                    final node = rows[index];
                    final entry = node.entry;
                    Widget row = ListTile(
                      key: ValueKey('archive-node-${node.key}'),
                      leading: Icon(
                        node.isFolder
                            ? Icons.folder_outlined
                            : entryIcon(entry!.kind),
                        size: 22,
                      ),
                      title: Text(
                        node.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        node.isFolder
                            ? '${node.children.length} '
                                  '${node.children.length == 1 ? 'Eintrag' : 'Einträge'}'
                            : entry!.kind.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: entry != null && entry.id == widget.selectedId,
                      trailing: entry == null
                          ? const Icon(Icons.chevron_right, size: 18)
                          : widget.menuFor(entry),
                      onTap: () => node.isFolder
                          ? _navigate([
                              ...ancestors.map((e) => e.key),
                              node.key,
                            ])
                          : widget.onSelect(entry),
                    );
                    if (entry != null) row = widget.decorate(entry, row);
                    return row;
                  },
                ),
        ),
      ],
    );
  }
}
