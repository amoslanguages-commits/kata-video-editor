import 'dart:io';

import 'package:path/path.dart' as p;

class ExportFilenameVersioner {
  const ExportFilenameVersioner();

  Future<String> uniquePath({
    required String directoryPath,
    required String fileName,
  }) async {
    final safeName = fileName.trim().isEmpty ? 'export.mp4' : fileName.trim();
    final extension = p.extension(safeName).isEmpty ? '.mp4' : p.extension(safeName);
    final baseName = p.basenameWithoutExtension(safeName);

    final firstPath = p.join(directoryPath, '$baseName$extension');
    if (!await File(firstPath).exists()) return firstPath;

    for (var version = 2; version <= 99; version++) {
      final label = version.toString().padLeft(2, '0');
      final candidate = p.join(directoryPath, '${baseName}_v$label$extension');
      if (!await File(candidate).exists()) return candidate;
    }

    final fallback = DateTime.now().millisecondsSinceEpoch;
    return p.join(directoryPath, '${baseName}_$fallback$extension');
  }
}
