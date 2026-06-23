import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/audio_effects/audio_effect_chain_models.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_preset_factory.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_slot_factory.dart';
import 'package:nle_editor/domain/audio_effects/audio_effect_value_models.dart';

class AudioEffectRepository {
  final db.AppDatabase database;
  final AudioEffectSlotFactory slotFactory;
  final AudioEffectPresetFactory presetFactory;

  const AudioEffectRepository({
    required this.database,
    this.slotFactory = const AudioEffectSlotFactory(),
    this.presetFactory = const AudioEffectPresetFactory(),
  });

  Future<NleAudioEffectChain> getClipChain(String clipId) async {
    final raw = await database.getClipEffectChainJson(clipId);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        return NleAudioEffectChain.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }

    return NleAudioEffectChain(
      ownerId: clipId,
      ownerType: NleAudioEffectRackOwnerType.clip,
      slots: const [],
      enabled: true,
      version: 1,
    );
  }

  Future<NleAudioEffectChain> getTrackChain(String trackId) async {
    final raw = await database.getTrackEffectChainJson(trackId);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        return NleAudioEffectChain.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }

    return NleAudioEffectChain(
      ownerId: trackId,
      ownerType: NleAudioEffectRackOwnerType.track,
      slots: const [],
      enabled: true,
      version: 1,
    );
  }

  Future<NleAudioEffectChain> getMasterChain(String projectId) async {
    final project = await database.getProject(projectId);
    final raw = project?.masterEffectChainJson;

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        return NleAudioEffectChain.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }

    return NleAudioEffectChain(
      ownerId: projectId,
      ownerType: NleAudioEffectRackOwnerType.master,
      slots: [
        slotFactory.create(type: NleAudioEffectType.limiter, order: 0),
      ],
      enabled: true,
      version: 1,
    );
  }

  Future<void> saveChain(NleAudioEffectChain chain) {
    switch (chain.ownerType) {
      case NleAudioEffectRackOwnerType.clip:
        return database.updateClipEffectChainJson(
          clipId: chain.ownerId,
          effectChainJson: jsonEncode(chain.toJson()),
        );

      case NleAudioEffectRackOwnerType.track:
        return database.updateTrackEffectChainJson(
          trackId: chain.ownerId,
          effectChainJson: jsonEncode(chain.toJson()),
        );

      case NleAudioEffectRackOwnerType.master:
        return database.updateProjectMasterEffectChainJson(
          projectId: chain.ownerId,
          masterEffectChainJson: jsonEncode(chain.toJson()),
        );
    }
  }

  Future<NleAudioEffectChain> addSlot({
    required NleAudioEffectChain chain,
    required NleAudioEffectType type,
  }) async {
    final nextOrder = chain.slots.isEmpty
        ? 0
        : chain.slots.map((slot) => slot.order).reduce((a, b) => a > b ? a : b) + 1;

    final slot = slotFactory.create(
      type: type,
      order: nextOrder,
    );

    final next = chain.copyWith(
      slots: [...chain.slots, slot],
    );

    await saveChain(next);
    return next;
  }

  Future<NleAudioEffectChain> removeSlot({
    required NleAudioEffectChain chain,
    required String slotId,
  }) async {
    final next = chain.copyWith(
      slots: chain.slots.where((slot) => slot.id != slotId).toList(),
    );

    await saveChain(next);
    return next;
  }

  Future<NleAudioEffectChain> updateSlot({
    required NleAudioEffectChain chain,
    required NleAudioEffectSlot slot,
  }) async {
    final next = chain.copyWith(
      slots: chain.slots.map((item) {
        return item.id == slot.id ? slot : item;
      }).toList(),
    );

    await saveChain(next);
    return next;
  }

  Future<NleAudioEffectChain> applyPreset({
    required NleAudioEffectChain chain,
    required NleAudioEffectChainPresetId preset,
  }) async {
    final next = presetFactory.createChainPreset(
      preset: preset,
      ownerId: chain.ownerId,
      ownerType: chain.ownerType,
    );

    await saveChain(next);
    return next;
  }
}
