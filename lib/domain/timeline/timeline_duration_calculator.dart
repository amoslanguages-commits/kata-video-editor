import 'dart:math' as math;
import 'package:nle_editor/domain/timeline/multitrack_models.dart';

class TimelineDurationCalculator {
  static const int defaultEmptyTimelineMicros = 60 * 1000000;
  static const int tailPaddingMicros = 3 * 1000000;

  const TimelineDurationCalculator();

  int calculateFromClips(
    List<MultitrackClip> clips, {
    int minimumMicros = defaultEmptyTimelineMicros,
    bool addTailPadding = true,
  }) {
    if (clips.isEmpty) {
      return minimumMicros;
    }

    var maxEnd = 0;
    for (final clip in clips) {
      maxEnd = math.max(maxEnd, clip.timelineEndMicros);
    }

    if (addTailPadding) {
      maxEnd += tailPaddingMicros;
    }

    return math.max(maxEnd, minimumMicros);
  }
}
