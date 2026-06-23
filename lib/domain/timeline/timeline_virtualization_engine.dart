import 'dart:math' as math;

import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_viewport_models.dart';

/// Pure, stateless engine that computes track and clip layout geometry and
/// filters the result to only what is visible in the current viewport window.
class TimelineVirtualizationEngine {
  const TimelineVirtualizationEngine();

  // ---------------------------------------------------------------------------
  // Track layout
  // ---------------------------------------------------------------------------

  /// Builds the full list of track layout entries by stacking tracks
  /// top-to-bottom.  When [compactTracks] is true, smaller fixed heights are
  /// used regardless of the individual [MultitrackTrack.height].
  List<TimelineTrackLayoutEntry> buildTrackLayout({
    required List<MultitrackTrack> tracks,
    required bool compactTracks,
  }) {
    final entries = <TimelineTrackLayoutEntry>[];
    var top = 0.0;

    for (var i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      final h = trackHeight(track: track, compactTracks: compactTracks);

      entries.add(
        TimelineTrackLayoutEntry(
          track: track,
          top: top,
          height: h,
          visualIndex: i,
        ),
      );

      top += h;
    }

    return entries;
  }

  /// Returns only the entries whose vertical span intersects [window].
  List<TimelineTrackLayoutEntry> visibleTracks({
    required List<TimelineTrackLayoutEntry> entries,
    required TimelineVisibleWindow window,
  }) {
    return entries.where((e) => e.visibleIn(window)).toList();
  }

  // ---------------------------------------------------------------------------
  // Clip layout
  // ---------------------------------------------------------------------------

  /// Returns all clips belonging to [track] whose horizontal span is inside
  /// the visible window, sorted by start time.
  List<MultitrackClip> visibleClipsForTrack({
    required MultitrackTrack track,
    required List<MultitrackClip> allClips,
    required TimelineVisibleWindow window,
  }) {
    final visible = allClips
        .where((c) => c.trackId == track.id)
        .where(window.clipIsHorizontallyVisible)
        .toList();

    visible.sort((a, b) =>
        a.timelineStartMicros.compareTo(b.timelineStartMicros));

    return visible;
  }

  /// Computes [TimelineClipLayoutEntry] for every visible clip in [trackEntry].
  List<TimelineClipLayoutEntry> buildVisibleClipLayoutForTrack({
    required TimelineTrackLayoutEntry trackEntry,
    required List<MultitrackClip> allClips,
    required TimelineVisibleWindow window,
    required TimelineScale scale,
  }) {
    final clips = visibleClipsForTrack(
      track: trackEntry.track,
      allClips: allClips,
      window: window,
    );

    return clips.map((clip) {
      return TimelineClipLayoutEntry(
        clip: clip,
        track: trackEntry.track,
        left: scale.microsToPx(clip.timelineStartMicros),
        width: math.max(12, scale.microsToPx(clip.durationMicros)),
        top: trackEntry.top + 6,
        height: math.max(20, trackEntry.height - 12),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Sizing helpers
  // ---------------------------------------------------------------------------

  /// Total pixel height of the stacked track rows.
  double totalTrackHeight(List<TimelineTrackLayoutEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.last.bottom;
  }

  /// Height for a single track row.
  double trackHeight({
    required MultitrackTrack track,
    required bool compactTracks,
  }) {
    if (compactTracks) {
      return track.isAudio ? 42.0 : 48.0;
    }
    // Honour the per-track height set by the user, with a sane minimum.
    return math.max(36.0, track.height);
  }
}
