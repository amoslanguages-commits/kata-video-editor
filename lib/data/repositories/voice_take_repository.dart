import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/audio/nle_audio_model.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';
import 'package:nle_editor/domain/voice/voice_take_models.dart';

class VoiceTakeRepository {
  final db.AppDatabase database;

  const VoiceTakeRepository({
    required this.database,
  });

  Future<List<NleVoiceTake>> getTakesForProject(String projectId) async {
    final rows = await database.getVoiceTakesForProject(projectId);
    return rows.map(_fromRow).toList();
  }

  Future<List<NleVoiceTake>> getTakesForSession(String sessionId) async {
    final rows = await database.getVoiceTakesForSession(sessionId);
    return rows.map(_fromRow).toList();
  }

  Future<void> saveTake(NleVoiceTake take) {
    return database.upsertVoiceTake(
      db.VoiceTakesCompanion(
        id: Value(take.id),
        projectId: Value(take.projectId),
        sessionId: Value(take.sessionId),
        name: Value(take.name),
        localPath: Value(take.localPath),
        durationMicros: Value(take.durationMicros),
        timelineStartMicros: Value(take.timelineStartMicros),
        status: Value(take.status.name),
        cleanupPreset: Value(take.cleanupPreset.name),
        audioClipId: Value(take.audioClipId),
        waveformCacheId: Value(take.waveformCacheId),
        formatInfoJson: Value(jsonEncode(take.formatInfo.toJson())),
        recordedAt: Value(take.recordedAt),
        updatedAt: Value(DateTime.now()),
        version: Value(take.version),
      ),
    );
  }

  Future<void> deleteTake(String id) {
    return database.deleteVoiceTakeById(id);
  }

  Future<void> linkAudioClip({
    required String takeId,
    required String audioClipId,
  }) {
    return database.updateVoiceTakeAudioClipId(
      takeId: takeId,
      audioClipId: audioClipId,
    );
  }

  NleVoiceTake _fromRow(db.VoiceTake row) {
    return NleVoiceTake(
      id: row.id,
      projectId: row.projectId,
      sessionId: row.sessionId,
      name: row.name,
      localPath: row.localPath,
      durationMicros: row.durationMicros,
      timelineStartMicros: row.timelineStartMicros,
      status: _enumByName(
        NleVoiceTakeStatus.values,
        row.status,
        NleVoiceTakeStatus.draft,
      ),
      cleanupPreset: _enumByName(
        NleVoiceCleanupPreset.values,
        row.cleanupPreset,
        NleVoiceCleanupPreset.none,
      ),
      audioClipId: row.audioClipId,
      waveformCacheId: row.waveformCacheId,
      formatInfo: NleAudioFormatInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.formatInfoJson) as Map),
      ),
      recordedAt: row.recordedAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }

  T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    final string = name?.toString();
    if (string == null) return fallback;

    for (final value in values) {
      if (value.name == string) return value;
    }

    return fallback;
  }
}
