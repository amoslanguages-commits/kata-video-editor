// 33A-PRO: Audio Engine Foundation — Audio Repository
//
// Provides CRUD access to audio-related data in the Drift database:
//   - Clip audio settings (volume, pan, mute, fades)
//   - Track volume / mute / solo
//   - Waveform cache records

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/audio/nle_audio_model.dart';

class AudioRepository {
  final db.AppDatabase database;

  const AudioRepository({required this.database});

  // ── Waveform Cache ─────────────────────────────────────────────────────────

  Future<db.AudioWaveformCache?> getWaveformCache(String assetId) {
    return database.getWaveformCache(assetId);
  }

  Stream<db.AudioWaveformCache?> watchWaveformCache(String assetId) {
    return database.watchWaveformCache(assetId);
  }

  /// Marks a waveform as pending (triggers background render).
  Future<void> requestWaveformRender(String assetId) {
    return database.upsertWaveformCache(
      db.AudioWaveformCachesCompanion(
        assetId:   Value(assetId),
        status:    const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Saves successfully rendered waveform data.
  Future<void> saveWaveformResult({
    required String assetId,
    required String peakDataPath,
    List<double>? inlineSamples,
    int samplesPerSecond = 100,
  }) {
    return database.upsertWaveformCache(
      db.AudioWaveformCachesCompanion(
        assetId:          Value(assetId),
        peakDataPath:     Value(peakDataPath),
        samplesJson:      inlineSamples != null
            ? Value(jsonEncode(inlineSamples))
            : const Value.absent(),
        samplesPerSecond: Value(samplesPerSecond),
        status:           const Value('ready'),
        updatedAt:        Value(DateTime.now()),
      ),
    );
  }

  Future<void> markWaveformError({
    required String assetId,
    required String errorMessage,
  }) {
    return database.upsertWaveformCache(
      db.AudioWaveformCachesCompanion(
        assetId:      Value(assetId),
        status:       const Value('error'),
        errorMessage: Value(errorMessage),
        updatedAt:    Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteWaveformCache(String assetId) {
    return database.deleteWaveformCache(assetId);
  }

  // ── Clip Audio Settings ────────────────────────────────────────────────────

  Future<void> setClipVolume({
    required String clipId,
    required double volume,
  }) {
    return database.updateClipAudioSettings(
      clipId: clipId,
      volume: AudioGainUtils.clampVolume(volume),
    );
  }

  Future<void> setClipPan({
    required String clipId,
    required double pan,
  }) {
    return database.updateClipAudioSettings(
      clipId:   clipId,
      audioPan: AudioGainUtils.clampPan(pan),
    );
  }

  Future<void> setClipMuted({
    required String clipId,
    required bool isMuted,
  }) {
    return database.updateClipAudioSettings(
      clipId:      clipId,
      isAudioMuted: isMuted,
    );
  }

  Future<void> setClipFadeIn({
    required String clipId,
    required int durationMicros,
  }) {
    return database.updateClipAudioSettings(
      clipId:       clipId,
      fadeInMicros: durationMicros.clamp(0, 30000000),
    );
  }

  Future<void> setClipFadeOut({
    required String clipId,
    required int durationMicros,
  }) {
    return database.updateClipAudioSettings(
      clipId:        clipId,
      fadeOutMicros: durationMicros.clamp(0, 30000000),
    );
  }

  // ── Track Audio Settings ───────────────────────────────────────────────────

  Future<void> setTrackVolume({
    required String trackId,
    required double volume,
  }) {
    return database.setTrackVolume(
      trackId: trackId,
      volume:  AudioGainUtils.clampVolume(volume),
    );
  }

  Future<void> setTrackMuted({
    required String trackId,
    required bool isMuted,
  }) {
    return database.setTrackMuted(trackId: trackId, muted: isMuted);
  }

  Future<void> setTrackSolo({
    required String trackId,
    required bool isSolo,
  }) {
    return database.setTrackSolo(trackId: trackId, solo: isSolo);
  }

  // ── Convenience Query ──────────────────────────────────────────────────────

  Future<db.Clip?> getClip(String clipId) {
    return database.getClip(clipId);
  }

  Future<db.Track?> getTrack(String trackId) async {
    try {
      return await database.getTrack(trackId);
    } catch (_) {
      return null;
    }
  }

  Stream<db.Clip?> watchClip(String clipId) {
    return database.watchClip(clipId);
  }

  Stream<List<db.Track>> watchAudioTracks(String projectId) {
    return database.watchProjectTracks(projectId).map(
      (tracks) => tracks.where((t) => t.type == 'audio').toList(),
    );
  }

  Future<String> createAudioClip({
    required String projectId,
    required String trackId,
    required String localPath,
    required String name,
    required int timelineStartMicros,
    required int durationMicros,
    required NleAudioClipKind kind,
    required NleAudioFormatInfo formatInfo,
    String? voiceTakeId,
    bool isVoiceRecording = false,
  }) async {
    final clipId = const Uuid().v4();
    final assetId = const Uuid().v4();
    final now = DateTime.now();

    // Create an Asset first
    await database.insertAsset(
      db.AssetsCompanion.insert(
        id: assetId,
        projectId: projectId,
        originalPath: localPath,
        fileName: name,
        fileType: 'audio',
        durationMicros: Value(durationMicros),
        hasAudio: const Value(true),
        audioChannels: Value(formatInfo.channels),
        audioSampleRate: Value(formatInfo.sampleRate),
        createdAt: Value(now),
      ),
    );

    // Now insert the clip referencing this asset
    await database.insertClip(
      db.ClipsCompanion.insert(
        id: clipId,
        projectId: projectId,
        trackId: trackId,
        assetId: Value(assetId),
        clipType: const Value('audio'),
        timelineStartMicros: Value(timelineStartMicros),
        timelineEndMicros: Value(timelineStartMicros + durationMicros),
        sourceInMicros: const Value(0),
        sourceOutMicros: Value(durationMicros),
        voiceTakeId: Value(voiceTakeId),
        isVoiceRecording: Value(isVoiceRecording),
        createdAt: Value(now),
        modifiedAt: Value(now),
      ),
    );

    return clipId;
  }
}
