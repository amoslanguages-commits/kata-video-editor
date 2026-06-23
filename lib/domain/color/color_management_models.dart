// lib/domain/color/color_management_models.dart
//
// 30A-PRO: Industry Color Management Core — Dart Models
//
// Enums and value objects describing the full color management pipeline:
//   Input Color Transform → Working Space → Output Color Transform
//
// This module contains NO Flutter dependencies — it is pure Dart so it
// can be used from domain, rendering, and test layers alike.

// ============================================================
// ENUMS
// ============================================================

enum NleColorSpace {
  auto,
  srgb,
  rec709,
  displayP3,
  rec2020,
  acesCg,
  aces2065,
  cameraLog,
  unknown,
}

enum NleTransferCurve {
  auto,
  linear,
  srgb,
  rec709,
  gamma22,
  gamma24,
  logC,
  slog3,
  clog3,
  vLog,
  hlg,
  pq,
  unknown,
}

enum NleWorkingColorSpace {
  linearSrgb,
  linearRec709,
  acesCg,
}

enum NleOutputColorSpace {
  rec709,
  srgb,
  displayP3,
  rec2020,
}

enum NleOutputTransferCurve {
  srgb,
  rec709,
  gamma24,
  hlg,
  pq,
}

enum NleColorPipelineQuality {
  auto,
  compatibility8bit,
  standard16f,
  highPrecision32f,
}

enum NleToneMapMode {
  none,
  simpleReinhard,
  acesApprox,
  hable,
}

// ============================================================
// HELPER
// ============================================================

T _enumByName<T extends Enum>(
  List<T> values,
  Object? name,
  T fallback,
) {
  final string = name?.toString();
  if (string == null) return fallback;
  for (final value in values) {
    if (value.name == string) return value;
  }
  return fallback;
}

// ============================================================
// INPUT COLOR TRANSFORM
// ============================================================

class NleInputColorTransform {
  final NleColorSpace colorSpace;
  final NleTransferCurve transferCurve;
  final bool fullRange;
  final double exposureBias;
  final double inputBlackLevel;
  final double inputWhiteLevel;

  const NleInputColorTransform({
    required this.colorSpace,
    required this.transferCurve,
    this.fullRange = true,
    this.exposureBias = 0.0,
    this.inputBlackLevel = 0.0,
    this.inputWhiteLevel = 1.0,
  });

  const NleInputColorTransform.auto()
      : colorSpace = NleColorSpace.auto,
        transferCurve = NleTransferCurve.auto,
        fullRange = true,
        exposureBias = 0.0,
        inputBlackLevel = 0.0,
        inputWhiteLevel = 1.0;

  Map<String, dynamic> toJson() {
    return {
      'colorSpace': colorSpace.name,
      'transferCurve': transferCurve.name,
      'fullRange': fullRange,
      'exposureBias': exposureBias,
      'inputBlackLevel': inputBlackLevel,
      'inputWhiteLevel': inputWhiteLevel,
    };
  }

  factory NleInputColorTransform.fromJson(Map<String, dynamic> json) {
    return NleInputColorTransform(
      colorSpace: _enumByName(
        NleColorSpace.values,
        json['colorSpace'],
        NleColorSpace.auto,
      ),
      transferCurve: _enumByName(
        NleTransferCurve.values,
        json['transferCurve'],
        NleTransferCurve.auto,
      ),
      fullRange: json['fullRange'] != false,
      exposureBias: (json['exposureBias'] as num?)?.toDouble() ?? 0.0,
      inputBlackLevel: (json['inputBlackLevel'] as num?)?.toDouble() ?? 0.0,
      inputWhiteLevel: (json['inputWhiteLevel'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

// ============================================================
// WORKING COLOR TRANSFORM
// ============================================================

class NleWorkingColorTransform {
  final NleWorkingColorSpace workingSpace;
  final bool sceneLinear;
  final bool clampNegative;
  final bool allowSuperWhites;

  const NleWorkingColorTransform({
    required this.workingSpace,
    this.sceneLinear = true,
    this.clampNegative = true,
    this.allowSuperWhites = true,
  });

  const NleWorkingColorTransform.defaultSceneLinear()
      : workingSpace = NleWorkingColorSpace.linearRec709,
        sceneLinear = true,
        clampNegative = true,
        allowSuperWhites = true;

  Map<String, dynamic> toJson() {
    return {
      'workingSpace': workingSpace.name,
      'sceneLinear': sceneLinear,
      'clampNegative': clampNegative,
      'allowSuperWhites': allowSuperWhites,
    };
  }

  factory NleWorkingColorTransform.fromJson(Map<String, dynamic> json) {
    return NleWorkingColorTransform(
      workingSpace: _enumByName(
        NleWorkingColorSpace.values,
        json['workingSpace'],
        NleWorkingColorSpace.linearRec709,
      ),
      sceneLinear: json['sceneLinear'] != false,
      clampNegative: json['clampNegative'] != false,
      allowSuperWhites: json['allowSuperWhites'] != false,
    );
  }
}

// ============================================================
// OUTPUT COLOR TRANSFORM
// ============================================================

class NleOutputColorTransform {
  final NleOutputColorSpace colorSpace;
  final NleOutputTransferCurve transferCurve;
  final NleToneMapMode toneMapMode;
  final double outputBlackLevel;
  final double outputWhiteLevel;
  final bool dither;
  final bool legalRange;

  const NleOutputColorTransform({
    required this.colorSpace,
    required this.transferCurve,
    this.toneMapMode = NleToneMapMode.none,
    this.outputBlackLevel = 0.0,
    this.outputWhiteLevel = 1.0,
    this.dither = true,
    this.legalRange = false,
  });

  const NleOutputColorTransform.rec709Sdr()
      : colorSpace = NleOutputColorSpace.rec709,
        transferCurve = NleOutputTransferCurve.rec709,
        toneMapMode = NleToneMapMode.none,
        outputBlackLevel = 0.0,
        outputWhiteLevel = 1.0,
        dither = true,
        legalRange = false;

  Map<String, dynamic> toJson() {
    return {
      'colorSpace': colorSpace.name,
      'transferCurve': transferCurve.name,
      'toneMapMode': toneMapMode.name,
      'outputBlackLevel': outputBlackLevel,
      'outputWhiteLevel': outputWhiteLevel,
      'dither': dither,
      'legalRange': legalRange,
    };
  }

  factory NleOutputColorTransform.fromJson(Map<String, dynamic> json) {
    return NleOutputColorTransform(
      colorSpace: _enumByName(
        NleOutputColorSpace.values,
        json['colorSpace'],
        NleOutputColorSpace.rec709,
      ),
      transferCurve: _enumByName(
        NleOutputTransferCurve.values,
        json['transferCurve'],
        NleOutputTransferCurve.rec709,
      ),
      toneMapMode: _enumByName(
        NleToneMapMode.values,
        json['toneMapMode'],
        NleToneMapMode.none,
      ),
      outputBlackLevel: (json['outputBlackLevel'] as num?)?.toDouble() ?? 0.0,
      outputWhiteLevel: (json['outputWhiteLevel'] as num?)?.toDouble() ?? 1.0,
      dither: json['dither'] != false,
      legalRange: json['legalRange'] == true,
    );
  }
}

// ============================================================
// FULL COLOR MANAGEMENT PIPELINE
// ============================================================

class NleColorManagementPipeline {
  final bool enabled;
  final NleColorPipelineQuality quality;
  final NleInputColorTransform defaultInput;
  final NleWorkingColorTransform working;
  final NleOutputColorTransform previewOutput;
  final NleOutputColorTransform exportOutput;
  final bool forceCompatibilityMode;
  final bool previewMatchesExport;

  const NleColorManagementPipeline({
    required this.enabled,
    required this.quality,
    required this.defaultInput,
    required this.working,
    required this.previewOutput,
    required this.exportOutput,
    this.forceCompatibilityMode = false,
    this.previewMatchesExport = true,
  });

  const NleColorManagementPipeline.defaultRec709()
      : enabled = true,
        quality = NleColorPipelineQuality.auto,
        defaultInput = const NleInputColorTransform.auto(),
        working = const NleWorkingColorTransform.defaultSceneLinear(),
        previewOutput = const NleOutputColorTransform.rec709Sdr(),
        exportOutput = const NleOutputColorTransform.rec709Sdr(),
        forceCompatibilityMode = false,
        previewMatchesExport = true;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'quality': quality.name,
      'defaultInput': defaultInput.toJson(),
      'working': working.toJson(),
      'previewOutput': previewOutput.toJson(),
      'exportOutput': exportOutput.toJson(),
      'forceCompatibilityMode': forceCompatibilityMode,
      'previewMatchesExport': previewMatchesExport,
    };
  }

  factory NleColorManagementPipeline.fromJson(Map<String, dynamic> json) {
    return NleColorManagementPipeline(
      enabled: json['enabled'] != false,
      quality: _enumByName(
        NleColorPipelineQuality.values,
        json['quality'],
        NleColorPipelineQuality.auto,
      ),
      defaultInput: NleInputColorTransform.fromJson(
        Map<String, dynamic>.from(json['defaultInput'] as Map? ?? const {}),
      ),
      working: NleWorkingColorTransform.fromJson(
        Map<String, dynamic>.from(json['working'] as Map? ?? const {}),
      ),
      previewOutput: NleOutputColorTransform.fromJson(
        Map<String, dynamic>.from(json['previewOutput'] as Map? ?? const {}),
      ),
      exportOutput: NleOutputColorTransform.fromJson(
        Map<String, dynamic>.from(json['exportOutput'] as Map? ?? const {}),
      ),
      forceCompatibilityMode: json['forceCompatibilityMode'] == true,
      previewMatchesExport: json['previewMatchesExport'] != false,
    );
  }
}
