import 'package:flutter/material.dart';

class WorkspaceColors {
  WorkspaceColors(BuildContext context)
    : dark = Theme.of(context).brightness == Brightness.dark;
  final bool dark;
  Color get paper => dark ? const Color(0xff1c201e) : const Color(0xfffcfcfb);
  Color get rail => dark ? const Color(0xff252b27) : const Color(0xffeceeea);
  Color get sidebar => dark ? const Color(0xff222723) : const Color(0xfff4f5f1);
  Color get ink => dark ? const Color(0xffe2e8e3) : const Color(0xff29322d);
  Color get soft => dark ? const Color(0xffa4b0a7) : const Color(0xff69736b);
  Color get line => dark ? const Color(0xff384139) : const Color(0xffdfe3dc);
  Color get selection =>
      dark ? const Color(0xff414542) : const Color(0xffdfe2df);
  Color get selected =>
      dark ? const Color(0xff354c3d) : const Color(0xffdce8dc);
  Color get accent => dark ? const Color(0xffacd2b4) : const Color(0xff315d42);
}
