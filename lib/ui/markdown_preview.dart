import 'package:flutter/material.dart';
import 'markdown_editor.dart';

/// Read-only descriptions share the editor's renderer, layout and link handling.
/// The overview never creates an implicit draft or saves checkbox changes.
class MarkdownPreview extends StatefulWidget {
  const MarkdownPreview({super.key, required this.text, required this.onLink});
  final String text;
  final ValueChanged<String?> onLink;

  @override
  State<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends State<MarkdownPreview> {
  late final _source = TextEditingController(text: widget.text);
  var _epoch = 0;

  @override
  void didUpdateWidget(covariant MarkdownPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _source.text = widget.text;
      _epoch++;
    }
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MarkdownEditor(
    controller: _source,
    mode: MarkdownEditorMode.read,
    locked: true,
    epoch: _epoch,
    onChanged: () {},
    onModeChanged: (_) {},
    onEditing: () {},
    onLink: widget.onLink,
  );
}
