enum GpuRenderFormat {
  rgba8,
  rgba16f,
  rgba32f,
}

enum ColorPassPrecision {
  compatibility8bit,
  halfFloat16f,
  fullFloat32f,
}

class ColorPipelineStats {
  final int passCount;
  final GpuRenderFormat format;
  final ColorPassPrecision precision;
  final bool usedFallback;
  final String? fallbackReason;

  const ColorPipelineStats({
    required this.passCount,
    required this.format,
    required this.precision,
    required this.usedFallback,
    this.fallbackReason,
  });

  factory ColorPipelineStats.fromJson(Map<String, dynamic> json) {
    return ColorPipelineStats(
      passCount: (json['passCount'] as num?)?.toInt() ?? 0,
      format: _parseFormat(json['format']?.toString()),
      precision: _parsePrecision(json['precision']?.toString()),
      usedFallback: json['usedFallback'] == true,
      fallbackReason: json['fallbackReason']?.toString(),
    );
  }

  static GpuRenderFormat _parseFormat(String? value) {
    switch (value?.toLowerCase()) {
      case 'rgba16f':
        return GpuRenderFormat.rgba16f;
      case 'rgba32f':
        return GpuRenderFormat.rgba32f;
      case 'rgba8':
      default:
        return GpuRenderFormat.rgba8;
    }
  }

  static ColorPassPrecision _parsePrecision(String? value) {
    switch (value?.toLowerCase()) {
      case 'half_float_16f':
      case 'halffloat16f':
        return ColorPassPrecision.halfFloat16f;
      case 'full_float_32f':
      case 'fullfloat32f':
        return ColorPassPrecision.fullFloat32f;
      case 'compatibility_8bit':
      case 'compatibility8bit':
      default:
        return ColorPassPrecision.compatibility8bit;
    }
  }

  String get displayLabel {
    switch (precision) {
      case ColorPassPrecision.fullFloat32f:
        return '32-bit float';
      case ColorPassPrecision.halfFloat16f:
        return '16-bit float';
      case ColorPassPrecision.compatibility8bit:
        return '8-bit compatibility';
    }
  }
}
