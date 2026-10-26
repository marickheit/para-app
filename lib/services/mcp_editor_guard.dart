import 'package:flutter/foundation.dart';
import '../domain/workspace.dart';

/// Shared by every editor and the bridge for one repository opening.
class McpEditorGuard extends ChangeNotifier {
  static final _guards = Expando<McpEditorGuard>();
  static McpEditorGuard forRepository(WorkspaceRepository repository) =>
      _guards[repository] ??= McpEditorGuard();
  final Map<Object, (String, bool)> _editors = {};
  final Set<String> _writing = {};

  void report(Object owner, String id, {required bool blocked}) {
    _editors[owner] = (id, blocked);
  }

  void remove(Object owner) => _editors.remove(owner);
  bool isWriting(String id) => _writing.contains(id);
  bool acquire(String id) {
    if (_writing.contains(id) ||
        _editors.values.any((e) => e.$1 == id && e.$2)) {
      return false;
    }
    _writing.add(id);
    notifyListeners();
    return true;
  }

  void release(String id) {
    _writing.remove(id);
    notifyListeners();
  }
}
