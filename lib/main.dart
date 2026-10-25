import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'services/pdf_content.dart';
import 'data/local_workspace_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    const override = String.fromEnvironment('PARA_DATA_DIR');
    final root = override.isNotEmpty
        ? Directory(override)
        : Directory(
            p.join((await getApplicationSupportDirectory()).path, 'workspace'),
          );
    final repository = await LocalWorkspaceRepository.open(
      root,
      pdfTextExtractor: extractPdfText,
    );
    runApp(ParaApp(repository: repository, dataDirectory: root.path));
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
