// lib/domain/color_qc/color_qc_models.dart

enum ColorQaSeverity {
  info,
  warning,
  error,
  releaseBlocker,
}

enum ColorQaArea {
  colorManagement,
  gpuPipeline,
  shaderCompile,
  previewExport,
  deviceFallback,
  memoryLeak,
  hdrOutput,
  scopeAccuracy,
}

class ColorQaIssue {
  final String id;
  final ColorQaSeverity severity;
  final ColorQaArea area;
  final String title;
  final String message;
  final String? suggestedFix;

  const ColorQaIssue({
    required this.id,
    required this.severity,
    required this.area,
    required this.title,
    required this.message,
    this.suggestedFix,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'severity': severity.name,
      'area': area.name,
      'title': title,
      'message': message,
      'suggestedFix': suggestedFix,
    };
  }

  factory ColorQaIssue.fromJson(Map<String, dynamic> json) {
    return ColorQaIssue(
      id: json['id'] as String? ?? '',
      severity: _parseSeverity(json['severity'] as String?),
      area: _parseArea(json['area'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      suggestedFix: json['suggestedFix'] as String?,
    );
  }

  static ColorQaSeverity _parseSeverity(String? value) {
    switch (value?.toLowerCase()) {
      case 'info':
        return ColorQaSeverity.info;
      case 'warning':
        return ColorQaSeverity.warning;
      case 'error':
        return ColorQaSeverity.error;
      case 'releaseblocker':
      case 'release_blocker':
        return ColorQaSeverity.releaseBlocker;
      default:
        return ColorQaSeverity.error;
    }
  }

  static ColorQaArea _parseArea(String? value) {
    switch (value?.toLowerCase()) {
      case 'colormanagement':
      case 'color_management':
        return ColorQaArea.colorManagement;
      case 'gpupipeline':
      case 'gpu_pipeline':
        return ColorQaArea.gpuPipeline;
      case 'shadercompile':
      case 'shader_compile':
        return ColorQaArea.shaderCompile;
      case 'previewexport':
      case 'preview_export':
        return ColorQaArea.previewExport;
      case 'devicefallback':
      case 'device_fallback':
        return ColorQaArea.deviceFallback;
      case 'memoryleak':
      case 'memory_leak':
        return ColorQaArea.memoryLeak;
      case 'hdroutput':
      case 'hdr_output':
        return ColorQaArea.hdrOutput;
      case 'scopeaccuracy':
      case 'scope_accuracy':
        return ColorQaArea.scopeAccuracy;
      default:
        return ColorQaArea.gpuPipeline;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorQaIssue &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          severity == other.severity &&
          area == other.area &&
          title == other.title &&
          message == other.message &&
          suggestedFix == other.suggestedFix;

  @override
  int get hashCode =>
      id.hashCode ^
      severity.hashCode ^
      area.hashCode ^
      title.hashCode ^
      message.hashCode ^
      suggestedFix.hashCode;
}

class ColorQaReport {
  final DateTime timestamp;
  final bool passed;
  final List<ColorQaIssue> issues;

  const ColorQaReport({
    required this.timestamp,
    required this.passed,
    required this.issues,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'passed': passed,
      'issues': issues.map((i) => i.toJson()).toList(),
    };
  }

  factory ColorQaReport.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'] as List? ?? const [];
    return ColorQaReport(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      passed: json['passed'] == true,
      issues: rawIssues
          .whereType<Map>()
          .map((item) => ColorQaIssue.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
