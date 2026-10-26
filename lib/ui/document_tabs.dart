/// UUID-based tab order. Contents and unsaved drafts never belong here.
class DocumentTabs {
  final List<String> ids = [];
  String? preview;

  void open(String id, {bool temporary = false}) {
    if (ids.contains(id)) {
      if (!temporary) keep(id);
      return;
    }
    if (temporary && preview != null) ids.remove(preview);
    ids.add(id);
    if (temporary) preview = id;
  }

  void keep(String id) {
    if (preview == id) preview = null;
  }

  String? close(String id) {
    final index = ids.indexOf(id);
    if (index < 0) return null;
    ids.removeAt(index);
    if (preview == id) preview = null;
    return ids.isEmpty ? null : ids[index.clamp(0, ids.length - 1)];
  }

  List<String> get persistent => ids.where((id) => id != preview).toList();
}
