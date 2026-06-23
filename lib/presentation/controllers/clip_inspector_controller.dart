import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/repositories/clip_inspector_repository.dart';
import 'package:nle_editor/domain/editor_history/editor_action_models.dart';
import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_refresh_bridge.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';

class ClipInspectorController {
  final String projectId;
  final ClipInspectorRepository repository;
  final TimelineEditRefreshBridge refreshBridge;
  final Ref ref;
  final db.AppDatabase database;

  Timer? _debounce;
  Map<String, dynamic>? _clipSnapshotBefore;

  ClipInspectorController({
    required this.projectId,
    required this.repository,
    required this.refreshBridge,
    required this.ref,
    required this.database,
  });

  void dispose() {
    _debounce?.cancel();
  }

  Future<void> _captureBeforeSnapshot(String clipId) async {
    if (_clipSnapshotBefore == null) {
      _clipSnapshotBefore = await database.clipSnapshot(clipId);
    }
  }

  Future<void> updateTransform({
    required String clipId,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    double? opacity,
  }) async {
    await _captureBeforeSnapshot(clipId);

    await repository.updateTransform(
      clipId: clipId,
      positionX: positionX,
      positionY: positionY,
      scale: scale,
      rotation: rotation,
      opacity: opacity,
    );

    _refreshDebounced(clipId: clipId, reason: 'clip_transform_changed');
  }

  Future<void> updateFitAndCrop({
    required String clipId,
    ClipFitMode? fitMode,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) async {
    await _captureBeforeSnapshot(clipId);

    await repository.updateFitAndCrop(
      clipId: clipId,
      fitMode: fitMode,
      cropLeft: cropLeft,
      cropTop: cropTop,
      cropRight: cropRight,
      cropBottom: cropBottom,
    );

    _refreshDebounced(clipId: clipId, reason: 'clip_crop_fit_changed');
  }

  Future<void> updateSpeed({
    required String clipId,
    required double speed,
  }) async {
    await _captureBeforeSnapshot(clipId);

    await repository.updateSpeed(
      clipId: clipId,
      speed: speed,
    );

    _refreshDebounced(clipId: clipId, reason: 'clip_speed_changed');
  }

  Future<void> updateAudio({
    required String clipId,
    double? volume,
    int? fadeInMicros,
    int? fadeOutMicros,
  }) async {
    await _captureBeforeSnapshot(clipId);

    await repository.updateAudio(
      clipId: clipId,
      volume: volume,
      fadeInMicros: fadeInMicros,
      fadeOutMicros: fadeOutMicros,
    );

    _refreshDebounced(clipId: clipId, reason: 'clip_audio_changed');
  }

  Future<void> updateColor({
    required String clipId,
    double? brightness,
    double? contrast,
    double? saturation,
    double? exposure,
    double? temperature,
    double? tint,
    double? highlights,
    double? shadows,
  }) async {
    await _captureBeforeSnapshot(clipId);

    await repository.updateColor(
      clipId: clipId,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      exposure: exposure,
      temperature: temperature,
      tint: tint,
      highlights: highlights,
      shadows: shadows,
    );

    _refreshDebounced(clipId: clipId, reason: 'clip_color_changed');
  }

  Future<void> updateText({
    required String clipId,
    String? textContent,
    String? textStyleJson,
    String? colorHex,
  }) async {
    await _captureBeforeSnapshot(clipId);

    await repository.updateText(
      clipId: clipId,
      textContent: textContent,
      textStyleJson: textStyleJson,
      colorHex: colorHex,
    );

    _refreshDebounced(clipId: clipId, reason: 'clip_text_changed');
  }

  Future<void> resetVisualAdjustments(String clipId) async {
    _debounce?.cancel();
    final before = await database.clipSnapshot(clipId);
    _clipSnapshotBefore = null;

    await repository.resetVisualAdjustments(clipId);

    final after = await database.clipSnapshot(clipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.updateClipInspector,
      label: 'Reset Clip Adjustments',
      before: {'clip': before},
      after: {'clip': after},
    );

    await _refreshNow('clip_visual_reset');
  }

  void _refreshDebounced({
    required String clipId,
    required String reason,
  }) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 120), () async {
      final before = _clipSnapshotBefore;
      _clipSnapshotBefore = null;
      final after = await database.clipSnapshot(clipId);
      if (before != null) {
        ref.read(editorHistoryControllerProvider(projectId).notifier).record(
          type: EditorActionType.updateClipInspector,
          label: 'Update Clip Properties',
          before: {'clip': before},
          after: {'clip': after},
        );
      }
      refreshBridge.refresh(
        projectId: projectId,
        reason: reason,
      );
    });
  }

  Future<void> _refreshNow(String reason) {
    _debounce?.cancel();

    return refreshBridge.refresh(
      projectId: projectId,
      reason: reason,
    );
  }
}
