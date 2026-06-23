import 'package:flutter/services.dart';

import 'package:nle_editor/domain/audio/nle_audio_model.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';

class NativeVoiceRecorderService {
  static const MethodChannel _channel = MethodChannel('nle/voice_recorder');

  const NativeVoiceRecorderService();

  Future<void> prepare({
    required String outputPath,
    required NleVoiceRecordingQualitySettings settings,
    required NleVoiceMonitoringMode monitoringMode,
  }) async {
    await _channel.invokeMethod(
      'voice_prepare',
      {
        'outputPath': outputPath,
        'sampleRate': settings.sampleRate,
        'channelCount': settings.channelCount,
        'bitrate': settings.bitrate,
        'container': settings.container,
        'codec': settings.codec,
        'monitoringMode': monitoringMode.name,
      },
    );
  }

  Future<void> start() async {
    await _channel.invokeMethod('voice_start');
  }

  Future<void> pause() async {
    await _channel.invokeMethod('voice_pause');
  }

  Future<void> resume() async {
    await _channel.invokeMethod('voice_resume');
  }

  Future<NleNativeVoiceRecordingResult> stop() async {
    final result = await _channel.invokeMethod<Map>('voice_stop');

    if (result == null) {
      throw StateError('Native voice recorder returned null stop result');
    }

    return NleNativeVoiceRecordingResult.fromJson(
      Map<String, dynamic>.from(result),
    );
  }

  Future<void> cancel() async {
    await _channel.invokeMethod('voice_cancel');
  }

  Future<NleVoiceRecordingMeter> getMeter() async {
    final result = await _channel.invokeMethod<Map>('voice_meter');

    if (result == null) return const NleVoiceRecordingMeter.silent();

    return NleVoiceRecordingMeter.fromJson(
      Map<String, dynamic>.from(result),
    );
  }

  Future<bool> isRecording() async {
    final result = await _channel.invokeMethod<bool>('voice_is_recording');
    return result == true;
  }
}

class NleNativeVoiceRecordingResult {
  final String outputPath;
  final int durationMicros;
  final NleAudioFormatInfo formatInfo;

  const NleNativeVoiceRecordingResult({
    required this.outputPath,
    required this.durationMicros,
    required this.formatInfo,
  });

  factory NleNativeVoiceRecordingResult.fromJson(Map<String, dynamic> json) {
    return NleNativeVoiceRecordingResult(
      outputPath: json['outputPath']?.toString() ?? '',
      durationMicros: (json['durationMicros'] as num?)?.toInt() ?? 0,
      formatInfo: NleAudioFormatInfo.fromJson(
        Map<String, dynamic>.from(json['formatInfo'] as Map? ?? const {}),
      ),
    );
  }
}
