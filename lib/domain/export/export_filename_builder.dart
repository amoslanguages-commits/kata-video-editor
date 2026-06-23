class ExportFilenamePatterns {
  ExportFilenamePatterns._();

  static const String defaultPattern = '{project}_{platform}_{resolution}_{date}';
  static const String projectDate = '{project}_{date}';
  static const String projectPresetVersion = '{project}_{preset}_v{version}';
  static const String platformReady = '{platform}_{project}_{resolution}_{date}';
}

class ExportFilenameBuilder {
  const ExportFilenameBuilder();

  String build({
    required String pattern,
    required String projectName,
    required String presetName,
    required String platform,
    required String resolution,
    required String extension,
    int version = 1,
    DateTime? now,
  }) {
    final date = _dateStamp(now ?? DateTime.now());
    var output = pattern.trim().isEmpty
        ? ExportFilenamePatterns.defaultPattern
        : pattern.trim();

    output = output.replaceAll('{project}', projectName);
    output = output.replaceAll('{preset}', presetName);
    output = output.replaceAll('{platform}', platform);
    output = output.replaceAll('{resolution}', resolution);
    output = output.replaceAll('{date}', date);
    output = output.replaceAll('{version}', version.toString().padLeft(2, '0'));

    final safeBase = _safeName(output);
    final safeExtension = _safeExtension(extension);
    return '$safeBase.$safeExtension';
  }

  String _dateStamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}';
  }

  String _safeExtension(String value) {
    final cleaned = value.replaceAll('.', '').trim().toLowerCase();
    if (cleaned == 'mov') return 'mov';
    return 'mp4';
  }

  String _safeName(String value) {
    final buffer = StringBuffer();
    var lastWasSeparator = false;

    for (final codeUnit in value.codeUnits) {
      final isNumber = codeUnit >= 48 && codeUnit <= 57;
      final isUpper = codeUnit >= 65 && codeUnit <= 90;
      final isLower = codeUnit >= 97 && codeUnit <= 122;
      final isDot = codeUnit == 46;
      final isDash = codeUnit == 45;
      final isUnderscore = codeUnit == 95;
      final allowed = isNumber || isUpper || isLower || isDot || isDash || isUnderscore;

      if (allowed) {
        buffer.writeCharCode(codeUnit);
        lastWasSeparator = false;
      } else if (!lastWasSeparator) {
        buffer.write('_');
        lastWasSeparator = true;
      }
    }

    var result = buffer.toString();
    while (result.startsWith('_') || result.startsWith('.')) {
      result = result.substring(1);
    }
    while (result.endsWith('_') || result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result.isEmpty ? 'export' : result;
  }
}
