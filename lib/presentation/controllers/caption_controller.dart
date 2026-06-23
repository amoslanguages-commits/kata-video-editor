import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/caption_repository.dart';
import 'package:nle_editor/domain/captions/caption_segment_models.dart';
import 'package:nle_editor/domain/captions/caption_timing_tools.dart';
import 'package:nle_editor/domain/captions/subtitle_track_models.dart';

class CaptionEditorState {
  final bool loading;
  final List<NleSubtitleTrack> tracks;
  final String? selectedTrackId;
  final String? selectedSegmentId;
  final String? error;

  const CaptionEditorState({
    required this.loading,
    required this.tracks,
    this.selectedTrackId,
    this.selectedSegmentId,
    this.error,
  });

  const CaptionEditorState.initial()
      : loading = false,
        tracks = const [],
        selectedTrackId = null,
        selectedSegmentId = null,
        error = null;

  NleSubtitleTrack? get selectedTrack {
    if (selectedTrackId == null) {
      return tracks.isNotEmpty ? tracks.first : null;
    }

    return tracks.where((track) => track.id == selectedTrackId).firstOrNull;
  }

  NleCaptionSegment? get selectedSegment {
    final track = selectedTrack;
    if (track == null || selectedSegmentId == null) return null;

    return track.segments
        .where((segment) => segment.id == selectedSegmentId)
        .firstOrNull;
  }

  CaptionEditorState copyWith({
    bool? loading,
    List<NleSubtitleTrack>? tracks,
    String? selectedTrackId,
    String? selectedSegmentId,
    String? error,
    bool clearError = false,
  }) {
    return CaptionEditorState(
      loading: loading ?? this.loading,
      tracks: tracks ?? this.tracks,
      selectedTrackId: selectedTrackId ?? this.selectedTrackId,
      selectedSegmentId: selectedSegmentId ?? this.selectedSegmentId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CaptionController extends StateNotifier<CaptionEditorState> {
  final String projectId;
  final CaptionRepository repository;
  final CaptionTimingTools timingTools;

  CaptionController({
    required this.projectId,
    required this.repository,
    this.timingTools = const CaptionTimingTools(),
  }) : super(const CaptionEditorState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final tracks = await repository.getTracks(projectId);

      state = state.copyWith(
        loading: false,
        tracks: tracks,
        selectedTrackId: tracks.isNotEmpty ? tracks.first.id : null,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> createTrack() async {
    final trackId = await repository.createTrack(projectId: projectId);
    await load();
    state = state.copyWith(selectedTrackId: trackId);
  }

  Future<void> selectTrack(String trackId) async {
    state = state.copyWith(selectedTrackId: trackId);
  }

  Future<void> selectSegment(String segmentId) async {
    state = state.copyWith(selectedSegmentId: segmentId);
  }

  Future<void> createSegmentAt({
    required int startMicros,
    int durationMicros = 2500000,
  }) async {
    var track = state.selectedTrack;

    if (track == null) {
      await createTrack();
      track = state.selectedTrack;
    }

    if (track == null) return;

    final id = await repository.createSegment(
      projectId: projectId,
      trackId: track.id,
      startMicros: startMicros,
      endMicros: startMicros + durationMicros,
    );

    await load();
    state = state.copyWith(
      selectedTrackId: track.id,
      selectedSegmentId: id,
    );
  }

  Future<void> updateSegment(NleCaptionSegment segment) async {
    await repository.saveSegment(
      projectId: projectId,
      segment: segment,
    );

    await load();

    state = state.copyWith(
      selectedTrackId: segment.trackId,
      selectedSegmentId: segment.id,
    );
  }

  Future<void> updateSegmentText({
    required String segmentId,
    required String text,
  }) async {
    final segment = _segmentById(segmentId);
    if (segment == null || segment.locked) return;

    await updateSegment(segment.copyWith(text: text));
  }

  Future<void> deleteSegment(String segmentId) async {
    await repository.deleteSegment(segmentId);
    await load();
  }

  Future<void> shiftSelected(int deltaMicros) async {
    final segment = state.selectedSegment;
    if (segment == null || segment.locked) return;

    await updateSegment(
      timingTools.shift(
        segment: segment,
        deltaMicros: deltaMicros,
      ),
    );
  }

  Future<void> setTrackBurnedIn({
    required String trackId,
    required bool burnedIn,
  }) async {
    final track = state.tracks.where((t) => t.id == trackId).firstOrNull;
    if (track == null) return;

    await repository.saveTrack(
      track.copyWith(burnedIn: burnedIn),
    );

    await load();
  }

  Future<void> setTrackEnabled({
    required String trackId,
    required bool enabled,
  }) async {
    final track = state.tracks.where((t) => t.id == trackId).firstOrNull;
    if (track == null) return;

    await repository.saveTrack(
      track.copyWith(enabled: enabled),
    );

    await load();
  }

  Future<void> splitSegment({
    required String segmentId,
    required int splitMicros,
    required String firstId,
    required String secondId,
  }) async {
    final segment = _segmentById(segmentId);
    if (segment == null || segment.locked) return;

    final parts = timingTools.split(
      segment: segment,
      splitMicros: splitMicros,
      firstId: firstId,
      secondId: secondId,
    );

    if (parts.length == 2) {
      await repository.deleteSegment(segmentId);
      for (final part in parts) {
        await repository.saveSegment(
          projectId: projectId,
          segment: part,
        );
      }
      await load();
      state = state.copyWith(
        selectedSegmentId: firstId,
      );
    }
  }

  Future<void> mergeSegments({
    required String firstId,
    required String secondId,
  }) async {
    final first = _segmentById(firstId);
    final second = _segmentById(secondId);
    if (first == null || second == null || first.locked || second.locked) return;

    final merged = timingTools.merge(first: first, second: second);
    await repository.deleteSegment(secondId);
    await updateSegment(merged);
  }

  Future<void> updateSegmentTiming({
    required String segmentId,
    required int startMicros,
    required int endMicros,
  }) async {
    final segment = _segmentById(segmentId);
    if (segment == null || segment.locked) return;

    await updateSegment(
      segment.copyWith(
        startMicros: startMicros,
        endMicros: endMicros,
      ),
    );
  }

  Future<void> deleteTrack(String trackId) async {
    await repository.deleteTrack(trackId);
    await load();
    if (state.selectedTrackId == trackId) {
      state = state.copyWith(
        selectedTrackId: state.tracks.isNotEmpty ? state.tracks.first.id : null,
        selectedSegmentId: null,
      );
    }
  }

  Future<void> importSrt({
    required String trackId,
    required String source,
  }) async {
    await repository.importSrt(
      projectId: projectId,
      trackId: trackId,
      source: source,
    );
    await load();
  }

  Future<void> importWebVtt({
    required String trackId,
    required String source,
  }) async {
    await repository.importWebVtt(
      projectId: projectId,
      trackId: trackId,
      source: source,
    );
    await load();
  }

  Future<String> exportSrt(String trackId) {
    return repository.exportSrt(trackId);
  }

  Future<String> exportWebVtt(String trackId) {
    return repository.exportWebVtt(trackId);
  }

  NleCaptionSegment? _segmentById(String segmentId) {
    for (final track in state.tracks) {
      for (final segment in track.segments) {
        if (segment.id == segmentId) {
          return segment;
        }
      }
    }
    return null;
  }
}
