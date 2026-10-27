import 'package:markdown/markdown.dart' as md;

/// Offsets always address the original source; rendering never rewrites it.
enum MarkdownBlockKind { paragraph, heading, list, code, table, other }

class MarkdownSourceBlock {
  const MarkdownSourceBlock(this.start, this.end, this.kind);
  final int start;
  final int end;
  final MarkdownBlockKind kind;
  String text(String source) => source.substring(start, end);
}

class _SourceLine {
  const _SourceLine(
    this.start,
    this.end,
    this.next,
    this.content,
    this.newline,
  );
  final int start, end, next;
  final String content, newline;
}

List<_SourceLine> _lines(String source) {
  final result = <_SourceLine>[];
  var start = 0;
  while (start < source.length) {
    var end = start;
    while (end < source.length && source[end] != '\r' && source[end] != '\n') {
      end++;
    }
    var next = end;
    if (next < source.length) {
      if (source[next] == '\r' &&
          next + 1 < source.length &&
          source[next + 1] == '\n') {
        next += 2;
      } else {
        next++;
      }
    }
    result.add(
      _SourceLine(
        start,
        end,
        next,
        source.substring(start, end),
        source.substring(end, next),
      ),
    );
    start = next;
  }
  return result;
}

final _fence = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
final _heading = RegExp(r'^ {0,3}#{1,6}(?:\s|$)');
final _list = RegExp(r'^ {0,3}(?:[-+*]|\d{1,9}[.)])(?:[ \t]+|$)');
final _quote = RegExp(r'^ {0,3}>');
final _indent = RegExp(r'^(?: {4}|\t)');
final _definition = RegExp(r'^ {0,3}\[[^\]]+\]:[ \t]*');
final _setext = RegExp(r'^ {0,3}(?:=+|-+)[ \t]*$');
final _rule = RegExp(
  r'^ {0,3}(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){3,})$',
);

/// Conservative top-level units. Complex nested syntax stays together so that
/// editing one unit cannot discard neighbouring source or its indentation.
List<MarkdownSourceBlock> markdownBlocks(String source) {
  final lines = _lines(source);
  final result = <MarkdownSourceBlock>[];
  var i = 0;
  while (i < lines.length) {
    if (lines[i].content.trim().isEmpty) {
      i++;
      continue;
    }
    final first = i;
    final text = lines[i].content;
    var kind = MarkdownBlockKind.paragraph;
    final fence = _fence.firstMatch(text);
    if (fence != null) {
      kind = MarkdownBlockKind.code;
      final marker = fence[1]!;
      i++;
      final close = RegExp(
        '^ {0,3}${RegExp.escape(marker[0])}{${marker.length},}[ \\t]*\$',
      );
      while (i < lines.length) {
        final closed = close.hasMatch(lines[i].content);
        i++;
        if (closed) break;
      }
    } else if (_indent.hasMatch(text)) {
      kind = MarkdownBlockKind.code;
      i++;
      while (i < lines.length) {
        if (_indent.hasMatch(lines[i].content)) {
          i++;
        } else if (lines[i].content.trim().isEmpty &&
            i + 1 < lines.length &&
            _indent.hasMatch(lines[i + 1].content)) {
          i++;
        } else {
          break;
        }
      }
    } else if (_heading.hasMatch(text) || _rule.hasMatch(text)) {
      kind = _heading.hasMatch(text)
          ? MarkdownBlockKind.heading
          : MarkdownBlockKind.other;
      i++;
    } else if (_list.hasMatch(text) || _quote.hasMatch(text)) {
      kind = _list.hasMatch(text)
          ? MarkdownBlockKind.list
          : MarkdownBlockKind.other;
      i++;
      while (i < lines.length) {
        final next = lines[i].content;
        if (next.trim().isEmpty) {
          var following = i + 1;
          while (following < lines.length &&
              lines[following].content.trim().isEmpty) {
            following++;
          }
          if (following < lines.length &&
              (_list.hasMatch(lines[following].content) ||
                  RegExp(r'^[ \t]+\S').hasMatch(lines[following].content) ||
                  _quote.hasMatch(lines[following].content))) {
            i = following;
            continue;
          }
          break;
        }
        if (kind == MarkdownBlockKind.list &&
            RegExp(r'^[ \t]+\S').hasMatch(next)) {
          i++;
          continue;
        }
        if (_heading.hasMatch(next) ||
            _rule.hasMatch(next) ||
            _fence.hasMatch(next)) {
          break;
        }
        // Lazy list/quote continuation belongs to the same Markdown container.
        i++;
      }
    } else {
      if (text.trimLeft().startsWith('<') || _definition.hasMatch(text)) {
        kind = MarkdownBlockKind.other;
      }
      i++;
      while (i < lines.length && lines[i].content.trim().isNotEmpty) {
        final next = lines[i].content;
        if (kind == MarkdownBlockKind.paragraph &&
            i == first + 1 &&
            _setext.hasMatch(next)) {
          kind = MarkdownBlockKind.heading;
          i++;
          break;
        }
        if (_heading.hasMatch(next) ||
            _list.hasMatch(next) ||
            _quote.hasMatch(next) ||
            _fence.hasMatch(next) ||
            _rule.hasMatch(next)) {
          break;
        }
        i++;
      }
      final block = source.substring(lines[first].start, lines[i - 1].end);
      if (kind == MarkdownBlockKind.paragraph &&
          MarkdownSourceTable.tryParse(block) != null) {
        kind = MarkdownBlockKind.table;
      }
    }
    result.add(MarkdownSourceBlock(lines[first].start, lines[i - 1].end, kind));
  }
  return result;
}

/// Checkbox marker offset (the single space/x inside the brackets).
class MarkdownSourceCheckbox {
  const MarkdownSourceCheckbox(this.offset, this.checked);
  final int offset;
  final bool checked;
}

final _taskCandidate = RegExp(
  r'^((?:[ \t]*>[ \t]?)*[ \t]*(?:[-+*]|\d{1,9}[.)])[ \t]+\[)([ xX])(\][ \t]+)',
);

/// Associates markers using the actual GFM AST. Candidate-looking text in code,
/// HTML or escaped syntax is never made interactive. Inserting private markers
/// must leave the entire AST unchanged; otherwise no unsafe mapping is returned.
List<MarkdownSourceCheckbox> markdownCheckboxes(
  String source, {
  bool renderOrder = false,
}) {
  final candidates = <MarkdownSourceCheckbox>[];
  final inserts = <(int, String)>[];
  // Choose a delimiter that is absent from the user text.
  var marker = '\uE000para-task-';
  while (source.contains(marker)) {
    marker = '\uE000$marker';
  }
  for (final line in _lines(source)) {
    final match = _taskCandidate.firstMatch(line.content);
    if (match == null) continue;
    final id = candidates.length;
    candidates.add(
      MarkdownSourceCheckbox(line.start + match[1]!.length, match[2] != ' '),
    );
    inserts.add((line.start + match.end, '$marker$id\uE001'));
  }
  if (candidates.isEmpty) return [];
  final instrumented = StringBuffer();
  var cursor = 0;
  for (final insert in inserts) {
    instrumented.write(source.substring(cursor, insert.$1));
    instrumented.write(insert.$2);
    cursor = insert.$1;
  }
  instrumented.write(source.substring(cursor));
  final markerPattern = RegExp('${RegExp.escape(marker)}(\\d+)\uE001');
  List<md.Node> parse(String text) => md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  ).parseLines(text.split(RegExp(r'\r\n|\n|\r')));
  final original = parse(source);
  final marked = parse(instrumented.toString());
  String signature(md.Node node, {bool strip = false}) {
    if (node is md.Text) {
      return 'T${strip ? node.text.replaceAll(markerPattern, '') : node.text}';
    }
    if (node is md.Element) {
      final attributes = node.attributes.keys.toList()..sort();
      return '<${node.tag} ${attributes.map((a) => '$a=${node.attributes[a]}').join(';')}>'
          '${(node.children ?? []).map((n) => signature(n, strip: strip)).join()}'
          '</${node.tag}>';
    }
    return node.textContent;
  }

  if (original.map(signature).join() !=
      marked.map((n) => signature(n, strip: true)).join()) {
    return [];
  }
  final result = <MarkdownSourceCheckbox>[];
  void visit(md.Node node) {
    if (node is! md.Element) return;
    // flutter_markdown_plus creates list bullets after visiting child items.
    for (final child in node.children ?? <md.Node>[]) {
      visit(child);
    }
    if (node.tag == 'li' && node.attributes['class'] == 'task-list-item') {
      if (renderOrder) {
        final first = node.children?.firstOrNull;
        // Match flutter_markdown_plus's bullet construction exactly. Loose
        // task lists have their input inside a paragraph, not as the li bullet.
        if (first is! md.Element || first.attributes['type'] != 'checkbox') {
          return;
        }
      }
      final found = markerPattern.firstMatch(node.textContent);
      if (found == null) return;
      final id = int.tryParse(found[1]!);
      if (id == null || id >= candidates.length) return;
      result.add(candidates[id]);
    }
  }

  for (final node in marked) {
    visit(node);
  }
  if (!renderOrder) result.sort((a, b) => a.offset.compareTo(b.offset));
  return result;
}

/// Only appended for rendering isolated blocks, never written to source.
String markdownReferenceDefinitions(String source) {
  if (!source.contains(']:')) return '';
  final result = StringBuffer();
  md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    blockSyntaxes: [_ReferenceCollector(result)],
  ).parse(source);
  return result.toString();
}

/// The real block parser decides whether a definition exists. This also handles
/// multiline titles and definitions inside containers, while ignoring code/HTML.
class _ReferenceCollector extends md.LinkReferenceDefinitionSyntax {
  const _ReferenceCollector(this.result);
  final StringBuffer result;

  @override
  bool canParse(md.BlockParser parser) {
    if (!super.canParse(parser)) return false;
    // The base pattern also matches ordinary `[label][reference]` paragraphs.
    // Do not add a second failing definition syntax to the parser: its one-
    // syntax retry guard would alternate between us and the standard syntax.
    final start = parser.lines.indexOf(parser.current);
    final document = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
    final probe = md.BlockParser(parser.lines.sublist(start), document);
    super.parse(probe);
    return document.linkReferences.isNotEmpty;
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    final start = parser.lines.indexOf(parser.current);
    final node = super.parse(parser);
    final end = parser.isDone
        ? parser.lines.length
        : parser.lines.indexOf(parser.current);
    if (end > start) {
      for (final line in parser.lines.getRange(start, end)) {
        result.writeln(line.content);
      }
    }
    return node;
  }
}

class _TableRow {
  _TableRow(
    this.line,
    this.fragments,
    this.starts,
    this.leading,
    this.trailing,
  );
  final _SourceLine line;
  final List<String> fragments;
  final List<int> starts;
  final String leading, trailing;
  String join(List<String> cells) => '$leading${cells.join('|')}$trailing';

  static _TableRow? parse(_SourceLine line) {
    final raw = line.content;
    if (_indent.hasMatch(raw) || raw.trim().isEmpty) return null;
    final pipes = <int>[];
    var slashCount = 0;
    var codeRun = 0;
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (c == '\\') {
        slashCount++;
        continue;
      }
      final escaped = slashCount.isOdd;
      slashCount = 0;
      if (c == '`' && !escaped) {
        var end = i + 1;
        while (end < raw.length && raw[end] == '`') {
          end++;
        }
        final run = end - i;
        if (codeRun == 0) {
          codeRun = run;
        } else if (codeRun == run) {
          codeRun = 0;
        }
        i = end - 1;
      }
      if (c == '|' && !escaped) {
        // GFM splits even code-span pipes unless escaped. Such a source is
        // unsuitable for intuitive direct cell editing: use source mode.
        if (codeRun != 0) return null;
        pipes.add(i);
      }
    }
    if (pipes.isEmpty || codeRun != 0) return null;
    final first = raw.trimLeft().startsWith('|') ? pipes.first : null;
    final last = raw.trimRight().endsWith('|') && pipes.last != first
        ? pipes.last
        : null;
    final start = first == null ? 0 : first + 1;
    final end = last ?? raw.length;
    final separators = pipes.where((p) => p >= start && p < end).toList();
    final fragments = <String>[];
    final starts = <int>[];
    var pos = start;
    for (final separator in [...separators, end]) {
      fragments.add(raw.substring(pos, separator));
      starts.add(pos);
      pos = separator + 1;
    }
    return _TableRow(
      line,
      fragments,
      starts,
      raw.substring(0, start),
      raw.substring(end),
    );
  }
}

/// Safe rectangular GFM table. Existing formatting, outside bytes and delimiter
/// alignments are retained; unsupported/ambiguous tables deliberately return null.
class MarkdownSourceTable {
  MarkdownSourceTable._(this.source, this._rows, this._allLines);
  final String source;
  final List<_TableRow> _rows;
  final List<_SourceLine> _allLines;

  List<List<String>> get cells => List.unmodifiable([
    for (var i = 0; i < _rows.length; i++)
      if (i != 1)
        List<String>.unmodifiable(_rows[i].fragments.map((s) => s.trim())),
  ]);
  String get newline =>
      _allLines.map((l) => l.newline).where((e) => e.isNotEmpty).firstOrNull ??
      '\n';

  static MarkdownSourceTable? tryParse(String source) {
    final lines = _lines(source);
    if (lines.length < 2) return null;
    final rows = <_TableRow>[];
    for (final line in lines) {
      final row = _TableRow.parse(line);
      if (row == null) return null;
      rows.add(row);
    }
    final width = rows.first.fragments.length;
    if (width == 0 || rows.any((r) => r.fragments.length != width)) return null;
    if (rows[1].fragments.any(
      (s) => !RegExp(r'^:?-{3,}:?$').hasMatch(s.trim()),
    )) {
      return null;
    }
    return MarkdownSourceTable._(source, rows, lines);
  }

  static String create(int columns, int rows, {String newline = '\n'}) {
    if (columns < 1 || rows < 1) {
      throw ArgumentError('Positive table size required.');
    }
    String row(List<String> values) => '| ${values.join(' | ')} |';
    return [
      row(List.generate(columns, (i) => 'Spalte ${i + 1}')),
      row(List.filled(columns, '---')),
      for (var i = 1; i < rows; i++) row(List.filled(columns, '')),
    ].join(newline);
  }

  int _physicalRow(int row) {
    RangeError.checkValidIndex(row, cells, 'row');
    return row == 0 ? 0 : row + 1;
  }

  String replaceCell(int row, int col, String value) {
    final target = _rows[_physicalRow(row)];
    RangeError.checkValidIndex(col, target.fragments, 'col');
    if (value.contains('\r') || value.contains('\n')) {
      throw ArgumentError('A Markdown table cell occupies one source line.');
    }
    final fragment = target.fragments[col];
    final left = fragment.length - fragment.trimLeft().length;
    final right = fragment.trimRight().length;
    final start = target.line.start + target.starts[col] + left;
    final end =
        target.line.start + target.starts[col] + (right < left ? left : right);
    final escaped = StringBuffer();
    var slashes = 0;
    for (var i = 0; i < value.length; i++) {
      final c = value[i];
      if (c == '|' && slashes.isEven) escaped.write('\\');
      escaped.write(c);
      slashes = c == '\\' ? slashes + 1 : 0;
    }
    return source.replaceRange(start, end, escaped.toString());
  }

  String insertRow(int after) {
    _physicalRow(after);
    final at = after == 0 ? 2 : after + 2;
    final raw = '| ${List.filled(cells.first.length, '').join(' | ')} |';
    if (at < _allLines.length) {
      return source.replaceRange(
        _allLines[at].start,
        _allLines[at].start,
        '$raw$newline',
      );
    }
    final ending = _allLines.last.newline.isEmpty ? '' : newline;
    final separator = _allLines.last.newline.isEmpty ? newline : '';
    return '$source$separator$raw$ending';
  }

  String deleteRow(int index) {
    if (index == 0) throw ArgumentError('The header cannot be deleted.');
    final physical = _physicalRow(index);
    var start = _allLines[physical].start;
    final end = _allLines[physical].next;
    if (physical == _allLines.length - 1 &&
        _allLines[physical].newline.isEmpty) {
      start = _allLines[physical - 1].end;
    }
    return source.replaceRange(start, end, '');
  }

  String insertColumn(int after) {
    RangeError.checkValidIndex(after, cells.first, 'after');
    return _changeColumns((fragments, row) {
      fragments.insert(after + 1, row == 1 ? ' --- ' : '  ');
    });
  }

  String deleteColumn(int index) {
    RangeError.checkValidIndex(index, cells.first, 'index');
    if (cells.first.length == 1) {
      throw ArgumentError('Keep at least one column.');
    }
    return _changeColumns((fragments, _) => fragments.removeAt(index));
  }

  String _changeColumns(void Function(List<String>, int) operation) {
    final result = StringBuffer();
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final fragments = List<String>.of(row.fragments);
      operation(fragments, i);
      result.write(row.join(fragments));
      result.write(row.line.newline);
    }
    return result.toString();
  }
}
