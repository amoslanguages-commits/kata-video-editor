// lib/presentation/controllers/source_preview_controller.dart
//
// 29F: Controls the Source Preview monitor — loading assets, setting in/out
// points, playing, pausing, and inserting selections to the timeline.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/repositories/source_insert_repository.dart';
import 'package:nle_editor/domain/editor_history/editor_action_models.dart';
import 'package:nle_editor/domain/preview/preview_monitor.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/source_preview/source_preview_models.dart';
import 'package:nle_editor/domain/source_preview/source_preview_render_graph_builder.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_refresh_bridge.dart';
import 'package:nle_editor/native_bridge/native_preview_events.dart';
import 'package:nle_editor/native_bridge/native_true_preview_service.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';

class SourcePreviewController extends StateNotifier<SourcePreviewState> {
  final String projectId;
  final SourceInsertRepository insertRepository;
  final NativeTruePreviewService previewService;
  final SourcePreviewRenderGraphBuilder graphBuilder;
  final Ref ref;
  final db.AppDatabase database;
  final TimelineEditRefreshBridge refreshBridge;

  StreamSubscription<NativePreviewEvent>? _eventSub;

  SourcePreviewController({
    required this.projectId,
    required this.insertRepository,
    required this.previewService,
    required this.ref,
    required this.database,
    required this.refreshBridge,
    this.graphBuilder = const SourcePreviewRenderGraphBuilder(),
  }) : super(const SourcePreviewState.empty()) {
    _eventSub = previewService.events.listen(_handleEvent);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    previewService.disposePreview(monitor: PreviewMonitor.source);
    super.dispose();
  }

  // ── Asset loading ─────────────────────────────────────────────────────────

  Future<void> loadAsset(NleMediaAsset nleAsset) async {
    final asset = SourcePreviewAsset(
      id: nleAsset.id,
      projectId: nleAsset.projectId,
      name: nleAsset.displayName,
      assetType: nleAsset.type.name,
      originalPath: nleAsset.originalPath,
      proxyPath: nleAsset.proxyPath,
      thumbnailPath: nleAsset.thumbnailPath,
      durationMicros: nleAsset.timecodeInfo.durationMicros,
      width: nleAsset.videoInfo.width,
      height: nleAsset.videoInfo.height,
      hasVideo: nleAsset.videoInfo.width > 0 || nleAsset.type == NleMediaAssetType.video,
      hasAudio: nleAsset.audioInfo.sampleRate > 0 || nleAsset.type == NleMediaAssetType.audio,
    );

    final outPoint = asset.durationMicros > 0 ? asset.durationMicros : 1;

    state = SourcePreviewState(
      asset: asset,
      playheadMicros: 0,
      inPointMicros: 0,
      outPointMicros: outPoint,
      isPlaying: false,
    );

    await _prepareAndRender();
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  Future<void> renderFrame(int micros) async {
    if (state.asset == null) return;
    final safe = micros.clamp(0, state.selectedDurationMicros);
    state = state.copyWith(playheadMicros: safe, isPlaying: false);
    await previewService.renderFrame(
      monitor: PreviewMonitor.source,
      timelineTimeMicros: safe,
    );
  }

  Future<void> play() async {
    if (state.asset == null) return;
    state = state.copyWith(isPlaying: true);
    await previewService.play(
      monitor: PreviewMonitor.source,
      fromTimelineTimeMicros: state.playheadMicros,
    );
  }

  Future<void> pause() async {
    state = state.copyWith(isPlaying: false);
    await previewService.pause(monitor: PreviewMonitor.source);
  }

  // ── In / Out points ───────────────────────────────────────────────────────

  Future<void> markIn() async {
    final asset = state.asset;
    if (asset == null) return;

    final newIn  = state.playheadMicros.clamp(0, asset.durationMicros);
    final newOut = state.outPointMicros.clamp(newIn + 1, asset.durationMicros);

    state = state.copyWith(
      inPointMicros:  newIn,
      outPointMicros: newOut,
      playheadMicros: 0,
    );

    await _prepareAndRender();
  }

  Future<void> markOut() async {
    final asset = state.asset;
    if (asset == null) return;

    final absolute = state.inPointMicros + state.playheadMicros;
    final newOut   = absolute.clamp(state.inPointMicros + 1, asset.durationMicros);

    state = state.copyWith(outPointMicros: newOut);
    await _prepareAndRender();
  }

  Future<void> clearInOut() async {
    final asset = state.asset;
    if (asset == null) return;

    state = state.copyWith(
      inPointMicros:  0,
      outPointMicros: asset.durationMicros,
      playheadMicros: 0,
    );

    await _prepareAndRender();
  }

  // ── Insert to timeline ────────────────────────────────────────────────────

  /// Inserts the current in/out selection to the timeline at [timelineStartMicros].
  /// Optionally targets [preferredTrackId].  Returns the new clip id.
  Future<String> insertToTimeline({
    required int timelineStartMicros,
    String? preferredTrackId,
  }) async {
    final asset = state.asset;
    if (asset == null) {
      throw const SourceInsertException('No source asset loaded.');
    }

    final newClipId = await insertRepository.insertSelectedRange(
      projectId:           projectId,
      asset:               asset,
      inPointMicros:       state.inPointMicros,
      outPointMicros:      state.outPointMicros,
      timelineStartMicros: timelineStartMicros,
      preferredTrackId:    preferredTrackId,
    );

    final after = await database.clipSnapshot(newClipId);

    ref.read(editorHistoryControllerProvider(projectId).notifier).record(
      type: EditorActionType.sourceInsert,
      label: 'Insert Clip',
      before: {},
      after: {
        'clip': after,
        'clipId': newClipId,
      },
    );

    await refreshBridge.refresh(
      projectId: projectId,
      reason: 'source_clip_inserted',
    );

    return newClipId;
  }

  // ── Event handling (source monitor only) ─────────────────────────────────

  void _handleEvent(NativePreviewEvent event) {
    if (event.monitor != PreviewMonitor.source) return;

    switch (event) {
      case PreviewTextureReadyEvent():
        state = state.copyWith(
          textureId:       event.textureId,
          isPreviewReady:  true,
        );
        break;

      case PreviewFrameRenderedEvent():
        state = state.copyWith(playheadMicros: event.timelineTimeMicros);
        break;

      case PreviewEndedEvent():
        state = state.copyWith(isPlaying: false);
        break;

      default:
        break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _prepareAndRender() async {
    final asset = state.asset;
    if (asset == null) return;

    final json = graphBuilder.buildJsonString(
      asset:          asset,
      inPointMicros:  state.inPointMicros,
      outPointMicros: state.outPointMicros,
    );

    await previewService.prepare(
      monitor:         PreviewMonitor.source,
      projectId:       'source_${asset.id}',
      renderGraphJson: json,
      qualityMode:     NativePreviewQualityMode.auto,
      preferProxy:     true,
      maxPreviewWidth: 960,
      maxPreviewHeight:540,
    );

    await previewService.renderFrame(
      monitor:            PreviewMonitor.source,
      timelineTimeMicros: state.playheadMicros,
    );
  }
}
