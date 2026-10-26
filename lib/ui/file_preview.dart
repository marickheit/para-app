import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path/path.dart' as p;
import 'package:file_selector/file_selector.dart';
import 'package:open_filex/open_filex.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../domain/workspace.dart';
import '../services/file_formats.dart';
import 'common.dart';
import 'workspace_style.dart';

class FilePreviewMemory {
  final transforms = <String, Matrix4>{};
}

class FilePreview extends StatefulWidget {
  const FilePreview({
    super.key,
    required this.entry,
    required this.repository,
    this.memory,
  });
  final FilePreviewMemory? memory;
  final Entry entry;
  final WorkspaceRepository repository;
  @override
  State<FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<FilePreview> {
  final _pdf = PdfViewerController();
  @override
  void dispose() {
    if (_pdf.isReady) {
      widget.memory?.transforms[widget.entry.id] = _pdf.value.clone();
    }
    super.dispose();
  }

  late Future<String> _path = widget.repository.filePath(widget.entry.id);
  @override
  void didUpdateWidget(covariant FilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.revision != widget.entry.revision) {
      _path = widget.repository.filePath(widget.entry.id);
    }
  }

  Future<void> _export() async {
    try {
      final path = await _path;
      final target = await getSaveLocation(
        suggestedName: widget.entry.fileName,
      );
      if (target != null) await File(path).copy(target.path);
    } catch (e) {
      if (mounted) showMessage(context, errorLabel(e));
    }
  }

  Future<void> _external() async {
    try {
      final result = await OpenFilex.open(await _path);
      if (result.type != ResultType.done && mounted) {
        showMessage(context, result.message);
      }
    } catch (e) {
      if (mounted) showMessage(context, errorLabel(e));
    }
  }

  Widget _fallback([String? message]) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 35),
    child: Column(
      children: [
        Icon(
          fileIcon(widget.entry),
          size: 32,
          color: WorkspaceColors(context).soft,
        ),
        const SizedBox(height: 14),
        Text(
          message ?? 'Für dieses Format gibt es keine Vorschau.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _export,
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text('Datei speichern …'),
            ),
            TextButton(
              onPressed: _external,
              child: const Text('Mit Standard-App öffnen'),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _path,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text(errorLabel(snapshot.error!));
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final path = snapshot.data!, ext = p.extension(path).toLowerCase();
      if (ext == '.pdf') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: WorkspaceColors(context).line),
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: PdfViewer.file(
                  path,
                  controller: _pdf,
                  passwordProvider: () => null,
                  params: PdfViewerParams(
                    sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
                      calculateInitialZoom:
                          (document, controller, fit, cover) =>
                              controller.viewSize.width /
                              (document.pages.first.width + 16),
                    ),
                    onViewerReady: (_, controller) {
                      final remembered =
                          widget.memory?.transforms[widget.entry.id];
                      if (remembered != null) {
                        controller.goTo(remembered, duration: Duration.zero);
                      }
                    },
                    backgroundColor: WorkspaceColors(context).sidebar,
                    errorBannerBuilder: (context, error, stack, documentRef) =>
                        _fallback('Die PDF-Vorschau ist nicht verfügbar.'),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _external,
                child: const Text('Mit Standard-App öffnen'),
              ),
            ),
          ],
        );
      }
      if ({
        '.png',
        '.jpg',
        '.jpeg',
        '.gif',
        '.webp',
        '.bmp',
        '.svg',
      }.contains(ext)) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: WorkspaceColors(context).sidebar,
            border: Border.all(color: WorkspaceColors(context).line),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ext == '.svg'
              ? SvgPicture.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      _fallback('Die Bildvorschau ist nicht verfügbar.'),
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      _fallback('Die Bildvorschau ist nicht verfügbar.'),
                ),
        );
      }
      if (ext == '.csv') {
        return FutureBuilder<String?>(
          future: readSmallTextFile(File(path)),
          builder: (context, text) {
            if (text.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (text.data == null) {
              return _fallback(
                'Diese Tabelle ist zu groß oder nicht als UTF-8 lesbar.',
              );
            }
            final rows = csvPreview(text.data!);
            if (rows.isEmpty) return const Text('Leere Tabelle');
            final columns = rows
                .map((r) => r.length)
                .reduce((a, b) => a > b ? a : b)
                .clamp(1, 20);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      horizontalMargin: 8,
                      columnSpacing: 22,
                      headingRowHeight: 35,
                      columns: List.generate(
                        columns,
                        (i) => DataColumn(
                          label: Text(
                            i < rows.first.length ? rows.first[i] : '',
                          ),
                        ),
                      ),
                      rows: rows
                          .skip(1)
                          .map(
                            (row) => DataRow(
                              cells: List.generate(
                                columns,
                                (i) => DataCell(
                                  Text(i < row.length ? row[i] : ''),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tabellenvorschau · bis zu 200 Zeilen / 20 Spalten',
                    style: TextStyle(
                      fontSize: 11,
                      color: WorkspaceColors(context).soft,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
      return SingleChildScrollView(child: _fallback());
    },
  );
}
