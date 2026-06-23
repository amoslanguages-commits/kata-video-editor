import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';

class TimelineSnapPoint {
  final int micros;
  final String reason;

  const TimelineSnapPoint({
    required this.micros,
    required this.reason,
  });
}

class MultitrackTimelineUiState {
  final TimelineScale scale;
  final int playheadMicros;
  final String? selectedClipId;
  final String? selectedTrackId;
  final bool snappingEnabled;
  final TimelineSnapPoint? activeSnapPoint;
  final double horizontalScrollPx;
  final double verticalScrollPx;
  final bool showWaveforms;
  final bool showThumbnails;
  final bool compactTracks;

  const MultitrackTimelineUiState({
    required this.scale,
    required this.playheadMicros,
    this.selectedClipId,
    this.selectedTrackId,
    this.snappingEnabled = true,
    this.activeSnapPoint,
    this.horizontalScrollPx = 0,
    this.verticalScrollPx = 0,
    this.showWaveforms = true,
    this.showThumbnails = true,
    this.compactTracks = false,
  });

  factory MultitrackTimelineUiState.initial() {
    return const MultitrackTimelineUiState(
      scale: TimelineScale.normal,
      playheadMicros: 0,
    );
  }

  MultitrackTimelineUiState copyWith({
    TimelineScale? scale,
    int? playheadMicros,
    String? selectedClipId,
    String? selectedTrackId,
    bool clearSelectedClip = false,
    bool? snappingEnabled,
    TimelineSnapPoint? activeSnapPoint,
    bool clearSnap = false,
    double? horizontalScrollPx,
    double? verticalScrollPx,
    bool? showWaveforms,
    bool? showThumbnails,
    bool? compactTracks,
  }) {
    return MultitrackTimelineUiState(
      scale: scale ?? this.scale,
      playheadMicros: playheadMicros ?? this.playheadMicros,
      selectedClipId:
          clearSelectedClip ? null : selectedClipId ?? this.selectedClipId,
      selectedTrackId: selectedTrackId ?? this.selectedTrackId,
      snappingEnabled: snappingEnabled ?? this.snappingEnabled,
      activeSnapPoint: clearSnap ? null : activeSnapPoint ?? this.activeSnapPoint,
      horizontalScrollPx: horizontalScrollPx ?? this.horizontalScrollPx,
      verticalScrollPx: verticalScrollPx ?? this.verticalScrollPx,
      showWaveforms: showWaveforms ?? this.showWaveforms,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      compactTracks: compactTracks ?? this.compactTracks,
    );
  }
}

class MultitrackTimelineController
    extends StateNotifier<MultitrackTimelineUiState> {
  MultitrackTimelineController() : super(MultitrackTimelineUiState.initial());

  void setPlayheadFromPx(double px) {
    state = state.copyWith(
      playheadMicros: math.max(0, state.scale.pxToMicros(px)),
    );
  }

  void setPlayheadMicros(int micros) {
    state = state.copyWith(playheadMicros: math.max(0, micros));
  }

  void zoomBy(double factor) {
    state = state.copyWith(scale: state.scale.zoomBy(factor));
  }

  /// Directly sets the scale (used by pinch-zoom + anchored zoom helpers).
  void setScale(TimelineScale scale) {
    state = state.copyWith(scale: scale);
  }

  /// Clamps [pixelsPerSecond] to the valid range before applying.
  void zoomToPixelsPerSecond(double pixelsPerSecond) {
    state = state.copyWith(
      scale: TimelineScale(
        pixelsPerSecond: pixelsPerSecond.clamp(
          TimelineScale.min.pixelsPerSecond,
          TimelineScale.max.pixelsPerSecond,
        ),
      ),
    );
  }

  /// Zooms around a fixed timeline position so the anchor stays visually
  /// stable.  Use [setScale] + scroll correction to keep the view centred.
  void zoomAroundTimelineMicros({
    required int anchorMicros,
    required double factor,
  }) {
    state = state.copyWith(
      scale: state.scale.zoomBy(factor),
    );
  }

  void setSnappingEnabled(bool enabled) {
    state = state.copyWith(snappingEnabled: enabled);
  }

  void toggleSnappingEnabled() {
    state = state.copyWith(snappingEnabled: !state.snappingEnabled);
  }

  void selectClip(String clipId) {
    state = state.copyWith(selectedClipId: clipId);
  }

  void selectTrack(String trackId) {
    state = state.copyWith(selectedTrackId: trackId);
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedClip: true);
  }

  void setScroll({
    double? horizontal,
    double? vertical,
  }) {
    state = state.copyWith(
      horizontalScrollPx: horizontal,
      verticalScrollPx: vertical,
    );
  }

  void setActiveSnap(TimelineSnapPoint? snap) {
    state = state.copyWith(
      activeSnapPoint: snap,
      clearSnap: snap == null,
    );
  }

  void toggleWaveforms() {
    state = state.copyWith(showWaveforms: !state.showWaveforms);
  }

  void toggleThumbnails() {
    state = state.copyWith(showThumbnails: !state.showThumbnails);
  }

  void toggleCompactTracks() {
    state = state.copyWith(compactTracks: !state.compactTracks);
  }
}
