// 33A-PRO: Audio Engine Foundation — Audio Timeline Controller
//
// StateNotifier that manages the audio timeline state for a single project.
// Responsibilities:
//   - Track/clip CRUD operations via AudioRepository
//   - Immediate native-side parameter updates via NativeAudioEngineService
//   - Audio graph rebuild + push after structural changes

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/repositories/audio_repository.dart';
import 'package:nle_editor/domain/audio/audio_graph_service.dart';
import 'package:nle_editor/platform/audio/native_audio_engine_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AudioTimelineState {
  final List<db.Track> audioTracks;
  final String?  selectedTrackId;
  final String?  selectedClipId;

  /// true while a graph update is in flight to the native side.
  final bool isUpdatingGraph;

  final String? lastError;

  const AudioTimelineState({
    this.audioTracks      = const [],
    this.selectedTrackId,
    this.selectedClipId,
    this.isUpdatingGraph  = false,
    this.lastError,
  });

  AudioTimelineState copyWith({
    List<db.Track>? audioTracks,
    Object?         selectedTrackId = _sentinel,
    Object?         selectedClipId  = _sentinel,
    bool?           isUpdatingGraph,
    Object?         lastError = _sentinel,
  }) {
    return AudioTimelineState(
      audioTracks:      audioTracks      ?? this.audioTracks,
      selectedTrackId:  selectedTrackId  == _sentinel
          ? this.selectedTrackId
          : selectedTrackId as String?,
      selectedClipId:   selectedClipId   == _sentinel
          ? this.selectedClipId
          : selectedClipId as String?,
      isUpdatingGraph:  isUpdatingGraph  ?? this.isUpdatingGraph,
      lastError:        lastError        == _sentinel
          ? this.lastError
          : lastError as String?,
    );
  }
}

const _sentinel = Object();

// ── Controller ────────────────────────────────────────────────────────────────

class AudioController extends StateNotifier<AudioTimelineState> {
  final String            projectId;
  final AudioRepository   repository;
  final AudioGraphService graphService;
  final NativeAudioEngineService nativeAudio;
  final Ref               ref;

  AudioController({
    required this.projectId,
    required this.repository,
    required this.graphService,
    required this.nativeAudio,
    required this.ref,
  }) : super(const AudioTimelineState());

  // ── Selection ──────────────────────────────────────────────────────────────

  void selectTrack(String? trackId) {
    state = state.copyWith(selectedTrackId: trackId, selectedClipId: null);
  }

  void selectClip(String? clipId) {
    state = state.copyWith(selectedClipId: clipId);
  }

  // ── Track Operations ───────────────────────────────────────────────────────

  Future<void> setTrackVolume({
    required String trackId,
    required double volume,
  }) async {
    await repository.setTrackVolume(trackId: trackId, volume: volume);
    // Immediate native override — no full graph rebuild needed for a knob tweak.
    await nativeAudio.setTrackVolume(
      projectId: projectId,
      trackId:   trackId,
      volume:    volume,
    );
  }

  Future<void> toggleTrackMute(String trackId) async {
    final track = await repository.getTrack(trackId);
    if (track == null) return;
    final newMuted = !track.isMuted;

    await repository.setTrackMuted(trackId: trackId, isMuted: newMuted);
    await nativeAudio.setTrackMute(
      projectId: projectId,
      trackId:   trackId,
      isMuted:   newMuted,
    );
  }

  Future<void> toggleTrackSolo(String trackId) async {
    final track = await repository.getTrack(trackId);
    if (track == null) return;
    final newSolo = !track.isSolo;

    await repository.setTrackSolo(trackId: trackId, isSolo: newSolo);
    await nativeAudio.setTrackSolo(
      projectId: projectId,
      trackId:   trackId,
      isSolo:    newSolo,
    );
  }

  // ── Clip Operations ────────────────────────────────────────────────────────

  Future<void> setClipVolume({
    required String trackId,
    required String clipId,
    required double volume,
  }) async {
    await repository.setClipVolume(clipId: clipId, volume: volume);
    await nativeAudio.setClipVolume(
      projectId: projectId,
      trackId:   trackId,
      clipId:    clipId,
      volume:    volume,
    );
  }

  Future<void> setClipPan({
    required String clipId,
    required double pan,
  }) async {
    await repository.setClipPan(clipId: clipId, pan: pan);
    // Pan requires a full graph update because the native API does not
    // support a discrete pan override yet.
    await _pushGraphUpdate();
  }

  Future<void> setClipMuted({
    required String trackId,
    required String clipId,
    required bool isMuted,
  }) async {
    await repository.setClipMuted(clipId: clipId, isMuted: isMuted);
    await nativeAudio.setClipMute(
      projectId: projectId,
      trackId:   trackId,
      clipId:    clipId,
      isMuted:   isMuted,
    );
  }

  Future<void> setClipFadeIn({
    required String clipId,
    required int durationMicros,
  }) async {
    await repository.setClipFadeIn(
      clipId:         clipId,
      durationMicros: durationMicros,
    );
    await _pushGraphUpdate();
  }

  Future<void> setClipFadeOut({
    required String clipId,
    required int durationMicros,
  }) async {
    await repository.setClipFadeOut(
      clipId:         clipId,
      durationMicros: durationMicros,
    );
    await _pushGraphUpdate();
  }

  // ── Graph push ─────────────────────────────────────────────────────────────

  /// Rebuilds the NleAudioGraph and pushes it to the native audio mixer.
  Future<void> _pushGraphUpdate() async {
    if (state.isUpdatingGraph) return;
    state = state.copyWith(isUpdatingGraph: true, lastError: null);
    try {
      final graph = await graphService.buildGraph(projectId);
      final result = await nativeAudio.updateAudioGraph(graph);
      if (!result.accepted) {
        state = state.copyWith(
          isUpdatingGraph: false,
          lastError: result.message,
        );
        return;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdatingGraph: false,
        lastError: e.toString(),
      );
      return;
    }
    state = state.copyWith(isUpdatingGraph: false);
  }

  /// Force-loads the full audio graph (called on project open).
  Future<void> loadGraphForProject() async {
    state = state.copyWith(isUpdatingGraph: true, lastError: null);
    try {
      final graph = await graphService.buildGraph(projectId);
      await nativeAudio.loadAudioGraph(graph);
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    } finally {
      state = state.copyWith(isUpdatingGraph: false);
    }
  }
}
