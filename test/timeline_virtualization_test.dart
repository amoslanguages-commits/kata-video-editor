// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';

import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_clip_layout_cache.dart';
import 'package:nle_editor/domain/timeline/timeline_viewport_models.dart';
import 'package:nle_editor/domain/timeline/timeline_virtualization_engine.dart';
import 'package:nle_editor/presentation/controllers/timeline_zoom_controller.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

MultitrackTrack _makeVideoTrack({
  String id = 'v1',
  int sortOrder = 1,
  double height = 58,
}) {
  return MultitrackTrack(
    id: id,
    projectId: 'proj',
    name: 'V$sortOrder',
    type: MultitrackTrackType.video,
    role: MultitrackTrackRole.mainVideo,
    sortOrder: sortOrder,
    height: height,
  );
}

MultitrackTrack _makeAudioTrack({
  String id = 'a1',
  int sortOrder = 1,
  double height = 48,
}) {
  return MultitrackTrack(
    id: id,
    projectId: 'proj',
    name: 'A$sortOrder',
    type: MultitrackTrackType.audio,
    role: MultitrackTrackRole.voice,
    sortOrder: sortOrder,
    height: height,
  );
}

MultitrackClip _makeClip({
  String id = 'c1',
  String trackId = 'v1',
  int startMicros = 0,
  int endMicros = 5000000,
}) {
  return MultitrackClip(
    id: id,
    projectId: 'proj',
    trackId: trackId,
    type: MultitrackClipType.video,
    name: 'Clip $id',
    timelineStartMicros: startMicros,
    timelineEndMicros: endMicros,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// TimelineVirtualizationEngine
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  group('TimelineVirtualizationEngine', () {
    const engine = TimelineVirtualizationEngine();

    // ── buildTrackLayout ──────────────────────────────────────────────────────

    test('buildTrackLayout stacks tracks with correct top offsets', () {
      final tracks = [
        _makeVideoTrack(id: 'v1', sortOrder: 1, height: 60),
        _makeAudioTrack(id: 'a1', sortOrder: 1, height: 48),
        _makeVideoTrack(id: 'v2', sortOrder: 2, height: 72),
      ];

      final layout = engine.buildTrackLayout(
        tracks: tracks,
        compactTracks: false,
      );

      expect(layout.length, 3);
      expect(layout[0].top, 0.0);
      expect(layout[0].height, 60.0);
      expect(layout[1].top, 60.0);
      expect(layout[1].height, 48.0);
      expect(layout[2].top, 108.0);
      expect(layout[2].height, 72.0);
    });

    test('buildTrackLayout uses compact heights in compact mode', () {
      final tracks = [
        _makeVideoTrack(id: 'v1', height: 100),
        _makeAudioTrack(id: 'a1', height: 100),
      ];

      final layout = engine.buildTrackLayout(
        tracks: tracks,
        compactTracks: true,
      );

      expect(layout[0].height, 48.0); // compact video
      expect(layout[1].height, 42.0); // compact audio
    });

    test('totalTrackHeight equals sum of all track heights', () {
      final tracks = [
        _makeVideoTrack(id: 'v1', height: 60),
        _makeAudioTrack(id: 'a1', height: 48),
      ];

      final layout = engine.buildTrackLayout(
        tracks: tracks,
        compactTracks: false,
      );

      expect(engine.totalTrackHeight(layout), 108.0);
    });

    test('totalTrackHeight is 0 for empty layout', () {
      expect(engine.totalTrackHeight([]), 0.0);
    });

    // ── visibleTracks ─────────────────────────────────────────────────────────

    test('visibleTracks returns only tracks inside vertical window', () {
      final scale = const TimelineScale(pixelsPerSecond: 72);

      final tracks = [
        _makeVideoTrack(id: 'v1', sortOrder: 1, height: 60),
        _makeVideoTrack(id: 'v2', sortOrder: 2, height: 60),
        _makeVideoTrack(id: 'v3', sortOrder: 3, height: 60),
        _makeAudioTrack(id: 'a1', sortOrder: 1, height: 60),
      ];

      final layout = engine.buildTrackLayout(
        tracks: tracks,
        compactTracks: false,
      );

      // Scroll 65 px so v1 [0, 60) ends before the window start.
      // visibleStartPx = max(0, 65 - 0) = 65
      // visibleEndPx   = 65 + 120 = 185
      // v1: [0,  60) → bottom=60 < 65 → NOT visible
      // v2: [60,120) → overlaps [65,185) → visible
      // v3: [120,180) → overlaps [65,185) → visible
      // a1: [180,240) → top=180 <= 185 → visible (partial)
      final window = TimelineVisibleWindow(
        horizontalScrollPx: 0,
        verticalScrollPx: 65,
        viewportWidthPx: 600,
        viewportHeightPx: 120,
        scale: scale,
        overscanPx: 0,
      );

      final visible = engine.visibleTracks(entries: layout, window: window);
      final visibleIds = visible.map((e) => e.track.id).toSet();

      expect(visibleIds.contains('v1'), isFalse); // clearly before window
      expect(visibleIds.contains('v2'), isTrue); // overlaps window
      expect(visibleIds.contains('v3'), isTrue); // overlaps window
    });

    // ── visibleClipsForTrack ──────────────────────────────────────────────────

    test('visibleClipsForTrack returns only clips in horizontal window', () {
      final scale = const TimelineScale(pixelsPerSecond: 72);

      // At 72 px/s:
      //  - clip A: 0–5s → px [0, 360)
      //  - clip B: 10–20s → px [720, 1440)
      //  - clip C: 30–40s → px [2160, 2880)
      final clips = [
        _makeClip(id: 'A', startMicros: 0, endMicros: 5000000),
        _makeClip(id: 'B', startMicros: 10000000, endMicros: 20000000),
        _makeClip(id: 'C', startMicros: 30000000, endMicros: 40000000),
      ];

      // Viewport shows px [700, 1500) → only clip B
      final window = TimelineVisibleWindow(
        horizontalScrollPx: 700,
        verticalScrollPx: 0,
        viewportWidthPx: 800,
        viewportHeightPx: 600,
        scale: scale,
        overscanPx: 0,
      );

      final track = _makeVideoTrack(id: 'v1');
      final visible = engine.visibleClipsForTrack(
        track: track,
        allClips: clips,
        window: window,
      );

      final visibleIds = visible.map((c) => c.id).toList();
      expect(visibleIds, contains('B'));
      expect(visibleIds, isNot(contains('A')));
      expect(visibleIds, isNot(contains('C')));
    });

    test('visibleClipsForTrack only returns clips belonging to the track', () {
      final scale = const TimelineScale(pixelsPerSecond: 72);

      final clips = [
        _makeClip(id: 'v-clip', trackId: 'v1'),
        _makeClip(id: 'a-clip', trackId: 'a1'),
      ];

      final window = TimelineVisibleWindow(
        horizontalScrollPx: 0,
        verticalScrollPx: 0,
        viewportWidthPx: 1000,
        viewportHeightPx: 600,
        scale: scale,
        overscanPx: 0,
      );

      final vTrack = _makeVideoTrack(id: 'v1');
      final visible = engine.visibleClipsForTrack(
        track: vTrack,
        allClips: clips,
        window: window,
      );

      expect(visible.map((c) => c.id), contains('v-clip'));
      expect(visible.map((c) => c.id), isNot(contains('a-clip')));
    });

    test('visibleClipsForTrack returns clips sorted by start time', () {
      final scale = const TimelineScale(pixelsPerSecond: 72);

      final clips = [
        _makeClip(id: 'late', startMicros: 20000000, endMicros: 25000000),
        _makeClip(id: 'early', startMicros: 0, endMicros: 5000000),
        _makeClip(id: 'mid', startMicros: 10000000, endMicros: 15000000),
      ];

      final window = TimelineVisibleWindow(
        horizontalScrollPx: 0,
        verticalScrollPx: 0,
        viewportWidthPx: 9999,
        viewportHeightPx: 600,
        scale: scale,
        overscanPx: 0,
      );

      final track = _makeVideoTrack(id: 'v1');
      final visible = engine.visibleClipsForTrack(
        track: track,
        allClips: clips,
        window: window,
      );

      expect(visible[0].id, 'early');
      expect(visible[1].id, 'mid');
      expect(visible[2].id, 'late');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // TimelineClipLayoutCache
  // ──────────────────────────────────────────────────────────────────────────

  group('TimelineClipLayoutCache', () {
    test('computes correct left + width geometry', () {
      final cache = TimelineClipLayoutCache();
      final scale = const TimelineScale(pixelsPerSecond: 72);
      final clip = _makeClip(startMicros: 1000000, endMicros: 6000000);

      final layout = cache.getLayout(clip: clip, scale: scale);

      // left  = 1s * 72 = 72 px
      // width = 5s * 72 = 360 px
      expect(layout.left, closeTo(72.0, 0.01));
      expect(layout.width, closeTo(360.0, 0.01));
    });

    test('returns the same object on a cache hit', () {
      final cache = TimelineClipLayoutCache();
      final scale = const TimelineScale(pixelsPerSecond: 72);
      final clip = _makeClip();

      final a = cache.getLayout(clip: clip, scale: scale);
      final b = cache.getLayout(clip: clip, scale: scale);

      expect(identical(a, b), isTrue);
    });

    test('invalidates on clip timing change', () {
      final cache = TimelineClipLayoutCache();
      final scale = const TimelineScale(pixelsPerSecond: 72);

      final clip1 = _makeClip(startMicros: 0, endMicros: 5000000);
      final layout1 = cache.getLayout(clip: clip1, scale: scale);

      // Move the clip → different cache key.
      final clip2 = _makeClip(startMicros: 1000000, endMicros: 6000000);
      final layout2 = cache.getLayout(clip: clip2, scale: scale);

      expect(layout1.left, isNot(equals(layout2.left)));
    });

    test('invalidates on scale change', () {
      final cache = TimelineClipLayoutCache();
      final clip = _makeClip(startMicros: 1000000, endMicros: 6000000);

      final layout72 = cache.getLayout(
        clip: clip,
        scale: const TimelineScale(pixelsPerSecond: 72),
      );
      final layout144 = cache.getLayout(
        clip: clip,
        scale: const TimelineScale(pixelsPerSecond: 144),
      );

      expect(layout72.left, closeTo(72.0, 0.01));
      expect(layout144.left, closeTo(144.0, 0.01));
    });

    test('evicts oldest entry when capacity is exceeded', () {
      final cache = TimelineClipLayoutCache(maxEntries: 3);
      final scale = const TimelineScale(pixelsPerSecond: 72);

      for (var i = 0; i < 5; i++) {
        final clip = _makeClip(
            id: 'c$i', startMicros: i * 1000000, endMicros: (i + 1) * 1000000);
        cache.getLayout(clip: clip, scale: scale);
      }

      expect(cache.length, lessThanOrEqualTo(3));
    });

    test('minimum clip width is 12 px', () {
      final cache = TimelineClipLayoutCache();
      // Very short 1µs clip → raw width ≈ 0.000072 px.
      final clip = _makeClip(startMicros: 0, endMicros: 1);
      final layout = cache.getLayout(
        clip: clip,
        scale: const TimelineScale(pixelsPerSecond: 72),
      );

      expect(layout.width, 12.0);
    });

    test('clear empties the cache', () {
      final cache = TimelineClipLayoutCache();
      final scale = const TimelineScale(pixelsPerSecond: 72);
      cache.getLayout(clip: _makeClip(), scale: scale);
      expect(cache.length, 1);

      cache.clear();
      expect(cache.length, 0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // TimelineVisibleWindow
  // ──────────────────────────────────────────────────────────────────────────

  group('TimelineVisibleWindow', () {
    test('startPx is clamped to 0 when scroll < overscan', () {
      final window = TimelineVisibleWindow(
        horizontalScrollPx: 100,
        verticalScrollPx: 0,
        viewportWidthPx: 800,
        viewportHeightPx: 600,
        scale: const TimelineScale(pixelsPerSecond: 72),
        overscanPx: 200,
      );

      // 100 - 200 = -100 → clamped to 0
      expect(window.startPx, 0.0);
    });

    test('endPx includes viewport width + overscan', () {
      final window = TimelineVisibleWindow(
        horizontalScrollPx: 500,
        verticalScrollPx: 0,
        viewportWidthPx: 800,
        viewportHeightPx: 600,
        scale: const TimelineScale(pixelsPerSecond: 72),
        overscanPx: 100,
      );

      expect(window.endPx, 500 + 800 + 100); // 1400
    });

    test('clipIsHorizontallyVisible returns true for overlapping clip', () {
      final scale = const TimelineScale(pixelsPerSecond: 72);
      final window = TimelineVisibleWindow(
        horizontalScrollPx: 360, // = 5s
        verticalScrollPx: 0,
        viewportWidthPx: 360, // = 5s wide
        viewportHeightPx: 600,
        scale: scale,
        overscanPx: 0,
      );

      // Clip 7s–12s → starts at px 504, ends at px 864 → overlaps [360,720)
      final clip = _makeClip(
        startMicros: 7000000,
        endMicros: 12000000,
      );

      expect(window.clipIsHorizontallyVisible(clip), isTrue);
    });

    test('clipIsHorizontallyVisible returns false for clip before window', () {
      final scale = const TimelineScale(pixelsPerSecond: 72);
      final window = TimelineVisibleWindow(
        horizontalScrollPx: 720, // = 10s
        verticalScrollPx: 0,
        viewportWidthPx: 360,
        viewportHeightPx: 600,
        scale: scale,
        overscanPx: 0,
      );

      // Clip ends at 5s = 360px → before window start at 720px
      final clip = _makeClip(startMicros: 0, endMicros: 5000000);
      expect(window.clipIsHorizontallyVisible(clip), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // TimelineZoomController
  // ──────────────────────────────────────────────────────────────────────────

  group('TimelineZoomController', () {
    const controller = TimelineZoomController();

    test('zoomWithAnchor keeps anchor timeline position stable', () {
      const currentScale = TimelineScale(pixelsPerSecond: 72);
      const factor = 2.0;

      // Viewport is 600px wide, scrolled to 72px (= 1s). Anchor at 300px
      // viewport → content position 372px = 5.17s.
      const anchorViewportPx = 300.0;
      const currentScrollPx = 72.0;

      final result = controller.zoomWithAnchor(
        currentScale: currentScale,
        factor: factor,
        anchorViewportPx: anchorViewportPx,
        currentScrollPx: currentScrollPx,
      );

      // New scale should be clamped (72 * 2 = 144 ≤ max=360).
      expect(result.nextScale.pixelsPerSecond, closeTo(144.0, 0.01));

      // Anchor content position at new scale: 5.17s * 144 ≈ 744px
      // New scroll = 744 - 300 = 444px
      expect(result.nextScrollPx, closeTo(444.0, 1.0));
    });

    test('zoomWithAnchor clamps to minimum scale', () {
      const currentScale = TimelineScale(pixelsPerSecond: 20);
      final result = controller.zoomWithAnchor(
        currentScale: currentScale,
        factor: 0.5,
        anchorViewportPx: 0,
        currentScrollPx: 0,
      );

      expect(
        result.nextScale.pixelsPerSecond,
        greaterThanOrEqualTo(TimelineScale.min.pixelsPerSecond),
      );
    });

    test('zoomWithAnchor clamps to maximum scale', () {
      const currentScale = TimelineScale(pixelsPerSecond: 350);
      final result = controller.zoomWithAnchor(
        currentScale: currentScale,
        factor: 2.0,
        anchorViewportPx: 0,
        currentScrollPx: 0,
      );

      expect(
        result.nextScale.pixelsPerSecond,
        lessThanOrEqualTo(TimelineScale.max.pixelsPerSecond),
      );
    });

    test('zoomWithAnchor with anchorViewportPx=0 and scroll=0 gives scroll=0',
        () {
      const currentScale = TimelineScale(pixelsPerSecond: 72);
      final result = controller.zoomWithAnchor(
        currentScale: currentScale,
        factor: 2.0,
        anchorViewportPx: 0,
        currentScrollPx: 0,
      );

      // Anchor at timeline micros 0 → new scroll should remain 0.
      expect(result.nextScrollPx, closeTo(0.0, 0.01));
    });
  });
}
