import 'package:pdfrx/pdfrx.dart';

/// Bounded extraction keeps huge or protected attachments usable without OCR.
Future<String?> extractPdfText(String path) async {
  await pdfrxFlutterInitialize();
  final document = await PdfDocument.openFile(
    path,
    passwordProvider: () => null,
  );
  try {
    final text = StringBuffer();
    for (final page in document.pages.take(100)) {
      text.writeln((await page.loadText())?.fullText ?? '');
      if (text.length >= 2 * 1024 * 1024) break;
    }
    final result = text.toString();
    return result.length > 2 * 1024 * 1024
        ? result.substring(0, 2 * 1024 * 1024)
        : result;
  } finally {
    await document.dispose();
  }
}
