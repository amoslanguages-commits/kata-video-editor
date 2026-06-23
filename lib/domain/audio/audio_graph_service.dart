// 33A-PRO: Audio Engine Foundation — Audio Graph Builder Service
//
// Builds the NleAudioGraph from the current Drift DB state for a project.
// This is called before every preview / export render to keep native audio in
// sync with the Dart-side timeline.

import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/audio/nle_audio_model.dart';

class AudioGraphService {
  final db.AppDatabase database;

  const AudioGraphService({required this.database});

  /// Builds the full NleAudioGraph for [projectId].
  ///
  /// Logic:
  ///   1. Load all Drift Tracks of type 'audio' for the project.
  ///   2. For each track, load all Clips.
  ///   3. Map them into NleAudioTrackNode / NleAudioClipNode.
  ///   4. Wrap in NleAudioGraph with project-level settings.
  Future<NleAudioGraph> buildGraph(String projectId) async {
    // Load audio tracks from the unified Tracks table.
    final tracks = await _getAudioTracks(projectId);
    final trackNodes = <NleAudioTrackNode>[];

    for (final track in tracks) {
      final clips = await _getTrackClips(track.id);
      final clipNodes = clips.map(_mapClipToNode).toList();

      trackNodes.add(
        NleAudioTrackNode(
          id:      track.id,
          name:    track.name,
          role:    track.trackRole ?? NleAudioTrackRole.standalone.value,
          volume:  track.volume,
          pan:     0.0, // Pan is not stored on the track yet — default centre.
          isMuted: track.isMuted,
          isSolo:  track.isSolo,
          clips:   clipNodes,
        ),
      );
    }

    // Also pick up embedded video audio from video tracks.
    // Video clips that have hasAudio == true (via their asset) must be included.
    final videoAudioNodes = await _buildVideoEmbeddedAudioNodes(projectId);
    trackNodes.addAll(videoAudioNodes);

    return NleAudioGraph(
      projectId: projectId,
      tracks:    trackNodes,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<List<db.Track>> _getAudioTracks(String projectId) async {
    final allTracks = await database.getProjectTracks(projectId);
    return allTracks.where((t) => t.type == 'audio').toList();
  }

  Future<List<db.Clip>> _getTrackClips(String trackId) async {
    return database.getTrackClips(trackId);
  }

  NleAudioClipNode _mapClipToNode(db.Clip clip) {
    // Parse fade info if stored as JSON in effectStack or default to clip fields.
    NleAudioFade fadeIn  = NleAudioFade(durationMicros: clip.fadeInMicros);
    NleAudioFade fadeOut = NleAudioFade(durationMicros: clip.fadeOutMicros);

    // If effectStack carries extended fade JSON, parse it.
    if (clip.effectStack != null) {
      try {
        final stack = jsonDecode(clip.effectStack!) as Map<String, dynamic>;
        if (stack['fadeIn'] != null) {
          fadeIn = NleAudioFade.fromJson(
            Map<String, dynamic>.from(stack['fadeIn'] as Map),
          );
        }
        if (stack['fadeOut'] != null) {
          fadeOut = NleAudioFade.fromJson(
            Map<String, dynamic>.from(stack['fadeOut'] as Map),
          );
        }
      } catch (_) {
        // Silently fall back to the simple values above.
      }
    }

    return NleAudioClipNode(
      id:                  clip.id,
      assetId:             clip.assetId,
      kind:                clip.isVoiceRecording
          ? NleAudioClipKind.voiceRecording.value
          : NleAudioClipKind.audioFile.value,
      timelineStartMicros: clip.timelineStartMicros,
      timelineEndMicros:   clip.timelineEndMicros,
      sourceInMicros:      clip.sourceInMicros,
      sourceOutMicros:     clip.sourceOutMicros,
      volume:              clip.volume,
      pan:                 clip.audioPan,
      isMuted:             clip.isAudioMuted,
      speed:               clip.speed,
      fadeIn:              fadeIn.toJson(),
      fadeOut:             fadeOut.toJson(),
    );
  }

  /// Builds NleAudioTrackNodes for embedded audio inside video tracks.
  ///
  /// Each video clip that has an audio stream is emitted as a separate audio
  /// track node so the native mixer can independently control it.
  Future<List<NleAudioTrackNode>> _buildVideoEmbeddedAudioNodes(
    String projectId,
  ) async {
    final videoTracks = await _getVideoTracks(projectId);
    final nodes = <NleAudioTrackNode>[];

    for (final vt in videoTracks) {
      final clips = await _getTrackClips(vt.id);

      // Only include clips that have an audio stream.
      final audioClips = clips.where((c) => !c.isAudioMuted).toList();
      if (audioClips.isEmpty) continue;

      final clipNodes = audioClips.map((c) {
        final fadeIn  = NleAudioFade(durationMicros: c.fadeInMicros);
        final fadeOut = NleAudioFade(durationMicros: c.fadeOutMicros);
        return NleAudioClipNode(
          id:                  'va_${c.id}',
          assetId:             c.assetId,
          kind:                NleAudioClipKind.videoEmbedded.value,
          timelineStartMicros: c.timelineStartMicros,
          timelineEndMicros:   c.timelineEndMicros,
          sourceInMicros:      c.sourceInMicros,
          sourceOutMicros:     c.sourceOutMicros,
          volume:              c.volume,
          pan:                 c.audioPan,
          isMuted:             c.isAudioMuted,
          speed:               c.speed,
          fadeIn:              fadeIn.toJson(),
          fadeOut:             fadeOut.toJson(),
        );
      }).toList();

      nodes.add(NleAudioTrackNode(
        id:      'va_${vt.id}',
        name:    '${vt.name} (Audio)',
        role:    NleAudioTrackRole.videoAudio.value,
        volume:  vt.volume,
        pan:     0.0,
        isMuted: vt.isMuted,
        isSolo:  vt.isSolo,
        clips:   clipNodes,
      ));
    }

    return nodes;
  }

  Future<List<db.Track>> _getVideoTracks(String projectId) async {
    final allTracks = await database.getProjectTracks(projectId);
    return allTracks.where((t) => t.type == 'video').toList();
  }
}
