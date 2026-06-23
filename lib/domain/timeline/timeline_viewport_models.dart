import 'dart:math' as math;

import 'package:nle_editor/domain/timeline/multitrack_models.dart';

/// Represents the current visible window of the timeline, accounting for
/// scroll position, viewport size, and overscan pixels.
class TimelineVisibleWindow {
  final double horizontalScrollPx;
  final double verticalScrollPx;
  final double viewportWidthPx;
  final double viewportHeightPx;
  final double overscanPx;
  final TimelineScale scale;

  const TimelineVisibleWindow({
    required this.horizontalScrollPx,
    required this.verticalScrollPx,
    required this.viewportWidthPx,
    required this.viewportHeightPx,
    required this.scale,
    this.overscanPx = 420,
  });

  /// First visible pixel in timeline content space (with overscan, clamped ≥ 0).
  double get startPx => math.max(0, horizontalScrollPx - overscanPx);

  /// Last visible pixel in timeline content space (with overscan).
  double get endPx => horizontalScrollPx + viewportWidthPx + overscanPx;

  /// First visible timeline position in microseconds (≥ 0).
  int get startMicros => math.max(0, scale.pxToMicros(startPx));

  /// Last visible timeline position in microseconds.
  int get endMicros => math.max(startMicros, scale.pxToMicros(endPx));

  /// First visible vertical pixel (with overscan, clamped ≥ 0).
  double get verticalStartPx => math.max(0, verticalScrollPx - overscanPx);

  /// Last visible vertical pixel (with overscan).
  double get verticalEndPx => verticalScrollPx + viewportHeightPx + overscanPx;

  /// Whether a clip's horizontal span intersects the visible window.
  bool clipIsHorizontallyVisible(MultitrackClip clip) {
    return clip.timelineEndMicros >= startMicros &&
        clip.timelineStartMicros <= endMicros;
  }

  /// Whether a track's vertical span intersects the visible window.
  bool trackIsVerticallyVisible({
    required double top,
    required double height,
  }) {
    final bottom = top + height;
    return bottom >= verticalStartPx && top <= verticalEndPx;
  }
}

/// Computed layout entry for a single track row.
class TimelineTrackLayoutEntry {
  final MultitrackTrack track;

  /// Vertical offset from the top of the tracks container in pixels.
  final double top;

  /// Row height in pixels.
  final double height;

  /// Visual stacking index (0 = top-most track).
  final int visualIndex;

  const TimelineTrackLayoutEntry({
    required this.track,
    required this.top,
    required this.height,
    required this.visualIndex,
  });

  /// Bottom edge = top + height.
  double get bottom => top + height;

  /// True when this entry's vertical span intersects [window].
  bool visibleIn(TimelineVisibleWindow window) {
    return window.trackIsVerticallyVisible(
      top: top,
      height: height,
    );
  }
}

/// Computed layout entry for a single clip within its track row.
class TimelineClipLayoutEntry {
  final MultitrackClip clip;
  final MultitrackTrack track;

  /// Horizontal offset from the left edge of the timeline content area.
  final double left;

  /// Width of the clip in pixels (minimum 12).
  final double width;

  /// Vertical offset from the top of the tracks container.
  final double top;

  /// Height of the clip rect inside its track.
  final double height;

  const TimelineClipLayoutEntry({
    required this.clip,
    required this.track,
    required this.left,
    required this.width,
    required this.top,
    required this.height,
  });

  /// Right edge = left + width.
  double get right => left + width;
}
