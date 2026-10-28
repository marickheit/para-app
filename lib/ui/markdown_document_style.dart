import 'package:flutter/material.dart';

/// Shared metrics keep rendered blocks, live input and table cells in rhythm.
class MarkdownDocumentStyle {
  static const columnWidth = 744.0; // 680 px text + two 32 px gutters.
  static const body = TextStyle(fontSize: 16, height: 1.55);
  static const source = TextStyle(
    fontFamily: 'monospace',
    fontSize: 15,
    height: 1.55,
  );
  static const blockGap = 16.0;
  static const listGap = 4.0;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xff202020)
      : const Color(0xfffcfcfb);

  static Color ink(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xffd6d6d6)
      : const Color(0xff29322d);

  static Color line(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xff3b3b3b)
      : const Color(0xffdfe3dc);

  static TextStyle heading(int level) => TextStyle(
    fontSize: switch (level) {
      1 => 30,
      2 => 22,
      3 => 19,
      4 => 17,
      _ => 16,
    },
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
}
