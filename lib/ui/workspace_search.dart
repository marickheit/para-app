import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../domain/workspace.dart';
import '../domain/search.dart';
import 'common.dart';
import 'workspace_style.dart';

Future<Entry?> showWorkspaceSearch(
  BuildContext context,
  List<Entry> entries, {
  bool filesOnly = false,
}) => showDialog<Entry>(
  context: context,
  builder: (_) => _WorkspaceSearch(entries: entries, filesOnly: filesOnly),
);

class _WorkspaceSearch extends StatefulWidget {
  const _WorkspaceSearch({required this.entries, required this.filesOnly});
  final List<Entry> entries;
  final bool filesOnly;
  @override
  State<_WorkspaceSearch> createState() => _WorkspaceSearchState();
}

class _WorkspaceSearchState extends State<_WorkspaceSearch> {
  String _query = '';
  int _active = 0;
  final _focus = FocusNode();
  final _scroll = ScrollController();
  List<WorkspaceSearchHit> get _rows => searchWorkspace(
    widget.entries,
    _query,
    filesOnly: widget.filesOnly,
  ).take(80).toList();
  @override
  void initState() {
    super.initState();
    _focus.onKeyEvent = (_, event) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          final rows = _rows;
          if (rows.isNotEmpty) {
            setState(
              () => _active =
                  (_active +
                      (event.logicalKey == LogicalKeyboardKey.arrowDown
                          ? 1
                          : -1) +
                      rows.length) %
                  rows.length,
            );
            if (_scroll.hasClients) {
              _scroll.animateTo(
                (_active * 72.0).clamp(0, _scroll.position.maxScrollExtent),
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          }
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows, c = WorkspaceColors(context);
    return Dialog(
      alignment: const Alignment(0, -.65),
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: c.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: c.line),
      ),
      child: SizedBox(
        width: 560,
        height: math.min(490, MediaQuery.sizeOf(context).height - 80),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 18, color: c.soft),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('workspace-search-query'),
                      autofocus: true,
                      focusNode: _focus,
                      onChanged: (value) => setState(() {
                        _query = value;
                        _active = 0;
                      }),
                      onSubmitted: (_) {
                        if (rows.isNotEmpty) {
                          Navigator.pop(
                            context,
                            rows[_active.clamp(0, rows.length - 1)].entry,
                          );
                        }
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: widget.filesOnly
                            ? 'Datei- oder Notizname …'
                            : 'Namen oder Dateiinhalte suchen …',
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 7),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Esc',
                      style: TextStyle(fontSize: 11, color: c.soft),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.filesOnly
                      ? 'Datei wechseln'
                      : 'Arbeitsbereich durchsuchen · Namen & unterstützte Dateiinhalte',
                  style: TextStyle(fontSize: 11, color: c.soft),
                ),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('Keine passenden Inhalte'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final hit = rows[index], entry = hit.entry;
                        final path = [
                          entry.section.label,
                          ...ancestorsOf(
                            entry,
                            widget.entries,
                          ).reversed.map((e) => e.title),
                          entryFileLabel(entry),
                        ].join(' / ');
                        return Material(
                          color: index == _active
                              ? c.selected
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          child: ListTile(
                            key: ValueKey('search-result-${entry.id}'),
                            dense: true,
                            minLeadingWidth: 16,
                            horizontalTitleGap: 9,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            selected: index == _active,
                            leading: Icon(
                              fileIcon(entry),
                              size: 16,
                              color: c.soft,
                            ),
                            title: Text(
                              entryFileLabel(entry),
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                            ),
                            subtitle: Text(
                              '$path${isArchived(entry, widget.entries) ? ' · Archiviert' : ''}${hit.contentMatch ? '\nInhalt: ${entry.searchText.replaceAll(RegExp(r'\s+'), ' ').characters.take(100)}' : ''}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: c.soft),
                            ),
                            onTap: () => Navigator.pop(context, entry),
                          ),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: c.line),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${rows.length} Treffer · ↑↓ auswählen · Enter öffnen · Esc schließt',
                  style: TextStyle(fontSize: 11, color: c.soft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
