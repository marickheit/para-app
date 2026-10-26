import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../domain/search.dart';
import '../domain/workspace_format.dart';
import '../domain/workspace.dart';
import 'mcp_editor_guard.dart';

class McpException implements Exception {
  const McpException(this.code, this.message);
  final String code;
  final String message;
  Map<String, dynamic> toJson() => {'code': code, 'message': message};
}

const mcpReadTools = {
  'workspace_info',
  'list_entries',
  'search',
  'get_entry',
  'read_text',
  'list_tasks',
  'list_contexts',
  'get_links',
};
const mcpWriteTools = {
  'create_note',
  'create_task',
  'update_text',
  'update_task',
  'set_task_state',
};

class McpAccessService {
  McpAccessService(
    this.repository, {
    required this.canWrite,
    this.allowArchive = false,
  });
  final WorkspaceRepository repository;
  final bool canWrite;
  final bool allowArchive;
  final String openingId = const Uuid().v4();
  bool active = true;
  String? lastAction;
  final Set<String> _running = {};
  final Map<
    String,
    ({String payload, DateTime at, Future<Map<String, dynamic>> result})
  >
  _requests = {};

  void revoke() => active = false;
  void _check() {
    if (!active) {
      throw const McpException('revoked', 'Verbindung nicht mehr freigegeben.');
    }
  }

  Future<Map<String, dynamic>> call(String tool, Map<String, dynamic> args) {
    _check();
    _validate(tool, args);
    if (!mcpWriteTools.contains(tool)) return _execute(tool, args);
    if (!canWrite) {
      throw const McpException(
        'read_only',
        'Nur lesender Zugriff freigegeben.',
      );
    }
    final id = args['request_id'] as String;
    final payload = sha256
        .convert(utf8.encode(jsonEncode([tool, _canonical(args)])))
        .toString();
    final now = DateTime.now();
    _requests.removeWhere(
      (requestId, value) =>
          !_running.contains(requestId) &&
          now.difference(value.at).inMinutes >= 30,
    );
    final previous = _requests[id];
    if (previous != null) {
      if (previous.payload != payload) {
        throw const McpException(
          'request_conflict',
          'Request-ID wurde anders verwendet.',
        );
      }
      return previous.result;
    }
    if (_requests.length >= 1000) {
      throw const McpException(
        'busy',
        'Wiederholungsspeicher voll. Später erneut versuchen.',
      );
    }
    // Reserve synchronously, before the first async operation can complete.
    _running.add(id);
    final future = _execute(tool, args);
    future.then<void>(
      (_) {
        _running.remove(id);
      },
      onError: (Object error, StackTrace stack) {
        _running.remove(id);
      },
    );
    _requests[id] = (payload: payload, at: now, result: future);
    return future;
  }

  Future<Map<String, dynamic>> _execute(
    String tool,
    Map<String, dynamic> a,
  ) async {
    try {
      return await repository.exclusive(() async {
        _check();
        final all = await repository.getEntries();
        final archive = a['include_archive'] == true;
        if (archive && !allowArchive) {
          throw const McpException('forbidden', 'Archiv nicht freigegeben.');
        }
        final visible = all
            .where(
              (e) =>
                  !e.inTrash &&
                  (!isArchived(e, all) || archive && allowArchive),
            )
            .toList();
        Entry require(String? id) =>
            visible.where((e) => e.id == id).firstOrNull ??
            (throw const McpException('not_found', 'Inhalt nicht verfügbar.'));
        Map<String, dynamic> meta(Entry e) => _metadata(e, all);
        Map<String, dynamic> result;
        if (tool == 'workspace_info') {
          result = {
            'bridge_version': 1,
            'opening_id': openingId,
            'write': canWrite,
            'archive': allowArchive,
            'app_version': workspaceAppVersion,
            'max_text_bytes': 1048576,
          };
        } else if (tool == 'list_contexts') {
          final items = await repository.getContexts();
          result = _page(
            items
                .map(
                  (e) => <String, dynamic>{
                    'id': e.id,
                    'name': e.name,
                    'color': e.color,
                    'active': e.active,
                    'position': e.position,
                  },
                )
                .toList(),
            a,
          );
        } else if (tool == 'get_entry' || tool == 'read_text') {
          final entry = require(a['id'] as String);
          result = meta(entry);
          if (tool == 'read_text') {
            final snapshot = await repository.readSnapshot(entry.id);
            if (!snapshot.note.editable) {
              throw const McpException(
                'unsupported',
                'Nur Textinhalte sind lesbar.',
              );
            }
            final text = snapshot.note.text;
            final offset = (a['offset'] as int?) ?? 0;
            final length = (a['length'] as int?) ?? 65536;
            if (offset > text.length) {
              throw const McpException(
                'invalid_input',
                'Textposition außerhalb des Inhalts.',
              );
            }
            final end = (offset + length).clamp(0, text.length);
            result.addAll({
              'text': text.substring(offset, end),
              'body_hash': snapshot.note.hash,
              'offset': offset,
              'next_offset': end < text.length ? end : null,
              'total_characters': text.length,
            });
          }
        } else if (tool == 'get_links') {
          final entry = require(a['id'] as String);
          final linked = a['direction'] == 'incoming'
              ? await repository.backlinks(entry.id)
              : await repository.outgoingLinks(entry.id);
          final ids = visible.map((e) => e.id).toSet();
          result = _page(
            linked.where((e) => ids.contains(e.id)).map(meta).toList(),
            a,
          );
        } else if (tool == 'list_entries' ||
            tool == 'list_tasks' ||
            tool == 'search') {
          var entries = visible;
          if (a.containsKey('parent_id')) {
            require(a['parent_id'] as String);
            entries = entries
                .where((e) => e.parentId == a['parent_id'])
                .toList();
          }
          if (a.containsKey('section')) {
            entries = entries
                .where((e) => e.section.name == a['section'])
                .toList();
          }
          if (a.containsKey('kind')) {
            entries = entries.where((e) => e.kind.name == a['kind']).toList();
          }
          if (tool == 'list_tasks') {
            entries = entries.where((e) => e.kind == EntryKind.task).toList();
            if (a.containsKey('state')) {
              entries = entries
                  .where((e) => e.taskState.name == a['state'])
                  .toList();
            }
            if (a.containsKey('project_id')) {
              final project = require(a['project_id'] as String);
              if (project.kind != EntryKind.project) {
                throw const McpException('invalid_input', 'Projekt benötigt.');
              }
              entries = entries
                  .where((e) => belongsTo(e, project.id, all))
                  .toList();
            }
            final filter = TaskFilter(
              contextIds: (a['context_ids'] as List?)?.cast<String>() ?? [],
              allContexts: a['all_contexts'] == true,
              maxMinutes: a['max_minutes'] as int?,
              maxEnergy: a['max_energy'] == null
                  ? null
                  : EnergyLevel.values.byName(a['max_energy'] as String),
              includeUnspecified: a['include_unspecified'] != false,
            );
            entries = entries
                .where(
                  (e) => filter.matches(
                    contexts: e.contextIds,
                    minutes: e.estimatedMinutes,
                    energy: e.energy,
                  ),
                )
                .toList();
          }
          if (tool == 'search') {
            entries = searchWorkspace(
              entries,
              a['query'] as String,
            ).map((h) => h.entry).toList();
          }
          result = _page(
            entries
                .map(
                  (e) => {
                    ...meta(e),
                    if (tool == 'search')
                      'snippet': _snippet(e.searchText, a['query'] as String),
                  },
                )
                .toList(),
            a,
            preserveOrder: tool == 'search',
          );
        } else {
          _check();
          final guard = McpEditorGuard.forRepository(repository);
          final target = a['id'] as String?;
          if (target != null) {
            final e = require(target);
            if (isArchived(e, all)) {
              throw const McpException(
                'read_only',
                'Archivierte Inhalte sind schreibgeschützt.',
              );
            }
            if (!guard.acquire(target)) {
              throw const McpException(
                'editor_busy',
                'Inhalt ist im Editor ungespeichert oder beschäftigt.',
              );
            }
          }
          try {
            if (tool == 'create_note' || tool == 'create_task') {
              if (a['parent_id'] != null) {
                final parent = require(a['parent_id'] as String);
                if (!parent.kind.isContainer || isArchived(parent, all)) {
                  throw const McpException(
                    'invalid_input',
                    'Aktiven Zielordner wählen.',
                  );
                }
              }
              _check();
              final created = await repository.create(
                kind: tool == 'create_note' ? EntryKind.note : EntryKind.task,
                draft: EntryDraft(
                  title: a['title'] as String,
                  body: a['text'] as String? ?? '',
                  taskState: TaskState.values.byName(
                    a['state'] as String? ?? 'inbox',
                  ),
                  contextIds: (a['context_ids'] as List?)?.cast<String>(),
                  estimatedMinutes: a['estimated_minutes'] as int?,
                  energy: a['energy'] == null
                      ? null
                      : EnergyLevel.values.byName(a['energy'] as String),
                ),
                section: ParaSection.values.byName(
                  a['section'] as String? ?? 'inbox',
                ),
                parentId: a['parent_id'] as String?,
              );
              result = meta(created);
            } else {
              final entry = require(target);
              if (tool != 'update_text' && entry.kind != EntryKind.task) {
                throw const McpException('invalid_input', 'Aufgabe benötigt.');
              }
              if (entry.revision != a['expected_revision']) {
                throw const McpException(
                  'conflict',
                  'Inhalt wurde geändert. Erneut lesen.',
                );
              }
              final current = await repository.readSnapshot(entry.id);
              if (!current.note.editable) {
                throw const McpException(
                  'unsupported',
                  'Text ist nicht bearbeitbar.',
                );
              }
              if (tool == 'update_text' &&
                  current.note.hash != a['expected_body_hash']) {
                throw const McpException(
                  'conflict',
                  'Text wurde geändert. Erneut lesen.',
                );
              }
              _check();
              final saved = await repository.saveSnapshot(
                id: entry.id,
                expectedRevision: entry.revision,
                expectedBodyHash: current.note.hash,
                draft: EntryDraft(
                  title: a['title'] as String? ?? entry.title,
                  body: tool == 'update_text'
                      ? a['text'] as String
                      : current.note.text,
                  goal: entry.goal,
                  dueDate: entry.dueDate,
                  context: entry.context,
                  taskState: a['state'] == null
                      ? entry.taskState
                      : TaskState.values.byName(a['state'] as String),
                  contextIds: a.containsKey('context_ids')
                      ? (a['context_ids'] as List).cast<String>()
                      : entry.contextIds,
                  estimatedMinutes: a.containsKey('estimated_minutes')
                      ? a['estimated_minutes'] as int?
                      : entry.estimatedMinutes,
                  energy: a.containsKey('energy')
                      ? (a['energy'] == null
                            ? null
                            : EnergyLevel.values.byName(a['energy'] as String))
                      : entry.energy,
                  updateTaskDetails: tool == 'update_task',
                ),
              );
              result = {...meta(saved.entry), 'body_hash': saved.note.hash};
            }
          } finally {
            if (target != null) guard.release(target);
          }
        }
        lastAction = tool;
        if (utf8.encode(jsonEncode(result)).length > 2 * 1024 * 1024) {
          throw const McpException(
            'too_large',
            'Antwort zu groß. Kleinere Seite oder Textabschnitt wählen.',
          );
        }
        return result;
      });
    } on McpException {
      rethrow;
    } on WorkspaceException {
      throw const McpException(
        'conflict_or_invalid',
        'Änderung abgelehnt. Angaben und aktuellen Inhalt prüfen.',
      );
    } catch (_) {
      throw const McpException(
        'storage_error',
        'Zugriff fehlgeschlagen. Arbeitsbereich in der App prüfen.',
      );
    }
  }

  Map<String, dynamic> _metadata(Entry e, List<Entry> all) {
    final project = ancestorsOf(
      e,
      all,
    ).where((p) => p.kind == EntryKind.project).firstOrNull;
    return {
      'id': e.id,
      'title': e.title,
      'kind': e.kind.name,
      'section': e.section.name,
      'parent_id': e.parentId,
      'project_id': project?.id,
      'revision': e.revision,
      'updated_at': e.updatedAt.toUtc().toIso8601String(),
      'link': entryLink(e.id),
      'archived': isArchived(e, all),
      'state': e.taskState.name,
      'goal': e.goal,
      'due_date': e.dueDate?.toIso8601String().split('T').first,
      'context_ids': e.contextIds,
      'estimated_minutes': e.estimatedMinutes,
      'energy': e.energy?.name,
      'file_size': e.fileSize,
    };
  }

  Map<String, dynamic> _page(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> a, {
    bool preserveOrder = false,
  }) {
    if (!preserveOrder) {
      items.sort((x, y) {
        final byTitle = (x['title'] ?? x['name'] ?? '').toString().compareTo(
          (y['title'] ?? y['name'] ?? '').toString(),
        );
        return byTitle == 0
            ? (x['id'] as String).compareTo(y['id'] as String)
            : byTitle;
      });
    }
    final query = Map<String, dynamic>.of(a)..remove('cursor');
    final fingerprint = sha256
        .convert(utf8.encode(jsonEncode([openingId, _canonical(query), items])))
        .toString();
    var offset = 0;
    if (a['cursor'] != null) {
      try {
        final value =
            jsonDecode(utf8.decode(base64Url.decode(a['cursor'] as String)))
                as List;
        if (value[0] != fingerprint ||
            value[1] is! int ||
            (value[1] as int) < 0 ||
            (value[1] as int) > items.length) {
          throw const FormatException();
        }
        offset = value[1] as int;
      } catch (_) {
        throw const McpException(
          'stale_cursor',
          'Seitencursor ungültig oder Bestand geändert. Neu beginnen.',
        );
      }
    }
    final end = (offset + (a['limit'] as int? ?? 50)).clamp(0, items.length);
    return {
      'items': items.sublist(offset, end),
      'total': items.length,
      'next_cursor': end < items.length
          ? base64Url.encode(utf8.encode(jsonEncode([fingerprint, end])))
          : null,
    };
  }

  String _snippet(String text, String query) {
    final at = normalizeSearch(text).indexOf(normalizeSearch(query.trim()));
    final start = (at - 60).clamp(0, text.length);
    return text.substring(start, (start + 240).clamp(0, text.length));
  }
}

Object? _canonical(Object? value) {
  if (value is Map) {
    return {
      for (final key in value.keys.cast<String>().toList()..sort())
        key: _canonical(value[key]),
    };
  }
  if (value is List) return value.map(_canonical).toList();
  return value;
}

void _validate(String tool, Map<String, dynamic> a) {
  const page = {'limit', 'cursor', 'include_archive'};
  const location = {'parent_id', 'section'};
  const task = {'context_ids', 'estimated_minutes', 'energy', 'state'};
  final allowed = switch (tool) {
    'workspace_info' => <String>{},
    'list_entries' => {...page, ...location, 'kind'},
    'search' => {...page, 'query'},
    'get_entry' => {'id', 'include_archive'},
    'read_text' => {'id', 'include_archive', 'offset', 'length'},
    'list_tasks' => {
      ...page,
      ...location,
      'state',
      'project_id',
      'context_ids',
      'all_contexts',
      'max_minutes',
      'max_energy',
      'include_unspecified',
    },
    'list_contexts' => {...page},
    'get_links' => {...page, 'id', 'direction'},
    'create_note' => {...location, 'title', 'text', 'request_id'},
    'create_task' => {...location, ...task, 'title', 'text', 'request_id'},
    'update_text' => {
      'id',
      'expected_revision',
      'expected_body_hash',
      'text',
      'request_id',
    },
    'update_task' => {
      ...task,
      'title',
      'id',
      'expected_revision',
      'request_id',
    },
    'set_task_state' => {'id', 'state', 'expected_revision', 'request_id'},
    _ => throw const McpException('unknown_tool', 'Unbekanntes Werkzeug.'),
  };
  const required = {
    'search': ['query'],
    'get_entry': ['id'],
    'read_text': ['id'],
    'get_links': ['id', 'direction'],
    'create_note': ['title', 'request_id'],
    'create_task': ['title', 'request_id'],
    'update_text': [
      'id',
      'text',
      'expected_revision',
      'expected_body_hash',
      'request_id',
    ],
    'update_task': ['id', 'expected_revision', 'request_id'],
    'set_task_state': ['id', 'state', 'expected_revision', 'request_id'],
  };
  void invalid() => throw const McpException(
    'invalid_input',
    'Ungültige oder fehlende Werkzeugangaben.',
  );
  if (a.keys.any((k) => !allowed.contains(k)) ||
      (required[tool] ?? []).any((k) => !a.containsKey(k))) {
    invalid();
  }
  for (final entry in a.entries) {
    final k = entry.key, v = entry.value;
    if (v == null && {'energy', 'estimated_minutes'}.contains(k)) continue;
    if ({
      'include_archive',
      'all_contexts',
      'include_unspecified',
    }.contains(k)) {
      if (v is! bool) invalid();
    } else if ({
      'expected_revision',
      'offset',
      'length',
      'limit',
      'estimated_minutes',
      'max_minutes',
    }.contains(k)) {
      if (v is! int || v < (k == 'offset' ? 0 : 1)) invalid();
      if (k == 'limit' && (v as int) > 100 ||
          k == 'length' && (v as int) > 262144) {
        invalid();
      }
    } else if (k == 'context_ids') {
      if (v is! List ||
          v.length > 100 ||
          v.any((e) => e is! String || e.length > 100)) {
        invalid();
      }
    } else {
      if (v is! String || v.length > (k == 'text' ? 1048576 : 4096)) invalid();
      if (k == 'text' && utf8.encode(v as String).length > 1048576) invalid();
      if ({'title', 'query', 'request_id'}.contains(k) &&
          (v as String).trim().isEmpty) {
        invalid();
      }
      if ({'id', 'parent_id', 'project_id'}.contains(k) &&
          entryIdFromLink('para://entry/$v') == null) {
        invalid();
      }
    }
    final options = switch (k) {
      'section' => ParaSection.values.map((e) => e.name),
      'kind' => EntryKind.values.map((e) => e.name),
      'state' => TaskState.values.map((e) => e.name),
      'energy' || 'max_energy' => EnergyLevel.values.map((e) => e.name),
      'direction' => ['incoming', 'outgoing'],
      _ => null,
    };
    if (options != null && !options.contains(v)) invalid();
  }
}
