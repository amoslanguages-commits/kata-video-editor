import 'package:nle_editor/data/database/app_database.dart';

class TimelineViewportWindow {
  final int startMicros;
  final int endMicros;
  final double pixelsPerSecond;
  final double scrollOffset;
  final double viewportWidth;

  const TimelineViewportWindow({
    required this.startMicros,
    required this.endMicros,
    required this.pixelsPerSecond,
    required this.scrollOffset,
    required this.viewportWidth,
  });

  bool clipVisible(Clip clip) {
    return clip.timelineEndMicros >= startMicros &&
        clip.timelineStartMicros <= endMicros;
  }
}

class TimelineViewportCalculator {
  static TimelineViewportWindow calculate({
    required double scrollOffset,
    required double viewportWidth,
    required double pixelsPerSecond,
    int overscanMicros = 3000000,
  }) {
    final startSeconds = scrollOffset / pixelsPerSecond;
    final visibleSeconds = viewportWidth / pixelsPerSecond;

    final startMicros =
        (startSeconds * 1000000).round() - overscanMicros;
    final endMicros =
        ((startSeconds + visibleSeconds) * 1000000).round() + overscanMicros;

    return TimelineViewportWindow(
      startMicros: startMicros.clamp(0, 1 << 62),
      endMicros: endMicros.clamp(0, 1 << 62),
      pixelsPerSecond: pixelsPerSecond,
      scrollOffset: scrollOffset,
      viewportWidth: viewportWidth,
    );
  }
}
