// 33B-PRO: Advanced Audio Automation — Effect Slot Panel
//
// Inspector panel for editing EQ, compressor, and noise-reduction settings
// on a track's effect chain. Used inside the audio inspector sidebar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/audio_automation/audio_automation_value_models.dart';
import 'package:nle_editor/domain/audio_automation/audio_effect_slot_models.dart';
import 'package:nle_editor/presentation/providers/audio_automation_providers.dart';

// ── Effect Slot Panel ─────────────────────────────────────────────────────────

class AudioEffectSlotPanel extends ConsumerWidget {
  final String trackId;
  final int durationMicros;

  const AudioEffectSlotPanel({
    super.key,
    required this.trackId,
    this.durationMicros = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = AudioAutomationControllerArgs(
      ownerId: trackId,
      ownerType: NleAudioAutomationOwnerType.track,
      durationMicros: durationMicros,
    );

    final editorState =
        ref.watch(audioAutomationControllerProvider(args));
    final ctrl = ref.read(audioAutomationControllerProvider(args).notifier);

    final slots = editorState.automation?.effectSlots ?? const [];

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
          _sectionHeader('EFFECTS'),
          const SizedBox(height: 8),
          if (slots.isEmpty)
            const _EmptyEffectsHint()
          else
            ...slots.map(
              (slot) => _EffectSlotTile(
                slot: slot,
                onToggle: () => ctrl.toggleEffectSlot(slot.id),
                onUpdate: ctrl.updateEffectSlot,
              ),
            ),
          const SizedBox(height: 8),
          _AddEffectButton(onAdd: (type) {
            ctrl.addEffectSlot(_defaultSlot(type, slots.length));
          }),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Row(
      children: [
        const Icon(Icons.auto_fix_high, size: 12, color: Color(0xFF29D884)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF29D884),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  NleAudioEffectSlot _defaultSlot(NleAudioEffectType type, int order) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    return NleAudioEffectSlot(
      id: id,
      type: type,
      name: _effectName(type),
      bypassMode: NleAudioEffectSlotBypassMode.active,
      order: order,
      eq3Band:
          type == NleAudioEffectType.eq3Band
              ? const NleAudioEq3BandSettings.flat()
              : null,
      compressor:
          type == NleAudioEffectType.compressor
              ? const NleAudioCompressorSettings.off()
              : null,
      noiseReduction:
          type == NleAudioEffectType.noiseReduction
              ? const NleAudioNoiseReductionSettings.off()
              : null,
    );
  }

  String _effectName(NleAudioEffectType type) {
    switch (type) {
      case NleAudioEffectType.eq3Band:
        return '3-Band EQ';
      case NleAudioEffectType.compressor:
        return 'Compressor';
      case NleAudioEffectType.limiter:
        return 'Limiter';
      case NleAudioEffectType.noiseReduction:
        return 'Noise Reduction';
      case NleAudioEffectType.noiseGate:
        return 'Noise Gate';
      case NleAudioEffectType.reverb:
        return 'Reverb';
      case NleAudioEffectType.pitchTempo:
        return 'Pitch / Tempo';
    }
  }
}

// ── Effect Slot Tile ──────────────────────────────────────────────────────────

class _EffectSlotTile extends StatelessWidget {
  final NleAudioEffectSlot slot;
  final VoidCallback onToggle;
  final ValueChanged<NleAudioEffectSlot> onUpdate;

  const _EffectSlotTile({
    required this.slot,
    required this.onToggle,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: slot.active
                  ? const Color(0xFF29D884).withAlpha(25)
                  : const Color(0xFF1A2535),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  _iconFor(slot.type),
                  size: 13,
                  color: slot.active
                      ? const Color(0xFF29D884)
                      : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slot.name,
                    style: TextStyle(
                      color:
                          slot.active ? Colors.white : Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 28,
                    height: 16,
                    decoration: BoxDecoration(
                      color: slot.active
                          ? const Color(0xFF29D884)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 140),
                      alignment: slot.active
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Expanded params when active
          if (slot.active) _buildParams(context),
        ],
      ),
    );
  }

  Widget _buildParams(BuildContext context) {
    switch (slot.type) {
      case NleAudioEffectType.eq3Band:
        return _Eq3BandParams(slot: slot, onUpdate: onUpdate);
      case NleAudioEffectType.compressor:
        return _CompressorParams(slot: slot, onUpdate: onUpdate);
      case NleAudioEffectType.noiseReduction:
        return _NoiseReductionParams(slot: slot, onUpdate: onUpdate);
      default:
        return const SizedBox.shrink();
    }
  }

  IconData _iconFor(NleAudioEffectType type) {
    switch (type) {
      case NleAudioEffectType.eq3Band:
        return Icons.equalizer;
      case NleAudioEffectType.compressor:
        return Icons.compress;
      case NleAudioEffectType.noiseReduction:
        return Icons.noise_control_off;
      case NleAudioEffectType.reverb:
        return Icons.surround_sound;
      case NleAudioEffectType.limiter:
        return Icons.lock_outline;
      case NleAudioEffectType.noiseGate:
        return Icons.do_not_disturb_on_outlined;
      case NleAudioEffectType.pitchTempo:
        return Icons.speed;
    }
  }
}

// ── EQ Params ─────────────────────────────────────────────────────────────────

class _Eq3BandParams extends StatelessWidget {
  final NleAudioEffectSlot slot;
  final ValueChanged<NleAudioEffectSlot> onUpdate;

  const _Eq3BandParams({required this.slot, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final eq = slot.eq3Band ?? const NleAudioEq3BandSettings.flat();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Column(
        children: [
          _dbSlider(
            label: 'LOW',
            value: eq.lowGainDb,
            onChanged: (v) => onUpdate(
              slot.copyWith(eq3Band: eq.copyWith(lowGainDb: v)),
            ),
          ),
          _dbSlider(
            label: 'MID',
            value: eq.midGainDb,
            onChanged: (v) => onUpdate(
              slot.copyWith(eq3Band: eq.copyWith(midGainDb: v)),
            ),
          ),
          _dbSlider(
            label: 'HIGH',
            value: eq.highGainDb,
            onChanged: (v) => onUpdate(
              slot.copyWith(eq3Band: eq.copyWith(highGainDb: v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dbSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(-18.0, 18.0),
            min: -18.0,
            max: 18.0,
            activeColor: const Color(0xFF29D884),
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '${value.toStringAsFixed(1)} dB',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ── Compressor Params ─────────────────────────────────────────────────────────

class _CompressorParams extends StatelessWidget {
  final NleAudioEffectSlot slot;
  final ValueChanged<NleAudioEffectSlot> onUpdate;

  const _CompressorParams({required this.slot, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final comp = slot.compressor ?? const NleAudioCompressorSettings.off();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Column(
        children: [
          _paramRow(
            label: 'THRESHOLD',
            value: comp.thresholdDb,
            min: -60.0,
            max: 0.0,
            suffix: 'dB',
            onChanged: (v) => onUpdate(
              slot.copyWith(compressor: comp.copyWith(thresholdDb: v)),
            ),
          ),
          _paramRow(
            label: 'RATIO',
            value: comp.ratio,
            min: 1.0,
            max: 20.0,
            suffix: ':1',
            onChanged: (v) => onUpdate(
              slot.copyWith(compressor: comp.copyWith(ratio: v)),
            ),
          ),
          _paramRow(
            label: 'MAKEUP',
            value: comp.makeupGainDb,
            min: 0.0,
            max: 24.0,
            suffix: 'dB',
            onChanged: (v) => onUpdate(
              slot.copyWith(compressor: comp.copyWith(makeupGainDb: v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paramRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
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
          width: 44,
          child: Text(
            '${value.toStringAsFixed(1)} $suffix',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ── Noise Reduction Params ────────────────────────────────────────────────────

class _NoiseReductionParams extends StatelessWidget {
  final NleAudioEffectSlot slot;
  final ValueChanged<NleAudioEffectSlot> onUpdate;

  const _NoiseReductionParams({required this.slot, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final nr =
        slot.noiseReduction ?? const NleAudioNoiseReductionSettings.off();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Row(
        children: [
          const SizedBox(
            width: 50,
            child: Text(
              'AMOUNT',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          Expanded(
            child: Slider(
              value: nr.amount.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              activeColor: const Color(0xFF29D884),
              inactiveColor: Colors.white12,
              onChanged: (v) => onUpdate(
                slot.copyWith(
                  noiseReduction: nr.copyWith(amount: v),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${(nr.amount * 100).round()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Effect Button ─────────────────────────────────────────────────────────

class _AddEffectButton extends StatelessWidget {
  final ValueChanged<NleAudioEffectType> onAdd;

  const _AddEffectButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF29D884).withAlpha(76)),
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFF29D884).withAlpha(15),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 14, color: Color(0xFF29D884)),
            SizedBox(width: 4),
            Text(
              'Add Effect',
              style: TextStyle(
                color: Color(0xFF29D884),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<NleAudioEffectType>(
      context: context,
      backgroundColor: const Color(0xFF0C1824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Add Effect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final type in [
                NleAudioEffectType.eq3Band,
                NleAudioEffectType.compressor,
                NleAudioEffectType.noiseReduction,
                NleAudioEffectType.limiter,
              ])
                ListTile(
                  leading: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF29D884)),
                  title: Text(
                    _typeName(type),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onAdd(type);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _typeName(NleAudioEffectType type) {
    switch (type) {
      case NleAudioEffectType.eq3Band:
        return '3-Band EQ';
      case NleAudioEffectType.compressor:
        return 'Compressor';
      case NleAudioEffectType.noiseReduction:
        return 'Noise Reduction';
      case NleAudioEffectType.limiter:
        return 'Limiter';
      default:
        return type.name;
    }
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyEffectsHint extends StatelessWidget {
  const _EmptyEffectsHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'No effects added',
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
      ),
    );
  }
}
