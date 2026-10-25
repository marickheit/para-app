import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'services/pdf_content.dart';
import 'services/workspace_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    const override = String.fromEnvironment('PARA_DATA_DIR');
    const configOverride = String.fromEnvironment('PARA_CONFIG_DIR');
    final configuration = configOverride.isEmpty
        ? await getApplicationSupportDirectory()
        : Directory(configOverride);
    final manager = WorkspaceManager(
      configurationDirectory: configuration,
      defaultRoot: Directory(p.join(configuration.path, 'workspace')),
      overrideRoot: override.isEmpty ? null : Directory(override),
      pdfTextExtractor: extractPdfText,
    );
    runApp(WorkspaceHost(manager: manager));
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SelectableText(
                'Der lokale Arbeitsbereich konnte nicht geöffnet werden.\n\n$error',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
