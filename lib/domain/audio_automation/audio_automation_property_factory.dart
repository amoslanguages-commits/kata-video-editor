// 33B-PRO: Advanced Audio Automation — Property Factory
//
// Builds the canonical list of [NleAnimatableProperty] and
// [NleAudioAutomationLane] instances for clip and track owners.
// Uses the shared 32E keyframe system — no separate animation engine.

import 'package:nle_editor/domain/audio_automation/audio_automation_models.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_value_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

class AudioAutomationPropertyFactory {
  const AudioAutomationPropertyFactory();

  // ── Specs ────────────────────────────────────────────────────────────────

  List<NleAudioAutomationPropertySpec> specs() {
    return const [
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.clipGain,
        propertyPath: 'audio.clip.gain',
        label: 'Clip Gain',
        min: 0.0,
        max: 2.0,
        defaultValue: 1.0,
        unit: 'x',
        showInClipLane: true,
        showInTrackLane: false,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.clipPan,
        propertyPath: 'audio.clip.pan',
        label: 'Clip Pan',
        min: -1.0,
        max: 1.0,
        defaultValue: 0.0,
        unit: '',
        showInClipLane: true,
        showInTrackLane: false,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.trackVolume,
        propertyPath: 'audio.track.volume',
        label: 'Track Volume',
        min: 0.0,
        max: 2.0,
        defaultValue: 1.0,
        unit: 'x',
        showInClipLane: false,
        showInTrackLane: true,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.trackPan,
        propertyPath: 'audio.track.pan',
        label: 'Track Pan',
        min: -1.0,
        max: 1.0,
        defaultValue: 0.0,
        unit: '',
        showInClipLane: false,
        showInTrackLane: true,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.duckingAmount,
        propertyPath: 'audio.track.ducking.amountDb',
        label: 'Ducking',
        min: -24.0,
        max: 0.0,
        defaultValue: -8.0,
        unit: 'dB',
        showInClipLane: false,
        showInTrackLane: true,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.eqLowGain,
        propertyPath: 'audio.track.effects.eq.lowGainDb',
        label: 'EQ Low',
        min: -18.0,
        max: 18.0,
        defaultValue: 0.0,
        unit: 'dB',
        showInClipLane: false,
        showInTrackLane: true,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.eqMidGain,
        propertyPath: 'audio.track.effects.eq.midGainDb',
        label: 'EQ Mid',
        min: -18.0,
        max: 18.0,
        defaultValue: 0.0,
        unit: 'dB',
        showInClipLane: false,
        showInTrackLane: true,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.eqHighGain,
        propertyPath: 'audio.track.effects.eq.highGainDb',
        label: 'EQ High',
        min: -18.0,
        max: 18.0,
        defaultValue: 0.0,
        unit: 'dB',
        showInClipLane: false,
        showInTrackLane: true,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.compressorThreshold,
        propertyPath: 'audio.track.effects.compressor.thresholdDb',
        label: 'Comp Threshold',
        min: -60.0,
        max: 0.0,
        defaultValue: -18.0,
        unit: 'dB',
        showInClipLane: false,
        showInTrackLane: true,
      ),
      NleAudioAutomationPropertySpec(
        property: NleAudioAutomationProperty.noiseReductionAmount,
        propertyPath: 'audio.track.effects.noiseReduction.amount',
        label: 'Noise Reduction',
        min: 0.0,
        max: 1.0,
        defaultValue: 0.0,
        unit: '',
        showInClipLane: false,
        showInTrackLane: true,
      ),
    ];
  }

  // ── Property lists ────────────────────────────────────────────────────────

  List<NleAnimatableProperty> clipProperties({required String clipId}) {
    return specs()
        .where((spec) => spec.showInClipLane)
        .map(
          (spec) => _property(
            ownerId: clipId,
            ownerType: NleKeyframeOwnerType.audioClip,
            spec: spec,
          ),
        )
        .toList();
  }

  List<NleAnimatableProperty> trackProperties({required String trackId}) {
    return specs()
        .where((spec) => spec.showInTrackLane)
        .map(
          (spec) => _property(
            ownerId: trackId,
            ownerType: NleKeyframeOwnerType.audioTrack,
            spec: spec,
          ),
        )
        .toList();
  }

  // ── Lane lists ────────────────────────────────────────────────────────────

  List<NleAudioAutomationLane> clipLanes({required String clipId}) {
    return specs()
        .where((spec) => spec.showInClipLane)
        .map(
          (spec) => _lane(
            ownerId: clipId,
            ownerType: NleAudioAutomationOwnerType.clip,
            spec: spec,
          ),
        )
        .toList();
  }

  List<NleAudioAutomationLane> trackLanes({required String trackId}) {
    return specs()
        .where((spec) => spec.showInTrackLane)
        .map(
          (spec) => _lane(
            ownerId: trackId,
            ownerType: NleAudioAutomationOwnerType.track,
            spec: spec,
          ),
        )
        .toList();
  }

  // ── Private builders ──────────────────────────────────────────────────────

  NleAnimatableProperty _property({
    required String ownerId,
    required NleKeyframeOwnerType ownerType,
    required NleAudioAutomationPropertySpec spec,
  }) {
    return NleAnimatableProperty(
      id: '$ownerId:${spec.propertyPath}',
      ownerId: ownerId,
      ownerType: ownerType,
      propertyPath: spec.propertyPath,
      label: spec.label,
      group: NleKeyframePropertyGroup.audio,
      valueType: NleKeyframeValueType.number,
      defaultValue: NleKeyframeValue.number(spec.defaultValue),
      min: spec.min,
      max: spec.max,
      enabled: true,
      keyframes: const [],
    );
  }

  NleAudioAutomationLane _lane({
    required String ownerId,
    required NleAudioAutomationOwnerType ownerType,
    required NleAudioAutomationPropertySpec spec,
  }) {
    return NleAudioAutomationLane(
      id: '$ownerId:${spec.propertyPath}:lane',
      ownerId: ownerId,
      ownerType: ownerType,
      propertyPath: spec.propertyPath,
      label: spec.label,
      min: spec.min,
      max: spec.max,
      unit: spec.unit,
      visible: true,
      height: NleAudioAutomationLaneHeight.normal,
    );
  }
}
