import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_viewport_models.dart';

/// Snapshot of which clips are currently visible, and the time range they cover.
///
/// This is a lightweight DTO used by future waveform / thumbnail lazy-loading
/// systems to know which clips need their media loaded, and what time range is
/// relevant.
class TimelineMediaVisibility {
  /// IDs of all clips whose horizontal span intersects the visible window.
  final List<String> visibleClipIds;

  /// Start of the visible timeline range in microseconds.
  final int startMicros;

  /// End of the visible timeline range in microseconds.
  final int endMicros;

  const TimelineMediaVisibility({
    required this.visibleClipIds,
    required this.startMicros,
    required this.endMicros,
  });
}

/// Resolves [TimelineMediaVisibility] from the current clip list and viewport.
///
/// This is a pure, stateless utility — call [resolve] whenever the scroll
/// position or zoom changes to get an up-to-date visibility snapshot.
class TimelineMediaVisibilityResolver {
  const TimelineMediaVisibilityResolver();

  TimelineMediaVisibility resolve({
    required List<MultitrackClip> clips,
    required TimelineVisibleWindow window,
  }) {
    final visibleIds = clips
        .where(window.clipIsHorizontallyVisible)
        .map((clip) => clip.id)
        .toList(growable: false);

    return TimelineMediaVisibility(
      visibleClipIds: visibleIds,
      startMicros: window.startMicros,
      endMicros: window.endMicros,
    );
  }
}
