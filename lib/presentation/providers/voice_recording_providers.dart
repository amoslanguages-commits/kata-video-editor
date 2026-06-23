import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/audio_repository.dart';
import 'package:nle_editor/data/repositories/voice_recording_repository.dart';
import 'package:nle_editor/data/repositories/voice_take_repository.dart';
import 'package:nle_editor/domain/voice/voice_cleanup_preset_applier.dart';
import 'package:nle_editor/domain/voice/voice_recording_path_service.dart';
import 'package:nle_editor/domain/voice/voice_recording_session_models.dart';
import 'package:nle_editor/domain/voice/voice_track_helper.dart';
import 'package:nle_editor/platform/audio/native_audio_engine_service.dart';
import 'package:nle_editor/platform/voice/microphone_permission_service.dart';
import 'package:nle_editor/platform/voice/native_voice_recorder_service.dart';
import 'package:nle_editor/presentation/controllers/voice_recording_controller.dart';
import 'package:nle_editor/presentation/providers/audio_effect_providers.dart';
import 'package:nle_editor/presentation/providers/audio_providers.dart';
import 'package:nle_editor/presentation/providers/database_providers.dart';

final microphonePermissionServiceProvider =
    Provider<MicrophonePermissionService>((ref) {
  return const MicrophonePermissionService();
});

final nativeVoiceRecorderServiceProvider =
    Provider<NativeVoiceRecorderService>((ref) {
  return const NativeVoiceRecorderService();
});

final voiceRecordingPathServiceProvider =
    Provider<VoiceRecordingPathService>((ref) {
  return const VoiceRecordingPathService();
});

final voiceTakeRepositoryProvider = Provider<VoiceTakeRepository>((ref) {
  return VoiceTakeRepository(
    database: ref.watch(appDatabaseProvider),
  );
});

final voiceCleanupPresetApplierProvider =
    Provider<VoiceCleanupPresetApplier>((ref) {
  return VoiceCleanupPresetApplier(
    effectRepository: ref.watch(audioEffectRepositoryProvider),
  );
});

final voiceRecordingRepositoryProvider =
    Provider<VoiceRecordingRepository>((ref) {
  return VoiceRecordingRepository(
    audioRepository: ref.watch(audioRepositoryProvider),
    takeRepository: ref.watch(voiceTakeRepositoryProvider),
    cleanupPresetApplier: ref.watch(voiceCleanupPresetApplierProvider),
  );
});

final voiceTrackHelperProvider = Provider<VoiceTrackHelper>((ref) {
  return VoiceTrackHelper(
    audioRepository: ref.watch(audioRepositoryProvider),
  );
});

class VoiceRecordingControllerArgs {
  final String projectId;
  final int timelinePlayheadMicros;

  const VoiceRecordingControllerArgs({
    required this.projectId,
    required this.timelinePlayheadMicros,
  });

  @override
  bool operator ==(Object other) {
    return other is VoiceRecordingControllerArgs &&
        other.projectId == projectId &&
        other.timelinePlayheadMicros == timelinePlayheadMicros;
  }

  @override
  int get hashCode => Object.hash(projectId, timelinePlayheadMicros);
}

final voiceRecordingControllerProvider =
    StateNotifierProvider.family<
        VoiceRecordingController,
        NleVoiceRecordingSession,
        VoiceRecordingControllerArgs>((ref, args) {
  return VoiceRecordingController(
    projectId: args.projectId,
    timelinePlayheadMicros: args.timelinePlayheadMicros,
    permissionService: ref.watch(microphonePermissionServiceProvider),
    nativeRecorder: ref.watch(nativeVoiceRecorderServiceProvider),
    nativeAudio: ref.watch(nativeAudioEngineServiceProvider),
    pathService: ref.watch(voiceRecordingPathServiceProvider),
    recordingRepository: ref.watch(voiceRecordingRepositoryProvider),
    takeRepository: ref.watch(voiceTakeRepositoryProvider),
    audioRepository: ref.watch(audioRepositoryProvider),
    voiceTrackHelper: ref.watch(voiceTrackHelperProvider),
  );
});
