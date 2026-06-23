import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/domain/services/app_permission_service.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/domain/services/timeline_command_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class VoiceoverState {
  final bool isRecording;
  final bool isPaused;
  final int durationMicros;
  final String? filePath;

  const VoiceoverState({
    this.isRecording = false,
    this.isPaused = false,
    this.durationMicros = 0,
    this.filePath,
  });

  VoiceoverState copyWith({
    bool? isRecording,
    bool? isPaused,
    int? durationMicros,
    String? filePath,
  }) {
    return VoiceoverState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      durationMicros: durationMicros ?? this.durationMicros,
      filePath: filePath ?? this.filePath,
    );
  }
}

class VoiceoverRecordingService extends StateNotifier<VoiceoverState> {
  final AppPermissionService _permissionService;
  final ProjectStorageService _storageService;
  final AssetRepository _assetRepository;
  final TimelineCommandService _timelineCommandService;

  final RecorderController _recorderController = RecorderController();

  Timer? _timer;
  String? _currentProjectId;
  int _currentTimelineStartMicros = 0;
  DateTime? _startTime;
  int _accumulatedMicros = 0;

  VoiceoverRecordingService({
    required AppPermissionService permissionService,
    required ProjectStorageService storageService,
    required AssetRepository assetRepository,
    required TimelineCommandService timelineCommandService,
  })  : _permissionService = permissionService,
        _storageService = storageService,
        _assetRepository = assetRepository,
        _timelineCommandService = timelineCommandService,
        super(const VoiceoverState());

  static const _uuid = Uuid();

  Future<bool> startRecording({
    required String projectId,
    required int timelineStartMicros,
  }) async {
    if (state.isRecording) return false;

    // 1. Ensure microphone permission
    final hasAccess = await _permissionService.ensureHasAccess(
      AppPermissionType.microphone,
      projectId: projectId,
      source: 'voiceover_recorder',
    );

    if (!hasAccess) {
      return false;
    }

    _currentProjectId = projectId;
    _currentTimelineStartMicros = timelineStartMicros;
    _accumulatedMicros = 0;
    _startTime = DateTime.now();

    final folders = await _storageService.getProjectFolders(projectId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${folders.temp}/voiceover_$timestamp.wav';

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await _recorderController.record(path: filePath);
      } catch (e) {
        debugPrint('[VoiceoverRecordingService] RecorderController start error: $e');
        return false;
      }
    }

    state = VoiceoverState(
      isRecording: true,
      isPaused: false,
      durationMicros: 0,
      filePath: filePath,
    );

    _startTimer();
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!state.isRecording || state.isPaused) return;
      final now = DateTime.now();
      final delta = now.difference(_startTime!).inMicroseconds;
      state = state.copyWith(
        durationMicros: _accumulatedMicros + delta,
      );
    });
  }

  void pauseRecording() {
    if (!state.isRecording || state.isPaused) return;
    _timer?.cancel();
    final now = DateTime.now();
    _accumulatedMicros += now.difference(_startTime!).inMicroseconds;
    
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        _recorderController.pause();
      } catch (_) {}
    }

    state = state.copyWith(isPaused: true);
  }

  void resumeRecording() {
    if (!state.isRecording || !state.isPaused) return;
    _startTime = DateTime.now();
    
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        _recorderController.record();
      } catch (_) {}
    }

    state = state.copyWith(isPaused: false);
    _startTimer();
  }

  Future<String?> stopRecording() async {
    if (!state.isRecording) return null;

    _timer?.cancel();
    if (!state.isPaused && _startTime != null) {
      final now = DateTime.now();
      _accumulatedMicros += now.difference(_startTime!).inMicroseconds;
    }

    final projectId = _currentProjectId!;
    final filePath = state.filePath!;
    final duration = state.durationMicros;

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await _recorderController.stop();
      } catch (e) {
        debugPrint('[VoiceoverRecordingService] RecorderController stop error: $e');
      }
    } else {
      // Simulate writing a dummy audio file on desktop/test environments
      try {
        final file = File(filePath);
        await file.create(recursive: true);
        // Write some mock WAV headers/bytes
        await file.writeAsBytes(List.generate(100, (i) => i));
      } catch (_) {}
    }

    final assetId = _uuid.v4();
    final fileName = 'Voiceover_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.wav';

    // Insert voiceover asset
    await _assetRepository.insertAsset(
      AssetsCompanion.insert(
        id: assetId,
        projectId: projectId,
        originalPath: filePath,
        fileName: fileName,
        fileSize: const Value(1024),
        fileType: 'audio',
        hasVideo: const Value(false),
        hasAudio: const Value(true),
        importStatus: const Value('ready'),
        durationMicros: Value(duration),
        waveformStatus: const Value('pending'),
      ),
    );

    // Auto-insert clip onto timeline
    final clipId = await _timelineCommandService.addAssetToTimeline(
      projectId: projectId,
      assetId: assetId,
      timelineStartMicros: _currentTimelineStartMicros,
    );

    state = const VoiceoverState();
    _currentProjectId = null;
    _currentTimelineStartMicros = 0;

    return clipId;
  }

  Future<void> cancelRecording() async {
    if (!state.isRecording) return;
    _timer?.cancel();

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await _recorderController.stop();
      } catch (_) {}
    }

    final filePath = state.filePath;
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    state = const VoiceoverState();
    _currentProjectId = null;
    _currentTimelineStartMicros = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorderController.dispose();
    super.dispose();
  }
}

final voiceoverRecordingServiceProvider =
    StateNotifierProvider<VoiceoverRecordingService, VoiceoverState>((ref) {
  return VoiceoverRecordingService(
    permissionService: ref.watch(appPermissionServiceProvider),
    storageService: ref.watch(projectStorageServiceProvider),
    assetRepository: ref.watch(assetRepositoryProvider),
    timelineCommandService: ref.watch(timelineCommandServiceProvider),
  );
});
