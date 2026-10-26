import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import '../domain/workspace.dart';
import 'common.dart';
import '../services/mcp_bridge.dart';
import 'mcp_settings.dart';

enum SettingsAction { open, create, copy, backup }

Future<SettingsAction?> showWorkspaceSettings(
  BuildContext context,
  WorkspaceRepository repository,
  String root, {
  required bool canChangeRoot,
  int tab = 0,
  McpBridge? mcp,
}) => showDialog<SettingsAction>(
  context: context,
  builder: (_) => _WorkspaceSettings(
    repository: repository,
    root: root,
    canChangeRoot: canChangeRoot,
    initialTab: tab,
    mcp: mcp,
  ),
);

class _WorkspaceSettings extends StatefulWidget {
  const _WorkspaceSettings({
    required this.repository,
    required this.root,
    required this.canChangeRoot,
    required this.initialTab,
    this.mcp,
  });
  final WorkspaceRepository repository;
  final String root;
  final bool canChangeRoot;
  final int initialTab;
  final McpBridge? mcp;
  @override
  State<_WorkspaceSettings> createState() => _WorkspaceSettingsState();
}

class _WorkspaceSettingsState extends State<_WorkspaceSettings> {
  late final StreamSubscription<List<TaskContext>> _subscription;
  List<TaskContext> _contexts = [];
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _subscription = widget.repository.watchContexts().listen((values) {
      if (mounted) setState(() => _contexts = values);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _save(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([TaskContext? item]) async {
    final name = TextEditingController(text: item?.name);
    final form = GlobalKey<FormState>();
    var color =
        item?.color ?? contextColors[_contexts.length % contextColors.length];
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              item == null ? 'Kontext anlegen' : 'Kontext bearbeiten',
            ),
            content: SizedBox(
              width: 370,
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: const ValueKey('context-name'),
                      controller: name,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Bitte einen Namen eingeben.'
                          : item?.name != value.trim() &&
                                _contexts.any(
                                  (e) =>
                                      e.id != item?.id &&
                                      e.name.toLowerCase() ==
                                          value.trim().toLowerCase(),
                                )
                          ? 'Dieser Name ist bereits vergeben.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    const Text('Farbe'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final choice in contextColors)
                          ChoiceChip(
                            key: ValueKey('context-color-$choice'),
                            label: Icon(
                              Icons.circle,
                              color: Color(choice),
                              size: 18,
                            ),
                            selected: color == choice,
                            onSelected: (_) => setState(() => color = choice),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
        ),
      );
      if (accepted == true && mounted) {
        await _save(() async {
          await widget.repository.saveContext(
            id: item?.id,
            name: name.text,
            color: color,
            active: item?.active ?? true,
          );
        });
      }
    } finally {
      name.dispose();
    }
  }

  Widget _data() => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Text(
        'Aktueller Arbeitsbereich',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      SelectableText(widget.root, style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      const Text(
        'Dieser Ordner enthält Inhalte, Kontexte, Farben und die gespeicherte Ansicht.',
      ),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        key: const ValueKey('open-workspace'),
        onPressed: widget.canChangeRoot
            ? () => Navigator.pop(context, SettingsAction.open)
            : null,
        icon: const Icon(LucideIcons.folderOpen, size: 17),
        label: const Text('Arbeitsbereich öffnen …'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const ValueKey('copy-workspace'),
        onPressed: widget.canChangeRoot
            ? () => Navigator.pop(context, SettingsAction.copy)
            : null,
        icon: const Icon(LucideIcons.copy, size: 17),
        label: const Text('An einen anderen Ort kopieren …'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const ValueKey('create-workspace'),
        onPressed: widget.canChangeRoot
            ? () => Navigator.pop(context, SettingsAction.create)
            : null,
        icon: const Icon(LucideIcons.folderPlus, size: 17),
        label: const Text('Neuen Arbeitsbereich anlegen …'),
      ),
      if (!widget.canChangeRoot)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            'Dieser Start verwendet einen fest vorgegebenen Datenordner. Die normale Ordnerauswahl bleibt unverändert.',
            style: TextStyle(fontSize: 11),
          ),
        ),
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 10),
      const Text(
        'Eine vollständige Sicherung enthält auch Papierkorb, Textverlauf und Einstellungen.',
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: () async {
              final result = await OpenFilex.open(widget.root);
              if (result.type != ResultType.done && mounted) {
                showMessage(
                  context,
                  'Der Datenordner konnte nicht geöffnet werden.',
                );
              }
            },
            child: const Text('Datenordner öffnen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, SettingsAction.backup),
            icon: const Icon(LucideIcons.archive, size: 16),
            label: const Text('Sicherung erstellen'),
          ),
        ],
      ),
    ],
  );

  Widget _contextList() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Kontexte dieses Arbeitsbereichs',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('new-context'),
              onPressed: _busy ? null : _edit,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Kontext'),
            ),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Mehrere Kontexte je Aufgabe. Inaktive bleiben an bisherigen Aufgaben erhalten.',
          style: TextStyle(fontSize: 11),
        ),
      ),
      const SizedBox(height: 8),
      if (_busy) const LinearProgressIndicator(minHeight: 2),
      Expanded(
        child: ListView(
          children: [
            for (final item in _contexts)
              ListTile(
                key: ValueKey('settings-context-${item.id}'),
                leading: Icon(Icons.circle, color: Color(item.color), size: 13),
                title: Text(item.name),
                subtitle: item.active ? null : const Text('Inaktiv'),
                onTap: _busy ? null : () => _edit(item),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Nach oben',
                      onPressed: _busy || _contexts.indexOf(item) == 0
                          ? null
                          : () => _save(() async {
                              await widget.repository.saveContext(
                                id: item.id,
                                name: item.name,
                                color: item.color,
                                active: item.active,
                                position: _contexts.indexOf(item) - 1,
                              );
                            }),
                      icon: const Icon(LucideIcons.arrowUp, size: 15),
                    ),
                    IconButton(
                      tooltip: 'Nach unten',
                      onPressed:
                          _busy ||
                              _contexts.indexOf(item) == _contexts.length - 1
                          ? null
                          : () => _save(() async {
                              await widget.repository.saveContext(
                                id: item.id,
                                name: item.name,
                                color: item.color,
                                active: item.active,
                                position: _contexts.indexOf(item) + 1,
                              );
                            }),
                      icon: const Icon(LucideIcons.arrowDown, size: 15),
                    ),
                    Switch(
                      value: item.active,
                      onChanged: _busy
                          ? null
                          : (value) => _save(() async {
                              await widget.repository.saveContext(
                                id: item.id,
                                name: item.name,
                                color: item.color,
                                active: value,
                              );
                            }),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog(
      child: DefaultTabController(
        length: widget.mcp == null ? 2 : 3,
        initialIndex: widget.initialTab,
        child: SizedBox(
          width: 700,
          height: math.min(610, MediaQuery.sizeOf(context).height - 70),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 10, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Einstellungen',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text('Schließen'),
                    ),
                  ],
                ),
              ),
              TabBar(
                tabs: [
                  const Tab(text: 'Daten & Sicherung'),
                  const Tab(text: 'Aufgaben / Kontexte'),
                  if (widget.mcp != null) const Tab(text: 'KI-Anbindung'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _data(),
                    _contextList(),
                    if (widget.mcp != null) McpSettings(bridge: widget.mcp!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
