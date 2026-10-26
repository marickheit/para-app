import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/mcp_bridge.dart';
import '../services/workspace_manager.dart';
import 'common.dart';

class McpSettings extends StatefulWidget {
  const McpSettings({super.key, required this.bridge});
  final McpBridge bridge;
  @override
  State<McpSettings> createState() => _McpSettingsState();
}

class _McpSettingsState extends State<McpSettings> {
  bool _write = false, _archive = false, _busy = true;
  bool _supported = true;
  @override
  void initState() {
    super.initState();
    widget.bridge.addListener(_changed);
    _load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final saved = await widget.bridge.repository.readSetting('mcp.v1');
      if (saved != null) {
        final value = jsonDecode(saved) as Map<String, dynamic>;
        if (value['version'] != 1) throw const FormatException();
        _write = value['write'] == true;
        _archive = value['archive'] == true;
      }
    } catch (_) {
      _supported = false;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    widget.bridge.removeListener(_changed);
    super.dispose();
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    try {
      final chosen = await NativeWorkspaceDirectoryAccess().choose();
      if (chosen == null) return;
      await widget.bridge.enable(
        Directory(chosen.path),
        write: _write,
        archive: _archive,
      );
    } catch (error) {
      if (mounted) showMessage(context, errorLabel(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bridge = widget.bridge;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'KI-Anbindung für diesen Arbeitsbereich',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Text(
          'Gib einem lokalen MCP-Client Zugriff auf deine gespeicherten Inhalte. Der Client kann sie an seinen KI-Anbieter übermitteln. Die Freigabe endet beim Beenden der App oder Wechseln des Arbeitsbereichs.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<bool>(
          key: const ValueKey('mcp-permission'),
          initialValue: _write,
          decoration: const InputDecoration(labelText: 'Zugriff'),
          items: const [
            DropdownMenuItem(value: false, child: Text('Nur lesen')),
            DropdownMenuItem(value: true, child: Text('Lesen und Schreiben')),
          ],
          onChanged: _busy || bridge.enabled
              ? null
              : (v) => setState(() => _write = v!),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Archiv mit freigeben'),
          subtitle: const Text(
            'Archiv bleibt schreibgeschützt. Papierkorb und Textverlauf sind nicht zugänglich.',
          ),
          value: _archive,
          onChanged: _busy || bridge.enabled
              ? null
              : (v) => setState(() => _archive = v),
        ),
        const Text(
          'Die Freigabe umfasst den gesamten aktiven Bestand dieses Arbeitsbereichs. Keine zusätzliche Bestätigung einzelner Aktionen. Offene ungespeicherte Texte sind gegen Änderungen geschützt.',
        ),
        const SizedBox(height: 16),
        if (!_supported)
          const Text(
            'Gespeicherte KI-Einstellung ist nicht lesbar. Keine Verbindung aktiviert.',
          ),
        if (bridge.enabled) ...[
          Text(
            bridge.canWrite ? 'Aktiv: Lesen und Schreiben' : 'Aktiv: Nur lesen',
          ),
          const SizedBox(height: 8),
          SelectableText('Verbindungsdatei: ${bridge.connectionPath}'),
          const SizedBox(height: 8),
          Text(
            'Letzter erfolgreicher Aufruf: ${bridge.lastAction ?? 'Noch keiner'}',
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('mcp-disable'),
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await bridge.disable();
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: const Text('Zugriff sofort widerrufen'),
          ),
        ] else ...[
          FilledButton(
            key: const ValueKey('mcp-enable'),
            onPressed: _busy || !_supported ? null : _enable,
            child: const Text('Freigeben und Verbindungsdatei ablegen …'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Wähle einen lokalen, nicht synchronisierten Ordner außerhalb von Repository, Arbeitsbereichen und Sicherungen. Die Datei enthält einen geheimen Zugang. Nach neuer Freigabe den MCP-Client neu verbinden.',
          ),
        ],
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}
