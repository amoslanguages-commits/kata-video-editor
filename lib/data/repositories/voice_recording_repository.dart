import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/repositories/audio_repository.dart';
import 'package:nle_editor/data/repositories/voice_take_repository.dart';
import 'package:nle_editor/domain/audio/nle_audio_model.dart';
import 'package:nle_editor/domain/voice/voice_cleanup_preset_applier.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';
import 'package:nle_editor/domain/voice/voice_take_models.dart';

class VoiceRecordingRepository {
  final AudioRepository audioRepository;
  final VoiceTakeRepository takeRepository;
  final VoiceCleanupPresetApplier cleanupPresetApplier;

  const VoiceRecordingRepository({
    required this.audioRepository,
    required this.takeRepository,
    required this.cleanupPresetApplier,
  });

  Future<NleVoiceTake> createTake({
    required String projectId,
    required String sessionId,
    required String localPath,
    required int durationMicros,
    required int timelineStartMicros,
    required NleVoiceCleanupPreset cleanupPreset,
    required NleAudioFormatInfo formatInfo,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final take = NleVoiceTake(
      id: id,
      projectId: projectId,
      sessionId: sessionId,
      name: 'Voice Take ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      localPath: localPath,
      durationMicros: durationMicros,
      timelineStartMicros: timelineStartMicros,
      status: NleVoiceTakeStatus.draft,
      cleanupPreset: cleanupPreset,
      formatInfo: formatInfo,
      recordedAt: now,
      updatedAt: now,
      version: 1,
    );

    await takeRepository.saveTake(take);
    return take;
  }

  Future<String> insertTakeAsAudioClip({
    required NleVoiceTake take,
    required String voiceTrackId,
    required NleVoiceInsertMode insertMode,
  }) async {
    final audioClipId = await audioRepository.createAudioClip(
      projectId: take.projectId,
      trackId: voiceTrackId,
      localPath: take.localPath,
      name: take.name,
      timelineStartMicros: take.timelineStartMicros,
      durationMicros: take.durationMicros,
      kind: NleAudioClipKind.voiceOver,
      formatInfo: take.formatInfo,
      voiceTakeId: take.id,
      isVoiceRecording: true,
    );

    await takeRepository.linkAudioClip(
      takeId: take.id,
      audioClipId: audioClipId,
    );

    await cleanupPresetApplier.applyToAudioClip(
      audioClipId: audioClipId,
      preset: take.cleanupPreset,
    );

    return audioClipId;
  }
}
