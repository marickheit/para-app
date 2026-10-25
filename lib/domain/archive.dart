import 'workspace.dart';

class ArchiveNode {
  ArchiveNode({required this.key, required this.title, this.kind, this.entry});
  final String key;
  final String title;
  final EntryKind? kind;
  Entry? entry;
  final List<ArchiveNode> children = [];
  bool get isFolder => entry == null || kind?.isContainer == true;
  int get contentCount =>
      (entry == null ? 0 : 1) +
      children.fold(0, (count, child) => count + child.contentCount);
}

List<ArchiveNode> buildArchiveTree(List<Entry> entries) {
  final years = <ArchiveNode>[];
  final nodes = <String, ArchiveNode>{};
  ArchiveNode add(
    List<ArchiveNode> list,
    String key,
    String title, {
    EntryKind? kind,
    Entry? entry,
  }) {
    final node = nodes.putIfAbsent(key, () {
      final node = ArchiveNode(
        key: key,
        title: title,
        kind: kind,
        entry: entry,
      );
      list.add(node);
      return node;
    });
    if (entry != null) node.entry = entry;
    return node;
  }

  for (final entry in entries.where((e) => isArchived(e, entries))) {
    final root = archiveRootOf(entry, entries);
    final location =
        root.archiveLocation ??
        archiveLocationFor(root, entries, root.archivedAt ?? root.updatedAt);
    final year = add(years, 'year:${location.year}', location.year.toString());
    final bucket = location.someday ? 'someday' : location.section.name;
    final section = add(
      year.children,
      '${year.key}/$bucket',
      location.someday ? 'Irgendwann / Vielleicht' : location.section.label,
    );
    var current = section;
    for (final ancestor in location.ancestors) {
      current = add(
        current.children,
        '${current.key}/${ancestor.id}',
        ancestor.title,
        kind: ancestor.kind,
      );
    }
    final chain = entry.id == root.id
        ? [entry]
        : [
            ...ancestorsOf(
              entry,
              entries,
            ).takeWhile((e) => e.id != root.id).toList().reversed,
            entry,
          ];
    if (entry.id != root.id) {
      current = add(
        current.children,
        '${current.key}/${root.id}',
        root.title,
        kind: root.kind,
        entry: root,
      );
    }
    for (final item in chain) {
      current = add(
        current.children,
        '${current.key}/${item.id}',
        item.title,
        kind: item.kind,
        entry: item,
      );
    }
  }
  void sort(List<ArchiveNode> nodes, {bool years = false}) {
    nodes.sort((a, b) {
      if (years) return b.title.compareTo(a.title);
      final order = (a.isFolder ? 0 : 1).compareTo(b.isFolder ? 0 : 1);
      return order != 0
          ? order
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    for (final node in nodes) {
      sort(node.children);
    }
  }

  sort(years, years: true);
  return years;
}
