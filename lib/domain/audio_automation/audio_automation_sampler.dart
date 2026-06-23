// 33B-PRO: Advanced Audio Automation — Automation Sampler
//
// Evaluates the 32E KeyframeInterpolationEngine at a given timeline position
// for all audio automation properties. The output NleSampledAudio* structs are
// what the native audio engine receives for preview and export.
//
// Architecture:
//   NleAudioAutomationState
//     → AudioAutomationSampler.sampleClip / sampleTrack
//       → KeyframeInterpolationEngine.sampleProperty
//         → NleSampledAudioClipAutomation / NleSampledAudioTrackAutomation
//           → NativeAudioEngineService (method-channel dispatch)

import 'package:nle_editor/domain/audio/nle_audio_model.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_interpolation_engine.dart';

// ── Sampled Result Types ──────────────────────────────────────────────────────

class NleSampledAudioClipAutomation {
  final double gain;
  final double pan;

  const NleSampledAudioClipAutomation({
    required this.gain,
    required this.pan,
  });
}

class NleSampledAudioTrackAutomation {
  final double volume;
  final double pan;
  final double duckingAmountDb;
  final double eqLowGainDb;
  final double eqMidGainDb;
  final double eqHighGainDb;
  final double compressorThresholdDb;
  final double noiseReductionAmount;

  const NleSampledAudioTrackAutomation({
    required this.volume,
    required this.pan,
    required this.duckingAmountDb,
    required this.eqLowGainDb,
    required this.eqMidGainDb,
    required this.eqHighGainDb,
    required this.compressorThresholdDb,
    required this.noiseReductionAmount,
  });
}

// ── Sampler ───────────────────────────────────────────────────────────────────

/// Evaluates all automation properties for a clip or track at a specific time.
///
/// Uses the shared [KeyframeInterpolationEngine] from 32E — no audio-specific
/// animation engine.
class AudioAutomationSampler {
  final KeyframeInterpolationEngine engine;

  const AudioAutomationSampler({
    this.engine = const KeyframeInterpolationEngine(),
  });

  /// Sample all clip-level automation values at [localClipTimeMicros].
  ///
  /// [localClipTimeMicros] is relative to the clip start (0 = clip start).
  NleSampledAudioClipAutomation sampleClip({
    required NleAudioClip clip,
    required NleAudioAutomationState automation,
    required int localClipTimeMicros,
  }) {
    // Start from the clip's static values.
    var gain = clip.volume;
    var pan  = clip.pan;

    for (final property in automation.keyframeTrack.properties) {
      final sampled = engine.sampleProperty(
        property: property,
        localTimeMicros: localClipTimeMicros,
      );

      switch (property.propertyPath) {
        case 'audio.clip.gain':
          gain = sampled.numberOrZero;
          break;

        case 'audio.clip.pan':
          pan = sampled.numberOrZero;
          break;
      }
    }

    return NleSampledAudioClipAutomation(
      gain: gain.clamp(0.0, 2.0),
      pan:  pan.clamp(-1.0, 1.0),
    );
  }

  /// Sample all track-level automation values at [timelineMicros].
  ///
  /// [timelineMicros] is absolute timeline position.
  NleSampledAudioTrackAutomation sampleTrack({
    required NleAudioTrack track,
    required NleAudioAutomationState automation,
    required int timelineMicros,
  }) {
    var volume                 = track.volume;
    var pan                    = track.pan;
    var duckingAmountDb        = automation.ducking.amountDb;
    var eqLowGainDb            = 0.0;
    var eqMidGainDb            = 0.0;
    var eqHighGainDb           = 0.0;
    var compressorThresholdDb  = -18.0;
    var noiseReductionAmount   = 0.0;

    for (final property in automation.keyframeTrack.properties) {
      final sampled = engine.sampleProperty(
        property: property,
        localTimeMicros: timelineMicros,
      );

      switch (property.propertyPath) {
        case 'audio.track.volume':
          volume = sampled.numberOrZero;
          break;

        case 'audio.track.pan':
          pan = sampled.numberOrZero;
          break;

        case 'audio.track.ducking.amountDb':
          duckingAmountDb = sampled.numberOrZero;
          break;

        case 'audio.track.effects.eq.lowGainDb':
          eqLowGainDb = sampled.numberOrZero;
          break;

        case 'audio.track.effects.eq.midGainDb':
          eqMidGainDb = sampled.numberOrZero;
          break;

        case 'audio.track.effects.eq.highGainDb':
          eqHighGainDb = sampled.numberOrZero;
          break;

        case 'audio.track.effects.compressor.thresholdDb':
          compressorThresholdDb = sampled.numberOrZero;
          break;

        case 'audio.track.effects.noiseReduction.amount':
          noiseReductionAmount = sampled.numberOrZero;
          break;
      }
    }

    return NleSampledAudioTrackAutomation(
      volume:                volume.clamp(0.0, 2.0),
      pan:                   pan.clamp(-1.0, 1.0),
      duckingAmountDb:       duckingAmountDb.clamp(-24.0, 0.0),
      eqLowGainDb:           eqLowGainDb.clamp(-18.0, 18.0),
      eqMidGainDb:           eqMidGainDb.clamp(-18.0, 18.0),
      eqHighGainDb:          eqHighGainDb.clamp(-18.0, 18.0),
      compressorThresholdDb: compressorThresholdDb.clamp(-60.0, 0.0),
      noiseReductionAmount:  noiseReductionAmount.clamp(0.0, 1.0),
    );
  }
}
