// 33B-PRO: Advanced Audio Automation — Providers

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/audio_automation_repository.dart';
import 'package:nle_editor/domain/audio_automation/audio_automation_value_models.dart';
import 'package:nle_editor/presentation/controllers/audio_automation_controller.dart';
export 'package:nle_editor/presentation/controllers/audio_automation_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final audioAutomationRepositoryProvider =
    Provider<AudioAutomationRepository>((ref) {
  return AudioAutomationRepository(
    database: ref.watch(databaseProvider),
  );
});

// ── Controller Args ───────────────────────────────────────────────────────────

class AudioAutomationControllerArgs {
  final String ownerId;
  final NleAudioAutomationOwnerType ownerType;
  final int durationMicros;

  const AudioAutomationControllerArgs({
    required this.ownerId,
    required this.ownerType,
    required this.durationMicros,
  });

  @override
  bool operator ==(Object other) {
    return other is AudioAutomationControllerArgs &&
        other.ownerId == ownerId &&
        other.ownerType == ownerType &&
        other.durationMicros == durationMicros;
  }

  @override
  int get hashCode => Object.hash(ownerId, ownerType, durationMicros);
}

// ── Controller Provider ───────────────────────────────────────────────────────

final audioAutomationControllerProvider = StateNotifierProvider.family<
    AudioAutomationController,
    AudioAutomationEditorState,
    AudioAutomationControllerArgs>((ref, args) {
  return AudioAutomationController(
    ownerId: args.ownerId,
    ownerType: args.ownerType,
    durationMicros: args.durationMicros,
    repository: ref.watch(audioAutomationRepositoryProvider),
  );
});
