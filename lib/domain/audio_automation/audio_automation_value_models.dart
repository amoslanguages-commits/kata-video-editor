// 33B-PRO: Advanced Audio Automation — Value Models
//
// Enums and value objects describing automation properties, ducking, and
// write modes. These are intentionally free of any Flutter/Riverpod dependency
// so they can be used at any layer.

// ── Enumerations ──────────────────────────────────────────────────────────────

enum NleAudioAutomationOwnerType {
  clip,
  track,
  master,
}

enum NleAudioAutomationProperty {
  clipGain,
  clipPan,
  trackVolume,
  trackPan,
  masterGain,
  fadeInDuration,
  fadeOutDuration,
  duckingAmount,
  duckingThreshold,
  eqLowGain,
  eqMidGain,
  eqHighGain,
  compressorThreshold,
  compressorRatio,
  noiseReductionAmount,
}

enum NleAudioAutomationLaneHeight {
  compact,
  normal,
  expanded,
}

enum NleAudioDuckingSource {
  none,
  voiceTrack,
  selectedTrack,
  allVoiceTracks,
}

enum NleAudioAutomationWriteMode {
  off,
  read,
  touch,
  latch,
  write,
}

// ── Property Spec ──────────────────────────────────────────────────────────────

/// Describes the metadata (range, label, path, visibility) of a single
/// automatable audio property.
class NleAudioAutomationPropertySpec {
  final NleAudioAutomationProperty property;
  final String propertyPath;
  final String label;
  final double min;
  final double max;
  final double defaultValue;
  final String unit;
  final bool showInClipLane;
  final bool showInTrackLane;

  const NleAudioAutomationPropertySpec({
    required this.property,
    required this.propertyPath,
    required this.label,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.unit,
    required this.showInClipLane,
    required this.showInTrackLane,
  });

  Map<String, dynamic> toJson() {
    return {
      'property': property.name,
      'propertyPath': propertyPath,
      'label': label,
      'min': min,
      'max': max,
      'defaultValue': defaultValue,
      'unit': unit,
      'showInClipLane': showInClipLane,
      'showInTrackLane': showInTrackLane,
    };
  }
}

// ── Ducking Settings ──────────────────────────────────────────────────────────

class NleAudioDuckingSettings {
  final bool enabled;
  final NleAudioDuckingSource source;
  final double amountDb;
  final double thresholdDb;
  final int attackMicros;
  final int releaseMicros;

  const NleAudioDuckingSettings({
    required this.enabled,
    required this.source,
    required this.amountDb,
    required this.thresholdDb,
    required this.attackMicros,
    required this.releaseMicros,
  });

  const NleAudioDuckingSettings.off()
      : enabled = false,
        source = NleAudioDuckingSource.none,
        amountDb = -8.0,
        thresholdDb = -24.0,
        attackMicros = 120000,
        releaseMicros = 450000;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'source': source.name,
      'amountDb': amountDb,
      'thresholdDb': thresholdDb,
      'attackMicros': attackMicros,
      'releaseMicros': releaseMicros,
    };
  }

  factory NleAudioDuckingSettings.fromJson(Map<String, dynamic> json) {
    return NleAudioDuckingSettings(
      enabled: json['enabled'] == true,
      source: _enumByName(
        NleAudioDuckingSource.values,
        json['source'],
        NleAudioDuckingSource.none,
      ),
      amountDb: (json['amountDb'] as num?)?.toDouble() ?? -8.0,
      thresholdDb: (json['thresholdDb'] as num?)?.toDouble() ?? -24.0,
      attackMicros: (json['attackMicros'] as num?)?.toInt() ?? 120000,
      releaseMicros: (json['releaseMicros'] as num?)?.toInt() ?? 450000,
    );
  }

  NleAudioDuckingSettings copyWith({
    bool? enabled,
    NleAudioDuckingSource? source,
    double? amountDb,
    double? thresholdDb,
    int? attackMicros,
    int? releaseMicros,
  }) {
    return NleAudioDuckingSettings(
      enabled: enabled ?? this.enabled,
      source: source ?? this.source,
      amountDb: amountDb ?? this.amountDb,
      thresholdDb: thresholdDb ?? this.thresholdDb,
      attackMicros: attackMicros ?? this.attackMicros,
      releaseMicros: releaseMicros ?? this.releaseMicros,
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
