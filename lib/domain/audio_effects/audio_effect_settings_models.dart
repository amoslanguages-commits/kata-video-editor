class NleEq3BandEffectSettings {
  final double lowGainDb;
  final double midGainDb;
  final double highGainDb;
  final double lowFrequencyHz;
  final double highFrequencyHz;

  const NleEq3BandEffectSettings({
    required this.lowGainDb,
    required this.midGainDb,
    required this.highGainDb,
    required this.lowFrequencyHz,
    required this.highFrequencyHz,
  });

  const NleEq3BandEffectSettings.flat()
      : lowGainDb = 0.0,
        midGainDb = 0.0,
        highGainDb = 0.0,
        lowFrequencyHz = 220.0,
        highFrequencyHz = 4000.0;

  const NleEq3BandEffectSettings.voicePresence()
      : lowGainDb = -2.0,
        midGainDb = 2.5,
        highGainDb = 1.5,
        lowFrequencyHz = 180.0,
        highFrequencyHz = 4200.0;

  const NleEq3BandEffectSettings.musicWarmth()
      : lowGainDb = 2.0,
        midGainDb = 0.5,
        highGainDb = 1.0,
        lowFrequencyHz = 220.0,
        highFrequencyHz = 5200.0;

  Map<String, dynamic> toJson() {
    return {
      'lowGainDb': lowGainDb,
      'midGainDb': midGainDb,
      'highGainDb': highGainDb,
      'lowFrequencyHz': lowFrequencyHz,
      'highFrequencyHz': highFrequencyHz,
    };
  }

  factory NleEq3BandEffectSettings.fromJson(Map<String, dynamic> json) {
    return NleEq3BandEffectSettings(
      lowGainDb: (json['lowGainDb'] as num?)?.toDouble() ?? 0.0,
      midGainDb: (json['midGainDb'] as num?)?.toDouble() ?? 0.0,
      highGainDb: (json['highGainDb'] as num?)?.toDouble() ?? 0.0,
      lowFrequencyHz: (json['lowFrequencyHz'] as num?)?.toDouble() ?? 220.0,
      highFrequencyHz:
          (json['highFrequencyHz'] as num?)?.toDouble() ?? 4000.0,
    );
  }

  NleEq3BandEffectSettings copyWith({
    double? lowGainDb,
    double? midGainDb,
    double? highGainDb,
    double? lowFrequencyHz,
    double? highFrequencyHz,
  }) {
    return NleEq3BandEffectSettings(
      lowGainDb: lowGainDb ?? this.lowGainDb,
      midGainDb: midGainDb ?? this.midGainDb,
      highGainDb: highGainDb ?? this.highGainDb,
      lowFrequencyHz: lowFrequencyHz ?? this.lowFrequencyHz,
      highFrequencyHz: highFrequencyHz ?? this.highFrequencyHz,
    );
  }
}

class NleCompressorEffectSettings {
  final double thresholdDb;
  final double ratio;
  final double attackMs;
  final double releaseMs;
  final double makeupGainDb;
  final double kneeDb;

  const NleCompressorEffectSettings({
    required this.thresholdDb,
    required this.ratio,
    required this.attackMs,
    required this.releaseMs,
    required this.makeupGainDb,
    required this.kneeDb,
  });

  const NleCompressorEffectSettings.off()
      : thresholdDb = -18.0,
        ratio = 1.0,
        attackMs = 12.0,
        releaseMs = 120.0,
        makeupGainDb = 0.0,
        kneeDb = 6.0;

  const NleCompressorEffectSettings.voice()
      : thresholdDb = -22.0,
        ratio = 3.0,
        attackMs = 8.0,
        releaseMs = 100.0,
        makeupGainDb = 2.5,
        kneeDb = 6.0;

  const NleCompressorEffectSettings.musicGlue()
      : thresholdDb = -14.0,
        ratio = 1.8,
        attackMs = 20.0,
        releaseMs = 180.0,
        makeupGainDb = 1.0,
        kneeDb = 8.0;

  Map<String, dynamic> toJson() {
    return {
      'thresholdDb': thresholdDb,
      'ratio': ratio,
      'attackMs': attackMs,
      'releaseMs': releaseMs,
      'makeupGainDb': makeupGainDb,
      'kneeDb': kneeDb,
    };
  }

  factory NleCompressorEffectSettings.fromJson(Map<String, dynamic> json) {
    return NleCompressorEffectSettings(
      thresholdDb: (json['thresholdDb'] as num?)?.toDouble() ?? -18.0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 1.0,
      attackMs: (json['attackMs'] as num?)?.toDouble() ?? 12.0,
      releaseMs: (json['releaseMs'] as num?)?.toDouble() ?? 120.0,
      makeupGainDb: (json['makeupGainDb'] as num?)?.toDouble() ?? 0.0,
      kneeDb: (json['kneeDb'] as num?)?.toDouble() ?? 6.0,
    );
  }

  NleCompressorEffectSettings copyWith({
    double? thresholdDb,
    double? ratio,
    double? attackMs,
    double? releaseMs,
    double? makeupGainDb,
    double? kneeDb,
  }) {
    return NleCompressorEffectSettings(
      thresholdDb: thresholdDb ?? this.thresholdDb,
      ratio: ratio ?? this.ratio,
      attackMs: attackMs ?? this.attackMs,
      releaseMs: releaseMs ?? this.releaseMs,
      makeupGainDb: makeupGainDb ?? this.makeupGainDb,
      kneeDb: kneeDb ?? this.kneeDb,
    );
  }
}

class NleLimiterEffectSettings {
  final double ceilingDb;
  final double releaseMs;
  final bool truePeakSafe;

  const NleLimiterEffectSettings({
    required this.ceilingDb,
    required this.releaseMs,
    required this.truePeakSafe,
  });

  const NleLimiterEffectSettings.defaultLimiter()
      : ceilingDb = -1.0,
        releaseMs = 80.0,
        truePeakSafe = true;

  Map<String, dynamic> toJson() {
    return {
      'ceilingDb': ceilingDb,
      'releaseMs': releaseMs,
      'truePeakSafe': truePeakSafe,
    };
  }

  factory NleLimiterEffectSettings.fromJson(Map<String, dynamic> json) {
    return NleLimiterEffectSettings(
      ceilingDb: (json['ceilingDb'] as num?)?.toDouble() ?? -1.0,
      releaseMs: (json['releaseMs'] as num?)?.toDouble() ?? 80.0,
      truePeakSafe: json['truePeakSafe'] != false,
    );
  }

  NleLimiterEffectSettings copyWith({
    double? ceilingDb,
    double? releaseMs,
    bool? truePeakSafe,
  }) {
    return NleLimiterEffectSettings(
      ceilingDb: ceilingDb ?? this.ceilingDb,
      releaseMs: releaseMs ?? this.releaseMs,
      truePeakSafe: truePeakSafe ?? this.truePeakSafe,
    );
  }
}

class NleNoiseGateEffectSettings {
  final double thresholdDb;
  final double reductionDb;
  final double attackMs;
  final double releaseMs;

  const NleNoiseGateEffectSettings({
    required this.thresholdDb,
    required this.reductionDb,
    required this.attackMs,
    required this.releaseMs,
  });

  const NleNoiseGateEffectSettings.voiceClean()
      : thresholdDb = -42.0,
        reductionDb = -18.0,
        attackMs = 5.0,
        releaseMs = 160.0;

  Map<String, dynamic> toJson() {
    return {
      'thresholdDb': thresholdDb,
      'reductionDb': reductionDb,
      'attackMs': attackMs,
      'releaseMs': releaseMs,
    };
  }

  factory NleNoiseGateEffectSettings.fromJson(Map<String, dynamic> json) {
    return NleNoiseGateEffectSettings(
      thresholdDb: (json['thresholdDb'] as num?)?.toDouble() ?? -42.0,
      reductionDb: (json['reductionDb'] as num?)?.toDouble() ?? -18.0,
      attackMs: (json['attackMs'] as num?)?.toDouble() ?? 5.0,
      releaseMs: (json['releaseMs'] as num?)?.toDouble() ?? 160.0,
    );
  }

  NleNoiseGateEffectSettings copyWith({
    double? thresholdDb,
    double? reductionDb,
    double? attackMs,
    double? releaseMs,
  }) {
    return NleNoiseGateEffectSettings(
      thresholdDb: thresholdDb ?? this.thresholdDb,
      reductionDb: reductionDb ?? this.reductionDb,
      attackMs: attackMs ?? this.attackMs,
      releaseMs: releaseMs ?? this.releaseMs,
    );
  }
}

class NleNoiseReductionEffectSettings {
  final double amount;
  final bool voiceOptimized;

  const NleNoiseReductionEffectSettings({
    required this.amount,
    required this.voiceOptimized,
  });

  const NleNoiseReductionEffectSettings.light()
      : amount = 0.25,
        voiceOptimized = true;

  const NleNoiseReductionEffectSettings.strong()
      : amount = 0.55,
        voiceOptimized = true;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'voiceOptimized': voiceOptimized,
    };
  }

  factory NleNoiseReductionEffectSettings.fromJson(Map<String, dynamic> json) {
    return NleNoiseReductionEffectSettings(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      voiceOptimized: json['voiceOptimized'] != false,
    );
  }

  NleNoiseReductionEffectSettings copyWith({
    double? amount,
    bool? voiceOptimized,
  }) {
    return NleNoiseReductionEffectSettings(
      amount: amount ?? this.amount,
      voiceOptimized: voiceOptimized ?? this.voiceOptimized,
    );
  }
}

class NleReverbEffectSettings {
  final double roomSize;
  final double damping;
  final double wet;
  final double dry;

  const NleReverbEffectSettings({
    required this.roomSize,
    required this.damping,
    required this.wet,
    required this.dry,
  });

  const NleReverbEffectSettings.smallRoom()
      : roomSize = 0.22,
        damping = 0.55,
        wet = 0.12,
        dry = 1.0;

  const NleReverbEffectSettings.bigSpace()
      : roomSize = 0.72,
        damping = 0.35,
        wet = 0.28,
        dry = 0.9;

  Map<String, dynamic> toJson() {
    return {
      'roomSize': roomSize,
      'damping': damping,
      'wet': wet,
      'dry': dry,
    };
  }

  factory NleReverbEffectSettings.fromJson(Map<String, dynamic> json) {
    return NleReverbEffectSettings(
      roomSize: (json['roomSize'] as num?)?.toDouble() ?? 0.22,
      damping: (json['damping'] as num?)?.toDouble() ?? 0.55,
      wet: (json['wet'] as num?)?.toDouble() ?? 0.12,
      dry: (json['dry'] as num?)?.toDouble() ?? 1.0,
    );
  }

  NleReverbEffectSettings copyWith({
    double? roomSize,
    double? damping,
    double? wet,
    double? dry,
  }) {
    return NleReverbEffectSettings(
      roomSize: roomSize ?? this.roomSize,
      damping: damping ?? this.damping,
      wet: wet ?? this.wet,
      dry: dry ?? this.dry,
    );
  }
}

class NlePitchTempoEffectSettings {
  final double pitchSemitones;
  final double tempoMultiplier;
  final bool preserveFormants;

  const NlePitchTempoEffectSettings({
    required this.pitchSemitones,
    required this.tempoMultiplier,
    required this.preserveFormants,
  });

  const NlePitchTempoEffectSettings.identity()
      : pitchSemitones = 0.0,
        tempoMultiplier = 1.0,
        preserveFormants = true;

  Map<String, dynamic> toJson() {
    return {
      'pitchSemitones': pitchSemitones,
      'tempoMultiplier': tempoMultiplier,
      'preserveFormants': preserveFormants,
    };
  }

  factory NlePitchTempoEffectSettings.fromJson(Map<String, dynamic> json) {
    return NlePitchTempoEffectSettings(
      pitchSemitones: (json['pitchSemitones'] as num?)?.toDouble() ?? 0.0,
      tempoMultiplier: (json['tempoMultiplier'] as num?)?.toDouble() ?? 1.0,
      preserveFormants: json['preserveFormants'] != false,
    );
  }

  NlePitchTempoEffectSettings copyWith({
    double? pitchSemitones,
    double? tempoMultiplier,
    bool? preserveFormants,
  }) {
    return NlePitchTempoEffectSettings(
      pitchSemitones: pitchSemitones ?? this.pitchSemitones,
      tempoMultiplier: tempoMultiplier ?? this.tempoMultiplier,
      preserveFormants: preserveFormants ?? this.preserveFormants,
    );
  }
}

class NleVoiceEnhancerEffectSettings {
  final double clarity;
  final double body;
  final double air;
  final double deEss;

  const NleVoiceEnhancerEffectSettings({
    required this.clarity,
    required this.body,
    required this.air,
    required this.deEss,
  });

  const NleVoiceEnhancerEffectSettings.creatorVoice()
      : clarity = 0.55,
        body = 0.35,
        air = 0.40,
        deEss = 0.25;

  Map<String, dynamic> toJson() {
    return {
      'clarity': clarity,
      'body': body,
      'air': air,
      'deEss': deEss,
    };
  }

  factory NleVoiceEnhancerEffectSettings.fromJson(Map<String, dynamic> json) {
    return NleVoiceEnhancerEffectSettings(
      clarity: (json['clarity'] as num?)?.toDouble() ?? 0.55,
      body: (json['body'] as num?)?.toDouble() ?? 0.35,
      air: (json['air'] as num?)?.toDouble() ?? 0.40,
      deEss: (json['deEss'] as num?)?.toDouble() ?? 0.25,
    );
  }

  NleVoiceEnhancerEffectSettings copyWith({
    double? clarity,
    double? body,
    double? air,
    double? deEss,
  }) {
    return NleVoiceEnhancerEffectSettings(
      clarity: clarity ?? this.clarity,
      body: body ?? this.body,
      air: air ?? this.air,
      deEss: deEss ?? this.deEss,
    );
  }
}
