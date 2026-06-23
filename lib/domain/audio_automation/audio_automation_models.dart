// 33B-PRO: Advanced Audio Automation — Automation State Model
//
// Combines the automation lane layout, 32E keyframe track, ducking settings,
// and effect slots into a single serialisable state object per owner (clip or
// track).

import 'package:nle_editor/domain/audio_automation/audio_automation_value_models.dart';
import 'package:nle_editor/domain/audio_automation/audio_effect_slot_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';

// ── Automation Lane ───────────────────────────────────────────────────────────

/// A single row in the audio automation panel in the timeline.
/// Each lane corresponds to one [NleAnimatableProperty] in the keyframe track.
class NleAudioAutomationLane {
  final String id;
  final String ownerId;
  final NleAudioAutomationOwnerType ownerType;
  final String propertyPath;
  final String label;
  final double min;
  final double max;
  final String unit;
  final bool visible;
  final NleAudioAutomationLaneHeight height;

  const NleAudioAutomationLane({
    required this.id,
    required this.ownerId,
    required this.ownerType,
    required this.propertyPath,
    required this.label,
    required this.min,
    required this.max,
    required this.unit,
    required this.visible,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerType': ownerType.name,
      'propertyPath': propertyPath,
      'label': label,
      'min': min,
      'max': max,
      'unit': unit,
      'visible': visible,
      'height': height.name,
    };
  }

  factory NleAudioAutomationLane.fromJson(Map<String, dynamic> json) {
    return NleAudioAutomationLane(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      ownerType: _enumByName(
        NleAudioAutomationOwnerType.values,
        json['ownerType'],
        NleAudioAutomationOwnerType.clip,
      ),
      propertyPath: json['propertyPath']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? '',
      visible: json['visible'] != false,
      height: _enumByName(
        NleAudioAutomationLaneHeight.values,
        json['height'],
        NleAudioAutomationLaneHeight.normal,
      ),
    );
  }

  NleAudioAutomationLane copyWith({
    bool? visible,
    NleAudioAutomationLaneHeight? height,
  }) {
    return NleAudioAutomationLane(
      id: id,
      ownerId: ownerId,
      ownerType: ownerType,
      propertyPath: propertyPath,
      label: label,
      min: min,
      max: max,
      unit: unit,
      visible: visible ?? this.visible,
      height: height ?? this.height,
    );
  }
}

// ── Automation State ──────────────────────────────────────────────────────────

/// Complete automation state for a single clip or track.
///
/// - [keyframeTrack] is a 32E [NleKeyframeTrack] with audio property paths.
/// - [lanes] control which properties are visible in the timeline UI.
/// - [effectSlots] hold EQ / compressor / noise-reduction state.
/// - [ducking] holds track-level auto-ducking configuration.
class NleAudioAutomationState {
  final String ownerId;
  final NleAudioAutomationOwnerType ownerType;
  final NleAudioAutomationWriteMode writeMode;
  final NleAudioDuckingSettings ducking;
  final List<NleAudioEffectSlot> effectSlots;
  final List<NleAudioAutomationLane> lanes;
  final NleKeyframeTrack keyframeTrack;
  final int version;

  const NleAudioAutomationState({
    required this.ownerId,
    required this.ownerType,
    required this.writeMode,
    required this.ducking,
    required this.effectSlots,
    required this.lanes,
    required this.keyframeTrack,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'ownerType': ownerType.name,
      'writeMode': writeMode.name,
      'ducking': ducking.toJson(),
      'effectSlots': effectSlots.map((slot) => slot.toJson()).toList(),
      'lanes': lanes.map((lane) => lane.toJson()).toList(),
      'keyframeTrack': keyframeTrack.toJson(),
      'version': version,
    };
  }

  factory NleAudioAutomationState.fromJson(Map<String, dynamic> json) {
    return NleAudioAutomationState(
      ownerId: json['ownerId']?.toString() ?? '',
      ownerType: _enumByName(
        NleAudioAutomationOwnerType.values,
        json['ownerType'],
        NleAudioAutomationOwnerType.clip,
      ),
      writeMode: _enumByName(
        NleAudioAutomationWriteMode.values,
        json['writeMode'],
        NleAudioAutomationWriteMode.read,
      ),
      ducking: NleAudioDuckingSettings.fromJson(
        Map<String, dynamic>.from(json['ducking'] as Map? ?? const {}),
      ),
      effectSlots: (json['effectSlots'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleAudioEffectSlot.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      lanes: (json['lanes'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleAudioAutomationLane.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      keyframeTrack: NleKeyframeTrack.fromJson(
        Map<String, dynamic>.from(
            json['keyframeTrack'] as Map? ?? const {}),
      ),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleAudioAutomationState copyWith({
    NleAudioAutomationWriteMode? writeMode,
    NleAudioDuckingSettings? ducking,
    List<NleAudioEffectSlot>? effectSlots,
    List<NleAudioAutomationLane>? lanes,
    NleKeyframeTrack? keyframeTrack,
    int? version,
  }) {
    return NleAudioAutomationState(
      ownerId: ownerId,
      ownerType: ownerType,
      writeMode: writeMode ?? this.writeMode,
      ducking: ducking ?? this.ducking,
      effectSlots: effectSlots ?? this.effectSlots,
      lanes: lanes ?? this.lanes,
      keyframeTrack: keyframeTrack ?? this.keyframeTrack,
      version: version ?? this.version,
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
