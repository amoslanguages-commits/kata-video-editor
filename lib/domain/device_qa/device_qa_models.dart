// ============================================================================
// 29E: Dart Device QA Models
// ============================================================================

enum DeviceTier {
  lowEnd,
  midRange,
  highEnd,
  unknown,
}

enum DeviceQaSeverity {
  pass,
  warning,
  fail,
}

class DeviceQaIssue {
  final String id;
  final DeviceQaSeverity severity;
  final String message;
  final Map<String, dynamic> details;

  const DeviceQaIssue({
    required this.id,
    required this.severity,
    required this.message,
    this.details = const {},
  });

  bool get isFail    => severity == DeviceQaSeverity.fail;
  bool get isWarning => severity == DeviceQaSeverity.warning;
  bool get isPassed  => severity == DeviceQaSeverity.pass;

  factory DeviceQaIssue.fromJson(Map<String, dynamic> json) {
    return DeviceQaIssue(
      id:       json['id']?.toString() ?? '',
      severity: _severity(json['severity']?.toString()),
      message:  json['message']?.toString() ?? '',
      details:  Map<String, dynamic>.from(json['details'] as Map? ?? const {}),
    );
  }

  static DeviceQaSeverity _severity(String? v) => switch (v) {
    'fail'    => DeviceQaSeverity.fail,
    'warning' => DeviceQaSeverity.warning,
    _         => DeviceQaSeverity.pass,
  };
}

class CodecCapabilityReport {
  final bool hasH264Decoder;
  final bool hasH264Encoder;
  final bool hasAacDecoder;
  final bool hasAacEncoder;
  final bool supports1080pExport;
  final bool supports4kExport;
  final int maxH264EncodeWidth;
  final int maxH264EncodeHeight;

  const CodecCapabilityReport({
    required this.hasH264Decoder,
    required this.hasH264Encoder,
    required this.hasAacDecoder,
    required this.hasAacEncoder,
    required this.supports1080pExport,
    required this.supports4kExport,
    required this.maxH264EncodeWidth,
    required this.maxH264EncodeHeight,
  });

  factory CodecCapabilityReport.fromJson(Map<String, dynamic> json) {
    return CodecCapabilityReport(
      hasH264Decoder:      json['hasH264Decoder']      as bool? ?? false,
      hasH264Encoder:      json['hasH264Encoder']      as bool? ?? false,
      hasAacDecoder:       json['hasAacDecoder']       as bool? ?? false,
      hasAacEncoder:       json['hasAacEncoder']       as bool? ?? false,
      supports1080pExport: json['supports1080pExport'] as bool? ?? false,
      supports4kExport:    json['supports4kExport']    as bool? ?? false,
      maxH264EncodeWidth:  (json['maxH264EncodeWidth']  as num?)?.toInt() ?? 0,
      maxH264EncodeHeight: (json['maxH264EncodeHeight'] as num?)?.toInt() ?? 0,
    );
  }
}

class EglCapabilityReport {
  final bool eglAvailable;
  final String glesVersion;
  final String glRenderer;
  final String glVendor;
  final int maxTextureSize;
  final bool supportsExternalOes;
  final bool supportsFramebufferObject;

  const EglCapabilityReport({
    required this.eglAvailable,
    required this.glesVersion,
    required this.glRenderer,
    required this.glVendor,
    required this.maxTextureSize,
    required this.supportsExternalOes,
    required this.supportsFramebufferObject,
  });

  factory EglCapabilityReport.fromJson(Map<String, dynamic> json) {
    return EglCapabilityReport(
      eglAvailable:              json['eglAvailable']              as bool? ?? false,
      glesVersion:               json['glesVersion']?.toString()   ?? 'unknown',
      glRenderer:                json['glRenderer']?.toString()     ?? 'unknown',
      glVendor:                  json['glVendor']?.toString()       ?? 'unknown',
      maxTextureSize:            (json['maxTextureSize'] as num?)?.toInt() ?? 0,
      supportsExternalOes:       json['supportsExternalOes']       as bool? ?? false,
      supportsFramebufferObject: json['supportsFramebufferObject'] as bool? ?? false,
    );
  }
}

class ThermalStatusReport {
  final bool thermalApiAvailable;
  final String currentStatus;
  final bool shouldThrottlePreview;
  final bool shouldBlockLongExport;

  const ThermalStatusReport({
    required this.thermalApiAvailable,
    required this.currentStatus,
    required this.shouldThrottlePreview,
    required this.shouldBlockLongExport,
  });

  factory ThermalStatusReport.fromJson(Map<String, dynamic> json) {
    return ThermalStatusReport(
      thermalApiAvailable:  json['thermalApiAvailable']  as bool?   ?? false,
      currentStatus:        json['currentStatus']?.toString()        ?? 'unknown',
      shouldThrottlePreview: json['shouldThrottlePreview'] as bool?  ?? false,
      shouldBlockLongExport: json['shouldBlockLongExport'] as bool?  ?? false,
    );
  }
}

class DeviceRecommendation {
  final String previewQuality;
  final int maxExportWidth;
  final int maxExportHeight;
  final double maxFrameRate;
  final bool preferProxyPreview;
  final bool requireProxyFor4k;
  final bool allow4kExport;
  final List<String> notes;

  const DeviceRecommendation({
    required this.previewQuality,
    required this.maxExportWidth,
    required this.maxExportHeight,
    required this.maxFrameRate,
    required this.preferProxyPreview,
    required this.requireProxyFor4k,
    required this.allow4kExport,
    required this.notes,
  });

  factory DeviceRecommendation.fromJson(Map<String, dynamic> json) {
    return DeviceRecommendation(
      previewQuality:     json['previewQuality']?.toString()  ?? 'auto',
      maxExportWidth:     (json['maxExportWidth']  as num?)?.toInt() ?? 1080,
      maxExportHeight:    (json['maxExportHeight'] as num?)?.toInt() ?? 1920,
      maxFrameRate:       (json['maxFrameRate']    as num?)?.toDouble() ?? 30.0,
      preferProxyPreview: json['preferProxyPreview'] as bool? ?? true,
      requireProxyFor4k:  json['requireProxyFor4k']  as bool? ?? true,
      allow4kExport:      json['allow4kExport']       as bool? ?? false,
      notes:              (json['notes'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ?? const [],
    );
  }
}

class DeviceCapabilityReport {
  final String manufacturer;
  final String brand;
  final String model;
  final String androidRelease;
  final int androidSdk;
  final DeviceTier deviceTier;
  final int totalMemoryMb;
  final int availableMemoryMb;
  final int cpuCoreCount;
  final CodecCapabilityReport codec;
  final EglCapabilityReport egl;
  final ThermalStatusReport thermal;
  final DeviceRecommendation recommendation;

  const DeviceCapabilityReport({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.androidRelease,
    required this.androidSdk,
    required this.deviceTier,
    required this.totalMemoryMb,
    required this.availableMemoryMb,
    required this.cpuCoreCount,
    required this.codec,
    required this.egl,
    required this.thermal,
    required this.recommendation,
  });

  factory DeviceCapabilityReport.fromJson(Map<String, dynamic> json) {
    return DeviceCapabilityReport(
      manufacturer:      json['manufacturer']?.toString()   ?? '',
      brand:             json['brand']?.toString()           ?? '',
      model:             json['model']?.toString()           ?? '',
      androidRelease:    json['androidRelease']?.toString()  ?? '',
      androidSdk:        (json['androidSdk']        as num?)?.toInt() ?? 0,
      deviceTier:        _tier(json['deviceTier']?.toString()),
      totalMemoryMb:     (json['totalMemoryMb']     as num?)?.toInt() ?? 0,
      availableMemoryMb: (json['availableMemoryMb'] as num?)?.toInt() ?? 0,
      cpuCoreCount:      (json['cpuCoreCount']      as num?)?.toInt() ?? 0,
      codec:         CodecCapabilityReport.fromJson(
          Map<String, dynamic>.from(json['codecReport'] as Map? ?? const {})),
      egl:           EglCapabilityReport.fromJson(
          Map<String, dynamic>.from(json['eglReport'] as Map? ?? const {})),
      thermal:       ThermalStatusReport.fromJson(
          Map<String, dynamic>.from(json['thermalReport'] as Map? ?? const {})),
      recommendation: DeviceRecommendation.fromJson(
          Map<String, dynamic>.from(json['recommendation'] as Map? ?? const {})),
    );
  }

  static DeviceTier _tier(String? v) => switch (v) {
    'low_end'   => DeviceTier.lowEnd,
    'mid_range' => DeviceTier.midRange,
    'high_end'  => DeviceTier.highEnd,
    _           => DeviceTier.unknown,
  };

  String get tierLabel => switch (deviceTier) {
    DeviceTier.lowEnd   => 'Low-end',
    DeviceTier.midRange => 'Mid-range',
    DeviceTier.highEnd  => 'High-end',
    DeviceTier.unknown  => 'Unknown',
  };
}

class DeviceQaReport {
  final bool passed;
  final int passCount;
  final int warningCount;
  final int failCount;
  final DeviceCapabilityReport capabilityReport;
  final List<DeviceQaIssue> issues;

  const DeviceQaReport({
    required this.passed,
    required this.passCount,
    required this.warningCount,
    required this.failCount,
    required this.capabilityReport,
    required this.issues,
  });

  factory DeviceQaReport.fromJson(Map<String, dynamic> json) {
    final rawCap    = Map<String, dynamic>.from(json['capabilityReport'] as Map? ?? const {});
    final rawIssues = json['issues'] as List<dynamic>? ?? [];

    return DeviceQaReport(
      passed:           json['passed']       as bool? ?? false,
      passCount:        (json['passCount']    as num?)?.toInt() ?? 0,
      warningCount:     (json['warningCount'] as num?)?.toInt() ?? 0,
      failCount:        (json['failCount']    as num?)?.toInt() ?? 0,
      capabilityReport: DeviceCapabilityReport.fromJson(rawCap),
      issues:           rawIssues
                            .cast<Map<String, dynamic>>()
                            .map(DeviceQaIssue.fromJson)
                            .toList(),
    );
  }
}

class MemoryPressureResult {
  final int beforeAvailableMb;
  final int afterAvailableMb;
  final int allocatedMb;
  final bool survived;
  final String message;

  const MemoryPressureResult({
    required this.beforeAvailableMb,
    required this.afterAvailableMb,
    required this.allocatedMb,
    required this.survived,
    required this.message,
  });

  factory MemoryPressureResult.fromJson(Map<String, dynamic> json) {
    return MemoryPressureResult(
      beforeAvailableMb: (json['beforeAvailableMb'] as num?)?.toInt() ?? 0,
      afterAvailableMb:  (json['afterAvailableMb']  as num?)?.toInt() ?? 0,
      allocatedMb:       (json['allocatedMb']        as num?)?.toInt() ?? 0,
      survived:          json['survived'] as bool? ?? false,
      message:           json['message']?.toString() ?? '',
    );
  }
}

class ExportRecoverySuggestion {
  final bool canRetry;
  final bool retryWithProxy;
  final int retryWidth;
  final int retryHeight;
  final double retryFrameRate;
  final bool disable4k;
  final String message;

  const ExportRecoverySuggestion({
    required this.canRetry,
    required this.retryWithProxy,
    required this.retryWidth,
    required this.retryHeight,
    required this.retryFrameRate,
    required this.disable4k,
    required this.message,
  });

  factory ExportRecoverySuggestion.fromJson(Map<String, dynamic> json) {
    return ExportRecoverySuggestion(
      canRetry:       json['canRetry']       as bool?   ?? false,
      retryWithProxy: json['retryWithProxy'] as bool?   ?? true,
      retryWidth:     (json['retryWidth']    as num?)?.toInt()    ?? 1080,
      retryHeight:    (json['retryHeight']   as num?)?.toInt()    ?? 1920,
      retryFrameRate: (json['retryFrameRate'] as num?)?.toDouble() ?? 30.0,
      disable4k:      json['disable4k']      as bool?   ?? true,
      message:        json['message']?.toString() ?? '',
    );
  }
}
