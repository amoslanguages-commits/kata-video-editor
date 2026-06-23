// 33B-PRO: Advanced Audio Automation — Controller
//
// Manages the editor-side automation state for a single clip or track:
// keyframe add/move/delete, write-mode changes, ducking updates, and effect
// slot toggling. Uses the shared 32E [KeyframeEditingTools].

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/audio_automation_repository.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_models.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_value_models.dart';
import 'package:nle_editor/domain/audio_automation/audio_effect_slot_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_editing_tools.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

// ── Editor State ──────────────────────────────────────────────────────────────

class AudioAutomationEditorState {
  final bool loading;
  final NleAudioAutomationState? automation;
  final String? selectedPropertyId;
  final String? selectedKeyframeId;
  final String? error;

  const AudioAutomationEditorState({
    required this.loading,
    this.automation,
    this.selectedPropertyId,
    this.selectedKeyframeId,
    this.error,
  });

  const AudioAutomationEditorState.initial()
      : loading = false,
        automation = null,
        selectedPropertyId = null,
        selectedKeyframeId = null,
        error = null;

  NleAnimatableProperty? get selectedProperty {
    final current = automation;
    if (current == null || selectedPropertyId == null) return null;
    return current.keyframeTrack.properties
        .where((p) => p.id == selectedPropertyId)
        .firstOrNull;
  }

  AudioAutomationEditorState copyWith({
    bool? loading,
    NleAudioAutomationState? automation,
    String? selectedPropertyId,
    String? selectedKeyframeId,
    String? error,
    bool clearError = false,
  }) {
    return AudioAutomationEditorState(
      loading: loading ?? this.loading,
      automation: automation ?? this.automation,
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      selectedKeyframeId: selectedKeyframeId ?? this.selectedKeyframeId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class AudioAutomationController
    extends StateNotifier<AudioAutomationEditorState> {
  final String ownerId;
  final NleAudioAutomationOwnerType ownerType;
  final int durationMicros;
  final AudioAutomationRepository repository;
  final KeyframeEditingTools tools;

  AudioAutomationController({
    required this.ownerId,
    required this.ownerType,
    required this.durationMicros,
    required this.repository,
    this.tools = const KeyframeEditingTools(),
  }) : super(const AudioAutomationEditorState.initial()) {
    load();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final automation = ownerType == NleAudioAutomationOwnerType.clip
          ? await repository.getClipAutomation(
              clipId: ownerId,
              clipDurationMicros: durationMicros,
            )
          : await repository.getTrackAutomation(trackId: ownerId);

      state = state.copyWith(
        loading: false,
        automation: automation,
        selectedPropertyId: automation.keyframeTrack.properties.isNotEmpty
            ? automation.keyframeTrack.properties.first.id
            : null,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ── Property Selection ────────────────────────────────────────────────────

  void selectProperty(String propertyId) {
    state = state.copyWith(
      selectedPropertyId: propertyId,
      selectedKeyframeId: null,
    );
  }

  void selectKeyframe(String keyframeId) {
    state = state.copyWith(selectedKeyframeId: keyframeId);
  }

  // ── Keyframe Operations ───────────────────────────────────────────────────

  Future<void> addKeyframe({
    required int timeMicros,
    required double value,
  }) async {
    final automation = state.automation;
    final property = state.selectedProperty;
    if (automation == null || property == null) return;

    final updated = tools.addKeyframe(
      property: property,
      timeOffsetMicros: timeMicros,
      value: NleKeyframeValue.number(value),
      interpolation: NleKeyframeInterpolation.easeInOut,
    );

    await _replaceProperty(automation: automation, property: updated);
  }

  Future<void> moveKeyframe({
    required String keyframeId,
    required int timeMicros,
  }) async {
    final automation = state.automation;
    final property = state.selectedProperty;
    if (automation == null || property == null) return;

    final updated = tools.moveKeyframe(
      property: property,
      keyframeId: keyframeId,
      timeOffsetMicros: timeMicros,
      clipDurationMicros: durationMicros,
    );

    await _replaceProperty(automation: automation, property: updated);
  }

  Future<void> updateKeyframeValue({
    required String keyframeId,
    required double value,
  }) async {
    final automation = state.automation;
    final property = state.selectedProperty;
    if (automation == null || property == null) return;

    final updated = tools.updateKeyframeValue(
      property: property,
      keyframeId: keyframeId,
      value: NleKeyframeValue.number(value),
    );

    await _replaceProperty(automation: automation, property: updated);
  }

  Future<void> setKeyframeInterpolation({
    required String keyframeId,
    required NleKeyframeInterpolation interpolation,
  }) async {
    final automation = state.automation;
    final property = state.selectedProperty;
    if (automation == null || property == null) return;

    final updated = tools.setInterpolation(
      property: property,
      keyframeId: keyframeId,
      interpolation: interpolation,
    );

    await _replaceProperty(automation: automation, property: updated);
  }

  Future<void> deleteKeyframe(String keyframeId) async {
    final automation = state.automation;
    final property = state.selectedProperty;
    if (automation == null || property == null) return;

    final updated = tools.removeKeyframe(
      property: property,
      keyframeId: keyframeId,
    );

    await _replaceProperty(automation: automation, property: updated);
    state = state.copyWith(selectedKeyframeId: null);
  }

  // ── Ducking ───────────────────────────────────────────────────────────────

  Future<void> updateDucking(NleAudioDuckingSettings ducking) async {
    final automation = state.automation;
    if (automation == null) return;
    await _saveAutomation(automation.copyWith(ducking: ducking));
  }

  // ── Write Mode ────────────────────────────────────────────────────────────

  Future<void> setWriteMode(NleAudioAutomationWriteMode mode) async {
    final automation = state.automation;
    if (automation == null) return;
    await _saveAutomation(automation.copyWith(writeMode: mode));
  }

  // ── Effect Slots ──────────────────────────────────────────────────────────

  Future<void> toggleEffectSlot(String slotId) async {
    final automation = state.automation;
    if (automation == null) return;

    final slots = automation.effectSlots.map((slot) {
      if (slot.id != slotId) return slot;
      return slot.copyWith(
        bypassMode: slot.active
            ? NleAudioEffectSlotBypassMode.bypassed
            : NleAudioEffectSlotBypassMode.active,
      );
    }).toList();

    await _saveAutomation(automation.copyWith(effectSlots: slots));
  }

  Future<void> updateEffectSlot(NleAudioEffectSlot slot) async {
    final automation = state.automation;
    if (automation == null) return;

    final slots = automation.effectSlots.map((s) {
      return s.id == slot.id ? slot : s;
    }).toList();

    await _saveAutomation(automation.copyWith(effectSlots: slots));
  }

  Future<void> addEffectSlot(NleAudioEffectSlot slot) async {
    final automation = state.automation;
    if (automation == null) return;

    final slots = [...automation.effectSlots, slot]
      ..sort((a, b) => a.order.compareTo(b.order));

    await _saveAutomation(automation.copyWith(effectSlots: slots));
  }

  Future<void> removeEffectSlot(String slotId) async {
    final automation = state.automation;
    if (automation == null) return;

    final slots = automation.effectSlots
        .where((s) => s.id != slotId)
        .toList();

    await _saveAutomation(automation.copyWith(effectSlots: slots));
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _replaceProperty({
    required NleAudioAutomationState automation,
    required NleAnimatableProperty property,
  }) async {
    final properties = automation.keyframeTrack.properties
        .map((p) => p.id == property.id ? property : p)
        .toList();

    final track = automation.keyframeTrack.copyWith(properties: properties);
    await _saveAutomation(automation.copyWith(keyframeTrack: track));
  }

  Future<void> _saveAutomation(NleAudioAutomationState automation) async {
    state = state.copyWith(automation: automation, clearError: true);

    if (automation.ownerType == NleAudioAutomationOwnerType.clip) {
      await repository.saveClipAutomation(automation);
    } else {
      await repository.saveTrackAutomation(automation);
    }
  }
}
