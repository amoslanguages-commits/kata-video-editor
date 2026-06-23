import 'dart:collection';
import 'dart:math' as math;

import 'package:nle_editor/domain/timeline/multitrack_models.dart';

/// Cached clip geometry value, keyed on clip ID + timeline bounds + zoom level.
/// This avoids re-computing the same floating-point arithmetic on every build.
class TimelineClipLayoutValue {
  final String clipId;
  final double left;
  final double width;
  final int timelineStartMicros;
  final int timelineEndMicros;
  final double pixelsPerSecond;

  const TimelineClipLayoutValue({
    required this.clipId,
    required this.left,
    required this.width,
    required this.timelineStartMicros,
    required this.timelineEndMicros,
    required this.pixelsPerSecond,
  });
}

/// LRU cache for clip layout values.
///
/// The cache is keyed on `clipId:startMicros:endMicros:pxPerSec` so that a
/// clip invalidates its entry automatically whenever it is moved, trimmed, or
/// the zoom level changes.  Old entries are evicted when [maxEntries] is
/// exceeded.
///
/// Only plain geometry (left, width) is cached — never actual Flutter widgets.
class TimelineClipLayoutCache {
  final int maxEntries;

  /// LinkedHashMap preserves insertion order, which lets us efficiently evict
  /// the oldest (front) entry when the cache is full.
  final _values = LinkedHashMap<String, TimelineClipLayoutValue>();

  TimelineClipLayoutCache({this.maxEntries = 600});

  /// Returns the cached layout value for [clip] at [scale], computing and
  /// storing it if it is not already cached.
  TimelineClipLayoutValue getLayout({
    required MultitrackClip clip,
    required TimelineScale scale,
  }) {
    final key = _cacheKey(
      clipId: clip.id,
      start: clip.timelineStartMicros,
      end: clip.timelineEndMicros,
      pixelsPerSecond: scale.pixelsPerSecond,
    );

    // Move to back on hit (LRU order: front = oldest, back = newest).
    final existing = _values.remove(key);
    if (existing != null) {
      _values[key] = existing;
      return existing;
    }

    // Cache miss — compute and insert.
    final created = TimelineClipLayoutValue(
      clipId: clip.id,
      left: scale.microsToPx(clip.timelineStartMicros),
      width: math.max(12.0, scale.microsToPx(clip.durationMicros)),
      timelineStartMicros: clip.timelineStartMicros,
      timelineEndMicros: clip.timelineEndMicros,
      pixelsPerSecond: scale.pixelsPerSecond,
    );

    _values[key] = created;

    // Evict oldest entries when over capacity.
    while (_values.length > maxEntries) {
      _values.remove(_values.keys.first);
    }

    return created;
  }

  /// Clears the entire cache (e.g. on dispose or after a project change).
  void clear() => _values.clear();

  /// Number of entries currently in the cache.
  int get length => _values.length;

  String _cacheKey({
    required String clipId,
    required int start,
    required int end,
    required double pixelsPerSecond,
  }) {
    // Two decimal places is sufficient precision for cache keying.
    return '$clipId:$start:$end:${pixelsPerSecond.toStringAsFixed(2)}';
  }
}
