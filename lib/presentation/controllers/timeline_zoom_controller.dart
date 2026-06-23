import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';

/// Result of an anchored zoom operation.
class TimelineZoomResult {
  /// The new scale to apply.
  final TimelineScale nextScale;

  /// The corrected horizontal scroll offset that keeps the anchor visible.
  final double nextScrollPx;

  /// The timeline position (in microseconds) that was used as the anchor.
  final int anchorTimelineMicros;

  const TimelineZoomResult({
    required this.nextScale,
    required this.nextScrollPx,
    required this.anchorTimelineMicros,
  });
}

/// Stateless helper that computes anchored zoom so a viewport pixel (e.g. the
/// finger focal point or the playhead position) stays at the same screen
/// location after the zoom level changes.
class TimelineZoomController {
  const TimelineZoomController();

  /// Given a [factor] (>1 zooms in, <1 zooms out) and a [anchorViewportPx]
  /// (pixel offset within the visible track area), returns the new scale and
  /// the corrected horizontal scroll offset.
  TimelineZoomResult zoomWithAnchor({
    required TimelineScale currentScale,
    required double factor,
    required double anchorViewportPx,
    required double currentScrollPx,
  }) {
    // Convert the anchor screen position to a fixed timeline position.
    final anchorTimelineMicros =
        currentScale.pxToMicros(currentScrollPx + anchorViewportPx);

    // Apply zoom.
    final nextScale = currentScale.zoomBy(factor);

    // Compute where that timeline position now sits in content space.
    final newAnchorContentPx = nextScale.microsToPx(anchorTimelineMicros);

    // Scroll so the anchor appears at the same viewport pixel.
    final newScrollPx = math.max(0.0, newAnchorContentPx - anchorViewportPx);

    return TimelineZoomResult(
      nextScale: nextScale,
      nextScrollPx: newScrollPx,
      anchorTimelineMicros: anchorTimelineMicros,
    );
  }

  /// Applies the corrected scroll position to [controller].
  ///
  /// Must be called after the new scale has been applied and Flutter has had a
  /// chance to lay out the scrollable (use `addPostFrameCallback`).
  Future<void> applyScrollCorrection({
    required ScrollController controller,
    required double nextScrollPx,
  }) async {
    if (!controller.hasClients) return;

    final maxScroll = controller.position.maxScrollExtent;
    final clamped = nextScrollPx.clamp(0.0, maxScroll);
    controller.jumpTo(clamped);
  }
}
