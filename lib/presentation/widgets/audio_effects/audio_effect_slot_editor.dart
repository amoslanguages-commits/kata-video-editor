import 'package:flutter/material.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_chain_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_settings_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';

class AudioEffectSlotEditor extends StatelessWidget {
  final NleAudioEffectSlot slot;
  final ValueChanged<NleAudioEffectSlot> onChanged;

  const AudioEffectSlotEditor({
    super.key,
    required this.slot,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(PremiumRadius.md),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                slot.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              _buildWetMixSlider(),
            ],
          ),
          const SizedBox(height: PremiumSpacing.lg),
          const Divider(),
          const SizedBox(height: PremiumSpacing.md),
          _buildEffectControls(),
        ],
      ),
    );
  }

  Widget _buildWetMixSlider() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Mix:',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        SizedBox(
          width: 100,
          child: Slider(
            value: slot.wetMix,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              onChanged(slot.copyWith(wetMix: val));
            },
          ),
        ),
        Text(
          '${(slot.wetMix * 100).toInt()}%',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildEffectControls() {
    switch (slot.type) {
      case NleAudioEffectType.eq3Band:
        final settings = slot.eq3Band ?? const NleEq3BandEffectSettings.flat();
        return Column(
          children: [
            _buildSliderRow(
              label: 'Low Gain',
              value: settings.lowGainDb,
              min: -15.0,
              max: 15.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(eq3Band: settings.copyWith(lowGainDb: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Mid Gain',
              value: settings.midGainDb,
              min: -15.0,
              max: 15.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(eq3Band: settings.copyWith(midGainDb: val)),
              ),
            ),
            _buildSliderRow(
              label: 'High Gain',
              value: settings.highGainDb,
              min: -15.0,
              max: 15.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(eq3Band: settings.copyWith(highGainDb: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Low Crossover',
              value: settings.lowFrequencyHz,
              min: 80.0,
              max: 800.0,
              unit: ' Hz',
              onChanged: (val) => onChanged(
                slot.copyWith(eq3Band: settings.copyWith(lowFrequencyHz: val)),
              ),
            ),
            _buildSliderRow(
              label: 'High Crossover',
              value: settings.highFrequencyHz,
              min: 1000.0,
              max: 8000.0,
              unit: ' Hz',
              onChanged: (val) => onChanged(
                slot.copyWith(eq3Band: settings.copyWith(highFrequencyHz: val)),
              ),
            ),
          ],
        );

      case NleAudioEffectType.compressor:
        final settings = slot.compressor ?? const NleCompressorEffectSettings.voice();
        return Column(
          children: [
            _buildSliderRow(
              label: 'Threshold',
              value: settings.thresholdDb,
              min: -60.0,
              max: 0.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(compressor: settings.copyWith(thresholdDb: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Ratio',
              value: settings.ratio,
              min: 1.0,
              max: 20.0,
              unit: ':1',
              onChanged: (val) => onChanged(
                slot.copyWith(compressor: settings.copyWith(ratio: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Attack',
              value: settings.attackMs,
              min: 1.0,
              max: 100.0,
              unit: ' ms',
              onChanged: (val) => onChanged(
                slot.copyWith(compressor: settings.copyWith(attackMs: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Release',
              value: settings.releaseMs,
              min: 10.0,
              max: 1000.0,
              unit: ' ms',
              onChanged: (val) => onChanged(
                slot.copyWith(compressor: settings.copyWith(releaseMs: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Makeup Gain',
              value: settings.makeupGainDb,
              min: 0.0,
              max: 18.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(compressor: settings.copyWith(makeupGainDb: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Knee',
              value: settings.kneeDb,
              min: 0.0,
              max: 12.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(compressor: settings.copyWith(kneeDb: val)),
              ),
            ),
          ],
        );

      case NleAudioEffectType.limiter:
        final settings = slot.limiter ?? const NleLimiterEffectSettings.defaultLimiter();
        return Column(
          children: [
            _buildSliderRow(
              label: 'Ceiling',
              value: settings.ceilingDb,
              min: -24.0,
              max: 0.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(limiter: settings.copyWith(ceilingDb: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Release',
              value: settings.releaseMs,
              min: 10.0,
              max: 500.0,
              unit: ' ms',
              onChanged: (val) => onChanged(
                slot.copyWith(limiter: settings.copyWith(releaseMs: val)),
              ),
            ),
            _buildSwitchRow(
              label: 'True Peak Safe',
              value: settings.truePeakSafe,
              onChanged: (val) => onChanged(
                slot.copyWith(limiter: settings.copyWith(truePeakSafe: val)),
              ),
            ),
          ],
        );

      case NleAudioEffectType.noiseGate:
        final settings = slot.noiseGate ?? const NleNoiseGateEffectSettings.voiceClean();
        return Column(
          children: [
            _buildSliderRow(
              label: 'Threshold',
              value: settings.thresholdDb,
              min: -80.0,
              max: 0.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(noiseGate: settings.copyWith(thresholdDb: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Reduction',
              value: settings.reductionDb,
              min: -40.0,
              max: 0.0,
              unit: ' dB',
              onChanged: (val) => onChanged(
                slot.copyWith(noiseGate: settings.copyWith(reductionDb: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Attack',
              value: settings.attackMs,
              min: 0.1,
              max: 50.0,
              unit: ' ms',
              onChanged: (val) => onChanged(
                slot.copyWith(noiseGate: settings.copyWith(attackMs: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Release',
              value: settings.releaseMs,
              min: 10.0,
              max: 1000.0,
              unit: ' ms',
              onChanged: (val) => onChanged(
                slot.copyWith(noiseGate: settings.copyWith(releaseMs: val)),
              ),
            ),
          ],
        );

      case NleAudioEffectType.noiseReduction:
        final settings = slot.noiseReduction ?? const NleNoiseReductionEffectSettings.light();
        return Column(
          children: [
            _buildSliderRow(
              label: 'Amount',
              value: settings.amount,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(noiseReduction: settings.copyWith(amount: val)),
              ),
            ),
            _buildSwitchRow(
              label: 'Voice Optimized',
              value: settings.voiceOptimized,
              onChanged: (val) => onChanged(
                slot.copyWith(noiseReduction: settings.copyWith(voiceOptimized: val)),
              ),
            ),
          ],
        );

      case NleAudioEffectType.reverb:
        final settings = slot.reverb ?? const NleReverbEffectSettings.smallRoom();
        return Column(
          children: [
            _buildSliderRow(
              label: 'Room Size',
              value: settings.roomSize,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(reverb: settings.copyWith(roomSize: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Damping',
              value: settings.damping,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(reverb: settings.copyWith(damping: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Wet Mix',
              value: settings.wet,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(reverb: settings.copyWith(wet: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Dry Mix',
              value: settings.dry,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(reverb: settings.copyWith(dry: val)),
              ),
            ),
          ],
        );

      case NleAudioEffectType.pitchTempo:
        final settings = slot.pitchTempo ?? const NlePitchTempoEffectSettings.identity();
        return Column(
          children: [
            _buildSliderRow(
              label: 'Pitch',
              value: settings.pitchSemitones,
              min: -12.0,
              max: 12.0,
              unit: ' st',
              onChanged: (val) => onChanged(
                slot.copyWith(pitchTempo: settings.copyWith(pitchSemitones: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Tempo',
              value: settings.tempoMultiplier,
              min: 0.25,
              max: 4.0,
              unit: 'x',
              onChanged: (val) => onChanged(
                slot.copyWith(pitchTempo: settings.copyWith(tempoMultiplier: val)),
              ),
            ),
            _buildSwitchRow(
              label: 'Preserve Formants',
              value: settings.preserveFormants,
              onChanged: (val) => onChanged(
                slot.copyWith(pitchTempo: settings.copyWith(preserveFormants: val)),
              ),
            ),
          ],
        );

      case NleAudioEffectType.voiceEnhancer:
        final settings = slot.voiceEnhancer ?? const NleVoiceEnhancerEffectSettings.creatorVoice();
        return Column(
          children: [
            _buildSliderRow(
              label: 'Clarity',
              value: settings.clarity,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(voiceEnhancer: settings.copyWith(clarity: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Body',
              value: settings.body,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(voiceEnhancer: settings.copyWith(body: val)),
              ),
            ),
            _buildSliderRow(
              label: 'Air',
              value: settings.air,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(voiceEnhancer: settings.copyWith(air: val)),
              ),
            ),
            _buildSliderRow(
              label: 'De-Ess',
              value: settings.deEss,
              min: 0.0,
              max: 1.0,
              unit: '',
              onChanged: (val) => onChanged(
                slot.copyWith(voiceEnhancer: settings.copyWith(deEss: val)),
              ),
            ),
          ],
        );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PremiumSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 6,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${value.toStringAsFixed(1)}$unit',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PremiumSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentPrimary,
          ),
        ],
      ),
    );
  }
}
