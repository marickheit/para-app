import 'dart:convert';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'markdown_source.dart';
import 'workspace_style.dart';

enum MarkdownEditorMode { live, raw, read }

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    required this.controller,
    required this.mode,
    required this.locked,
    this.canMutate,
    required this.epoch,
    required this.onChanged,
    required this.onModeChanged,
    required this.onEditing,
    required this.onLink,
  });
  final TextEditingController controller;
  final MarkdownEditorMode mode;
  final bool locked;
  final bool Function()? canMutate;
  final int epoch;
  final VoidCallback onChanged;
  final ValueChanged<MarkdownEditorMode> onModeChanged;
  final VoidCallback onEditing;
  final ValueChanged<String?> onLink;
  @override
  State<MarkdownEditor> createState() => MarkdownEditorState();
}

class _TextState {
  const _TextState(this.value, this.active, this.cell, this.cellValue);
  final TextEditingValue value;
  final TextEditingValue? cellValue;
  final int? active;
  final ({int start, int row, int column})? cell;
}

class MarkdownEditorState extends State<MarkdownEditor> {
  final _local = TextEditingController();
  final _localFocus = FocusNode();
  final _liveFieldRender = GlobalKey();
  final _rawFocus = FocusNode();
  final _undo = <_TextState>[], _redo = <_TextState>[];
  int? _start, _end;
  MarkdownBlockKind? _kind;
  ({int start, int row, int column})? _cell;
  TextEditingValue? _cellValue, _restoreCellValue;
  late TextEditingValue _previous;
  bool _syncing = false, _restoring = false;
  bool get _locked => widget.locked || !(widget.canMutate?.call() ?? true);
  TextEditingController get _source => widget.controller;
  bool get editingTable =>
      _cell != null && widget.mode == MarkdownEditorMode.live;
  bool get canUndo => _undo.isNotEmpty && !_locked;
  bool get canRedo => _redo.isNotEmpty && !_locked;
  String get _newline => _source.text.contains('\r\n') ? '\r\n' : '\n';

  @override
  void initState() {
    super.initState();
    _previous = _source.value;
    _source.addListener(_sourceChanged);
    _local.addListener(_localChanged);
    _localFocus.addListener(_focused);
    _rawFocus.addListener(_focused);
    if (_source.text.isEmpty && widget.mode == MarkdownEditorMode.live) {
      _start = _end = 0;
      _kind = MarkdownBlockKind.paragraph;
    }
  }

  void _focused() {
    if (!_locked && (_localFocus.hasFocus || _rawFocus.hasFocus)) {
      widget.onEditing();
    }
  }

  @override
  void didUpdateWidget(covariant MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sourceChanged);
      _source.addListener(_sourceChanged);
    }
    if (oldWidget.epoch != widget.epoch ||
        oldWidget.controller != widget.controller) {
      _undo.clear();
      _redo.clear();
      _cellValue = _restoreCellValue = null;
      _start = _end = null;
      _cell = null;
      _previous = _source.value;
    }
    if (oldWidget.mode != widget.mode) {
      _cellValue = _restoreCellValue = null;
      _start = _end = null;
      _cell = null;
      if (widget.mode == MarkdownEditorMode.live && _source.text.isEmpty) {
        _start = _end = 0;
        _kind = MarkdownBlockKind.paragraph;
        _setLocal(const TextEditingValue());
      }
    }
  }

  @override
  void dispose() {
    _source.removeListener(_sourceChanged);
    _local.removeListener(_localChanged);
    _local.dispose();
    _localFocus.dispose();
    _rawFocus.dispose();
    super.dispose();
  }

  void _sourceChanged() {
    final value = _source.value;
    if (value.text != _previous.text) {
      if (!_restoring) {
        _undo.add(_TextState(_previous, _start, _cell, _cellValue));
        _redo.clear();
        _restoreCellValue = null;
        var bytes = 0;
        for (var i = _undo.length - 1; i >= 0; i--) {
          bytes += _undo[i].value.text.length * 2;
          if (i < _undo.length - 1 &&
              (bytes > 8 * 1024 * 1024 || _undo.length - i > 100)) {
            _undo.removeRange(0, i + 1);
            break;
          }
        }
      }
      _previous = value;
      if (!_syncing && !_restoring) {
        _start = _end = null;
        _cell = null;
      }
      if (mounted) {
        setState(() {});
        widget.onChanged();
      }
    } else {
      _previous = value;
    }
  }

  void _setLocal(TextEditingValue value) {
    _syncing = true;
    _local.value = value;
    _syncing = false;
  }

  void _localChanged() {
    if (_syncing || _locked || _start == null || _end == null) return;
    final value = _local.value;
    _kind =
        markdownBlocks(value.text).firstOrNull?.kind ??
        MarkdownBlockKind.paragraph;
    final start = _start!, end = _end!;
    final text = _source.text.replaceRange(start, end, value.text);
    final selection = value.selection.isValid
        ? TextSelection(
            baseOffset: start + value.selection.baseOffset,
            extentOffset: start + value.selection.extentOffset,
          )
        : TextSelection.collapsed(offset: start);
    _end = start + value.text.length;
    _syncing = true;
    _source.value = TextEditingValue(
      text: text,
      selection: selection,
      composing: value.composing.isValid
          ? TextRange(
              start: start + value.composing.start,
              end: start + value.composing.end,
            )
          : TextRange.empty,
    );
    _syncing = false;
  }

  void _activate(MarkdownSourceBlock block, {int? offset, bool focus = true}) {
    if (_locked || widget.mode != MarkdownEditorMode.live) return;
    final text = _source.text.substring(block.start, block.end);
    _cell = null;
    _start = block.start;
    _end = block.end;
    _kind = block.kind;
    final at = ((offset ?? text.length)).clamp(0, text.length);
    _setLocal(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: at),
      ),
    );
    _source.selection = TextSelection.collapsed(offset: block.start + at);
    setState(() {});
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_locked) _localFocus.requestFocus();
      });
    }
  }

  void focusEditor() {
    if (_locked) return;
    if (widget.mode == MarkdownEditorMode.raw) {
      _rawFocus.requestFocus();
      return;
    }
    final blocks = markdownBlocks(_source.text);
    if (blocks.isNotEmpty) {
      _activate(blocks.last);
    } else {
      setState(() {
        _start = _end = 0;
        _kind = MarkdownBlockKind.paragraph;
      });
      _localFocus.requestFocus();
    }
  }

  void _replace(int start, int end, String text, {int? cursor}) {
    if (_locked) return;
    _syncing = true;
    _source.value = TextEditingValue(
      text: _source.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: cursor ?? start + text.length),
    );
    _syncing = false;
  }

  void insertText(String text) {
    if (_locked || widget.mode == MarkdownEditorMode.read) return;
    if (editingTable) {
      final cell = _cell!;
      final block = markdownBlocks(
        _source.text,
      ).where((b) => b.start == cell.start).firstOrNull;
      final table = block == null
          ? null
          : MarkdownSourceTable.tryParse(block.text(_source.text));
      if (block == null || table == null) return;
      final value = table.cells[cell.row][cell.column];
      final selection =
          _cellValue?.text == value && _cellValue!.selection.isValid
          ? _cellValue!.selection
          : TextSelection.collapsed(offset: value.length);
      final next = value.replaceRange(
        selection.start,
        selection.end,
        text.replaceAll(RegExp(r'[\r\n]+'), ' '),
      );
      final source = table.replaceCell(cell.row, cell.column, next);
      _replace(block.start, block.end, source);
      _cellValue = _restoreCellValue = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(
          offset: (selection.start + text.length).clamp(0, next.length),
        ),
      );
      setState(() {});
      return;
    }
    final s = _source.selection;
    final start = s.isValid ? s.start : _source.text.length;
    final end = s.isValid ? s.end : start;
    _replace(start, end, text);
    _start = _end = null;
    _cell = null;
    if (widget.mode == MarkdownEditorMode.live) {
      _activateAt(start + text.length);
    } else {
      _rawFocus.requestFocus();
    }
  }

  void _activateAt(int offset) {
    final blocks = markdownBlocks(_source.text);
    final block = blocks
        .where((b) => b.start <= offset && b.end >= offset)
        .firstOrNull;
    if (block != null) {
      _activate(block, offset: offset - block.start);
    } else {
      setState(() {
        _start = _end = offset;
        _kind = MarkdownBlockKind.paragraph;
        _cell = null;
      });
      _setLocal(
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _localFocus.requestFocus();
      });
    }
  }

  void format(String command) {
    if (_locked || widget.mode == MarkdownEditorMode.read) return;
    if (editingTable) {
      if (const {'heading', 'list', 'numbered', 'check'}.contains(command)) {
        return;
      }
      final value = _cellValue;
      final selected = value != null && value.selection.isValid
          ? value.text.substring(value.selection.start, value.selection.end)
          : '';
      final text = selected.isEmpty ? 'Text' : selected;
      insertText(switch (command) {
        'bold' => '**$text**',
        'italic' => '*$text*',
        'code' => '`$text`',
        'link' => '[$text](https://)',
        _ => text,
      });
      return;
    }
    final selection = _source.selection;
    final start = selection.isValid ? selection.start : _source.text.length;
    final end = selection.isValid ? selection.end : start;
    if (const {'heading', 'list', 'numbered', 'check'}.contains(command)) {
      final lineStart = start == 0
          ? 0
          : _source.text.lastIndexOf('\n', start - 1) + 1;
      final next = _source.text.indexOf('\n', end);
      final lineEnd = next < 0
          ? _source.text.length
          : (next > 0 && _source.text[next - 1] == '\r' ? next - 1 : next);
      final value = _source.text.substring(lineStart, lineEnd);
      final lines = value.split(RegExp(r'\r?\n'));
      final formatted = lines.indexed
          .map((pair) {
            final content = pair.$2.replaceFirst(
              RegExp(r'^ {0,3}(?:#{1,6} |(?:[-+*]|\d+[.)]) (?:\[[ xX]\] )?)'),
              '',
            );
            final marker = switch (command) {
              'heading' => '## ',
              'list' => '- ',
              'numbered' => '${pair.$1 + 1}. ',
              _ => '- [ ] ',
            };
            return '$marker$content';
          })
          .join(_newline);
      _replace(lineStart, lineEnd, formatted);
      _start = _end = null;
      _cell = null;
      if (widget.mode == MarkdownEditorMode.live) {
        _activateAt(lineStart + formatted.length);
      }
      return;
    }
    final chosen = _source.text.substring(start, end);
    final text = chosen.isEmpty ? 'Text' : chosen;
    final value = switch (command) {
      'heading' => '## $text',
      'bold' => '**$text**',
      'italic' => '*$text*',
      'list' => '- $text',
      'numbered' => '1. $text',
      'check' => '- [ ] $text',
      'code' => '`$text`',
      'link' => '[$text](https://)',
      _ => text,
    };
    insertText(value);
  }

  void insertTable(int columns, int rows) {
    if (_locked || widget.mode == MarkdownEditorMode.read) return;
    final table = MarkdownSourceTable.create(columns, rows, newline: _newline);
    final s = _source.selection;
    final at = widget.mode == MarkdownEditorMode.live
        ? (_cell != null
              ? markdownBlocks(
                  _source.text,
                ).firstWhere((b) => b.start == _cell!.start).end
              : _end ?? _source.text.length)
        : s.isValid
        ? s.start
        : _source.text.length;
    final prefix = at == 0 ? '' : '$_newline$_newline';
    final suffix = at == _source.text.length ? '' : '$_newline$_newline';
    _replace(at, at, '$prefix$table$suffix');
    _start = _end = null;
    _cell = (start: at + prefix.length, row: 0, column: 0);
    setState(() {});
  }

  void undo() => _restore(_undo, _redo);
  void redo() => _restore(_redo, _undo);
  void _restore(List<_TextState> from, List<_TextState> to) {
    if (_locked || from.isEmpty) return;
    to.add(_TextState(_source.value, _start, _cell, _cellValue));
    final state = from.removeLast();
    _restoring = true;
    _source.value = state.value;
    _restoring = false;
    _start = _end = null;
    _cell = state.cell;
    _cellValue = _restoreCellValue = state.cellValue;
    if (widget.mode == MarkdownEditorMode.live && state.cell == null) {
      final at = state.value.selection.isValid
          ? state.value.selection.extentOffset
          : state.active;
      if (at != null) {
        _activateAt(at);
        final selection = state.value.selection;
        if (_start != null &&
            selection.isValid &&
            selection.start >= _start! &&
            selection.end <= _end!) {
          _setLocal(
            _local.value.copyWith(
              selection: TextSelection(
                baseOffset: selection.baseOffset - _start!,
                extentOffset: selection.extentOffset - _start!,
              ),
            ),
          );
          _source.selection = selection;
        }
      }
    }
    setState(() {});
    widget.onChanged();
  }

  TextSelection? _visualLine(TextPosition position) {
    RenderEditable? editable;
    void visit(RenderObject object) {
      if (object is RenderEditable) {
        editable = object;
        return;
      }
      if (editable == null) object.visitChildren(visit);
    }

    final render = _liveFieldRender.currentContext?.findRenderObject();
    if (render != null) visit(render);
    return editable?.getLineAtOffset(position);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _locked) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if ((keyboard.isControlPressed || keyboard.isMetaPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyA) {
      selectAll();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _start = _end = null;
        _cell = null;
      });
      return KeyEventResult.handled;
    }
    if (!_localFocus.hasFocus || _start == null) return KeyEventResult.ignored;
    if (_local.value.composing.isValid && !_local.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final sel = _local.selection;
    if (!sel.isValid) return KeyEventResult.ignored;
    if (sel.isCollapsed &&
        !keyboard.isShiftPressed &&
        !keyboard.isControlPressed &&
        !keyboard.isMetaPressed) {
      final blocks = markdownBlocks(_source.text);
      final previous = blocks.where((b) => b.end <= _start!).lastOrNull;
      final next = blocks
          .where((b) => b.start >= _end! && b.start != _start)
          .firstOrNull;
      if (event.logicalKey == LogicalKeyboardKey.backspace &&
          sel.start == 0 &&
          previous != null &&
          _kind == MarkdownBlockKind.paragraph &&
          previous.kind == MarkdownBlockKind.paragraph) {
        final at = previous.end;
        _replace(at, _start!, '');
        _start = _end = null;
        _activateAt(at);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.delete &&
          sel.start == _local.text.length &&
          next != null &&
          _kind == MarkdownBlockKind.paragraph &&
          next.kind == MarkdownBlockKind.paragraph) {
        final at = _end!;
        _replace(at, next.start, '');
        _start = _end = null;
        _activateAt(at);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
          _visualLine(sel.extent)?.start == 0 &&
          previous != null) {
        _activate(previous);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
          _visualLine(sel.extent)?.end == _local.text.length &&
          next != null) {
        _activate(next, offset: 0);
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (keyboard.isShiftPressed ||
        _kind == MarkdownBlockKind.code ||
        _kind == MarkdownBlockKind.other) {
      final newline =
          keyboard.isShiftPressed && _kind == MarkdownBlockKind.paragraph
          ? '  $_newline'
          : _newline;
      _local.value = TextEditingValue(
        text: _local.text.replaceRange(sel.start, sel.end, newline),
        selection: TextSelection.collapsed(offset: sel.start + newline.length),
      );
      return KeyEventResult.handled;
    }
    if (_kind == MarkdownBlockKind.list) {
      final before = _local.text.substring(0, sel.start);
      final lineStart = before.lastIndexOf('\n') + 1;
      final line = before.substring(lineStart);
      final match = RegExp(
        r'^(\s*)([-+*]|\d+[.)]) (?:\[[ xX]\] )?',
      ).firstMatch(line);
      if (match != null) {
        final marker = match.group(2)!;
        if (line.substring(match.end).trim().isEmpty) {
          final start = _start! + lineStart;
          _replace(start, _start! + sel.end, '$_newline$_newline');
          _start = _end = null;
          _activateAt(start + _newline.length * 2);
        } else {
          final number = int.tryParse(marker.replaceAll(RegExp(r'\D'), ''));
          final prefix =
              '${match.group(1)}${number == null ? marker : '${number + 1}${marker.endsWith(')') ? ')' : '.'}'} ${match.group(0)!.contains('[') ? '[ ] ' : ''}';
          _local.value = TextEditingValue(
            text: _local.text.replaceRange(
              sel.start,
              sel.end,
              '$_newline$prefix',
            ),
            selection: TextSelection.collapsed(
              offset: sel.start + _newline.length + prefix.length,
            ),
          );
        }
        return KeyEventResult.handled;
      }
    }
    final start = _start! + sel.start, end = _start! + sel.end;
    _replace(start, end, '$_newline$_newline');
    _start = _end = null;
    _activateAt(start + _newline.length * 2);
    return KeyEventResult.handled;
  }

  void selectAll() {
    if (_locked) return;
    widget.onModeChanged(MarkdownEditorMode.raw);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _rawFocus.requestFocus();
      _source.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _source.text.length,
      );
    });
  }

  Widget _markdown(
    String data,
    int start,
    String references, {
    bool allowChecks = true,
  }) {
    final checks = markdownCheckboxes(data, renderOrder: true);
    var checkbox = 0;
    final colors = WorkspaceColors(context);
    return MarkdownBody(
      key: ValueKey((start, _locked, allowChecks)),
      data: '$data\n\n$references',
      selectable: false,
      onTapLink: (_, href, _) => widget.onLink(href),
      checkboxBuilder: (value) {
        final check = checkbox < checks.length ? checks[checkbox++] : null;
        return SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: _locked || check == null || !allowChecks
                ? null
                : (v) {
                    if (_locked ||
                        start + data.length > _source.text.length ||
                        _source.text.substring(start, start + data.length) !=
                            data) {
                      return;
                    }
                    _replace(
                      start + check.offset,
                      start + check.offset + 1,
                      v! ? 'x' : ' ',
                    );
                    setState(() {
                      _start = _end = null;
                      _cell = null;
                    });
                  },
          ),
        );
      },
      imageBuilder: (uri, title, alt) => TextButton.icon(
        onPressed: () => widget.onLink(uri.toString()),
        icon: const Icon(Icons.image_outlined, size: 16),
        label: Text(alt ?? title ?? 'Bildverweis'),
      ),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(fontSize: 13, height: 1.2, color: colors.ink),
        h1: const TextStyle(
          fontSize: 25,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
        h2: const TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        h1Padding: EdgeInsets.zero,
        h2Padding: const EdgeInsets.only(top: 5),
        blockSpacing: 6,
        listBullet: const TextStyle(fontSize: 13),
        tableColumnWidth: const _ContentColumnWidth(),
        tableScrollbarThumbVisibility: true,
      ),
    );
  }

  Widget _textField() => Focus(
    key: _liveFieldRender,
    onKeyEvent: _key,
    child: TextField(
      key: const ValueKey('markdown-live-block'),
      controller: _local,
      inputFormatters: [
        TextInputFormatter.withFunction(
          (oldValue, value) => _locked ? oldValue : value,
        ),
      ],
      focusNode: _localFocus,
      readOnly: _locked,
      minLines: 1,
      maxLines: null,
      style: TextStyle(
        fontFamily: _kind == MarkdownBlockKind.code ? 'monospace' : null,
        fontSize: 13,
        height: 1.2,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: 'Schreiben …',
      ),
    ),
  );
  Widget _inlineCell(String value, String references) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    document.parseLines(const LineSplitter().convert(references));
    InlineSpan span(md.Node node) {
      if (node is md.Text) return TextSpan(text: node.text);
      if (node is! md.Element) return TextSpan(text: node.textContent);
      final children = node.children?.map(span).toList();
      if (node.tag == 'a') {
        return WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: InkWell(
            onTap: () => widget.onLink(node.attributes['href']),
            child: Text(
              node.textContent,
              style: TextStyle(
                fontSize: 13,
                color: WorkspaceColors(context).accent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      }
      if (node.tag == 'img') {
        return TextSpan(text: node.attributes['alt'] ?? 'Bildverweis');
      }
      return TextSpan(
        children: children,
        text: node.tag == 'br' ? '\n' : null,
        style: switch (node.tag) {
          'strong' => const TextStyle(fontWeight: FontWeight.w600),
          'em' => const TextStyle(fontStyle: FontStyle.italic),
          'code' => const TextStyle(fontFamily: 'monospace'),
          'del' => const TextStyle(decoration: TextDecoration.lineThrough),
          _ => null,
        },
      );
    }

    return Text.rich(
      TextSpan(children: document.parseInline(value).map(span).toList()),
      style: const TextStyle(fontSize: 13, height: 1.2),
    );
  }

  Widget _table(
    MarkdownSourceBlock block,
    MarkdownSourceTable table,
    String references,
  ) {
    final selected = _cell?.start == block.start;
    final colors = WorkspaceColors(context);
    final cells = table.cells;
    void change(
      String Function(MarkdownSourceTable) operation,
      int row,
      int col,
    ) {
      if (_locked) return;
      final current = markdownBlocks(
        _source.text,
      ).where((b) => b.start == block.start).firstOrNull;
      final model = current == null
          ? null
          : MarkdownSourceTable.tryParse(current.text(_source.text));
      if (current == null || model == null) return;
      final value = operation(model);
      _replace(current.start, current.end, value);
      setState(() {
        _start = _end = null;
        _cell = (start: current.start, row: row, column: col);
      });
    }

    Widget action(String label, String tooltip, VoidCallback? callback) =>
        Tooltip(
          message: tooltip,
          child: TextButton(
            onPressed: _locked ? null : callback,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 27),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: Text(label),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 3,
            children: [
              Text(
                'Zeile ${_cell!.row + 1} · Spalte ${_cell!.column + 1}',
                style: TextStyle(fontSize: 11, color: colors.soft),
              ),
              action(
                'Zeile +',
                'Zeile darunter hinzufügen',
                () => change(
                  (current) => current.insertRow(_cell!.row),
                  _cell!.row + 1,
                  _cell!.column,
                ),
              ),
              action(
                'Zeile −',
                'Ausgewählte Datenzeile löschen',
                _cell!.row == 0
                    ? null
                    : () => change(
                        (current) => current.deleteRow(_cell!.row),
                        (_cell!.row - 1).clamp(0, cells.length - 2),
                        _cell!.column,
                      ),
              ),
              action(
                'Spalte +',
                'Spalte rechts hinzufügen',
                () => change(
                  (current) => current.insertColumn(_cell!.column),
                  _cell!.row,
                  _cell!.column + 1,
                ),
              ),
              action(
                'Spalte −',
                'Ausgewählte Spalte löschen',
                cells.first.length <= 1
                    ? null
                    : () => change(
                        (current) => current.deleteColumn(_cell!.column),
                        _cell!.row,
                        (_cell!.column - 1).clamp(0, cells.first.length - 2),
                      ),
              ),
              action(
                'Fertig',
                'Tabellenbearbeitung beenden',
                () => setState(() => _cell = null),
              ),
            ],
          ),
        _ScrollableTable(
          child: Table(
            key: ValueKey('markdown-table-${block.start}'),
            defaultColumnWidth: const _ContentColumnWidth(),
            border: TableBorder.all(color: colors.line),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              for (var r = 0; r < cells.length; r++)
                TableRow(
                  decoration: r == 0
                      ? BoxDecoration(color: colors.sidebar)
                      : null,
                  children: [
                    for (var c = 0; c < cells[r].length; c++)
                      Builder(
                        builder: (context) {
                          final cellSelected =
                              selected && _cell!.row == r && _cell!.column == c;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _locked
                                ? null
                                : () {
                                    widget.onEditing();
                                    setState(() {
                                      _start = _end = null;
                                      _cell = (
                                        start: block.start,
                                        row: r,
                                        column: c,
                                      );
                                    });
                                    _cellValue = TextEditingValue(
                                      text: cells[r][c],
                                      selection: TextSelection.collapsed(
                                        offset: cells[r][c].length,
                                      ),
                                    );
                                    _restoreCellValue = null;
                                    _source.selection = TextSelection.collapsed(
                                      offset: block.start,
                                    );
                                  },
                            child: Container(
                              key: ValueKey(
                                'markdown-cell-${block.start}-$r-$c',
                              ),
                              decoration: cellSelected
                                  ? BoxDecoration(
                                      border: Border.all(color: colors.soft),
                                    )
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: cellSelected
                                  ? _TableCellInput(
                                      key: ValueKey(
                                        'cell-input-${block.start}-$r-$c',
                                      ),
                                      value: cells[r][c],
                                      locked: _locked,
                                      canMutate: () => !_locked,
                                      restoredValue: _restoreCellValue,
                                      onValueChanged: (value) {
                                        if (_cell ==
                                            (
                                              start: block.start,
                                              row: r,
                                              column: c,
                                            )) {
                                          _cellValue = value;
                                        }
                                      },
                                      onChanged: (value) {
                                        if (_locked ||
                                            _cell !=
                                                (
                                                  start: block.start,
                                                  row: r,
                                                  column: c,
                                                )) {
                                          return;
                                        }
                                        final currentBlocks = markdownBlocks(
                                          _source.text,
                                        );
                                        final current = currentBlocks
                                            .where(
                                              (b) => b.start == block.start,
                                            )
                                            .firstOrNull;
                                        final model = current == null
                                            ? null
                                            : MarkdownSourceTable.tryParse(
                                                current.text(_source.text),
                                              );
                                        if (current != null &&
                                            model != null &&
                                            r < model.cells.length &&
                                            c < model.cells.first.length) {
                                          change(
                                            (current) => current.replaceCell(
                                              r,
                                              c,
                                              value,
                                            ),
                                            r,
                                            c,
                                          );
                                        }
                                      },
                                      onNext: (back) {
                                        var row = r, col = c + (back ? -1 : 1);
                                        if (col < 0) {
                                          if (row == 0) return;
                                          row--;
                                          col = cells.first.length - 1;
                                        }
                                        if (col >= cells.first.length) {
                                          if (row == cells.length - 1) return;
                                          row++;
                                          col = 0;
                                        }
                                        _restoreCellValue = null;
                                        setState(
                                          () => _cell = (
                                            start: block.start,
                                            row: row,
                                            column: col,
                                          ),
                                        );
                                      },
                                    )
                                  : _inlineCell(
                                      cells[r][c].isEmpty ? ' ' : cells[r][c],
                                      references,
                                    ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): undo,
      const SingleActivator(
        LogicalKeyboardKey.keyZ,
        control: true,
        shift: true,
      ): redo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
          redo,
      const SingleActivator(LogicalKeyboardKey.keyY, control: true): redo,
    };
    Widget content;
    if (widget.mode == MarkdownEditorMode.raw) {
      content = TextField(
        key: const ValueKey('markdown-body'),
        controller: _source,
        inputFormatters: [
          TextInputFormatter.withFunction(
            (oldValue, value) => _locked ? oldValue : value,
          ),
        ],
        focusNode: _rawFocus,
        readOnly: _locked,
        minLines: 18,
        maxLines: null,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.2,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Markdown schreiben …',
          contentPadding: EdgeInsets.zero,
        ),
      );
    } else if (widget.mode == MarkdownEditorMode.read) {
      content = SelectionArea(
        child: _markdown(
          _source.text.isEmpty ? '_Noch kein Text._' : _source.text,
          0,
          '',
        ),
      );
    } else {
      final blocks = markdownBlocks(_source.text);
      final references = markdownReferenceDefinitions(_source.text);
      final children = <Widget>[];
      final selectable = <Widget>[];
      void flushSelection() {
        if (selectable.isEmpty) return;
        children.add(
          SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.of(selectable),
            ),
          ),
        );
        selectable.clear();
      }

      void addEditor() {
        flushSelection();
        children.add(_textField());
      }

      var activeAdded = false;
      for (final block in blocks) {
        if (_start != null && block.start < _end! && block.end > _start!) {
          if (!activeAdded) {
            addEditor();
            activeAdded = true;
          }
          continue;
        }
        if (_start != null &&
            _start == _end &&
            !activeAdded &&
            block.start >= _start!) {
          addEditor();
          activeAdded = true;
        }
        final table = block.kind == MarkdownBlockKind.table
            ? MarkdownSourceTable.tryParse(block.text(_source.text))
            : null;
        final rendered = Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: table != null
              ? _table(block, table, references)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _locked ? null : () => _activate(block),
                  child: _markdown(
                    block.text(_source.text),
                    block.start,
                    references,
                  ),
                ),
        );
        if (table != null && _cell?.start == block.start) {
          flushSelection();
          children.add(rendered);
        } else {
          selectable.add(rendered);
        }
      }
      if (_start != null && !activeAdded) addEditor();
      flushSelection();
      if (children.isEmpty) {
        children.add(
          TextButton(
            onPressed: _locked ? null : focusEditor,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Schreiben …'),
            ),
          ),
        );
      }
      // EditableText must stay outside SelectionArea's caret Actions. Keep
      // contiguous rendered blocks selectable together on either side.
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return CallbackShortcuts(bindings: bindings, child: content);
  }
}

class _TableCellInput extends StatefulWidget {
  const _TableCellInput({
    super.key,
    required this.value,
    required this.locked,
    required this.canMutate,
    required this.onChanged,
    required this.onNext,
    required this.onValueChanged,
    this.restoredValue,
  });
  final String value;
  final bool locked;
  final bool Function() canMutate;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onNext;
  final ValueChanged<TextEditingValue> onValueChanged;
  final TextEditingValue? restoredValue;
  @override
  State<_TableCellInput> createState() => _TableCellInputState();
}

class _TableCellInputState extends State<_TableCellInput> {
  late final _controller = TextEditingController.fromValue(
    (widget.restoredValue?.text == widget.value
            ? widget.restoredValue
            : null) ??
        TextEditingValue(
          text: widget.value,
          selection: TextSelection.collapsed(offset: widget.value.length),
        ),
  );
  late String _previousText = widget.value;
  @override
  void initState() {
    super.initState();
    widget.onValueChanged(_controller.value);
    _controller.addListener(() {
      if (_controller.text == _previousText) {
        widget.onValueChanged(_controller.value);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TableCellInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restoredValue != null &&
        widget.restoredValue!.text == widget.value &&
        widget.restoredValue != oldWidget.restoredValue) {
      _previousText = widget.restoredValue!.text;
      _controller.value = widget.restoredValue!;
    } else if (widget.value != _controller.text) {
      _previousText = widget.value;
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          !widget.locked &&
          [
            LogicalKeyboardKey.tab,
            LogicalKeyboardKey.enter,
          ].contains(event.logicalKey) &&
          _controller.value.composing.isCollapsed) {
        widget.onNext(HardwareKeyboard.instance.isShiftPressed);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: TextField(
      key: const ValueKey('markdown-cell-input'),
      controller: _controller,
      autofocus: true,
      readOnly: widget.locked,
      onChanged: (value) {
        widget.onChanged(value);
        _previousText = _controller.text;
        widget.onValueChanged(_controller.value);
      },
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, value) {
          if (widget.locked || !widget.canMutate()) return oldValue;
          final text = value.text.replaceAll(RegExp(r'[\r\n]+'), ' ');
          if (text == value.text) return value;
          return value.copyWith(
            text: text,
            selection: TextSelection.collapsed(
              offset: value.selection.extentOffset.clamp(0, text.length),
            ),
            composing: TextRange.empty,
          );
        }),
      ],
      minLines: 1,
      maxLines: null,
      style: const TextStyle(fontSize: 13, height: 1.2),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    ),
  );
}

class MarkdownTablePicker extends StatefulWidget {
  const MarkdownTablePicker({super.key, required this.onSelected});
  final void Function(int columns, int rows) onSelected;
  @override
  State<MarkdownTablePicker> createState() => _MarkdownTablePickerState();
}

class _MarkdownTablePickerState extends State<MarkdownTablePicker> {
  int _columns = 3, _rows = 3;
  @override
  Widget build(BuildContext context) {
    final colors = WorkspaceColors(context);
    return SizedBox(
      width: 208,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_columns Spalten × $_rows Zeilen',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (var r = 1; r <= 6; r++)
            Row(
              children: [
                for (var c = 1; c <= 8; c++)
                  MouseRegion(
                    onEnter: (_) => setState(() {
                      _columns = c;
                      _rows = r;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: TextButton(
                          key: ValueKey('table-grid-$c-$r'),
                          onFocusChange: (focus) {
                            if (focus) {
                              setState(() {
                                _columns = c;
                                _rows = r;
                              });
                            }
                          },
                          onPressed: () => widget.onSelected(c, r),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            backgroundColor: c <= _columns && r <= _rows
                                ? colors.selection
                                : colors.paper,
                            side: BorderSide(
                              color: c <= _columns && r <= _rows
                                  ? colors.soft
                                  : colors.line,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: Semantics(
                            label: '$c Spalten, $r Zeilen',
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 7),
          Text(
            'Erste Zeile = Kopfzeile',
            style: TextStyle(fontSize: 11, color: colors.soft),
          ),
        ],
      ),
    );
  }
}

// No flex: short tables keep their natural width. Clamp both intrinsic limits
// so long words wrap too, instead of forcing an arbitrarily wide column.
class _ContentColumnWidth extends IntrinsicColumnWidth {
  const _ContentColumnWidth();

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      super.minIntrinsicWidth(cells, containerWidth).clamp(72.0, 320.0);

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      super.maxIntrinsicWidth(cells, containerWidth).clamp(72.0, 320.0);
}

class _ScrollableTable extends StatefulWidget {
  const _ScrollableTable({required this.child});
  final Widget child;

  @override
  State<_ScrollableTable> createState() => _ScrollableTableState();
}

class _ScrollableTableState extends State<_ScrollableTable> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _scroll,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    ),
  );
}
