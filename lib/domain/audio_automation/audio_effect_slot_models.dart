// 33B-PRO: Advanced Audio Automation — Effect Slot Models
//
// Foundation models for EQ, compressor, noise reduction, and the generic
// effect slot container. These are serialised as JSON and sent to the native
// audio engine alongside the automation keyframes.

// ── Effect Type Enums ─────────────────────────────────────────────────────────

enum NleAudioEffectType {
  eq3Band,
  compressor,
  limiter,
  noiseReduction,
  noiseGate,
  reverb,
  pitchTempo,
}

enum NleAudioEffectSlotBypassMode {
  active,
  bypassed,
}

// ── EQ 3-Band ─────────────────────────────────────────────────────────────────

class NleAudioEq3BandSettings {
  final double lowGainDb;
  final double midGainDb;
  final double highGainDb;
  final double lowFrequencyHz;
  final double highFrequencyHz;

  const NleAudioEq3BandSettings({
    required this.lowGainDb,
    required this.midGainDb,
    required this.highGainDb,
    required this.lowFrequencyHz,
    required this.highFrequencyHz,
  });

  const NleAudioEq3BandSettings.flat()
      : lowGainDb = 0.0,
        midGainDb = 0.0,
        highGainDb = 0.0,
        lowFrequencyHz = 220.0,
        highFrequencyHz = 4000.0;

  Map<String, dynamic> toJson() {
    return {
      'lowGainDb': lowGainDb,
      'midGainDb': midGainDb,
      'highGainDb': highGainDb,
      'lowFrequencyHz': lowFrequencyHz,
      'highFrequencyHz': highFrequencyHz,
    };
  }

  factory NleAudioEq3BandSettings.fromJson(Map<String, dynamic> json) {
    return NleAudioEq3BandSettings(
      lowGainDb: (json['lowGainDb'] as num?)?.toDouble() ?? 0.0,
      midGainDb: (json['midGainDb'] as num?)?.toDouble() ?? 0.0,
      highGainDb: (json['highGainDb'] as num?)?.toDouble() ?? 0.0,
      lowFrequencyHz: (json['lowFrequencyHz'] as num?)?.toDouble() ?? 220.0,
      highFrequencyHz: (json['highFrequencyHz'] as num?)?.toDouble() ?? 4000.0,
    );
  }

  NleAudioEq3BandSettings copyWith({
    double? lowGainDb,
    double? midGainDb,
    double? highGainDb,
    double? lowFrequencyHz,
    double? highFrequencyHz,
  }) {
    return NleAudioEq3BandSettings(
      lowGainDb: lowGainDb ?? this.lowGainDb,
      midGainDb: midGainDb ?? this.midGainDb,
      highGainDb: highGainDb ?? this.highGainDb,
      lowFrequencyHz: lowFrequencyHz ?? this.lowFrequencyHz,
      highFrequencyHz: highFrequencyHz ?? this.highFrequencyHz,
    );
  }
}

// ── Compressor ────────────────────────────────────────────────────────────────

class NleAudioCompressorSettings {
  final double thresholdDb;
  final double ratio;
  final double attackMs;
  final double releaseMs;
  final double makeupGainDb;

  const NleAudioCompressorSettings({
    required this.thresholdDb,
    required this.ratio,
    required this.attackMs,
    required this.releaseMs,
    required this.makeupGainDb,
  });

  const NleAudioCompressorSettings.off()
      : thresholdDb = -18.0,
        ratio = 2.5,
        attackMs = 12.0,
        releaseMs = 120.0,
        makeupGainDb = 0.0;

  Map<String, dynamic> toJson() {
    return {
      'thresholdDb': thresholdDb,
      'ratio': ratio,
      'attackMs': attackMs,
      'releaseMs': releaseMs,
      'makeupGainDb': makeupGainDb,
    };
  }

  factory NleAudioCompressorSettings.fromJson(Map<String, dynamic> json) {
    return NleAudioCompressorSettings(
      thresholdDb: (json['thresholdDb'] as num?)?.toDouble() ?? -18.0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 2.5,
      attackMs: (json['attackMs'] as num?)?.toDouble() ?? 12.0,
      releaseMs: (json['releaseMs'] as num?)?.toDouble() ?? 120.0,
      makeupGainDb: (json['makeupGainDb'] as num?)?.toDouble() ?? 0.0,
    );
  }

  NleAudioCompressorSettings copyWith({
    double? thresholdDb,
    double? ratio,
    double? attackMs,
    double? releaseMs,
    double? makeupGainDb,
  }) {
    return NleAudioCompressorSettings(
      thresholdDb: thresholdDb ?? this.thresholdDb,
      ratio: ratio ?? this.ratio,
      attackMs: attackMs ?? this.attackMs,
      releaseMs: releaseMs ?? this.releaseMs,
      makeupGainDb: makeupGainDb ?? this.makeupGainDb,
    );
  }
}

// ── Noise Reduction ───────────────────────────────────────────────────────────

class NleAudioNoiseReductionSettings {
  final double amount;
  final bool voiceOptimized;

  const NleAudioNoiseReductionSettings({
    required this.amount,
    required this.voiceOptimized,
  });

  const NleAudioNoiseReductionSettings.off()
      : amount = 0.0,
        voiceOptimized = true;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'voiceOptimized': voiceOptimized,
    };
  }

  factory NleAudioNoiseReductionSettings.fromJson(Map<String, dynamic> json) {
    return NleAudioNoiseReductionSettings(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      voiceOptimized: json['voiceOptimized'] != false,
    );
  }

  NleAudioNoiseReductionSettings copyWith({
    double? amount,
    bool? voiceOptimized,
  }) {
    return NleAudioNoiseReductionSettings(
      amount: amount ?? this.amount,
      voiceOptimized: voiceOptimized ?? this.voiceOptimized,
    );
  }
}

// ── Effect Slot ───────────────────────────────────────────────────────────────

/// A single effect slot in a track's effect chain.
class NleAudioEffectSlot {
  final String id;
  final NleAudioEffectType type;
  final String name;
  final NleAudioEffectSlotBypassMode bypassMode;
  final int order;

  final NleAudioEq3BandSettings? eq3Band;
  final NleAudioCompressorSettings? compressor;
  final NleAudioNoiseReductionSettings? noiseReduction;

  const NleAudioEffectSlot({
    required this.id,
    required this.type,
    required this.name,
    required this.bypassMode,
    required this.order,
    this.eq3Band,
    this.compressor,
    this.noiseReduction,
  });

  bool get active => bypassMode == NleAudioEffectSlotBypassMode.active;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'bypassMode': bypassMode.name,
      'order': order,
      if (eq3Band != null) 'eq3Band': eq3Band!.toJson(),
      if (compressor != null) 'compressor': compressor!.toJson(),
      if (noiseReduction != null) 'noiseReduction': noiseReduction!.toJson(),
    };
  }

  factory NleAudioEffectSlot.fromJson(Map<String, dynamic> json) {
    return NleAudioEffectSlot(
      id: json['id']?.toString() ?? '',
      type: _enumByName(
        NleAudioEffectType.values,
        json['type'],
        NleAudioEffectType.eq3Band,
      ),
      name: json['name']?.toString() ?? 'Effect',
      bypassMode: _enumByName(
        NleAudioEffectSlotBypassMode.values,
        json['bypassMode'],
        NleAudioEffectSlotBypassMode.active,
      ),
      order: (json['order'] as num?)?.toInt() ?? 0,
      eq3Band: json['eq3Band'] is Map
          ? NleAudioEq3BandSettings.fromJson(
              Map<String, dynamic>.from(json['eq3Band'] as Map),
            )
          : null,
      compressor: json['compressor'] is Map
          ? NleAudioCompressorSettings.fromJson(
              Map<String, dynamic>.from(json['compressor'] as Map),
            )
          : null,
      noiseReduction: json['noiseReduction'] is Map
          ? NleAudioNoiseReductionSettings.fromJson(
              Map<String, dynamic>.from(json['noiseReduction'] as Map),
            )
          : null,
    );
  }

  NleAudioEffectSlot copyWith({
    String? name,
    NleAudioEffectSlotBypassMode? bypassMode,
    int? order,
    NleAudioEq3BandSettings? eq3Band,
    NleAudioCompressorSettings? compressor,
    NleAudioNoiseReductionSettings? noiseReduction,
  }) {
    return NleAudioEffectSlot(
      id: id,
      type: type,
      name: name ?? this.name,
      bypassMode: bypassMode ?? this.bypassMode,
      order: order ?? this.order,
      eq3Band: eq3Band ?? this.eq3Band,
      compressor: compressor ?? this.compressor,
      noiseReduction: noiseReduction ?? this.noiseReduction,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  final string = name?.toString();
  if (string == null) return fallback;
  for (final value in values) {
    if (value.name == string) return value;
  }
  return fallback;
}
