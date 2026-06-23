enum NleVoiceRecordingStatus {
  idle,
  preparing,
  countingDown,
  recording,
  paused,
  stopping,
  completed,
  cancelled,
  failed,
}

enum NleVoiceTakeStatus {
  draft,
  selected,
  inserted,
  rejected,
  archived,
}

enum NleVoiceRecordingInputMode {
  microphone,
  headset,
  bluetooth,
  systemDefault,
}

enum NleVoiceMonitoringMode {
  off,
  lowLatency,
  safeDelayed,
}

enum NleVoiceRecordingQuality {
  draft,
  standard,
  high,
  studio,
}

enum NleVoiceCleanupPreset {
  none,
  cleanVoice,
  podcastVoice,
  noisyRoomCleanup,
  loudSocialVoice,
  warmNarration,
}

enum NleVoiceInsertMode {
  insertAtPlayhead,
  replaceSelectedTake,
  appendToVoiceTrack,
  createNewVoiceTrack,
}

class NleVoiceRecordingMeter {
  final double peak;
  final double rms;
  final bool clipping;

  const NleVoiceRecordingMeter({
    required this.peak,
    required this.rms,
    required this.clipping,
  });

  const NleVoiceRecordingMeter.silent()
      : peak = 0.0,
        rms = 0.0,
        clipping = false;

  Map<String, dynamic> toJson() {
    return {
      'peak': peak,
      'rms': rms,
      'clipping': clipping,
    };
  }

  factory NleVoiceRecordingMeter.fromJson(Map<String, dynamic> json) {
    return NleVoiceRecordingMeter(
      peak: (json['peak'] as num?)?.toDouble() ?? 0.0,
      rms: (json['rms'] as num?)?.toDouble() ?? 0.0,
      clipping: json['clipping'] == true,
    );
  }
}

class NleVoiceRecordingQualitySettings {
  final int sampleRate;
  final int channelCount;
  final int bitrate;
  final String container;
  final String codec;

  const NleVoiceRecordingQualitySettings({
    required this.sampleRate,
    required this.channelCount,
    required this.bitrate,
    required this.container,
    required this.codec,
  });

  const NleVoiceRecordingQualitySettings.standard()
      : sampleRate = 48000,
        channelCount = 1,
        bitrate = 128000,
        container = 'm4a',
        codec = 'aac';

  const NleVoiceRecordingQualitySettings.high()
      : sampleRate = 48000,
        channelCount = 1,
        bitrate = 192000,
        container = 'm4a',
        codec = 'aac';

  const NleVoiceRecordingQualitySettings.studio()
      : sampleRate = 48000,
        channelCount = 1,
        bitrate = 256000,
        container = 'm4a',
        codec = 'aac';

  factory NleVoiceRecordingQualitySettings.forQuality(
    NleVoiceRecordingQuality quality,
  ) {
    switch (quality) {
      case NleVoiceRecordingQuality.draft:
        return const NleVoiceRecordingQualitySettings(
          sampleRate: 44100,
          channelCount: 1,
          bitrate: 96000,
          container: 'm4a',
          codec: 'aac',
        );

      case NleVoiceRecordingQuality.standard:
        return const NleVoiceRecordingQualitySettings.standard();

      case NleVoiceRecordingQuality.high:
        return const NleVoiceRecordingQualitySettings.high();

      case NleVoiceRecordingQuality.studio:
        return const NleVoiceRecordingQualitySettings.studio();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sampleRate': sampleRate,
      'channelCount': channelCount,
      'bitrate': bitrate,
      'container': container,
      'codec': codec,
    };
  }

  factory NleVoiceRecordingQualitySettings.fromJson(
    Map<String, dynamic> json,
  ) {
    return NleVoiceRecordingQualitySettings(
      sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 48000,
      channelCount: (json['channelCount'] as num?)?.toInt() ?? 1,
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 128000,
      container: json['container']?.toString() ?? 'm4a',
      codec: json['codec']?.toString() ?? 'aac',
    );
  }
}
