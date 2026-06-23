import 'dart:io';

class CubeLutHeader {
  final String title;
  final int size;
  final int dataLineCount;
  final bool valid;
  final String? error;

  const CubeLutHeader({
    required this.title,
    required this.size,
    required this.dataLineCount,
    required this.valid,
    this.error,
  });
}

class CubeLutHeaderParser {
  const CubeLutHeaderParser();

  Future<CubeLutHeader> parseFile(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      return const CubeLutHeader(
        title: 'Missing LUT',
        size: 0,
        dataLineCount: 0,
        valid: false,
        error: 'File does not exist.',
      );
    }

    final lines = await file.readAsLines();

    var title = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'LUT';

    var size = 0;
    var dataLines = 0;

    for (final raw in lines) {
      final line = raw.trim();

      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.startsWith('TITLE')) {
        title = line
            .replaceFirst('TITLE', '')
            .trim()
            .replaceAll('"', '');
        continue;
      }

      if (line.startsWith('LUT_3D_SIZE')) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          size = int.tryParse(parts[1]) ?? 0;
        }
        continue;
      }

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 3 &&
          double.tryParse(parts[0]) != null &&
          double.tryParse(parts[1]) != null &&
          double.tryParse(parts[2]) != null) {
        dataLines++;
      }
    }

    if (size <= 0) {
      return CubeLutHeader(
        title: title,
        size: size,
        dataLineCount: dataLines,
        valid: false,
        error: 'Missing LUT_3D_SIZE.',
      );
    }

    final expected = size * size * size;

    if (dataLines < expected) {
      return CubeLutHeader(
        title: title,
        size: size,
        dataLineCount: dataLines,
        valid: false,
        error: 'Not enough LUT data. Expected $expected lines.',
      );
    }

    return CubeLutHeader(
      title: title,
      size: size,
      dataLineCount: dataLines,
      valid: true,
    );
  }
}
