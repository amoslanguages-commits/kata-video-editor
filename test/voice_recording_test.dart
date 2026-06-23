import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db_pkg;
import 'package:nle_editor/data/repositories/audio_repository.dart';
import 'package:nle_editor/data/repositories/audio_effect_repository.dart';
import 'package:nle_editor/data/repositories/voice_recording_repository.dart';
import 'package:nle_editor/data/repositories/voice_take_repository.dart';
import 'package:nle_editor/domain/audio/nle_audio_model.dart';
import 'package:nle_editor/domain/voice/voice_cleanup_preset_applier.dart';
import 'package:nle_editor/domain/voice/voice_recording_session_models.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';
import 'package:nle_editor/domain/voice/voice_take_models.dart';
import 'package:nle_editor/domain/voice/voice_track_helper.dart';
import 'package:nle_editor/platform/audio/native_audio_engine_service.dart';
import 'package:nle_editor/platform/voice/microphone_permission_service.dart';
import 'package:nle_editor/platform/voice/native_voice_recorder_service.dart';
import 'package:nle_editor/domain/voice/voice_recording_path_service.dart';
import 'package:nle_editor/presentation/controllers/voice_recording_controller.dart';
import 'package:nle_editor/presentation/providers/voice_recording_providers.dart';
import 'package:nle_editor/presentation/providers/audio_providers.dart';
import 'package:nle_editor/presentation/providers/database_providers.dart';
import 'package:nle_editor/native_bridge/native_command.dart';

// Fake implementations

class FakeMicrophonePermissionService extends MicrophonePermissionService {
  bool hasPermissionValue = true;

  @override
  Future<bool> hasPermission() async => hasPermissionValue;

  @override
  Future<bool> requestPermission() async => hasPermissionValue;

  @override
  Future<bool> ensurePermission() async => hasPermissionValue;
}

class FakeNativeVoiceRecorderService extends NativeVoiceRecorderService {
  bool isRecordingValue = false;
  NleVoiceRecordingMeter meterValue = const NleVoiceRecordingMeter(peak: 0.5, rms: 0.3, clipping: false);
  String? lastPreparedPath;

  @override
  Future<void> prepare({
    required String outputPath,
    required NleVoiceRecordingQualitySettings settings,
    required NleVoiceMonitoringMode monitoringMode,
  }) async {
    lastPreparedPath = outputPath;
  }

  @override
  Future<void> start() async {
    isRecordingValue = true;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<NleNativeVoiceRecordingResult> stop() async {
    isRecordingValue = false;
    return NleNativeVoiceRecordingResult(
      outputPath: lastPreparedPath ?? '/path/to/take.m4a',
      durationMicros: 5000000,
      formatInfo: const NleAudioFormatInfo(
        sampleRate: 48000,
        channels: 1,
        bitDepth: 16,
        codec: 'aac',
        bitrate: 128000,
      ),
    );
  }

  @override
  Future<void> cancel() async {
    isRecordingValue = false;
  }

  @override
  Future<NleVoiceRecordingMeter> getMeter() async {
    return meterValue;
  }

  @override
  Future<bool> isRecording() async {
    return isRecordingValue;
  }
}

class FakeNativeAudioEngineService implements NativeAudioEngineService {
  @override
  Future<NativeCommandResult> loadAudioGraph(NleAudioGraph graph) async {
    return const NativeCommandResult(commandId: 'load_graph', accepted: true);
  }

  @override
  Future<NativeCommandResult> updateAudioGraph(NleAudioGraph graph) async {
    return const NativeCommandResult(commandId: 'update_graph', accepted: true);
  }

  @override
  Future<NativeCommandResult> pause([String projectId = '']) async {
    return const NativeCommandResult(commandId: 'pause', accepted: true);
  }

  @override
  Future<NativeCommandResult> setTrackVolume({required String projectId, required String trackId, required double volume}) async {
    return const NativeCommandResult(commandId: 'track_vol', accepted: true);
  }

  @override
  Future<NativeCommandResult> setTrackMute({required String projectId, required String trackId, required bool isMuted}) async {
    return const NativeCommandResult(commandId: 'track_mute', accepted: true);
  }

  @override
  Future<NativeCommandResult> setTrackSolo({required String projectId, required String trackId, required bool isSolo}) async {
    return const NativeCommandResult(commandId: 'track_solo', accepted: true);
  }

  @override
  Future<NativeCommandResult> setClipVolume({required String projectId, required String trackId, required String clipId, required double volume}) async {
    return const NativeCommandResult(commandId: 'clip_vol', accepted: true);
  }

  @override
  Future<NativeCommandResult> setClipMute({required String projectId, required String trackId, required String clipId, required bool isMuted}) async {
    return const NativeCommandResult(commandId: 'clip_mute', accepted: true);
  }

  @override
  Future<NativeCommandResult> requestMixdown({
    required String projectId,
    required String outputPath,
    required NleAudioGraph graph,
    required Map<String, dynamic> exportProfile,
  }) async {
    return const NativeCommandResult(commandId: 'mixdown', accepted: true);
  }

  @override
  Future<NativeCommandResult> startMeterUpdates(String projectId) async {
    return const NativeCommandResult(commandId: 'start_meter', accepted: true);
  }

  @override
  Future<NativeCommandResult> stopMeterUpdates(String projectId) async {
    return const NativeCommandResult(commandId: 'stop_meter', accepted: true);
  }
}

class FakeVoiceRecordingPathService extends VoiceRecordingPathService {
  final String tempDir;
  FakeVoiceRecordingPathService(this.tempDir);

  @override
  Future<String> createTakePath({
    required String projectId,
    required String takeId,
    required String extension,
  }) async {
    final voiceDir = Directory('$tempDir/projects/$projectId/voice_takes');
    if (!voiceDir.existsSync()) {
      voiceDir.createSync(recursive: true);
    }
    return '${voiceDir.path}/take_$takeId.$extension';
  }

  @override
  Future<void> deleteFileIfExists(String localPath) async {
    final file = File(localPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

void main() {
  group('Voice Recording Value and Session Models Tests', () {
    test('NleVoiceRecordingMeter JSON serialization', () {
      const meter = NleVoiceRecordingMeter(peak: 0.8, rms: 0.4, clipping: true);
      final json = meter.toJson();
      expect(json['peak'], 0.8);
      expect(json['rms'], 0.4);
      expect(json['clipping'], true);

      final fromJson = NleVoiceRecordingMeter.fromJson(json);
      expect(fromJson.peak, 0.8);
      expect(fromJson.rms, 0.4);
      expect(fromJson.clipping, true);
    });

    test('NleVoiceRecordingQualitySettings quality mappings', () {
      final std = NleVoiceRecordingQualitySettings.forQuality(NleVoiceRecordingQuality.standard);
      expect(std.bitrate, 128000);
      expect(std.container, 'm4a');
      expect(std.codec, 'aac');

      final studio = NleVoiceRecordingQualitySettings.forQuality(NleVoiceRecordingQuality.studio);
      expect(studio.bitrate, 256000);
    });
  });

  group('Voice Take Repository & Recording Integration Tests', () {
    late db_pkg.AppDatabase db;
    late VoiceTakeRepository takeRepository;
    late AudioRepository audioRepository;
    late AudioEffectRepository effectRepository;
    late VoiceCleanupPresetApplier cleanupApplier;
    late VoiceRecordingRepository recordingRepository;
    late VoiceTrackHelper voiceTrackHelper;

    setUp(() async {
      db = db_pkg.AppDatabase(NativeDatabase.memory());
      takeRepository = VoiceTakeRepository(database: db);
      audioRepository = AudioRepository(database: db);
      effectRepository = AudioEffectRepository(database: db);
      cleanupApplier = VoiceCleanupPresetApplier(effectRepository: effectRepository);
      recordingRepository = VoiceRecordingRepository(
        audioRepository: audioRepository,
        takeRepository: takeRepository,
        cleanupPresetApplier: cleanupApplier,
      );
      voiceTrackHelper = VoiceTrackHelper(audioRepository: audioRepository);

      // Create a project
      await db.insertProject(
        db_pkg.ProjectsCompanion.insert(
          id: 'proj_1',
          name: 'Test Project',
          aspectRatio: const Value('16:9'),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Saves and loads voice take in database', () async {
      final take = NleVoiceTake(
        id: 'take_1',
        projectId: 'proj_1',
        sessionId: 'session_1',
        name: 'Take 1',
        localPath: '/local/path/take_1.m4a',
        durationMicros: 3000000,
        timelineStartMicros: 0,
        status: NleVoiceTakeStatus.draft,
        cleanupPreset: NleVoiceCleanupPreset.podcastVoice,
        formatInfo: const NleAudioFormatInfo(
          sampleRate: 48000,
          channels: 1,
          bitDepth: 16,
          codec: 'aac',
          bitrate: 128000,
        ),
        recordedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      await takeRepository.saveTake(take);

      final loaded = await takeRepository.getTakesForProject('proj_1');
      expect(loaded.length, 1);
      expect(loaded.first.id, 'take_1');
      expect(loaded.first.cleanupPreset, NleVoiceCleanupPreset.podcastVoice);
    });

    test('Inserts voice take as physical audio clip in database', () async {
      final take = NleVoiceTake(
        id: 'take_1',
        projectId: 'proj_1',
        sessionId: 'session_1',
        name: 'Take 1',
        localPath: '/local/path/take_1.m4a',
        durationMicros: 3000000,
        timelineStartMicros: 1000000,
        status: NleVoiceTakeStatus.draft,
        cleanupPreset: NleVoiceCleanupPreset.podcastVoice,
        formatInfo: const NleAudioFormatInfo(
          sampleRate: 48000,
          channels: 1,
          bitDepth: 16,
          codec: 'aac',
          bitrate: 128000,
        ),
        recordedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      await takeRepository.saveTake(take);

      final voiceTrackId = await voiceTrackHelper.ensureVoiceTrack('proj_1');

      final clipId = await recordingRepository.insertTakeAsAudioClip(
        take: take,
        voiceTrackId: voiceTrackId,
        insertMode: NleVoiceInsertMode.insertAtPlayhead,
      );

      // Verify that the clip exists and has the correct fields
      final clip = await audioRepository.getClip(clipId);
      expect(clip, isNotNull);
      expect(clip!.voiceTakeId, 'take_1');
      expect(clip.isVoiceRecording, isTrue);
      expect(clip.timelineStartMicros, 1000000);
      expect(clip.timelineEndMicros, 4000000);

      // Verify that the take is updated with the clipId
      final takes = await takeRepository.getTakesForProject('proj_1');
      expect(takes.first.audioClipId, clipId);
    });
  });

  group('VoiceRecordingController state machine tests', () {
    late db_pkg.AppDatabase db;
    late VoiceTakeRepository takeRepository;
    late AudioRepository audioRepository;
    late AudioEffectRepository effectRepository;
    late VoiceCleanupPresetApplier cleanupApplier;
    late VoiceRecordingRepository recordingRepository;
    late VoiceTrackHelper voiceTrackHelper;

    late FakeMicrophonePermissionService permissionService;
    late FakeNativeVoiceRecorderService nativeRecorder;
    late FakeNativeAudioEngineService nativeAudio;
    late FakeVoiceRecordingPathService pathService;

    late ProviderContainer container;
    late String tempDir;

    setUp(() async {
      db = db_pkg.AppDatabase(NativeDatabase.memory());
      takeRepository = VoiceTakeRepository(database: db);
      audioRepository = AudioRepository(database: db);
      effectRepository = AudioEffectRepository(database: db);
      cleanupApplier = VoiceCleanupPresetApplier(effectRepository: effectRepository);
      recordingRepository = VoiceRecordingRepository(
        audioRepository: audioRepository,
        takeRepository: takeRepository,
        cleanupPresetApplier: cleanupApplier,
      );
      voiceTrackHelper = VoiceTrackHelper(audioRepository: audioRepository);

      permissionService = FakeMicrophonePermissionService();
      nativeRecorder = FakeNativeVoiceRecorderService();
      nativeAudio = FakeNativeAudioEngineService();

      tempDir = '${Directory.current.path}/build/test_voice_${DateTime.now().millisecondsSinceEpoch}';
      pathService = FakeVoiceRecordingPathService(tempDir);

      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          audioRepositoryProvider.overrideWithValue(audioRepository),
          voiceTakeRepositoryProvider.overrideWithValue(takeRepository),
          voiceCleanupPresetApplierProvider.overrideWithValue(cleanupApplier),
          voiceRecordingRepositoryProvider.overrideWithValue(recordingRepository),
          voiceTrackHelperProvider.overrideWithValue(voiceTrackHelper),
          microphonePermissionServiceProvider.overrideWithValue(permissionService),
          nativeVoiceRecorderServiceProvider.overrideWithValue(nativeRecorder),
          nativeAudioEngineServiceProvider.overrideWithValue(nativeAudio),
          voiceRecordingPathServiceProvider.overrideWithValue(pathService),
        ],
      );

      // Create a project
      await db.insertProject(
        db_pkg.ProjectsCompanion.insert(
          id: 'proj_1',
          name: 'Test Project',
          aspectRatio: const Value('16:9'),
        ),
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      final dir = Directory(tempDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    test('Initializes with default settings and tracks', () async {
      final args = const VoiceRecordingControllerArgs(
        projectId: 'proj_1',
        timelinePlayheadMicros: 2000000,
      );

      final notifier = container.read(voiceRecordingControllerProvider(args).notifier);
      await notifier.initialize();

      final state = container.read(voiceRecordingControllerProvider(args));
      expect(state.status, NleVoiceRecordingStatus.idle);
      expect(state.timelineStartMicros, 2000000);
      expect(state.takes, isEmpty);
      expect(state.voiceTrackId, isNotEmpty);
    });

    test('Flow: prepare -> countdown -> record -> pause -> resume -> stop', () async {
      final args = const VoiceRecordingControllerArgs(
        projectId: 'proj_1',
        timelinePlayheadMicros: 2000000,
      );

      final notifier = container.read(voiceRecordingControllerProvider(args).notifier);
      // Wait for initialization
      await notifier.initialize();

      // Start recording with 1 second countdown
      notifier.setCountdownSeconds(1);
      final future = notifier.startRecording(cleanupPreset: NleVoiceCleanupPreset.warmNarration);

      // Verify prepares correctly (wait a microtask for async permission and path checks to run)
      await Future<void>.delayed(Duration.zero);
      expect(container.read(voiceRecordingControllerProvider(args)).status, NleVoiceRecordingStatus.countingDown);

      await future;

      // Now it should be recording
      expect(container.read(voiceRecordingControllerProvider(args)).status, NleVoiceRecordingStatus.recording);
      expect(container.read(voiceRecordingControllerProvider(args)).activeTakeId, isNotNull);

      // Pause
      await notifier.pauseRecording();
      expect(container.read(voiceRecordingControllerProvider(args)).status, NleVoiceRecordingStatus.paused);

      // Resume
      await notifier.resumeRecording();
      expect(container.read(voiceRecordingControllerProvider(args)).status, NleVoiceRecordingStatus.recording);

      // Stop
      final take = await notifier.stopRecording(
        insertIntoTimeline: true,
        cleanupPreset: NleVoiceCleanupPreset.warmNarration,
      );

      expect(take, isNotNull);
      expect(take!.status, NleVoiceTakeStatus.inserted);
      expect(take.cleanupPreset, NleVoiceCleanupPreset.warmNarration);

      final finalState = container.read(voiceRecordingControllerProvider(args));
      expect(finalState.status, NleVoiceRecordingStatus.completed);
      expect(finalState.takes.length, 1);
      expect(finalState.takes.first.id, take.id);
    });

    test('Flow: start -> cancel', () async {
      final args = const VoiceRecordingControllerArgs(
        projectId: 'proj_1',
        timelinePlayheadMicros: 2000000,
      );

      final notifier = container.read(voiceRecordingControllerProvider(args).notifier);
      await notifier.initialize();

      notifier.setCountdownSeconds(0);
      await notifier.startRecording();

      expect(container.read(voiceRecordingControllerProvider(args)).status, NleVoiceRecordingStatus.recording);

      await notifier.cancelRecording();

      expect(container.read(voiceRecordingControllerProvider(args)).status, NleVoiceRecordingStatus.cancelled);
      expect(container.read(voiceRecordingControllerProvider(args)).activeTakeId, isNull);
    });
  });
}
