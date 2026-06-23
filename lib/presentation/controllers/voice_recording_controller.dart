import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/repositories/audio_repository.dart';
import 'package:nle_editor/data/repositories/voice_recording_repository.dart';
import 'package:nle_editor/data/repositories/voice_take_repository.dart';
import 'package:nle_editor/domain/voice/voice_recording_path_service.dart';
import 'package:nle_editor/domain/voice/voice_recording_session_models.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';
import 'package:nle_editor/domain/voice/voice_take_models.dart';
import 'package:nle_editor/domain/voice/voice_track_helper.dart';
import 'package:nle_editor/platform/audio/native_audio_engine_service.dart';
import 'package:nle_editor/platform/voice/microphone_permission_service.dart';
import 'package:nle_editor/platform/voice/native_voice_recorder_service.dart';

class VoiceRecordingController
    extends StateNotifier<NleVoiceRecordingSession> {
  final String projectId;
  final int timelinePlayheadMicros;

  final MicrophonePermissionService permissionService;
  final NativeVoiceRecorderService nativeRecorder;
  final NativeAudioEngineService nativeAudio;
  final VoiceRecordingPathService pathService;
  final VoiceRecordingRepository recordingRepository;
  final VoiceTakeRepository takeRepository;
  final AudioRepository audioRepository;
  final VoiceTrackHelper voiceTrackHelper;

  Timer? _meterTimer;
  Timer? _elapsedTimer;
  DateTime? _recordingStartedAt;
  DateTime? _pauseStartedAt;
  int _pausedAccumulatedMicros = 0;

  VoiceRecordingController({
    required this.projectId,
    required this.timelinePlayheadMicros,
    required this.permissionService,
    required this.nativeRecorder,
    required this.nativeAudio,
    required this.pathService,
    required this.recordingRepository,
    required this.takeRepository,
    required this.audioRepository,
    required this.voiceTrackHelper,
  }) : super(const NleVoiceRecordingSession.empty()) {
    initialize();
  }

  Future<void>? _initializeFuture;

  Future<void> initialize() {
    _initializeFuture ??= _performInitialization();
    return _initializeFuture!;
  }

  Future<void> _performInitialization() async {
    final voiceTrackId = await voiceTrackHelper.ensureVoiceTrack(projectId);
    final takes = await takeRepository.getTakesForProject(projectId);
    final now = DateTime.now();

    state = NleVoiceRecordingSession(
      id: const Uuid().v4(),
      projectId: projectId,
      voiceTrackId: voiceTrackId,
      status: NleVoiceRecordingStatus.idle,
      inputMode: NleVoiceRecordingInputMode.systemDefault,
      monitoringMode: NleVoiceMonitoringMode.off,
      quality: NleVoiceRecordingQuality.high,
      qualitySettings: const NleVoiceRecordingQualitySettings.high(),
      countdownSeconds: 3,
      timelineStartMicros: timelinePlayheadMicros,
      elapsedMicros: 0,
      meter: const NleVoiceRecordingMeter.silent(),
      takes: takes,
      createdAt: now,
      updatedAt: now,
    );
  }

  void setQuality(NleVoiceRecordingQuality quality) {
    state = state.copyWith(
      quality: quality,
      qualitySettings: NleVoiceRecordingQualitySettings.forQuality(quality),
    );
  }

  void setCleanupPreset(NleVoiceCleanupPreset preset) {
    final currentTake = state.activeTakeId;
    if (currentTake == null) return;

    final nextTakes = state.takes.map((take) {
      if (take.id != currentTake) return take;
      return take.copyWith(cleanupPreset: preset);
    }).toList();

    state = state.copyWith(takes: nextTakes);
  }

  void setCountdownSeconds(int seconds) {
    state = state.copyWith(countdownSeconds: seconds.clamp(0, 10));
  }

  void setMonitoringMode(NleVoiceMonitoringMode mode) {
    state = state.copyWith(monitoringMode: mode);
  }

  Future<void> startRecording({
    int? timelineStartMicros,
    NleVoiceCleanupPreset cleanupPreset = NleVoiceCleanupPreset.cleanVoice,
  }) async {
    if (!state.canStart) return;

    final allowed = await permissionService.ensurePermission();

    if (!allowed) {
      state = state.copyWith(
        status: NleVoiceRecordingStatus.failed,
        error: 'Microphone permission is required.',
      );
      return;
    }

    await nativeAudio.pause();

    final takeId = const Uuid().v4();
    final outputPath = await pathService.createTakePath(
      projectId: projectId,
      takeId: takeId,
      extension: state.qualitySettings.container,
    );

    state = state.copyWith(
      status: NleVoiceRecordingStatus.preparing,
      timelineStartMicros: timelineStartMicros ?? timelinePlayheadMicros,
      elapsedMicros: 0,
      meter: const NleVoiceRecordingMeter.silent(),
      clearError: true,
    );

    try {
      await nativeRecorder.prepare(
        outputPath: outputPath,
        settings: state.qualitySettings,
        monitoringMode: state.monitoringMode,
      );

      if (state.countdownSeconds > 0) {
        state = state.copyWith(status: NleVoiceRecordingStatus.countingDown);

        await Future<void>.delayed(
          Duration(seconds: state.countdownSeconds),
        );
      }

      await nativeRecorder.start();

      _recordingStartedAt = DateTime.now();
      _pausedAccumulatedMicros = 0;
      _pauseStartedAt = null;

      state = state.copyWith(
        status: NleVoiceRecordingStatus.recording,
        activeTakeId: takeId,
      );

      _startMeters();
      _startElapsedTimer();
    } catch (error) {
      await pathService.deleteFileIfExists(outputPath);

      state = state.copyWith(
        status: NleVoiceRecordingStatus.failed,
        error: error.toString(),
      );
    }
  }

  Future<void> pauseRecording() async {
    if (!state.canPause) return;

    await nativeRecorder.pause();
    _pauseStartedAt = DateTime.now();
    state = state.copyWith(status: NleVoiceRecordingStatus.paused);
  }

  Future<void> resumeRecording() async {
    if (!state.canResume) return;

    await nativeRecorder.resume();
    final pauseStarted = _pauseStartedAt;
    if (pauseStarted != null) {
      _pausedAccumulatedMicros += DateTime.now().difference(pauseStarted).inMicroseconds;
    }
    _pauseStartedAt = null;
    state = state.copyWith(status: NleVoiceRecordingStatus.recording);
  }

  Future<NleVoiceTake?> stopRecording({
    bool insertIntoTimeline = true,
    NleVoiceCleanupPreset cleanupPreset = NleVoiceCleanupPreset.cleanVoice,
  }) async {
    if (!state.canStop) return null;

    state = state.copyWith(status: NleVoiceRecordingStatus.stopping);

    _stopTimers();

    try {
      final result = await nativeRecorder.stop();

      final take = await recordingRepository.createTake(
        projectId: projectId,
        sessionId: state.id,
        localPath: result.outputPath,
        durationMicros: result.durationMicros,
        timelineStartMicros: state.timelineStartMicros,
        cleanupPreset: cleanupPreset,
        formatInfo: result.formatInfo,
      );

      var finalTake = take;

      if (insertIntoTimeline) {
        final clipId = await recordingRepository.insertTakeAsAudioClip(
          take: take,
          voiceTrackId: state.voiceTrackId,
          insertMode: NleVoiceInsertMode.insertAtPlayhead,
        );

        finalTake = take.copyWith(
          audioClipId: clipId,
          status: NleVoiceTakeStatus.inserted,
        );
      }

      final takes = await takeRepository.getTakesForProject(projectId);

      state = state.copyWith(
        status: NleVoiceRecordingStatus.completed,
        elapsedMicros: result.durationMicros,
        meter: const NleVoiceRecordingMeter.silent(),
        takes: takes,
        activeTakeId: finalTake.id,
        clearError: true,
      );

      return finalTake;
    } catch (error) {
      state = state.copyWith(
        status: NleVoiceRecordingStatus.failed,
        error: error.toString(),
      );

      return null;
    }
  }

  Future<void> cancelRecording() async {
    _stopTimers();

    try {
      await nativeRecorder.cancel();
    } catch (_) {}

    state = state.copyWith(
      status: NleVoiceRecordingStatus.cancelled,
      elapsedMicros: 0,
      meter: const NleVoiceRecordingMeter.silent(),
      clearActiveTake: true,
    );
  }

  Future<void> deleteTake(NleVoiceTake take) async {
    await takeRepository.deleteTake(take.id);
    await pathService.deleteFileIfExists(take.localPath);

    final takes = await takeRepository.getTakesForProject(projectId);

    state = state.copyWith(
      takes: takes,
      clearActiveTake: state.activeTakeId == take.id,
    );
  }

  Future<void> insertExistingTake(NleVoiceTake take) async {
    if (take.audioClipId != null) return;

    await recordingRepository.insertTakeAsAudioClip(
      take: take,
      voiceTrackId: state.voiceTrackId,
      insertMode: NleVoiceInsertMode.insertAtPlayhead,
    );

    final takes = await takeRepository.getTakesForProject(projectId);

    state = state.copyWith(takes: takes);
  }

  void _startMeters() {
    _meterTimer?.cancel();

    _meterTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) async {
        if (!mounted) return;

        final meter = await nativeRecorder.getMeter();

        state = state.copyWith(meter: meter);
      },
    );
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        final started = _recordingStartedAt;
        if (started == null) return;

        if (state.status != NleVoiceRecordingStatus.recording) return;

        final elapsed = DateTime.now().difference(started).inMicroseconds -
            _pausedAccumulatedMicros;

        state = state.copyWith(elapsedMicros: elapsed);
      },
    );
  }

  void _stopTimers() {
    _meterTimer?.cancel();
    _elapsedTimer?.cancel();
    _meterTimer = null;
    _elapsedTimer = null;
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
