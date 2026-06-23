import 'package:nle_editor/domain/timeline/multitrack_models.dart';

class MultitrackTimelineViewModel {
  final String projectId;
  final int durationMicros;
  final List<MultitrackTrack> tracks;
  final List<MultitrackClip> clips;

  const MultitrackTimelineViewModel({
    required this.projectId,
    required this.durationMicros,
    required this.tracks,
    required this.clips,
  });

  factory MultitrackTimelineViewModel.empty(String projectId) {
    return MultitrackTimelineViewModel(
      projectId: projectId,
      durationMicros: 60 * 1000000,
      tracks: const [],
      clips: const [],
    );
  }

  bool get hasTracks => tracks.isNotEmpty;
  bool get hasClips => clips.isNotEmpty;

  List<MultitrackTrack> get visualTracks {
    return tracks.where((track) => track.isVisual).toList()
      ..sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
  }

  List<MultitrackTrack> get audioTracks {
    return tracks.where((track) => track.isAudio).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  int get visualTrackCount => visualTracks.length;
  int get audioTrackCount => audioTracks.length;

  int get clipCount => clips.length;

  bool get isReadyForTimeline {
    return tracks.isNotEmpty;
  }

  MultitrackTimelineViewModel copyWith({
    int? durationMicros,
    List<MultitrackTrack>? tracks,
    List<MultitrackClip>? clips,
  }) {
    return MultitrackTimelineViewModel(
      projectId: projectId,
      durationMicros: durationMicros ?? this.durationMicros,
      tracks: tracks ?? this.tracks,
      clips: clips ?? this.clips,
    );
  }
}
