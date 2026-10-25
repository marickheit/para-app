import 'dart:convert';
import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import '../domain/workspace.dart';

/// File picker and desktop drops use the same import rules.
class WorkspaceImporter {
  WorkspaceImporter(this.repository);
  final WorkspaceRepository repository;
  static const maxMarkdownBytes = 16 * 1024 * 1024;

  Future<Entry> importFile(
    XFile file, {
    ParaSection section = ParaSection.inbox,
    String? parentId,
  }) async {
    final extension = p.extension(file.name).toLowerCase();
    if ({'.md', '.markdown'}.contains(extension) &&
        await file.length() <= maxMarkdownBytes) {
      try {
        var length = 0;
        final body = await file
            .openRead()
            .map<List<int>>((chunk) {
              length += chunk.length;
              if (length > maxMarkdownBytes) throw const _MarkdownTooLarge();
              return chunk;
            })
            .transform(utf8.decoder)
            .join();
        return await repository.create(
          kind: EntryKind.note,
          parentId: parentId,
          section: section,
          draft: EntryDraft(
            title: p.basenameWithoutExtension(file.name),
            body: body,
          ),
        );
      } on FormatException {
        // Binary/non-UTF-8 files remain intact as ordinary attachments.
      } on _MarkdownTooLarge {
        // Reopen the stream and store large files without buffering them.
      }
    }
    return repository.importFile(
      name: file.name,
      bytes: file.openRead(),
      section: section,
      parentId: parentId,
    );
  }

  Future<Entry> importPath(
    XFile file, {
    ParaSection section = ParaSection.inbox,
    String? parentId,
  }) async {
    if (file.path.isNotEmpty &&
        await FileSystemEntity.type(file.path, followLinks: false) ==
            FileSystemEntityType.directory) {
      final folder = await repository.create(
        kind: EntryKind.folder,
        section: section,
        parentId: parentId,
        draft: EntryDraft(title: p.basename(file.path)),
      );
      await for (final child in Directory(file.path).list(followLinks: false)) {
        if (child is Link) continue;
        await importPath(
          XFile(child.path),
          section: section,
          parentId: folder.id,
        );
      }
      return folder;
    }
    return importFile(file, section: section, parentId: parentId);
  }
}

class _MarkdownTooLarge implements Exception {
  const _MarkdownTooLarge();
}
