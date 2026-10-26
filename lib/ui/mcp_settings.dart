import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/mcp_bridge.dart';
import 'common.dart';

class McpSettings extends StatefulWidget {
  const McpSettings({super.key, required this.bridge});
  final McpBridge bridge;
  @override
  State<McpSettings> createState() => _McpSettingsState();
}

class _McpSettingsState extends State<McpSettings> {
  bool _archive = false, _busy = true;
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

  Future<void> _setAccess(int access) async {
    setState(() => _busy = true);
    try {
      await widget.bridge.disable();
      if (access != 0) {
        await widget.bridge.enableAutomatic(
          write: access == 2,
          archive: _archive,
        );
      }
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
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Zugriff'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              key: const ValueKey('mcp-permission'),
              value: bridge.enabled ? (bridge.canWrite ? 2 : 1) : 0,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Aus')),
                DropdownMenuItem(value: 1, child: Text('Nur lesen')),
                DropdownMenuItem(value: 2, child: Text('Lesen und Schreiben')),
              ],
              onChanged: _busy || !_supported
                  ? null
                  : (value) {
                      if (value != null) _setAccess(value);
                    },
            ),
          ),
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
          const Text('Die Verbindung wird automatisch lokal verwaltet.'),
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
          const Text('Zugriff aus'),
        ],
        const SizedBox(height: 10),
        const Text(
          'Beim Einschalten wird die Verbindung automatisch eingerichtet. Nach erneuter Freigabe den MCP-Client neu verbinden. Nach App-Neustart ist der Zugriff aus.',
        ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}
