import 'package:nle_editor/domain/audio_effects/audio_effect_settings_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';

class NleAudioEffectSlot {
  final String id;
  final NleAudioEffectType type;
  final String name;
  final int order;
  final NleAudioEffectBypassMode bypassMode;
  final double wetMix;

  final NleEq3BandEffectSettings? eq3Band;
  final NleCompressorEffectSettings? compressor;
  final NleLimiterEffectSettings? limiter;
  final NleNoiseGateEffectSettings? noiseGate;
  final NleNoiseReductionEffectSettings? noiseReduction;
  final NleReverbEffectSettings? reverb;
  final NlePitchTempoEffectSettings? pitchTempo;
  final NleVoiceEnhancerEffectSettings? voiceEnhancer;

  const NleAudioEffectSlot({
    required this.id,
    required this.type,
    required this.name,
    required this.order,
    required this.bypassMode,
    required this.wetMix,
    this.eq3Band,
    this.compressor,
    this.limiter,
    this.noiseGate,
    this.noiseReduction,
    this.reverb,
    this.pitchTempo,
    this.voiceEnhancer,
  });

  bool get active => bypassMode == NleAudioEffectBypassMode.active;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'order': order,
      'bypassMode': bypassMode.name,
      'wetMix': wetMix,
      'eq3Band': eq3Band?.toJson(),
      'compressor': compressor?.toJson(),
      'limiter': limiter?.toJson(),
      'noiseGate': noiseGate?.toJson(),
      'noiseReduction': noiseReduction?.toJson(),
      'reverb': reverb?.toJson(),
      'pitchTempo': pitchTempo?.toJson(),
      'voiceEnhancer': voiceEnhancer?.toJson(),
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
      order: (json['order'] as num?)?.toInt() ?? 0,
      bypassMode: _enumByName(
        NleAudioEffectBypassMode.values,
        json['bypassMode'],
        NleAudioEffectBypassMode.active,
      ),
      wetMix: (json['wetMix'] as num?)?.toDouble() ?? 1.0,
      eq3Band: json['eq3Band'] is Map
          ? NleEq3BandEffectSettings.fromJson(
              Map<String, dynamic>.from(json['eq3Band'] as Map),
            )
          : null,
      compressor: json['compressor'] is Map
          ? NleCompressorEffectSettings.fromJson(
              Map<String, dynamic>.from(json['compressor'] as Map),
            )
          : null,
      limiter: json['limiter'] is Map
          ? NleLimiterEffectSettings.fromJson(
              Map<String, dynamic>.from(json['limiter'] as Map),
            )
          : null,
      noiseGate: json['noiseGate'] is Map
          ? NleNoiseGateEffectSettings.fromJson(
              Map<String, dynamic>.from(json['noiseGate'] as Map),
            )
          : null,
      noiseReduction: json['noiseReduction'] is Map
          ? NleNoiseReductionEffectSettings.fromJson(
              Map<String, dynamic>.from(json['noiseReduction'] as Map),
            )
          : null,
      reverb: json['reverb'] is Map
          ? NleReverbEffectSettings.fromJson(
              Map<String, dynamic>.from(json['reverb'] as Map),
            )
          : null,
      pitchTempo: json['pitchTempo'] is Map
          ? NlePitchTempoEffectSettings.fromJson(
              Map<String, dynamic>.from(json['pitchTempo'] as Map),
            )
          : null,
      voiceEnhancer: json['voiceEnhancer'] is Map
          ? NleVoiceEnhancerEffectSettings.fromJson(
              Map<String, dynamic>.from(json['voiceEnhancer'] as Map),
            )
          : null,
    );
  }

  NleAudioEffectSlot copyWith({
    String? name,
    int? order,
    NleAudioEffectBypassMode? bypassMode,
    double? wetMix,
    NleEq3BandEffectSettings? eq3Band,
    NleCompressorEffectSettings? compressor,
    NleLimiterEffectSettings? limiter,
    NleNoiseGateEffectSettings? noiseGate,
    NleNoiseReductionEffectSettings? noiseReduction,
    NleReverbEffectSettings? reverb,
    NlePitchTempoEffectSettings? pitchTempo,
    NleVoiceEnhancerEffectSettings? voiceEnhancer,
  }) {
    return NleAudioEffectSlot(
      id: id,
      type: type,
      name: name ?? this.name,
      order: order ?? this.order,
      bypassMode: bypassMode ?? this.bypassMode,
      wetMix: wetMix ?? this.wetMix,
      eq3Band: eq3Band ?? this.eq3Band,
      compressor: compressor ?? this.compressor,
      limiter: limiter ?? this.limiter,
      noiseGate: noiseGate ?? this.noiseGate,
      noiseReduction: noiseReduction ?? this.noiseReduction,
      reverb: reverb ?? this.reverb,
      pitchTempo: pitchTempo ?? this.pitchTempo,
      voiceEnhancer: voiceEnhancer ?? this.voiceEnhancer,
    );
  }
}

class NleAudioEffectChain {
  final String ownerId;
  final NleAudioEffectRackOwnerType ownerType;
  final List<NleAudioEffectSlot> slots;
  final bool enabled;
  final int version;

  const NleAudioEffectChain({
    required this.ownerId,
    required this.ownerType,
    required this.slots,
    required this.enabled,
    required this.version,
  });

  List<NleAudioEffectSlot> get orderedSlots {
    final next = [...slots];
    next.sort((a, b) => a.order.compareTo(b.order));
    return next;
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'ownerType': ownerType.name,
      'slots': orderedSlots.map((slot) => slot.toJson()).toList(),
      'enabled': enabled,
      'version': version,
    };
  }

  factory NleAudioEffectChain.fromJson(Map<String, dynamic> json) {
    return NleAudioEffectChain(
      ownerId: json['ownerId']?.toString() ?? '',
      ownerType: _enumByName(
        NleAudioEffectRackOwnerType.values,
        json['ownerType'],
        NleAudioEffectRackOwnerType.clip,
      ),
      slots: (json['slots'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleAudioEffectSlot.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      enabled: json['enabled'] != false,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleAudioEffectChain copyWith({
    List<NleAudioEffectSlot>? slots,
    bool? enabled,
    int? version,
  }) {
    return NleAudioEffectChain(
      ownerId: ownerId,
      ownerType: ownerType,
      slots: slots ?? this.slots,
      enabled: enabled ?? this.enabled,
      version: version ?? this.version,
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
