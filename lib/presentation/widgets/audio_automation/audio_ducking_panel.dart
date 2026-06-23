// 33B-PRO: Advanced Audio Automation — Ducking Inspector Panel
//
// Displayed in the audio inspector sidebar when a track supports auto-ducking.
// Provides controls for enabling ducking, selecting source, and setting
// amount / threshold / attack / release.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/audio_automation/audio_automation_value_models.dart';
import 'package:nle_editor/presentation/providers/audio_automation_providers.dart';

class AudioDuckingPanel extends ConsumerWidget {
  final String trackId;

  const AudioDuckingPanel({super.key, required this.trackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = AudioAutomationControllerArgs(
      ownerId: trackId,
      ownerType: NleAudioAutomationOwnerType.track,
      durationMicros: 0,
    );

    final state = ref.watch(audioAutomationControllerProvider(args));
    final ctrl =
        ref.read(audioAutomationControllerProvider(args).notifier);

    final ducking =
        state.automation?.ducking ?? const NleAudioDuckingSettings.off();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1422),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2535)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.volume_down, size: 12, color: Color(0xFF29D884)),
              const SizedBox(width: 6),
              const Text(
                'AUTO-DUCKING',
                style: TextStyle(
                  color: Color(0xFF29D884),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _ToggleSwitch(
                value: ducking.enabled,
                onChanged: (v) => ctrl.updateDucking(
                  ducking.copyWith(enabled: v),
                ),
              ),
            ],
          ),

          if (ducking.enabled) ...[
            const SizedBox(height: 12),

            // ── Source ──────────────────────────────────────────────────
            _labelRow('SOURCE'),
            const SizedBox(height: 4),
            _SourcePicker(
              source: ducking.source,
              onChanged: (s) =>
                  ctrl.updateDucking(ducking.copyWith(source: s)),
            ),

            const SizedBox(height: 10),

            // ── Amount ──────────────────────────────────────────────────
            _SliderRow(
              label: 'AMOUNT',
              value: ducking.amountDb,
              min: -24.0,
              max: 0.0,
              suffix: 'dB',
              onChanged: (v) =>
                  ctrl.updateDucking(ducking.copyWith(amountDb: v)),
            ),

            // ── Threshold ────────────────────────────────────────────────
            _SliderRow(
              label: 'THRESHOLD',
              value: ducking.thresholdDb,
              min: -60.0,
              max: 0.0,
              suffix: 'dB',
              onChanged: (v) =>
                  ctrl.updateDucking(ducking.copyWith(thresholdDb: v)),
            ),

            // ── Attack ───────────────────────────────────────────────────
            _SliderRow(
              label: 'ATTACK',
              value: ducking.attackMicros / 1000.0,
              min: 10.0,
              max: 500.0,
              suffix: 'ms',
              onChanged: (v) => ctrl.updateDucking(
                ducking.copyWith(attackMicros: (v * 1000).round()),
              ),
            ),

            // ── Release ──────────────────────────────────────────────────
            _SliderRow(
              label: 'RELEASE',
              value: ducking.releaseMicros / 1000.0,
              min: 50.0,
              max: 2000.0,
              suffix: 'ms',
              onChanged: (v) => ctrl.updateDucking(
                ducking.copyWith(releaseMicros: (v * 1000).round()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelRow(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Toggle Switch ─────────────────────────────────────────────────────────────

class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF29D884) : Colors.white12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 140),
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Source Picker ─────────────────────────────────────────────────────────────

class _SourcePicker extends StatelessWidget {
  final NleAudioDuckingSource source;
  final ValueChanged<NleAudioDuckingSource> onChanged;

  const _SourcePicker({required this.source, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in [
          NleAudioDuckingSource.voiceTrack,
          NleAudioDuckingSource.allVoiceTracks,
          NleAudioDuckingSource.selectedTrack,
        ])
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(s),
              child: Container(
                height: 26,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: source == s
                      ? const Color(0xFF29D884).withAlpha(40)
                      : Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: source == s
                        ? const Color(0xFF29D884)
                        : Colors.white12,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _label(s),
                  style: TextStyle(
                    color: source == s
                        ? const Color(0xFF29D884)
                        : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _label(NleAudioDuckingSource s) {
    switch (s) {
      case NleAudioDuckingSource.voiceTrack:
        return 'VOICE';
      case NleAudioDuckingSource.allVoiceTracks:
        return 'ALL VO';
      case NleAudioDuckingSource.selectedTrack:
        return 'SELECTED';
      default:
        return s.name.toUpperCase();
    }
  }
}

// ── Slider Row ────────────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: const Color(0xFF29D884),
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${value.toStringAsFixed(0)} $suffix',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
