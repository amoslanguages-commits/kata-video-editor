import 'package:nle_editor/domain/audio/nle_audio_model.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';

class NleVoiceTake {
  final String id;
  final String projectId;
  final String sessionId;

  final String name;
  final String localPath;
  final int durationMicros;
  final int timelineStartMicros;

  final NleVoiceTakeStatus status;
  final NleVoiceCleanupPreset cleanupPreset;

  final String? audioClipId;
  final String? waveformCacheId;

  final NleAudioFormatInfo formatInfo;

  final DateTime recordedAt;
  final DateTime updatedAt;
  final int version;

  const NleVoiceTake({
    required this.id,
    required this.projectId,
    required this.sessionId,
    required this.name,
    required this.localPath,
    required this.durationMicros,
    required this.timelineStartMicros,
    required this.status,
    required this.cleanupPreset,
    this.audioClipId,
    this.waveformCacheId,
    required this.formatInfo,
    required this.recordedAt,
    required this.updatedAt,
    required this.version,
  });

  bool get inserted => audioClipId != null && status == NleVoiceTakeStatus.inserted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'sessionId': sessionId,
      'name': name,
      'localPath': localPath,
      'durationMicros': durationMicros,
      'timelineStartMicros': timelineStartMicros,
      'status': status.name,
      'cleanupPreset': cleanupPreset.name,
      'audioClipId': audioClipId,
      'waveformCacheId': waveformCacheId,
      'formatInfo': formatInfo.toJson(),
      'recordedAt': recordedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  factory NleVoiceTake.fromJson(Map<String, dynamic> json) {
    return NleVoiceTake(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Voice Take',
      localPath: json['localPath']?.toString() ?? '',
      durationMicros: (json['durationMicros'] as num?)?.toInt() ?? 0,
      timelineStartMicros:
          (json['timelineStartMicros'] as num?)?.toInt() ?? 0,
      status: _enumByName(
        NleVoiceTakeStatus.values,
        json['status'],
        NleVoiceTakeStatus.draft,
      ),
      cleanupPreset: _enumByName(
        NleVoiceCleanupPreset.values,
        json['cleanupPreset'],
        NleVoiceCleanupPreset.none,
      ),
      audioClipId: json['audioClipId']?.toString(),
      waveformCacheId: json['waveformCacheId']?.toString(),
      formatInfo: NleAudioFormatInfo.fromJson(
        Map<String, dynamic>.from(json['formatInfo'] as Map? ?? const {}),
      ),
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleVoiceTake copyWith({
    String? name,
    int? durationMicros,
    int? timelineStartMicros,
    NleVoiceTakeStatus? status,
    NleVoiceCleanupPreset? cleanupPreset,
    String? audioClipId,
    String? waveformCacheId,
    NleAudioFormatInfo? formatInfo,
    DateTime? updatedAt,
    int? version,
  }) {
    return NleVoiceTake(
      id: id,
      projectId: projectId,
      sessionId: sessionId,
      name: name ?? this.name,
      localPath: localPath,
      durationMicros: durationMicros ?? this.durationMicros,
      timelineStartMicros: timelineStartMicros ?? this.timelineStartMicros,
      status: status ?? this.status,
      cleanupPreset: cleanupPreset ?? this.cleanupPreset,
      audioClipId: audioClipId ?? this.audioClipId,
      waveformCacheId: waveformCacheId ?? this.waveformCacheId,
      formatInfo: formatInfo ?? this.formatInfo,
      recordedAt: recordedAt,
      updatedAt: updatedAt ?? DateTime.now(),
      version: version ?? this.version,
    );
  }
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
