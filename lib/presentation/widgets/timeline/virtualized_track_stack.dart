import 'package:flutter/material.dart';

import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_clip_layout_cache.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_engine.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_models.dart';
import 'package:nle_editor/domain/timeline/timeline_viewport_models.dart';
import 'package:nle_editor/domain/timeline/timeline_virtualization_engine.dart';
import 'package:nle_editor/presentation/controllers/multitrack_timeline_controller.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_clip_actions.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_clip_widget.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_track_lane.dart';

/// Virtualised track stack that only builds the track lanes and clip widgets
/// currently visible in [visibleWindow], drastically reducing widget count
/// when the timeline has 100+ clips.
class VirtualizedTrackStack extends StatelessWidget {
  final List<MultitrackTrack> tracks;
  final List<MultitrackClip> clips;
  final double timelineWidth;
  final TimelineScale timelineScale;
  final MultitrackTimelineUiState ui;
  final TimelineVisibleWindow visibleWindow;
  final TimelineVirtualizationEngine virtualizationEngine;
  final TimelineClipLayoutCache clipLayoutCache;

  // Optional snapping support (29B-4 compatible).
  final TimelineSnapEngine? snapEngine;
  final TimelineSnapSettings? snapSettings;
  final List<TimelineMarkerSnapPoint> markers;
  final ValueChanged<TimelineSnapPoint?>? onSnapPreview;

  // Clip interaction callbacks.
  final ValueChanged<String> onClipTap;
  final Function(String, Offset)? onClipLongPress;
  final Future<void> Function({
    required String clipId,
    required String? targetTrackId,
    required int deltaMicros,
  })? onClipMove;
  final Future<void> Function({
    required String clipId,
    required int deltaMicros,
  })? onClipTrimLeft;
  final Future<void> Function({
    required String clipId,
    required int deltaMicros,
  })? onClipTrimRight;
  final void Function(String clipId, TimelineClipAction action)? onClipAction;

  const VirtualizedTrackStack({
    super.key,
    required this.tracks,
    required this.clips,
    required this.timelineWidth,
    required this.timelineScale,
    required this.ui,
    required this.visibleWindow,
    required this.virtualizationEngine,
    required this.clipLayoutCache,
    required this.onClipTap,
    this.onClipLongPress,
    this.snapEngine,
    this.snapSettings,
    this.markers = const [],
    this.onSnapPreview,
    this.onClipMove,
    this.onClipTrimLeft,
    this.onClipTrimRight,
    this.onClipAction,
  });

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final trackLayout = virtualizationEngine.buildTrackLayout(
      tracks: tracks,
      compactTracks: ui.compactTracks,
    );

    final visible = virtualizationEngine.visibleTracks(
      entries: trackLayout,
      window: visibleWindow,
    );

    return Stack(
      children: [
        for (final trackEntry in visible)
          Positioned(
            top: trackEntry.top,
            left: 0,
            width: timelineWidth,
            height: trackEntry.height,
            child: RepaintBoundary(
              child: TimelineTrackLane(
                track: trackEntry.track,
                totalWidth: timelineWidth,
                child: Stack(
                  children: _buildVisibleClips(trackEntry),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Clip building
  // ---------------------------------------------------------------------------

  List<Widget> _buildVisibleClips(TimelineTrackLayoutEntry trackEntry) {
    final visibleClips = virtualizationEngine.visibleClipsForTrack(
      track: trackEntry.track,
      allClips: clips,
      window: visibleWindow,
    );

    return visibleClips.map((clip) {
      return TimelineClipWidget(
        key: ValueKey(clip.id),
        clip: clip,
        track: trackEntry.track,
        allTracks: tracks,
        scale: timelineScale,
        trackHeight: trackEntry.height,
        onSelected: (id) => onClipTap(id),
        onLongPress: onClipLongPress != null ? (id, pos) => onClipLongPress!(id, pos) : null,

        // Snap preview callbacks (29B-4).
        onMovePreviewDeltaPx: (deltaPx) {
          final result = _snapMove(clip: clip, deltaPx: deltaPx);
          onSnapPreview?.call(result?.toTimelineSnapPoint());
        },
        onTrimLeftPreviewDeltaPx: (deltaPx) {
          final result = _snapTrimLeft(clip: clip, deltaPx: deltaPx);
          onSnapPreview?.call(result?.toTimelineSnapPoint());
        },
        onTrimRightPreviewDeltaPx: (deltaPx) {
          final result = _snapTrimRight(clip: clip, deltaPx: deltaPx);
          onSnapPreview?.call(result?.toTimelineSnapPoint());
        },
        onDragPreviewEnd: () => onSnapPreview?.call(null),

        // Real DB write callbacks.
        onMoveDeltaPx: (deltaPx, targetTrackId) async {
          final result = _snapMove(clip: clip, deltaPx: deltaPx);
          onSnapPreview?.call(null);
          await onClipMove?.call(
            clipId: clip.id,
            targetTrackId: targetTrackId,
            deltaMicros:
                result?.snappedDeltaMicros ?? timelineScale.pxToMicros(deltaPx),
          );
        },
        onTrimLeftDeltaPx: (deltaPx) async {
          final result = _snapTrimLeft(clip: clip, deltaPx: deltaPx);
          onSnapPreview?.call(null);
          await onClipTrimLeft?.call(
            clipId: clip.id,
            deltaMicros:
                result?.snappedDeltaMicros ?? timelineScale.pxToMicros(deltaPx),
          );
        },
        onTrimRightDeltaPx: (deltaPx) async {
          final result = _snapTrimRight(clip: clip, deltaPx: deltaPx);
          onSnapPreview?.call(null);
          await onClipTrimRight?.call(
            clipId: clip.id,
            deltaMicros:
                result?.snappedDeltaMicros ?? timelineScale.pxToMicros(deltaPx),
          );
        },
        onAction: (clipId, action) => onClipAction?.call(clipId, action),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Snap helpers
  // ---------------------------------------------------------------------------

  TimelineSnapResult? _snapMove({
    required MultitrackClip clip,
    required double deltaPx,
  }) {
    final engine = snapEngine;
    final settings = snapSettings;
    if (engine == null || settings == null || !settings.enabled) return null;

    return engine.snapMove(
      clip: clip,
      deltaMicros: timelineScale.pxToMicros(deltaPx),
      scale: timelineScale,
      allClips: clips,
      playheadMicros: ui.playheadMicros,
      settings: settings,
      markers: markers,
    );
  }

  TimelineSnapResult? _snapTrimLeft({
    required MultitrackClip clip,
    required double deltaPx,
  }) {
    final engine = snapEngine;
    final settings = snapSettings;
    if (engine == null || settings == null || !settings.enabled) return null;

    return engine.snapTrimLeft(
      clip: clip,
      deltaMicros: timelineScale.pxToMicros(deltaPx),
      scale: timelineScale,
      allClips: clips,
      playheadMicros: ui.playheadMicros,
      settings: settings,
      markers: markers,
    );
  }

  TimelineSnapResult? _snapTrimRight({
    required MultitrackClip clip,
    required double deltaPx,
  }) {
    final engine = snapEngine;
    final settings = snapSettings;
    if (engine == null || settings == null || !settings.enabled) return null;

    return engine.snapTrimRight(
      clip: clip,
      deltaMicros: timelineScale.pxToMicros(deltaPx),
      scale: timelineScale,
      allClips: clips,
      playheadMicros: ui.playheadMicros,
      settings: settings,
      markers: markers,
    );
  }
}
