import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_chain_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_preset_factory.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';
import 'package:nle_editor/presentation/controllers/audio_effect_controller.dart';
import 'package:nle_editor/presentation/providers/audio_effect_controller_provider.dart';
import 'package:nle_editor/presentation/widgets/audio_effects/audio_effect_slot_editor.dart';

class AudioEffectRackPanel extends ConsumerWidget {
  final String ownerId;
  final NleAudioEffectRackOwnerType ownerType;

  const AudioEffectRackPanel({
    super.key,
    required this.ownerId,
    required this.ownerType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = AudioEffectControllerArgs(
      ownerId: ownerId,
      ownerType: ownerType,
    );

    final state = ref.watch(audioEffectControllerProvider(args));
    final controller = ref.read(audioEffectControllerProvider(args).notifier);

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final chain = state.chain;

    if (chain == null) {
      return const Center(
        child: Text(
          'No effect rack.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PremiumSpacing.lg,
            vertical: PremiumSpacing.md,
          ),
          child: Row(
            children: [
              const Icon(Icons.graphic_eq_rounded, color: AppTheme.accentPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _title(ownerType),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Presets Menu
              PopupMenuButton<NleAudioEffectChainPresetId>(
                icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentPrimary),
                tooltip: 'Chain Presets',
                onSelected: controller.applyPreset,
                itemBuilder: (context) {
                  return NleAudioEffectChainPresetId.values.map((preset) {
                    return PopupMenuItem(
                      value: preset,
                      child: Text(_presetName(preset)),
                    );
                  }).toList();
                },
              ),
              // Add Effect Button
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentPrimary),
                tooltip: 'Add Effect',
                onPressed: () => _showAddEffectSheet(context, controller),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Slots Stack
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
                    ),
                  ),
                  child: chain.slots.isEmpty
                      ? const Center(
                          child: Text(
                            'Rack is empty.\nClick + to add audio effects.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(PremiumSpacing.md),
                          itemCount: chain.orderedSlots.length,
                          itemBuilder: (context, index) {
                            final slot = chain.orderedSlots[index];
                            final isSelected = slot.id == state.selectedSlotId;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: PremiumSpacing.sm),
                              child: _buildSlotCard(
                                context: context,
                                slot: slot,
                                isSelected: isSelected,
                                onSelect: () => controller.selectSlot(slot.id),
                                onBypassToggle: () => controller.toggleBypass(slot.id),
                                onDelete: () => controller.removeEffect(slot.id),
                                onMoveUp: index > 0
                                    ? () => _reorderSlot(controller, chain, slot, -1)
                                    : null,
                                onMoveDown: index < chain.slots.length - 1
                                    ? () => _reorderSlot(controller, chain, slot, 1)
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ),
              // Right: Selected Slot Parameters Editor
              Expanded(
                flex: 6,
                child: state.selectedSlot != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(PremiumSpacing.md),
                        child: AudioEffectSlotEditor(
                          slot: state.selectedSlot!,
                          onChanged: controller.updateSlot,
                        ),
                      )
                    : const Center(
                        child: Text(
                          'Select an effect to edit parameters.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCard({
    required BuildContext context,
    required NleAudioEffectSlot slot,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onBypassToggle,
    required VoidCallback onDelete,
    required VoidCallback? onMoveUp,
    required VoidCallback? onMoveDown,
  }) {
    final active = slot.active;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PremiumSpacing.md,
          vertical: PremiumSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.surfaceElevated
              : AppTheme.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(PremiumRadius.sm),
          border: Border.all(
            color: isSelected ? AppTheme.accentPrimary : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Bypass Switch (checkbox style)
            Checkbox(
              value: active,
              onChanged: (_) => onBypassToggle(),
              activeColor: AppTheme.accentPrimary,
            ),
            const SizedBox(width: 4),
            // Effect Icon
            Icon(
              _effectIcon(slot.type),
              color: active ? AppTheme.accentPrimary : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            // Effect Label
            Expanded(
              child: Opacity(
                opacity: active ? 1.0 : 0.4,
                child: Text(
                  slot.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Re-order triggers
            if (onMoveUp != null)
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onMoveUp,
              ),
            if (onMoveDown != null)
              IconButton(
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onMoveDown,
              ),
            const SizedBox(width: 4),
            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  void _reorderSlot(
    AudioEffectController controller,
    NleAudioEffectChain chain,
    NleAudioEffectSlot slot,
    int shift,
  ) async {
    final slots = chain.orderedSlots;
    final index = slots.indexWhere((s) => s.id == slot.id);
    if (index == -1) return;

    final targetIndex = index + shift;
    if (targetIndex < 0 || targetIndex >= slots.length) return;

    // Swap order values
    final a = slots[index];
    final b = slots[targetIndex];

    final updatedA = a.copyWith(order: b.order);
    final updatedB = b.copyWith(order: a.order);

    // Save both
    var nextChain = chain.copyWith(
      slots: chain.slots.map((s) {
        if (s.id == updatedA.id) return updatedA;
        if (s.id == updatedB.id) return updatedB;
        return s;
      }).toList(),
    );

    await controller.repository.saveChain(nextChain);
    await controller.load();
  }

  void _showAddEffectSheet(BuildContext context, AudioEffectController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(PremiumSpacing.lg),
                child: Text(
                  'Add Audio Effect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: NleAudioEffectType.values.map((type) {
                    return ListTile(
                      leading: Icon(_effectIcon(type), color: AppTheme.accentPrimary),
                      title: Text(_effectTypeName(type)),
                      onTap: () {
                        controller.addEffect(type);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _title(NleAudioEffectRackOwnerType type) {
    switch (type) {
      case NleAudioEffectRackOwnerType.clip:
        return 'Clip Effect Rack';
      case NleAudioEffectRackOwnerType.track:
        return 'Track Effect Rack';
      case NleAudioEffectRackOwnerType.master:
        return 'Master Output Rack';
    }
  }

  String _presetName(NleAudioEffectChainPresetId preset) {
    switch (preset) {
      case NleAudioEffectChainPresetId.cleanVoice:
        return 'Clean Voice';
      case NleAudioEffectChainPresetId.podcastVoice:
        return 'Podcast Voice';
      case NleAudioEffectChainPresetId.warmMusic:
        return 'Warm Music';
      case NleAudioEffectChainPresetId.loudSocial:
        return 'Loud Social Master';
      case NleAudioEffectChainPresetId.noisyRoomCleanup:
        return 'Noisy Room Cleanup';
      case NleAudioEffectChainPresetId.cinematicSpace:
        return 'Cinematic Space';
    }
  }

  String _effectTypeName(NleAudioEffectType type) {
    switch (type) {
      case NleAudioEffectType.eq3Band:
        return '3-Band Equalizer (EQ)';
      case NleAudioEffectType.compressor:
        return 'Dynamics Compressor';
      case NleAudioEffectType.limiter:
        return 'Ceiling Limiter';
      case NleAudioEffectType.noiseGate:
        return 'Noise Gate Threshold';
      case NleAudioEffectType.noiseReduction:
        return 'Background Noise Reduction';
      case NleAudioEffectType.reverb:
        return 'Reverberation Reverb';
      case NleAudioEffectType.pitchTempo:
        return 'Pitch / Tempo Modifier';
      case NleAudioEffectType.voiceEnhancer:
        return 'Creative Voice Enhancer';
    }
  }

  IconData _effectIcon(NleAudioEffectType type) {
    switch (type) {
      case NleAudioEffectType.eq3Band:
        return Icons.equalizer_rounded;
      case NleAudioEffectType.compressor:
        return Icons.compress_rounded;
      case NleAudioEffectType.limiter:
        return Icons.vertical_align_top_rounded;
      case NleAudioEffectType.noiseGate:
        return Icons.volume_off_rounded;
      case NleAudioEffectType.noiseReduction:
        return Icons.waves_rounded;
      case NleAudioEffectType.reverb:
        return Icons.surround_sound_rounded;
      case NleAudioEffectType.pitchTempo:
        return Icons.speed_rounded;
      case NleAudioEffectType.voiceEnhancer:
        return Icons.record_voice_over_rounded;
    }
  }
}
