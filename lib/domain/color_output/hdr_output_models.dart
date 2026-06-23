// lib/domain/color_output/hdr_output_models.dart
//
// 30J-PRO: HDR and Wide Color Gamut Output settings, enums,
// capability scans, mastering display metadata, and export validation.

enum NleOutputColorMode {
  rec709Sdr,
  srgbSdr,
  displayP3Sdr,
  rec2020Sdr,
  rec2020HlgHdr,
  rec2020PqHdr,
}

enum NleHdrTransferFunction {
  sdr,
  hlg,
  pq,
}

enum NleHdrMetadataMode {
  none,
  hdr10Static,
  auto,
}

enum NleToneMapOperator {
  none,
  reinhard,
  acesApprox,
  hable,
  mobileFilmSafe,
}

enum NleColorRangeMode {
  auto,
  full,
  limited,
}

enum NleOutputBitDepth {
  eightBit,
  tenBit,
}

enum NleWideColorPreviewMode {
  auto,
  forceSdrPreview,
  wideColorPreview,
  hdrPreview,
}

class NleHdrMasteringDisplayMetadata {
  final double maxDisplayMasteringLuminance;
  final double minDisplayMasteringLuminance;
  final double maxContentLightLevel;
  final double maxFrameAverageLightLevel;
  final double primaryRedX;
  final double primaryRedY;
  final double primaryGreenX;
  final double primaryGreenY;
  final double primaryBlueX;
  final double primaryBlueY;
  final double whitePointX;
  final double whitePointY;

  const NleHdrMasteringDisplayMetadata({
    this.maxDisplayMasteringLuminance = 1000.0,
    this.minDisplayMasteringLuminance = 0.005,
    this.maxContentLightLevel = 1000.0,
    this.maxFrameAverageLightLevel = 400.0,
    this.primaryRedX = 0.708,
    this.primaryRedY = 0.292,
    this.primaryGreenX = 0.170,
    this.primaryGreenY = 0.797,
    this.primaryBlueX = 0.131,
    this.primaryBlueY = 0.046,
    this.whitePointX = 0.3127,
    this.whitePointY = 0.3290,
  });

  factory NleHdrMasteringDisplayMetadata.fromJson(Map<String, dynamic> json) {
    return NleHdrMasteringDisplayMetadata(
      maxDisplayMasteringLuminance: (json['maxDisplayMasteringLuminance'] as num?)?.toDouble() ?? 1000.0,
      minDisplayMasteringLuminance: (json['minDisplayMasteringLuminance'] as num?)?.toDouble() ?? 0.005,
      maxContentLightLevel: (json['maxContentLightLevel'] as num?)?.toDouble() ?? 1000.0,
      maxFrameAverageLightLevel: (json['maxFrameAverageLightLevel'] as num?)?.toDouble() ?? 400.0,
      primaryRedX: (json['primaryRedX'] as num?)?.toDouble() ?? 0.708,
      primaryRedY: (json['primaryRedY'] as num?)?.toDouble() ?? 0.292,
      primaryGreenX: (json['primaryGreenX'] as num?)?.toDouble() ?? 0.170,
      primaryGreenY: (json['primaryGreenY'] as num?)?.toDouble() ?? 0.797,
      primaryBlueX: (json['primaryBlueX'] as num?)?.toDouble() ?? 0.131,
      primaryBlueY: (json['primaryBlueY'] as num?)?.toDouble() ?? 0.046,
      whitePointX: (json['whitePointX'] as num?)?.toDouble() ?? 0.3127,
      whitePointY: (json['whitePointY'] as num?)?.toDouble() ?? 0.3290,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDisplayMasteringLuminance': maxDisplayMasteringLuminance,
      'minDisplayMasteringLuminance': minDisplayMasteringLuminance,
      'maxContentLightLevel': maxContentLightLevel,
      'maxFrameAverageLightLevel': maxFrameAverageLightLevel,
      'primaryRedX': primaryRedX,
      'primaryRedY': primaryRedY,
      'primaryGreenX': primaryGreenX,
      'primaryGreenY': primaryGreenY,
      'primaryBlueX': primaryBlueX,
      'primaryBlueY': primaryBlueY,
      'whitePointX': whitePointX,
      'whitePointY': whitePointY,
    };
  }
}

class NleHdrOutputSettings {
  final NleOutputColorMode colorMode;
  final NleHdrTransferFunction transferFunction;
  final NleToneMapOperator toneMapOperator;
  final NleHdrMetadataMode metadataMode;
  final NleColorRangeMode colorRange;
  final NleOutputBitDepth bitDepth;
  final NleWideColorPreviewMode previewMode;
  final double targetPeakNits;
  final NleHdrMasteringDisplayMetadata masteringMetadata;

  const NleHdrOutputSettings({
    required this.colorMode,
    required this.transferFunction,
    required this.toneMapOperator,
    required this.metadataMode,
    required this.colorRange,
    required this.bitDepth,
    required this.previewMode,
    required this.targetPeakNits,
    required this.masteringMetadata,
  });

  factory NleHdrOutputSettings.defaultSettings() {
    return const NleHdrOutputSettings(
      colorMode: NleOutputColorMode.rec709Sdr,
      transferFunction: NleHdrTransferFunction.sdr,
      toneMapOperator: NleToneMapOperator.none,
      metadataMode: NleHdrMetadataMode.none,
      colorRange: NleColorRangeMode.auto,
      bitDepth: NleOutputBitDepth.eightBit,
      previewMode: NleWideColorPreviewMode.auto,
      targetPeakNits: 1000.0,
      masteringMetadata: NleHdrMasteringDisplayMetadata(),
    );
  }

  factory NleHdrOutputSettings.fromJson(Map<String, dynamic> json) {
    final modeStr = json['colorMode']?.toString();
    final tfStr = json['transferFunction']?.toString();
    final tmoStr = json['toneMapOperator']?.toString();
    final mdStr = json['metadataMode']?.toString();
    final rangeStr = json['colorRange']?.toString();
    final bitStr = json['bitDepth']?.toString();
    final prevStr = json['previewMode']?.toString();

    return NleHdrOutputSettings(
      colorMode: NleOutputColorMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => NleOutputColorMode.rec709Sdr,
      ),
      transferFunction: NleHdrTransferFunction.values.firstWhere(
        (e) => e.name == tfStr,
        orElse: () => NleHdrTransferFunction.sdr,
      ),
      toneMapOperator: NleToneMapOperator.values.firstWhere(
        (e) => e.name == tmoStr,
        orElse: () => NleToneMapOperator.none,
      ),
      metadataMode: NleHdrMetadataMode.values.firstWhere(
        (e) => e.name == mdStr,
        orElse: () => NleHdrMetadataMode.none,
      ),
      colorRange: NleColorRangeMode.values.firstWhere(
        (e) => e.name == rangeStr,
        orElse: () => NleColorRangeMode.auto,
      ),
      bitDepth: NleOutputBitDepth.values.firstWhere(
        (e) => e.name == bitStr,
        orElse: () => NleOutputBitDepth.eightBit,
      ),
      previewMode: NleWideColorPreviewMode.values.firstWhere(
        (e) => e.name == prevStr,
        orElse: () => NleWideColorPreviewMode.auto,
      ),
      targetPeakNits: (json['targetPeakNits'] as num?)?.toDouble() ?? 1000.0,
      masteringMetadata: json['masteringMetadata'] != null
          ? NleHdrMasteringDisplayMetadata.fromJson(Map<String, dynamic>.from(json['masteringMetadata'] as Map))
          : const NleHdrMasteringDisplayMetadata(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colorMode': colorMode.name,
      'transferFunction': transferFunction.name,
      'toneMapOperator': toneMapOperator.name,
      'metadataMode': metadataMode.name,
      'colorRange': colorRange.name,
      'bitDepth': bitDepth.name,
      'previewMode': previewMode.name,
      'targetPeakNits': targetPeakNits,
      'masteringMetadata': masteringMetadata.toJson(),
    };
  }

  NleOutputColorMode resolveFallbackMode(NleHdrDeviceCapability capability) {
    if (colorMode == NleOutputColorMode.rec2020HlgHdr) {
      if (capability.encoderSupportsHdrHlg && capability.encoderSupportsTenBit) {
        return NleOutputColorMode.rec2020HlgHdr;
      }
      if (capability.displaySupportsWideColor && capability.encoderSupportsWideColorP3) {
        return NleOutputColorMode.displayP3Sdr;
      }
      return NleOutputColorMode.rec709Sdr;
    }
    if (colorMode == NleOutputColorMode.rec2020PqHdr) {
      if (capability.encoderSupportsHdrPq && capability.encoderSupportsTenBit) {
        return NleOutputColorMode.rec2020PqHdr;
      }
      if (capability.displaySupportsWideColor && capability.encoderSupportsWideColorP3) {
        return NleOutputColorMode.displayP3Sdr;
      }
      return NleOutputColorMode.rec709Sdr;
    }
    if (colorMode == NleOutputColorMode.displayP3Sdr) {
      if (capability.displaySupportsWideColor && capability.encoderSupportsWideColorP3) {
        return NleOutputColorMode.displayP3Sdr;
      }
      return NleOutputColorMode.rec709Sdr;
    }
    return colorMode;
  }

  NleHdrOutputSettings copyWith({
    NleOutputColorMode? colorMode,
    NleHdrTransferFunction? transferFunction,
    NleToneMapOperator? toneMapOperator,
    NleHdrMetadataMode? metadataMode,
    NleColorRangeMode? colorRange,
    NleOutputBitDepth? bitDepth,
    NleWideColorPreviewMode? previewMode,
    double? targetPeakNits,
    NleHdrMasteringDisplayMetadata? masteringMetadata,
  }) {
    return NleHdrOutputSettings(
      colorMode: colorMode ?? this.colorMode,
      transferFunction: transferFunction ?? this.transferFunction,
      toneMapOperator: toneMapOperator ?? this.toneMapOperator,
      metadataMode: metadataMode ?? this.metadataMode,
      colorRange: colorRange ?? this.colorRange,
      bitDepth: bitDepth ?? this.bitDepth,
      previewMode: previewMode ?? this.previewMode,
      targetPeakNits: targetPeakNits ?? this.targetPeakNits,
      masteringMetadata: masteringMetadata ?? this.masteringMetadata,
    );
  }
}

class NleHdrDeviceCapability {
  final bool displaySupportsHdr;
  final bool displaySupportsWideColor;
  final double displayMaxNits;
  final bool encoderSupportsHdrHlg;
  final bool encoderSupportsHdrPq;
  final bool encoderSupportsWideColorP3;
  final bool encoderSupportsTenBit;

  const NleHdrDeviceCapability({
    required this.displaySupportsHdr,
    required this.displaySupportsWideColor,
    required this.displayMaxNits,
    required this.encoderSupportsHdrHlg,
    required this.encoderSupportsHdrPq,
    required this.encoderSupportsWideColorP3,
    required this.encoderSupportsTenBit,
  });

  factory NleHdrDeviceCapability.unknown() {
    return const NleHdrDeviceCapability(
      displaySupportsHdr: false,
      displaySupportsWideColor: false,
      displayMaxNits: 300.0,
      encoderSupportsHdrHlg: false,
      encoderSupportsHdrPq: false,
      encoderSupportsWideColorP3: false,
      encoderSupportsTenBit: false,
    );
  }

  factory NleHdrDeviceCapability.fromJson(Map<String, dynamic> json) {
    return NleHdrDeviceCapability(
      displaySupportsHdr: json['displaySupportsHdr'] == true,
      displaySupportsWideColor: json['displaySupportsWideColor'] == true,
      displayMaxNits: (json['displayMaxNits'] as num?)?.toDouble() ?? 300.0,
      encoderSupportsHdrHlg: json['encoderSupportsHdrHlg'] == true,
      encoderSupportsHdrPq: json['encoderSupportsHdrPq'] == true,
      encoderSupportsWideColorP3: json['encoderSupportsWideColorP3'] == true,
      encoderSupportsTenBit: json['encoderSupportsTenBit'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displaySupportsHdr': displaySupportsHdr,
      'displaySupportsWideColor': displaySupportsWideColor,
      'displayMaxNits': displayMaxNits,
      'encoderSupportsHdrHlg': encoderSupportsHdrHlg,
      'encoderSupportsHdrPq': encoderSupportsHdrPq,
      'encoderSupportsWideColorP3': encoderSupportsWideColorP3,
      'encoderSupportsTenBit': encoderSupportsTenBit,
    };
  }
}

class NleHdrExportValidation {
  final bool isHdrSafe;
  final List<String> warnings;
  final List<String> errors;
  final NleOutputColorMode suggestedColorMode;
  final NleOutputBitDepth suggestedBitDepth;
  final NleHdrTransferFunction suggestedTransferFunction;

  const NleHdrExportValidation({
    required this.isHdrSafe,
    required this.warnings,
    required this.errors,
    required this.suggestedColorMode,
    required this.suggestedBitDepth,
    required this.suggestedTransferFunction,
  });

  factory NleHdrExportValidation.fromJson(Map<String, dynamic> json) {
    final modeStr = json['suggestedColorMode']?.toString();
    final bitStr = json['suggestedBitDepth']?.toString();
    final tfStr = json['suggestedTransferFunction']?.toString();

    return NleHdrExportValidation(
      isHdrSafe: json['isHdrSafe'] == true,
      warnings: List<String>.from(json['warnings'] as List? ?? const []),
      errors: List<String>.from(json['errors'] as List? ?? const []),
      suggestedColorMode: NleOutputColorMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => NleOutputColorMode.rec709Sdr,
      ),
      suggestedBitDepth: NleOutputBitDepth.values.firstWhere(
        (e) => e.name == bitStr,
        orElse: () => NleOutputBitDepth.eightBit,
      ),
      suggestedTransferFunction: NleHdrTransferFunction.values.firstWhere(
        (e) => e.name == tfStr,
        orElse: () => NleHdrTransferFunction.sdr,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isHdrSafe': isHdrSafe,
      'warnings': warnings,
      'errors': errors,
      'suggestedColorMode': suggestedColorMode.name,
      'suggestedBitDepth': suggestedBitDepth.name,
      'suggestedTransferFunction': suggestedTransferFunction.name,
    };
  }
}
