import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/data/repositories/transition_repository.dart';
import 'package:nle_editor/domain/transitions/transition_presets.dart';
import 'package:nle_editor/native_bridge/native_command_service.dart';

class TransitionCommandService {
  final TransitionRepository transitionRepository;
  final TimelineRepository timelineRepository;
  final NativeCommandService nativeCommandService;

  static const _uuid = Uuid();

  TransitionCommandService({
    required this.transitionRepository,
    required this.timelineRepository,
    required this.nativeCommandService,
  });

  Future<String> addOrUpdateTransition({
    required String projectId,
    required String outgoingClipId,
    required String incomingClipId,
    required String transitionType,
    required int durationMicros,
    String direction = 'center',
    String easing = 'ease_in_out',
    Map<String, dynamic>? parameters,
  }) async {
    final outgoing = await timelineRepository.getClip(outgoingClipId);
    final incoming = await timelineRepository.getClip(incomingClipId);

    if (outgoing == null || incoming == null) {
      throw StateError('Transition clips not found.');
    }

    if (outgoing.projectId != projectId || incoming.projectId != projectId) {
      throw StateError('Transition clips do not belong to this project.');
    }

    if (outgoing.trackId != incoming.trackId) {
      throw StateError('Transitions can only be added between clips on the same track.');
    }

    if (outgoing.timelineStartMicros > incoming.timelineStartMicros) {
      throw StateError('Outgoing clip must come before incoming clip.');
    }

    final safeDuration = _safeTransitionDuration(
      outgoing: outgoing,
      incoming: incoming,
      requestedDurationMicros: durationMicros,
    );

    final preset = TransitionPresets.byId(transitionType);

    final payload = {
      ...preset.defaultParameters,
      ...(parameters ?? {}),
    };

    final existing = await transitionRepository.getTransitionBetween(
      outgoingClipId: outgoingClipId,
      incomingClipId: incomingClipId,
    );

    final transitionId = existing?.id ?? _uuid.v4();

    if (existing == null) {
      await transitionRepository.insertTransition(
        ClipTransitionsCompanion.insert(
          id: transitionId,
          projectId: projectId,
          outgoingClipId: outgoingClipId,
          incomingClipId: incomingClipId,
          transitionType: Value(transitionType),
          durationMicros: Value(safeDuration),
          direction: Value(direction),
          easing: Value(easing),
          parametersJson: Value(jsonEncode(payload)),
          isPremium: Value(preset.isPremium),
        ),
      );
    } else {
      await transitionRepository.updateTransitionFields(
        existing.id,
        ClipTransitionsCompanion(
          transitionType: Value(transitionType),
          durationMicros: Value(safeDuration),
          direction: Value(direction),
          easing: Value(easing),
          parametersJson: Value(jsonEncode(payload)),
          isPremium: Value(preset.isPremium),
          isDisabled: const Value(false),
        ),
      );
    }

    await nativeCommandService.sendTransitionChanged(
      projectId: projectId,
      transitionId: transitionId,
      action: existing == null ? 'add_transition' : 'update_transition',
    );

    return transitionId;
  }

  Future<void> removeTransition({
    required String projectId,
    required String transitionId,
  }) async {
    await transitionRepository.deleteTransition(transitionId);

    await nativeCommandService.sendTransitionChanged(
      projectId: projectId,
      transitionId: transitionId,
      action: 'delete_transition',
    );
  }

  Future<void> disableTransition({
    required String projectId,
    required String transitionId,
    required bool disabled,
  }) async {
    await transitionRepository.updateTransitionFields(
      transitionId,
      ClipTransitionsCompanion(
        isDisabled: Value(disabled),
      ),
    );

    await nativeCommandService.sendTransitionChanged(
      projectId: projectId,
      transitionId: transitionId,
      action: disabled ? 'disable_transition' : 'enable_transition',
    );
  }

  int _safeTransitionDuration({
    required Clip outgoing,
    required Clip incoming,
    required int requestedDurationMicros,
  }) {
    const minDuration = 100000;
    const maxDuration = 3000000;

    final outgoingDuration = outgoing.timelineEndMicros - outgoing.timelineStartMicros;
    final incomingDuration = incoming.timelineEndMicros - incoming.timelineStartMicros;

    final shortestClip = outgoingDuration < incomingDuration ? outgoingDuration : incomingDuration;

    final maxSafe = (shortestClip * 0.45).round().clamp(minDuration, maxDuration);

    return requestedDurationMicros.clamp(minDuration, maxSafe);
  }
}
