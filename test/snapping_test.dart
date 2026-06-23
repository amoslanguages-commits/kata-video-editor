import 'package:flutter_test/flutter_test.dart';

import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_models.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_engine.dart';
import 'package:nle_editor/presentation/controllers/timeline_snap_settings_controller.dart';

void main() {
  group('Timeline Snap Settings Controller Tests', () {
    test('Initial settings are default', () {
      final controller = TimelineSnapSettingsController();
      expect(controller.debugState.enabled, isTrue);
      expect(controller.debugState.thresholdPx, equals(10.0));
      expect(controller.debugState.snapToPlayhead, isTrue);
      expect(controller.debugState.snapToClipEdges, isTrue);
      expect(controller.debugState.snapToTimelineZero, isTrue);
      expect(controller.debugState.snapToMarkers, isTrue);
    });

    test('Toggles and setters update settings state correctly', () {
      final controller = TimelineSnapSettingsController();

      controller.toggleEnabled();
      expect(controller.debugState.enabled, isFalse);

      controller.setEnabled(true);
      expect(controller.debugState.enabled, isTrue);

      controller.setThresholdPx(50.0); // Should clamp to max 32.0
      expect(controller.debugState.thresholdPx, equals(32.0));

      controller.setThresholdPx(2.0); // Should clamp to min 4.0
      expect(controller.debugState.thresholdPx, equals(4.0));

      controller.togglePlayheadSnap();
      expect(controller.debugState.snapToPlayhead, isFalse);

      controller.toggleClipEdgeSnap();
      expect(controller.debugState.snapToClipEdges, isFalse);

      controller.toggleTimelineZeroSnap();
      expect(controller.debugState.snapToTimelineZero, isFalse);

      controller.toggleMarkerSnap();
      expect(controller.debugState.snapToMarkers, isFalse);
    });
  });

  group('Timeline Snap Engine Tests', () {
    const snapEngine = TimelineSnapEngine();
    const scale = TimelineScale(pixelsPerSecond: 100); // 1 px = 10,000 micros
    const settings =
        TimelineSnapSettings(thresholdPx: 10); // threshold is 100,000 micros

    // Test Clip Setup
    const clipA = MultitrackClip(
      id: 'clip_a',
      projectId: 'p1',
      trackId: 't1',
      type: MultitrackClipType.video,
      name: 'Clip A',
      timelineStartMicros: 1000000, // 1.0s
      timelineEndMicros: 4000000, // 4.0s
    );

    const clipB = MultitrackClip(
      id: 'clip_b',
      projectId: 'p1',
      trackId: 't1',
      type: MultitrackClipType.video,
      name: 'Clip B',
      timelineStartMicros: 5000000, // 5.0s
      timelineEndMicros: 8000000, // 8.0s
    );

    test('buildTargets creates active snap targets correctly', () {
      final targets = snapEngine.buildTargets(
        clips: [clipA, clipB],
        playheadMicros: 2500000,
        settings: settings,
        activeClipId: 'clip_a',
        markers: const [
          TimelineMarkerSnapPoint(
              id: 'm1', timelineMicros: 6000000, label: 'Marker 1'),
        ],
      );

      // Expected Targets:
      // - TimelineZero (0)
      // - Playhead (2,500,000)
      // - Clip B Start (5,000,000)
      // - Marker 1 (6,000,000)
      // - Clip B End (8,000,000)
      // (Clip A should be excluded since it is the active clip)

      expect(targets.length, equals(5));
      expect(targets[0].type, equals(TimelineSnapTargetType.timelineZero));
      expect(targets[0].timelineMicros, equals(0));

      expect(targets[1].type, equals(TimelineSnapTargetType.playhead));
      expect(targets[1].timelineMicros, equals(2500000));

      expect(targets[2].type, equals(TimelineSnapTargetType.clipStart));
      expect(targets[2].timelineMicros, equals(5000000));
      expect(targets[2].clipId, equals('clip_b'));

      expect(targets[3].type, equals(TimelineSnapTargetType.marker));
      expect(targets[3].timelineMicros, equals(6000000));

      expect(targets[4].type, equals(TimelineSnapTargetType.clipEnd));
      expect(targets[4].timelineMicros, equals(8000000));
    });

    test('snapMove snaps to playhead if start is close', () {
      // Playhead is at 950,000 micros. Clip A starts at 1,000,000 micros.
      // Move by -10,000 micros, bringing it to 990,000 micros (within threshold to 950,000).
      final result = snapEngine.snapMove(
        clip: clipA,
        deltaMicros: -10000,
        scale: scale,
        allClips: [clipA, clipB],
        playheadMicros: 950000,
        settings: settings,
      );

      expect(result.snapped, isTrue);
      expect(result.candidate?.target.type,
          equals(TimelineSnapTargetType.playhead));
      // Snapped start should align with playhead (950,000), which requires a snapped delta of -50,000
      expect(result.snappedDeltaMicros, equals(-50000));
    });

    test('snapMove snaps to timeline zero if start is close', () {
      // Move by -950,000 micros, bringing start to 50,000 micros (within 100,000 threshold to 0).
      final result = snapEngine.snapMove(
        clip: clipA,
        deltaMicros: -950000,
        scale: scale,
        allClips: [clipA, clipB],
        playheadMicros: 2500000,
        settings: settings,
      );

      expect(result.snapped, isTrue);
      expect(result.candidate?.target.type,
          equals(TimelineSnapTargetType.timelineZero));
      expect(result.snappedDeltaMicros,
          equals(-1000000)); // Should align exactly at 0
    });

    test(
        'snapMove clamps timeline start to zero even if snapped delta is negative',
        () {
      // Move by -1,500,000 micros (would shift start to -500,000, not close to snap zero).
      // It should still clamp to 0 start.
      final result = snapEngine.snapMove(
        clip: clipA,
        deltaMicros: -1500000,
        scale: scale,
        allClips: [clipA, clipB],
        playheadMicros: 2500000,
        settings: settings,
      );

      expect(result.snappedDeltaMicros,
          equals(-1000000)); // Clamped to -1.0s shift (so start = 0)
    });

    test('snapMove snaps clip start to other clip end', () {
      // Clip B starts at 5.0s. Clip A ends at 4.0s.
      // Move clip B by -920,000 micros, bringing start to 4,080,000 micros (close to Clip A end at 4.0s).
      final result = snapEngine.snapMove(
        clip: clipB,
        deltaMicros: -920000,
        scale: scale,
        allClips: [clipA, clipB],
        playheadMicros: 2500000,
        settings: settings,
      );

      expect(result.snapped, isTrue);
      expect(result.candidate?.target.type,
          equals(TimelineSnapTargetType.clipEnd));
      expect(result.candidate?.target.clipId, equals('clip_a'));
      expect(result.snappedDeltaMicros,
          equals(-1000000)); // Should align B's start to 4.0s (shift of -1.0s)
    });

    test('snapTrimLeft snaps left edge to playhead', () {
      // Trim left inwards to 1.95s (delta of +950,000 micros).
      // Playhead is at 2.0s. Trim is within threshold.
      final result = snapEngine.snapTrimLeft(
        clip: clipA,
        deltaMicros: 950000,
        scale: scale,
        allClips: [clipA, clipB],
        playheadMicros: 2000000,
        settings: settings,
      );

      expect(result.snapped, isTrue);
      expect(result.candidate?.target.type,
          equals(TimelineSnapTargetType.playhead));
      expect(result.snappedDeltaMicros,
          equals(1000000)); // Snap start of trim left exactly to 2.0s
    });

    test('snapTrimRight snaps right edge to clip start', () {
      // Clip A end is 4.0s. Clip B start is 5.0s.
      // Trim right outwards by 920,000 micros, bringing end to 4,920,000 micros (close to B start at 5.0s).
      final result = snapEngine.snapTrimRight(
        clip: clipA,
        deltaMicros: 920000,
        scale: scale,
        allClips: [clipA, clipB],
        playheadMicros: 2000000,
        settings: settings,
      );

      expect(result.snapped, isTrue);
      expect(result.candidate?.target.type,
          equals(TimelineSnapTargetType.clipStart));
      expect(result.candidate?.target.clipId, equals('clip_b'));
      expect(result.snappedDeltaMicros,
          equals(1000000)); // Align right edge exactly to 5.0s
    });

    test('Snapping is skipped when settings are disabled', () {
      final disabledSettings = settings.copyWith(enabled: false);

      final result = snapEngine.snapMove(
        clip: clipA,
        deltaMicros: -10000,
        scale: scale,
        allClips: [clipA, clipB],
        playheadMicros: 950000,
        settings: disabledSettings,
      );

      expect(result.snapped, isFalse);
      expect(result.snappedDeltaMicros, equals(-10000)); // Raw move
    });
  });
}
