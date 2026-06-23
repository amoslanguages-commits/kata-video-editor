import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/audio_effect_repository.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_chain_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_preset_factory.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';

class AudioEffectRackState {
  final bool loading;
  final NleAudioEffectChain? chain;
  final String? selectedSlotId;
  final String? error;

  const AudioEffectRackState({
    required this.loading,
    this.chain,
    this.selectedSlotId,
    this.error,
  });

  const AudioEffectRackState.initial()
      : loading = false,
        chain = null,
        selectedSlotId = null,
        error = null;

  NleAudioEffectSlot? get selectedSlot {
    final current = chain;
    if (current == null || selectedSlotId == null) return null;

    return current.slots.where((slot) => slot.id == selectedSlotId).firstOrNull;
  }

  AudioEffectRackState copyWith({
    bool? loading,
    NleAudioEffectChain? chain,
    String? selectedSlotId,
    String? error,
    bool clearError = false,
  }) {
    return AudioEffectRackState(
      loading: loading ?? this.loading,
      chain: chain ?? this.chain,
      selectedSlotId: selectedSlotId ?? this.selectedSlotId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AudioEffectController extends StateNotifier<AudioEffectRackState> {
  final String ownerId;
  final NleAudioEffectRackOwnerType ownerType;
  final AudioEffectRepository repository;

  AudioEffectController({
    required this.ownerId,
    required this.ownerType,
    required this.repository,
  }) : super(const AudioEffectRackState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final chain = await _loadChain();

      state = state.copyWith(
        loading: false,
        chain: chain,
        selectedSlotId: chain.slots.isNotEmpty ? chain.slots.first.id : null,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> addEffect(NleAudioEffectType type) async {
    final chain = state.chain;
    if (chain == null) return;

    final next = await repository.addSlot(
      chain: chain,
      type: type,
    );

    state = state.copyWith(
      chain: next,
      selectedSlotId: next.slots.last.id,
      clearError: true,
    );
  }

  Future<void> removeEffect(String slotId) async {
    final chain = state.chain;
    if (chain == null) return;

    final next = await repository.removeSlot(
      chain: chain,
      slotId: slotId,
    );

    state = state.copyWith(
      chain: next,
      selectedSlotId: next.slots.isNotEmpty ? next.slots.first.id : null,
      clearError: true,
    );
  }

  Future<void> updateSlot(NleAudioEffectSlot slot) async {
    final chain = state.chain;
    if (chain == null) return;

    final next = await repository.updateSlot(
      chain: chain,
      slot: slot,
    );

    state = state.copyWith(
      chain: next,
      selectedSlotId: slot.id,
      clearError: true,
    );
  }

  Future<void> toggleBypass(String slotId) async {
    final slot = state.chain?.slots.where((s) => s.id == slotId).firstOrNull;
    if (slot == null) return;

    final nextBypass = slot.active
        ? NleAudioEffectBypassMode.bypassed
        : NleAudioEffectBypassMode.active;

    await updateSlot(slot.copyWith(bypassMode: nextBypass));
  }

  Future<void> applyPreset(NleAudioEffectChainPresetId preset) async {
    final chain = state.chain;
    if (chain == null) return;

    final next = await repository.applyPreset(
      chain: chain,
      preset: preset,
    );

    state = state.copyWith(
      chain: next,
      selectedSlotId: next.slots.isNotEmpty ? next.slots.first.id : null,
      clearError: true,
    );
  }

  void selectSlot(String slotId) {
    state = state.copyWith(selectedSlotId: slotId);
  }

  Future<NleAudioEffectChain> _loadChain() {
    switch (ownerType) {
      case NleAudioEffectRackOwnerType.clip:
        return repository.getClipChain(ownerId);

      case NleAudioEffectRackOwnerType.track:
        return repository.getTrackChain(ownerId);

      case NleAudioEffectRackOwnerType.master:
        return repository.getMasterChain(ownerId);
    }
  }
}
