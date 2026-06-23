import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';
import 'package:nle_editor/domain/voice/voice_take_models.dart';

class NleVoiceRecordingSession {
  final String id;
  final String projectId;
  final String voiceTrackId;

  final NleVoiceRecordingStatus status;
  final NleVoiceRecordingInputMode inputMode;
  final NleVoiceMonitoringMode monitoringMode;
  final NleVoiceRecordingQuality quality;
  final NleVoiceRecordingQualitySettings qualitySettings;

  final int countdownSeconds;
  final int timelineStartMicros;
  final int elapsedMicros;

  final NleVoiceRecordingMeter meter;
  final List<NleVoiceTake> takes;
  final String? activeTakeId;
  final String? error;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NleVoiceRecordingSession({
    required this.id,
    required this.projectId,
    required this.voiceTrackId,
    required this.status,
    required this.inputMode,
    required this.monitoringMode,
    required this.quality,
    required this.qualitySettings,
    required this.countdownSeconds,
    required this.timelineStartMicros,
    required this.elapsedMicros,
    required this.meter,
    required this.takes,
    this.activeTakeId,
    this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  const NleVoiceRecordingSession.empty()
      : id = '',
        projectId = '',
        voiceTrackId = '',
        status = NleVoiceRecordingStatus.idle,
        inputMode = NleVoiceRecordingInputMode.systemDefault,
        monitoringMode = NleVoiceMonitoringMode.off,
        quality = NleVoiceRecordingQuality.high,
        qualitySettings = const NleVoiceRecordingQualitySettings.high(),
        countdownSeconds = 3,
        timelineStartMicros = 0,
        elapsedMicros = 0,
        meter = const NleVoiceRecordingMeter.silent(),
        takes = const [],
        activeTakeId = null,
        error = null,
        createdAt = null,
        updatedAt = null;

  bool get isRecording => status == NleVoiceRecordingStatus.recording;
  bool get canStart => status == NleVoiceRecordingStatus.idle ||
      status == NleVoiceRecordingStatus.completed ||
      status == NleVoiceRecordingStatus.cancelled ||
      status == NleVoiceRecordingStatus.failed;

  bool get canStop => status == NleVoiceRecordingStatus.recording ||
      status == NleVoiceRecordingStatus.paused;

  bool get canPause => status == NleVoiceRecordingStatus.recording;

  bool get canResume => status == NleVoiceRecordingStatus.paused;

  NleVoiceRecordingSession copyWith({
    String? id,
    String? projectId,
    String? voiceTrackId,
    NleVoiceRecordingStatus? status,
    NleVoiceRecordingInputMode? inputMode,
    NleVoiceMonitoringMode? monitoringMode,
    NleVoiceRecordingQuality? quality,
    NleVoiceRecordingQualitySettings? qualitySettings,
    int? countdownSeconds,
    int? timelineStartMicros,
    int? elapsedMicros,
    NleVoiceRecordingMeter? meter,
    List<NleVoiceTake>? takes,
    String? activeTakeId,
    String? error,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearError = false,
    bool clearActiveTake = false,
  }) {
    return NleVoiceRecordingSession(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      voiceTrackId: voiceTrackId ?? this.voiceTrackId,
      status: status ?? this.status,
      inputMode: inputMode ?? this.inputMode,
      monitoringMode: monitoringMode ?? this.monitoringMode,
      quality: quality ?? this.quality,
      qualitySettings: qualitySettings ?? this.qualitySettings,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      timelineStartMicros: timelineStartMicros ?? this.timelineStartMicros,
      elapsedMicros: elapsedMicros ?? this.elapsedMicros,
      meter: meter ?? this.meter,
      takes: takes ?? this.takes,
      activeTakeId: clearActiveTake ? null : activeTakeId ?? this.activeTakeId,
      error: clearError ? null : error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
