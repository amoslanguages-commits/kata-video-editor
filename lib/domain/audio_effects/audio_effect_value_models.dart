enum NleAudioEffectRackOwnerType {
  clip,
  track,
  master,
}

enum NleAudioEffectType {
  eq3Band,
  compressor,
  limiter,
  noiseGate,
  noiseReduction,
  reverb,
  pitchTempo,
  voiceEnhancer,
}

enum NleAudioEffectBypassMode {
  active,
  bypassed,
}

enum NleAudioEffectParameterType {
  gainDb,
  frequencyHz,
  ratio,
  milliseconds,
  percent,
  boolean,
  semitones,
  multiplier,
}

enum NleAudioEffectQuality {
  preview,
  high,
}

class NleAudioEffectParameter {
  final String id;
  final String label;
  final NleAudioEffectParameterType type;
  final double value;
  final double min;
  final double max;
  final String unit;

  const NleAudioEffectParameter({
    required this.id,
    required this.label,
    required this.type,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'value': value,
      'min': min,
      'max': max,
      'unit': unit,
    };
  }

  factory NleAudioEffectParameter.fromJson(Map<String, dynamic> json) {
    return NleAudioEffectParameter(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: _enumByName(
        NleAudioEffectParameterType.values,
        json['type'],
        NleAudioEffectParameterType.percent,
      ),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? '',
    );
  }

  NleAudioEffectParameter copyWith({
    double? value,
  }) {
    return NleAudioEffectParameter(
      id: id,
      label: label,
      type: type,
      value: value ?? this.value,
      min: min,
      max: max,
      unit: unit,
    );
  }
}

class NleAudioEffectPreset {
  final String id;
  final String name;
  final NleAudioEffectType effectType;
  final List<NleAudioEffectParameter> parameters;

  const NleAudioEffectPreset({
    required this.id,
    required this.name,
    required this.effectType,
    required this.parameters,
  });
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
