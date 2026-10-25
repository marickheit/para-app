import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

const maxTextFileBytes = 16 * 1024 * 1024;

bool isEditableTextName(String name) =>
    {'.txt', '.md', '.markdown'}.contains(p.extension(name).toLowerCase());
bool isSearchableTextName(String name) =>
    isEditableTextName(name) || p.extension(name).toLowerCase() == '.csv';
bool isMarkdownName(String name) =>
    {'.md', '.markdown'}.contains(p.extension(name).toLowerCase());

Future<String?> readSmallTextFile(File file) async {
  if (!await file.exists() || await file.length() > maxTextFileBytes) {
    return null;
  }
  try {
    var length = 0;
    final chunks = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      length += chunk.length;
      if (length > maxTextFileBytes) return null;
      chunks.add(chunk);
    }
    final text = utf8.decode(chunks.takeBytes());
    if (text.contains('\u0000')) return null;
    return text;
  } on FormatException {
    return null;
  }
}

/// Handles quoted separators/newlines without treating a CSV as editable text.
List<List<String>> csvPreview(String text, {int limit = 200}) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') {
      if (quoted && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (c == ',' && !quoted) {
      row.add(field.toString());
      field = StringBuffer();
    } else if ((c == '\n' || c == '\r') && !quoted) {
      row.add(field.toString());
      rows.add(row);
      if (rows.length >= limit) return rows;
      row = [];
      field = StringBuffer();
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
