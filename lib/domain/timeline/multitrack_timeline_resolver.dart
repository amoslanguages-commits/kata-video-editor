import 'package:nle_editor/domain/timeline/multitrack_models.dart';

class MultitrackTimelineResolver {
  const MultitrackTimelineResolver();

  ResolvedTimelineFrame resolveAt({
    required int timelineTimeMicros,
    required List<MultitrackTrack> tracks,
    required List<MultitrackClip> clips,
  }) {
    final clipsByTrack = <String, List<MultitrackClip>>{};

    for (final clip in clips) {
      clipsByTrack.putIfAbsent(clip.trackId, () => []).add(clip);
    }

    final visualTracks = tracks
        .where((track) => track.isVisual && !track.isHidden && !track.isMuted)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final audioTracksRaw = tracks.where((track) => track.isAudio).toList();
    final hasSoloAudio = audioTracksRaw.any((track) => track.isSolo);

    final audioTracks = audioTracksRaw
        .where((track) {
          if (track.isMuted) return false;
          if (hasSoloAudio && !track.isSolo) return false;
          return true;
        })
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final visualLayers = <ResolvedVisualLayer>[];

    for (final track in visualTracks) {
      final activeClips = (clipsByTrack[track.id] ?? const [])
          .where((clip) => !clip.isDisabled && clip.contains(timelineTimeMicros))
          .where((clip) => clip.isVisual)
          .toList()
        ..sort((a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));

      for (final clip in activeClips) {
        visualLayers.add(
          ResolvedVisualLayer(
            track: track,
            clip: clip,
            sourceTimeMicros: clip.sourceTimeForTimeline(timelineTimeMicros),
            timelineTimeMicros: timelineTimeMicros,
            layerIndex: visualLayers.length,
            opacity: clip.opacity,
          ),
        );
      }
    }

    final audioLayers = <ResolvedAudioLayer>[];

    for (final track in audioTracks) {
      final activeClips = (clipsByTrack[track.id] ?? const [])
          .where((clip) => !clip.isDisabled && clip.contains(timelineTimeMicros))
          .where((clip) => clip.isAudio)
          .toList();

      for (final clip in activeClips) {
        audioLayers.add(
          ResolvedAudioLayer(
            track: track,
            clip: clip,
            sourceTimeMicros: clip.sourceTimeForTimeline(timelineTimeMicros),
            timelineTimeMicros: timelineTimeMicros,
            volume: 1.0,
          ),
        );
      }
    }

    return ResolvedTimelineFrame(
      timelineTimeMicros: timelineTimeMicros,
      visualLayers: visualLayers,
      audioLayers: audioLayers,
    );
  }
}
