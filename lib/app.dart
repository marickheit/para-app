import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'domain/workspace.dart';
import 'ui/workspace_screen.dart';

class ParaApp extends StatelessWidget {
  const ParaApp({
    super.key,
    required this.repository,
    required this.dataDirectory,
  });
  final WorkspaceRepository repository;
  final String dataDirectory;

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xff35624a),
          brightness: brightness,
          surface: dark ? const Color(0xff1c201e) : const Color(0xfffcfcfb),
        ).copyWith(
          primary: dark ? const Color(0xffacd2b4) : const Color(0xff315d42),
          onSurface: dark ? const Color(0xffe2e8e3) : const Color(0xff29322d),
          onSurfaceVariant: dark
              ? const Color(0xffa4b0a7)
              : const Color(0xff69736b),
          surfaceContainerLow: dark
              ? const Color(0xff222723)
              : const Color(0xfff4f5f1),
          secondaryContainer: dark
              ? const Color(0xff354c3d)
              : const Color(0xffdce8dc),
          onSecondaryContainer: dark
              ? const Color(0xffacd2b4)
              : const Color(0xff315d42),
          outlineVariant: dark
              ? const Color(0xff384139)
              : const Color(0xffdfe3dc),
        );
    return ThemeData(
      useMaterial3: true,
      fontFamily: '.AppleSystemUIFont',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 13, height: 1.55),
        bodyLarge: TextStyle(fontSize: 13, height: 1.55),
        titleMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        headlineSmall: TextStyle(
          fontSize: 25,
          height: 1.3,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(fontSize: 11),
      ),
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(30, 30),
          maximumSize: const Size(32, 32),
          padding: const EdgeInsets.all(5),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          textStyle: const TextStyle(fontSize: 13),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'P.A.R.A.',
    debugShowCheckedModeBanner: false,
    locale: const Locale('de'),
    supportedLocales: const [Locale('de'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: WorkspaceScreen(repository: repository, dataDirectory: dataDirectory),
  );
}
