import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/rendering/multitrack_render_graph_mapper.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_engine.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_models.dart';
import 'package:nle_editor/domain/timeline/multitrack_timeline_view_model.dart';

void main() {
  group('AI Beat-Sync Snapping Tests', () {
    const snapEngine = TimelineSnapEngine();
    const scale = TimelineScale(pixelsPerSecond: 100); // 1 px = 10,000 micros
    const settings = TimelineSnapSettings(thresholdPx: 10); // threshold = 100,000 micros

    const clipA = MultitrackClip(
      id: 'clip_a',
      projectId: 'project_1',
      trackId: 'track_video',
      type: MultitrackClipType.video,
      name: 'Clip A',
      timelineStartMicros: 1000000, // 1.0s
      timelineEndMicros: 4000000,   // 4.0s
    );

    test('Snapping to dynamic beat markers works correctly', () {
      final markers = [
        const TimelineMarkerSnapPoint(
          id: 'beat_1',
          timelineMicros: 2500000, // 2.5s
          label: 'Beat 1',
        ),
      ];

      final targets = snapEngine.buildTargets(
        clips: const [clipA],
        playheadMicros: 0,
        settings: settings,
        activeClipId: 'clip_a',
        markers: markers,
      );

      // Verify that markers are mapped to snap targets
      expect(targets.any((t) => t.type == TimelineSnapTargetType.marker && t.timelineMicros == 2500000), isTrue);

      // Let's test snapping move to the beat marker
      // Move clipA start from 1.0s to 2.45s (delta = 1.45s) -> should snap to 2.5s (snapped delta = 1.5s)
      final result = snapEngine.snapMove(
        clip: clipA,
        deltaMicros: 1450000,
        scale: scale,
        allClips: const [clipA],
        playheadMicros: 0,
        settings: settings,
        markers: markers,
      );

      expect(result.snapped, isTrue);
      expect(result.snappedDeltaMicros, equals(1500000));
    });
  });

  group('Smart Audio Auto-Ducking Tests', () {
    const mapper = MultitrackRenderGraphMapper();

    test('Auto-ducking reduces volume of background music when overlapping voiceover', () {
      const voiceTrack = MultitrackTrack(
        id: 'track_voice',
        projectId: 'p1',
        name: 'Voiceover Track',
        type: MultitrackTrackType.audio,
        role: MultitrackTrackRole.voice,
        sortOrder: 0,
      );

      const musicTrack = MultitrackTrack(
        id: 'track_music',
        projectId: 'p1',
        name: 'Music Track',
        type: MultitrackTrackType.audio,
        role: MultitrackTrackRole.music,
        sortOrder: 1,
      );

      const voiceClip = MultitrackClip(
        id: 'clip_voice',
        projectId: 'p1',
        trackId: 'track_voice',
        type: MultitrackClipType.audio,
        name: 'Voice Clip',
        timelineStartMicros: 2000000, // 2.0s
        timelineEndMicros: 6000000,   // 6.0s
        volume: 1.0,
      );

      // Music clip overlaps voiceover from 2.0s to 5.0s
      const overlappingMusicClip = MultitrackClip(
        id: 'clip_music_overlapping',
        projectId: 'p1',
        trackId: 'track_music',
        type: MultitrackClipType.audio,
        name: 'Music Clip 1',
        timelineStartMicros: 1000000, // 1.0s
        timelineEndMicros: 5000000,   // 5.0s
        volume: 0.8,
      );

      // Music clip does not overlap voiceover
      const cleanMusicClip = MultitrackClip(
        id: 'clip_music_clean',
        projectId: 'p1',
        trackId: 'track_music',
        type: MultitrackClipType.audio,
        name: 'Music Clip 2',
        timelineStartMicros: 7000000, // 7.0s
        timelineEndMicros: 10000000,  // 10.0s
        volume: 0.8,
      );

      final timeline = MultitrackTimelineViewModel(
        projectId: 'p1',
        durationMicros: 10000000,
        tracks: const [voiceTrack, musicTrack],
        clips: const [voiceClip, overlappingMusicClip, cleanMusicClip],
      );

      // Map with autoDuckingEnabled = true
      final tracks = mapper.mapTracks(timeline, autoDuckingEnabled: true);

      // Find mapped clips
      final mappedMusicTrack = tracks.firstWhere((t) => t.id == 'track_music');
      final mappedOverlappingClip = mappedMusicTrack.clips.firstWhere((c) => c.id == 'clip_music_overlapping');
      final mappedCleanClip = mappedMusicTrack.clips.firstWhere((c) => c.id == 'clip_music_clean');

      // Overlapping music clip volume should be ducked by 20% (0.8 * 0.2 = 0.16)
      expect(mappedOverlappingClip.audio!.volume, closeTo(0.16, 0.001));

      // Clean music clip volume should remain 0.8
      expect(mappedCleanClip.audio!.volume, closeTo(0.8, 0.001));
    });
  });
}
