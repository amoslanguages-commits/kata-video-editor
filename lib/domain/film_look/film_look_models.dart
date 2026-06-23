enum NleFilmStockPreset {
  neutral,
  kodak2383,
  kodakVision3,
  fujiEterna,
  vintagePrint,
  bleachBypass,
  softPastel,
  warmDocumentary,
  coolNoir,
}

enum NleFilmGrainSize {
  fine,
  medium,
  coarse,
}

enum NleFilmLookPlacement {
  beforeLut,
  afterLut,
  beforeOutput,
}

class NleFilmGrainSettings {
  final bool enabled;
  final double amount;
  final double softness;
  final NleFilmGrainSize size;
  final bool monochrome;
  final double responseToLuma;

  const NleFilmGrainSettings({
    required this.enabled,
    required this.amount,
    required this.softness,
    required this.size,
    required this.monochrome,
    required this.responseToLuma,
  });

  const NleFilmGrainSettings.identity()
      : enabled = false,
        amount = 0.0,
        softness = 0.35,
        size = NleFilmGrainSize.medium,
        monochrome = false,
        responseToLuma = 0.55;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'amount': amount,
      'softness': softness,
      'size': size.name,
      'monochrome': monochrome,
      'responseToLuma': responseToLuma,
    };
  }

  factory NleFilmGrainSettings.fromJson(Map<String, dynamic> json) {
    return NleFilmGrainSettings(
      enabled: json['enabled'] == true,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      softness: (json['softness'] as num?)?.toDouble() ?? 0.35,
      size: _enumByName(
        NleFilmGrainSize.values,
        json['size'],
        NleFilmGrainSize.medium,
      ),
      monochrome: json['monochrome'] == true,
      responseToLuma: (json['responseToLuma'] as num?)?.toDouble() ?? 0.55,
    );
  }

  NleFilmGrainSettings copyWith({
    bool? enabled,
    double? amount,
    double? softness,
    NleFilmGrainSize? size,
    bool? monochrome,
    double? responseToLuma,
  }) {
    return NleFilmGrainSettings(
      enabled: enabled ?? this.enabled,
      amount: amount ?? this.amount,
      softness: softness ?? this.softness,
      size: size ?? this.size,
      monochrome: monochrome ?? this.monochrome,
      responseToLuma: responseToLuma ?? this.responseToLuma,
    );
  }
}

class NleHalationSettings {
  final bool enabled;
  final double amount;
  final double threshold;
  final double radius;
  final double redBias;
  final double warmth;

  const NleHalationSettings({
    required this.enabled,
    required this.amount,
    required this.threshold,
    required this.radius,
    required this.redBias,
    required this.warmth,
  });

  const NleHalationSettings.identity()
      : enabled = false,
        amount = 0.0,
        threshold = 0.72,
        radius = 0.35,
        redBias = 0.75,
        warmth = 0.35;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'amount': amount,
      'threshold': threshold,
      'radius': radius,
      'redBias': redBias,
      'warmth': warmth,
    };
  }

  factory NleHalationSettings.fromJson(Map<String, dynamic> json) {
    return NleHalationSettings(
      enabled: json['enabled'] == true,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.72,
      radius: (json['radius'] as num?)?.toDouble() ?? 0.35,
      redBias: (json['redBias'] as num?)?.toDouble() ?? 0.75,
      warmth: (json['warmth'] as num?)?.toDouble() ?? 0.35,
    );
  }

  NleHalationSettings copyWith({
    bool? enabled,
    double? amount,
    double? threshold,
    double? radius,
    double? redBias,
    double? warmth,
  }) {
    return NleHalationSettings(
      enabled: enabled ?? this.enabled,
      amount: amount ?? this.amount,
      threshold: threshold ?? this.threshold,
      radius: radius ?? this.radius,
      redBias: redBias ?? this.redBias,
      warmth: warmth ?? this.warmth,
    );
  }
}

class NleBloomSettings {
  final bool enabled;
  final double amount;
  final double threshold;
  final double radius;
  final double softness;

  const NleBloomSettings({
    required this.enabled,
    required this.amount,
    required this.threshold,
    required this.radius,
    required this.softness,
  });

  const NleBloomSettings.identity()
      : enabled = false,
        amount = 0.0,
        threshold = 0.80,
        radius = 0.45,
        softness = 0.45;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'amount': amount,
      'threshold': threshold,
      'radius': radius,
      'softness': softness,
    };
  }

  factory NleBloomSettings.fromJson(Map<String, dynamic> json) {
    return NleBloomSettings(
      enabled: json['enabled'] == true,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.80,
      radius: (json['radius'] as num?)?.toDouble() ?? 0.45,
      softness: (json['softness'] as num?)?.toDouble() ?? 0.45,
    );
  }

  NleBloomSettings copyWith({
    bool? enabled,
    double? amount,
    double? threshold,
    double? radius,
    double? softness,
  }) {
    return NleBloomSettings(
      enabled: enabled ?? this.enabled,
      amount: amount ?? this.amount,
      threshold: threshold ?? this.threshold,
      radius: radius ?? this.radius,
      softness: softness ?? this.softness,
    );
  }
}

class NlePrintSettings {
  final bool enabled;
  final double contrast;
  final double toe;
  final double shoulder;
  final double fade;
  final double saturation;
  final double highlightRolloff;
  final double shadowTint;
  final double highlightWarmth;

  const NlePrintSettings({
    required this.enabled,
    required this.contrast,
    required this.toe,
    required this.shoulder,
    required this.fade,
    required this.saturation,
    required this.highlightRolloff,
    required this.shadowTint,
    required this.highlightWarmth,
  });

  const NlePrintSettings.identity()
      : enabled = true,
        contrast = 1.0,
        toe = 0.12,
        shoulder = 0.18,
        fade = 0.0,
        saturation = 1.0,
        highlightRolloff = 0.35,
        shadowTint = 0.0,
        highlightWarmth = 0.0;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'contrast': contrast,
      'toe': toe,
      'shoulder': shoulder,
      'fade': fade,
      'saturation': saturation,
      'highlightRolloff': highlightRolloff,
      'shadowTint': shadowTint,
      'highlightWarmth': highlightWarmth,
    };
  }

  factory NlePrintSettings.fromJson(Map<String, dynamic> json) {
    return NlePrintSettings(
      enabled: json['enabled'] != false,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      toe: (json['toe'] as num?)?.toDouble() ?? 0.12,
      shoulder: (json['shoulder'] as num?)?.toDouble() ?? 0.18,
      fade: (json['fade'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      highlightRolloff: (json['highlightRolloff'] as num?)?.toDouble() ?? 0.35,
      shadowTint: (json['shadowTint'] as num?)?.toDouble() ?? 0.0,
      highlightWarmth: (json['highlightWarmth'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NlePrintSettings copyWith({
    bool? enabled,
    double? contrast,
    double? toe,
    double? shoulder,
    double? fade,
    double? saturation,
    double? highlightRolloff,
    double? shadowTint,
    double? highlightWarmth,
  }) {
    return NlePrintSettings(
      enabled: enabled ?? this.enabled,
      contrast: contrast ?? this.contrast,
      toe: toe ?? this.toe,
      shoulder: shoulder ?? this.shoulder,
      fade: fade ?? this.fade,
      saturation: saturation ?? this.saturation,
      highlightRolloff: highlightRolloff ?? this.highlightRolloff,
      shadowTint: shadowTint ?? this.shadowTint,
      highlightWarmth: highlightWarmth ?? this.highlightWarmth,
    );
  }
}

class NleVignetteSettings {
  final bool enabled;
  final double amount;
  final double radius;
  final double feather;
  final double roundness;

  const NleVignetteSettings({
    required this.enabled,
    required this.amount,
    required this.radius,
    required this.feather,
    required this.roundness,
  });

  const NleVignetteSettings.identity()
      : enabled = false,
        amount = 0.0,
        radius = 0.75,
        feather = 0.45,
        roundness = 1.0;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'amount': amount,
      'radius': radius,
      'feather': feather,
      'roundness': roundness,
    };
  }

  factory NleVignetteSettings.fromJson(Map<String, dynamic> json) {
    return NleVignetteSettings(
      enabled: json['enabled'] == true,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      radius: (json['radius'] as num?)?.toDouble() ?? 0.75,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.45,
      roundness: (json['roundness'] as num?)?.toDouble() ?? 1.0,
    );
  }

  NleVignetteSettings copyWith({
    bool? enabled,
    double? amount,
    double? radius,
    double? feather,
    double? roundness,
  }) {
    return NleVignetteSettings(
      enabled: enabled ?? this.enabled,
      amount: amount ?? this.amount,
      radius: radius ?? this.radius,
      feather: feather ?? this.feather,
      roundness: roundness ?? this.roundness,
    );
  }
}

class NleGateWeaveSettings {
  final bool enabled;
  final double amount;
  final double frequency;
  final double rotation;

  const NleGateWeaveSettings({
    required this.enabled,
    required this.amount,
    required this.frequency,
    required this.rotation,
  });

  const NleGateWeaveSettings.identity()
      : enabled = false,
        amount = 0.0,
        frequency = 0.7,
        rotation = 0.0;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'amount': amount,
      'frequency': frequency,
      'rotation': rotation,
    };
  }

  factory NleGateWeaveSettings.fromJson(Map<String, dynamic> json) {
    return NleGateWeaveSettings(
      enabled: json['enabled'] == true,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: (json['frequency'] as num?)?.toDouble() ?? 0.7,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleGateWeaveSettings copyWith({
    bool? enabled,
    double? amount,
    double? frequency,
    double? rotation,
  }) {
    return NleGateWeaveSettings(
      enabled: enabled ?? this.enabled,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      rotation: rotation ?? this.rotation,
    );
  }
}

class NleFilmLookSettings {
  final bool enabled;
  final double intensity;
  final NleFilmStockPreset preset;
  final NleFilmLookPlacement placement;

  final NleFilmGrainSettings grain;
  final NleHalationSettings halation;
  final NleBloomSettings bloom;
  final NlePrintSettings print;
  final NleVignetteSettings vignette;
  final NleGateWeaveSettings gateWeave;

  final double chromaticSoftness;

  const NleFilmLookSettings({
    required this.enabled,
    required this.intensity,
    required this.preset,
    required this.placement,
    required this.grain,
    required this.halation,
    required this.bloom,
    required this.print,
    required this.vignette,
    required this.gateWeave,
    required this.chromaticSoftness,
  });

  const NleFilmLookSettings.identity()
      : enabled = false,
        intensity = 1.0,
        preset = NleFilmStockPreset.neutral,
        placement = NleFilmLookPlacement.beforeOutput,
        grain = const NleFilmGrainSettings.identity(),
        halation = const NleHalationSettings.identity(),
        bloom = const NleBloomSettings.identity(),
        print = const NlePrintSettings.identity(),
        vignette = const NleVignetteSettings.identity(),
        gateWeave = const NleGateWeaveSettings.identity(),
        chromaticSoftness = 0.0;

  bool get isIdentity {
    return !enabled || intensity <= 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'intensity': intensity,
      'preset': preset.name,
      'placement': placement.name,
      'grain': grain.toJson(),
      'halation': halation.toJson(),
      'bloom': bloom.toJson(),
      'print': print.toJson(),
      'vignette': vignette.toJson(),
      'gateWeave': gateWeave.toJson(),
      'chromaticSoftness': chromaticSoftness,
    };
  }

  factory NleFilmLookSettings.fromJson(Map<String, dynamic> json) {
    return NleFilmLookSettings(
      enabled: json['enabled'] == true,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      preset: _enumByName(
        NleFilmStockPreset.values,
        json['preset'],
        NleFilmStockPreset.neutral,
      ),
      placement: _enumByName(
        NleFilmLookPlacement.values,
        json['placement'],
        NleFilmLookPlacement.beforeOutput,
      ),
      grain: NleFilmGrainSettings.fromJson(
        Map<String, dynamic>.from(json['grain'] as Map? ?? const {}),
      ),
      halation: NleHalationSettings.fromJson(
        Map<String, dynamic>.from(json['halation'] as Map? ?? const {}),
      ),
      bloom: NleBloomSettings.fromJson(
        Map<String, dynamic>.from(json['bloom'] as Map? ?? const {}),
      ),
      print: NlePrintSettings.fromJson(
        Map<String, dynamic>.from(json['print'] as Map? ?? const {}),
      ),
      vignette: NleVignetteSettings.fromJson(
        Map<String, dynamic>.from(json['vignette'] as Map? ?? const {}),
      ),
      gateWeave: NleGateWeaveSettings.fromJson(
        Map<String, dynamic>.from(json['gateWeave'] as Map? ?? const {}),
      ),
      chromaticSoftness: (json['chromaticSoftness'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleFilmLookSettings copyWith({
    bool? enabled,
    double? intensity,
    NleFilmStockPreset? preset,
    NleFilmLookPlacement? placement,
    NleFilmGrainSettings? grain,
    NleHalationSettings? halation,
    NleBloomSettings? bloom,
    NlePrintSettings? print,
    NleVignetteSettings? vignette,
    NleGateWeaveSettings? gateWeave,
    double? chromaticSoftness,
  }) {
    return NleFilmLookSettings(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      preset: preset ?? this.preset,
      placement: placement ?? this.placement,
      grain: grain ?? this.grain,
      halation: halation ?? this.halation,
      bloom: bloom ?? this.bloom,
      print: print ?? this.print,
      vignette: vignette ?? this.vignette,
      gateWeave: gateWeave ?? this.gateWeave,
      chromaticSoftness: chromaticSoftness ?? this.chromaticSoftness,
    );
  }
}

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
