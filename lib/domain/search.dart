import 'workspace.dart';

String normalizeSearch(String value) => value
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss');

class WorkspaceSearchHit {
  const WorkspaceSearchHit(this.entry, this.score, this.contentMatch);
  final Entry entry;
  final double score;
  final bool contentMatch;
}

double _nameScore(String name, String query) {
  final at = name.indexOf(query);
  if (at >= 0) return at == 0 ? 100 : 80 - at / 1000;
  var index = 0, last = -1, gaps = 0;
  for (var i = 0; i < name.length && index < query.length; i++) {
    if (name[i] == query[index]) {
      if (last >= 0) gaps += i - last - 1;
      last = i;
      index++;
    }
  }
  return index == query.length ? 40 - gaps / 100 : 0;
}

List<WorkspaceSearchHit> searchWorkspace(
  List<Entry> entries,
  String query, {
  bool filesOnly = false,
}) {
  final terms = normalizeSearch(
    query.trim(),
  ).split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  final hits = <WorkspaceSearchHit>[];
  for (final entry in entries) {
    if (entry.inTrash) continue;
    if (filesOnly &&
        !{
          EntryKind.file,
          EntryKind.note,
          EntryKind.folder,
        }.contains(entry.kind)) {
      continue;
    }
    final name = normalizeSearch(entry.title),
        text = normalizeSearch('${entry.searchText} ${entry.context}');
    var score = 0.0, matched = true, content = false;
    for (final term in terms) {
      final nameScore = _nameScore(name, term);
      final bodyMatch = !filesOnly && text.contains(term);
      if (nameScore == 0 && !bodyMatch) {
        matched = false;
        break;
      }
      score += nameScore > 0 ? nameScore : 60;
      if (bodyMatch && nameScore < 80) content = true;
    }
    if (matched) hits.add(WorkspaceSearchHit(entry, score, content));
  }
  hits.sort((a, b) {
    final archive = (isArchived(a.entry, entries) ? 1 : 0).compareTo(
      isArchived(b.entry, entries) ? 1 : 0,
    );
    if (archive != 0) return archive;
    if (terms.isNotEmpty) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
    }
    return b.entry.updatedAt.compareTo(a.entry.updatedAt);
  });
  return hits;
}
