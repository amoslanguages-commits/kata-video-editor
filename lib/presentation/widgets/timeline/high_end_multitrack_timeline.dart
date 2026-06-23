import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_clip_layout_cache.dart';
import 'package:nle_editor/domain/timeline/timeline_viewport_models.dart';
import 'package:nle_editor/domain/timeline/timeline_virtualization_engine.dart';
import 'package:nle_editor/presentation/controllers/multitrack_timeline_controller.dart';
import 'package:nle_editor/presentation/controllers/timeline_zoom_controller.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/providers/timeline_snap_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_clip_actions.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_performance_badge.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_playhead.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_ruler.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_snap_toggle.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_track_header.dart';
import 'package:nle_editor/presentation/widgets/timeline/virtualized_track_stack.dart';

/// High-end, pro-grade multitrack timeline widget.
///
/// 29B-5 additions over previous versions:
///   * Anchored zoom buttons (zoom around playhead).
///   * Pinch-to-zoom gesture (zoom around finger focal point).
///   * Virtualized clip + track rendering via [VirtualizedTrackStack].
///   * [TimelineClipLayoutCache] reduces per-frame geometry recalculations.
///   * [TimelinePerformanceBadge] debug overlay.
class HighEndMultitrackTimeline extends ConsumerStatefulWidget {
  final String projectId;
  final int durationMicros;
  final List<MultitrackTrack> tracks;
  final List<MultitrackClip> clips;
  final ValueChanged<int>? onSeek;
  final ValueChanged<String>? onClipSelected;
  final ValueChanged<String>? onTrackSelected;
  final Future<void> Function(String trackId, TrackControlAction action)?
      onTrackControl;

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
  final void Function(String clipId, Offset position)? onClipLongPress;

  const HighEndMultitrackTimeline({
    super.key,
    required this.projectId,
    required this.durationMicros,
    required this.tracks,
    required this.clips,
    this.onSeek,
    this.onClipSelected,
    this.onTrackSelected,
    this.onTrackControl,
    this.onClipMove,
    this.onClipTrimLeft,
    this.onClipTrimRight,
    this.onClipAction,
    this.onClipLongPress,
  });

  @override
  ConsumerState<HighEndMultitrackTimeline> createState() =>
      _HighEndMultitrackTimelineState();
}

class _HighEndMultitrackTimelineState
    extends ConsumerState<HighEndMultitrackTimeline> {
  // ──────────────────────────── Scroll controllers ────────────────────────────
  // Horizontal: ruler + lanes share one pair, kept in sync.
  late final ScrollController _horizontalRulerController;
  late final ScrollController _horizontalLanesController;
  // Vertical: headers + lanes share one pair, kept in sync.
  late final ScrollController _verticalHeadersController;
  late final ScrollController _verticalLanesController;

  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;

  // ──────────────────────────── Zoom state ────────────────────────────────────
  final _zoomController = const TimelineZoomController();
  double? _pinchStartPixelsPerSecond;
  double? _pinchAnchorViewportPx;

  // ──────────────────────────── Virtualization ────────────────────────────────
  final _virtualizationEngine = const TimelineVirtualizationEngine();
  final _clipLayoutCache = TimelineClipLayoutCache();

  // ──────────────────────────── Snapping ──────────────────────────────────────
  int? _lastSnapMicros;

  // ──────────────────────────── Layout constants ──────────────────────────────
  static const double _headerWidth = 140.0;
  static const double _rulerHeight = 36.0;
  static const double _toolbarHeight = 40.0;

  // ───────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _horizontalRulerController = ScrollController();
    _horizontalLanesController = ScrollController();
    _verticalHeadersController = ScrollController();
    _verticalLanesController = ScrollController();

    _horizontalRulerController.addListener(() {
      if (!_isSyncingHorizontal) {
        _isSyncingHorizontal = true;
        if (_horizontalLanesController.hasClients) {
          _horizontalLanesController.jumpTo(_horizontalRulerController.offset);
        }
        _isSyncingHorizontal = false;
      }
    });

    _horizontalLanesController.addListener(() {
      if (!_isSyncingHorizontal) {
        _isSyncingHorizontal = true;
        if (_horizontalRulerController.hasClients) {
          _horizontalRulerController.jumpTo(_horizontalLanesController.offset);
        }
        _isSyncingHorizontal = false;
      }
    });

    _verticalHeadersController.addListener(() {
      if (!_isSyncingVertical) {
        _isSyncingVertical = true;
        if (_verticalLanesController.hasClients) {
          _verticalLanesController.jumpTo(_verticalHeadersController.offset);
        }
        _isSyncingVertical = false;
      }
    });

    _verticalLanesController.addListener(() {
      if (!_isSyncingVertical) {
        _isSyncingVertical = true;
        if (_verticalHeadersController.hasClients) {
          _verticalHeadersController.jumpTo(_verticalLanesController.offset);
        }
        _isSyncingVertical = false;
      }
    });
  }

  @override
  void dispose() {
    _clipLayoutCache.clear();
    _horizontalRulerController.dispose();
    _horizontalLanesController.dispose();
    _verticalHeadersController.dispose();
    _verticalLanesController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Zoom helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// Zoom around the playhead position.
  Future<void> _zoomAroundPlayhead({required double factor}) async {
    final ui = ref.read(multitrackTimelineControllerProvider);
    final controller = ref.read(multitrackTimelineControllerProvider.notifier);

    final playheadContentPx = ui.scale.microsToPx(ui.playheadMicros);
    final scrollPx = _horizontalLanesController.hasClients
        ? _horizontalLanesController.offset
        : 0.0;
    final viewportAnchorPx = math.max(0.0, playheadContentPx - scrollPx);

    final result = _zoomController.zoomWithAnchor(
      currentScale: ui.scale,
      factor: factor,
      anchorViewportPx: viewportAnchorPx,
      currentScrollPx: scrollPx,
    );

    controller.setScale(result.nextScale);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomController.applyScrollCorrection(
        controller: _horizontalLanesController,
        nextScrollPx: result.nextScrollPx,
      );
    });
  }

  /// Zoom around a fixed viewport-space anchor pixel (e.g. pinch focal point).
  Future<void> _zoomAroundViewportAnchor({
    required double factor,
    required double viewportAnchorPx,
  }) async {
    final ui = ref.read(multitrackTimelineControllerProvider);
    final controller = ref.read(multitrackTimelineControllerProvider.notifier);

    final result = _zoomController.zoomWithAnchor(
      currentScale: ui.scale,
      factor: factor,
      anchorViewportPx: viewportAnchorPx,
      currentScrollPx: _horizontalLanesController.hasClients
          ? _horizontalLanesController.offset
          : 0.0,
    );

    controller.setScale(result.nextScale);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomController.applyScrollCorrection(
        controller: _horizontalLanesController,
        nextScrollPx: result.nextScrollPx,
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Snap helpers
  // ───────────────────────────────────────────────────────────────────────────

  void _handleSnapPreview(TimelineSnapPoint? snapPoint) {
    final controller = ref.read(multitrackTimelineControllerProvider.notifier);
    controller.setActiveSnap(snapPoint);

    if (snapPoint == null) {
      _lastSnapMicros = null;
      return;
    }

    if (_lastSnapMicros != snapPoint.micros) {
      _lastSnapMicros = snapPoint.micros;
      ref.read(hapticServiceProvider).selection();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(multitrackTimelineControllerProvider);
    final controller = ref.read(multitrackTimelineControllerProvider.notifier);

    final snapEngine = ref.read(timelineSnapEngineProvider);
    final snapSettings = ref.watch(timelineSnapSettingsProvider);
    final markers =
        ref.watch(timelineMarkerSnapPointsProvider(widget.projectId));

    // Sort tracks: visual tracks top (highest sortOrder first), then audio.
    final sortedTracks = List<MultitrackTrack>.from(widget.tracks)
      ..sort((a, b) {
        if (a.isVisual && b.isAudio) return -1;
        if (a.isAudio && b.isVisual) return 1;
        if (a.isVisual && b.isVisual) {
          return b.sortOrder.compareTo(a.sortOrder);
        }
        return a.sortOrder.compareTo(b.sortOrder);
      });

    // Pre-compute track layout so both headers and lanes use identical heights.
    final trackLayout = _virtualizationEngine.buildTrackLayout(
      tracks: sortedTracks,
      compactTracks: uiState.compactTracks,
    );
    final totalTrackHeight =
        _virtualizationEngine.totalTrackHeight(trackLayout);

    return LayoutBuilder(
      builder: (context, constraints) {
        final timelineViewportWidth = math.max(
          0.0,
          constraints.maxWidth - _headerWidth,
        );
        final timelineViewportHeight = math.max(
          0.0,
          constraints.maxHeight - _toolbarHeight - _rulerHeight,
        );

        final timelineWidth = math.max(
          timelineViewportWidth,
          uiState.scale.microsToPx(widget.durationMicros) + 240,
        );

        final hScroll = _horizontalLanesController.hasClients
            ? _horizontalLanesController.offset
            : 0.0;
        final vScroll = _verticalLanesController.hasClients
            ? _verticalLanesController.offset
            : 0.0;

        final visibleWindow = TimelineVisibleWindow(
          horizontalScrollPx: hScroll,
          verticalScrollPx: vScroll,
          viewportWidthPx: timelineViewportWidth,
          viewportHeightPx: timelineViewportHeight,
          scale: uiState.scale,
        );

        final visibleTracks = _virtualizationEngine.visibleTracks(
          entries: trackLayout,
          window: visibleWindow,
        );

        // Count visible clips for the performance badge.
        var visibleClipCount = 0;
        for (final entry in visibleTracks) {
          visibleClipCount += _virtualizationEngine
              .visibleClipsForTrack(
                track: entry.track,
                allClips: widget.clips,
                window: visibleWindow,
              )
              .length;
        }

        return Container(
          color: AppTheme.timelineBackground,
          child: Column(
            children: [
              // ── Toolbar ───────────────────────────────────────────────────
              _buildToolbar(
                controller: controller,
                uiState: uiState,
              ),

              // ── Ruler + main lanes ────────────────────────────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left: fixed track headers ─────────────────────────
                    SizedBox(
                      width: _headerWidth,
                      child: Column(
                        children: [
                          // Corner spacer aligned with ruler.
                          _buildCornerSpacer(),

                          // Vertically scrolling header list.
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _verticalHeadersController,
                              child: SizedBox(
                                height: totalTrackHeight,
                                child: Stack(
                                  children: [
                                    for (final entry in visibleTracks)
                                      Positioned(
                                        top: entry.top,
                                        left: 0,
                                        width: _headerWidth,
                                        height: entry.height,
                                        child: TimelineTrackHeader(
                                          track: entry.track,
                                          selected: uiState.selectedTrackId ==
                                              entry.track.id,
                                          onTap: () {
                                            controller
                                                .selectTrack(entry.track.id);
                                            widget.onTrackSelected
                                                ?.call(entry.track.id);
                                            ref
                                                .read(hapticServiceProvider)
                                                .selection();
                                          },
                                          onControl: (action) async {
                                            await widget.onTrackControl
                                                ?.call(entry.track.id, action);
                                            ref
                                                .read(hapticServiceProvider)
                                                .light();
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Right: ruler + scrollable lanes ───────────────────
                    Expanded(
                      child: Column(
                        children: [
                          // Ruler
                          SingleChildScrollView(
                            controller: _horizontalRulerController,
                            scrollDirection: Axis.horizontal,
                            child: TimelineRuler(
                              projectId: widget.projectId,
                              totalWidth: timelineWidth,
                              scale: uiState.scale,
                              durationMicros: widget.durationMicros,
                              onSeek: widget.onSeek,
                            ),
                          ),

                          // Lanes
                          Expanded(
                            child: Scrollbar(
                              controller: _horizontalLanesController,
                              child: SingleChildScrollView(
                                controller: _horizontalLanesController,
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: timelineWidth,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    // ── Pinch zoom ──────────────────────
                                    onScaleStart: (details) {
                                      _pinchStartPixelsPerSecond =
                                          uiState.scale.pixelsPerSecond;
                                      _pinchAnchorViewportPx =
                                          details.localFocalPoint.dx;
                                    },
                                    onScaleUpdate: (details) {
                                      final startPps =
                                          _pinchStartPixelsPerSecond;
                                      final anchor = _pinchAnchorViewportPx;
                                      if (startPps == null || anchor == null) {
                                        return;
                                      }
                                      // Ignore tiny two-finger pan jitter.
                                      if ((details.scale - 1.0).abs() < 0.015) {
                                        return;
                                      }

                                      final nextPps =
                                          (startPps * details.scale).clamp(
                                        TimelineScale.min.pixelsPerSecond,
                                        TimelineScale.max.pixelsPerSecond,
                                      );

                                      final currentPps = ref
                                          .read(
                                              multitrackTimelineControllerProvider)
                                          .scale
                                          .pixelsPerSecond;

                                      if ((nextPps - currentPps).abs() < 0.5) {
                                        return;
                                      }

                                      final factor = nextPps / currentPps;
                                      _zoomAroundViewportAnchor(
                                        factor: factor,
                                        viewportAnchorPx: anchor,
                                      );
                                    },
                                    onScaleEnd: (_) {
                                      _pinchStartPixelsPerSecond = null;
                                      _pinchAnchorViewportPx = null;
                                    },
                                    child: SingleChildScrollView(
                                      controller: _verticalLanesController,
                                      child: SizedBox(
                                        width: timelineWidth,
                                        height: totalTrackHeight,
                                        child: Stack(
                                          children: [
                                            // Virtualised clips + lanes.
                                            VirtualizedTrackStack(
                                              tracks: sortedTracks,
                                              clips: widget.clips,
                                              timelineWidth: timelineWidth,
                                              timelineScale: uiState.scale,
                                              ui: uiState,
                                              visibleWindow: visibleWindow,
                                              virtualizationEngine:
                                                  _virtualizationEngine,
                                              clipLayoutCache: _clipLayoutCache,
                                              snapEngine: snapEngine,
                                              snapSettings: snapSettings,
                                              markers: markers,
                                              onSnapPreview: _handleSnapPreview,
                                              onClipTap: (clipId) {
                                                controller.selectClip(clipId);
                                                widget.onClipSelected
                                                    ?.call(clipId);
                                                ref
                                                    .read(hapticServiceProvider)
                                                    .selection();
                                              },
                                              onClipMove: widget.onClipMove,
                                              onClipTrimLeft:
                                                  widget.onClipTrimLeft,
                                              onClipTrimRight:
                                                  widget.onClipTrimRight,
                                              onClipAction: widget.onClipAction,
                                              onClipLongPress: widget.onClipLongPress,
                                            ),

                                            // Cyan magnetic snap guide line.
                                            if (uiState.activeSnapPoint != null)
                                              Positioned(
                                                left: uiState.scale.microsToPx(
                                                      uiState.activeSnapPoint!
                                                          .micros,
                                                    ) -
                                                    1,
                                                top: 0,
                                                bottom: 0,
                                                width: 2,
                                                child: IgnorePointer(
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.cyanAccent,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.cyan,
                                                          blurRadius: 4,
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            // Playhead needle.
                                            TimelinePlayhead(
                                              playheadMicros:
                                                  uiState.playheadMicros,
                                              scale: uiState.scale,
                                              timelineHeight: totalTrackHeight,
                                            ),

                                            // Performance badge (bottom-right,
                                            // scrolls with content).
                                            Positioned(
                                              right: 12 + hScroll,
                                              bottom: 12 + vScroll,
                                              child: TimelinePerformanceBadge(
                                                totalTracks:
                                                    sortedTracks.length,
                                                visibleTracks:
                                                    visibleTracks.length,
                                                totalClips: widget.clips.length,
                                                visibleClips: visibleClipCount,
                                                pixelsPerSecond: uiState
                                                    .scale.pixelsPerSecond,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Sub-widget builders
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildToolbar({
    required MultitrackTimelineController controller,
    required MultitrackTimelineUiState uiState,
  }) {
    return Container(
      height: _toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.timelineBackground,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.grid_on_rounded,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Timeline',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // Snap toggle (tap = on/off, long press = settings sheet).
          const TimelineSnapToggle(),

          // Compact toggle.
          IconButton(
            icon: Icon(
              Icons.view_compact_rounded,
              size: 16,
              color: uiState.compactTracks
                  ? AppTheme.accentPrimary
                  : AppTheme.textSecondary,
            ),
            tooltip: 'Compact tracks',
            onPressed: () {
              controller.toggleCompactTracks();
              HapticFeedback.selectionClick();
            },
          ),

          // Waveform toggle.
          IconButton(
            icon: Icon(
              Icons.graphic_eq_rounded,
              size: 16,
              color: uiState.showWaveforms
                  ? AppTheme.accentPrimary
                  : AppTheme.textSecondary,
            ),
            tooltip: 'Waveforms',
            onPressed: () {
              controller.toggleWaveforms();
              HapticFeedback.selectionClick();
            },
          ),

          // Thumbnail toggle.
          IconButton(
            icon: Icon(
              Icons.photo_rounded,
              size: 16,
              color: uiState.showThumbnails
                  ? AppTheme.accentPrimary
                  : AppTheme.textSecondary,
            ),
            tooltip: 'Thumbnails',
            onPressed: () {
              controller.toggleThumbnails();
              HapticFeedback.selectionClick();
            },
          ),

          // Zoom out (anchor = playhead).
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded, size: 16),
            tooltip: 'Zoom out',
            onPressed: () {
              _zoomAroundPlayhead(factor: 0.8);
              HapticFeedback.selectionClick();
            },
          ),

          // Zoom level pill.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Text(
              '${uiState.scale.pixelsPerSecond.round()} px/s',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Zoom in (anchor = playhead).
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded, size: 16),
            tooltip: 'Zoom in',
            onPressed: () {
              _zoomAroundPlayhead(factor: 1.25);
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCornerSpacer() {
    return Container(
      width: _headerWidth,
      height: _rulerHeight,
      decoration: BoxDecoration(
        color: AppTheme.timelineBackground,
        border: Border(
          right: BorderSide(color: AppTheme.borderSubtle, width: 2),
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 12),
      child: const Text(
        'TRACKS',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
