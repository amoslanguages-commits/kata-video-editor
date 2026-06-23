// 33A-PRO: Audio Engine Foundation — Audio Meter Model
//
// Provides a live VU/peak meter reading for the audio mixer,
// sent from native Android to Dart via the event channel.

/// Per-channel meter level.
class NleAudioMeterChannel {
  /// RMS level in dBFS. Range: [-96.0, 0.0].
  final double rmsDb;

  /// Peak hold level in dBFS.
  final double peakDb;

  /// True if the channel has clipped (level >= 0 dBFS).
  final bool isClipping;

  const NleAudioMeterChannel({
    required this.rmsDb,
    required this.peakDb,
    required this.isClipping,
  });

  factory NleAudioMeterChannel.silence() {
    return const NleAudioMeterChannel(
      rmsDb:      -96.0,
      peakDb:     -96.0,
      isClipping: false,
    );
  }

  factory NleAudioMeterChannel.fromJson(Map<String, dynamic> json) {
    return NleAudioMeterChannel(
      rmsDb:      (json['rmsDb']  as num?)?.toDouble() ?? -96.0,
      peakDb:     (json['peakDb'] as num?)?.toDouble() ?? -96.0,
      isClipping: json['isClipping'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'rmsDb':      rmsDb,
    'peakDb':     peakDb,
    'isClipping': isClipping,
  };
}

/// A stereo (or multi-channel) meter reading from the native mixer.
class NleAudioMeterReading {
  final String projectId;
  final List<NleAudioMeterChannel> channels;
  final DateTime capturedAt;

  const NleAudioMeterReading({
    required this.projectId,
    required this.channels,
    required this.capturedAt,
  });

  factory NleAudioMeterReading.silence(String projectId) {
    return NleAudioMeterReading(
      projectId:  projectId,
      channels:   [
        NleAudioMeterChannel.silence(),
        NleAudioMeterChannel.silence(),
      ],
      capturedAt: DateTime.now(),
    );
  }

  factory NleAudioMeterReading.fromJson(Map<String, dynamic> json) {
    final ch = (json['channels'] as List<dynamic>? ?? [])
        .map((e) => NleAudioMeterChannel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
    return NleAudioMeterReading(
      projectId:  json['projectId'] as String? ?? '',
      channels:   ch.isEmpty ? [NleAudioMeterChannel.silence()] : ch,
      capturedAt: DateTime.now(),
    );
  }

  /// Left channel (index 0).
  NleAudioMeterChannel get left =>
      channels.isNotEmpty ? channels[0] : NleAudioMeterChannel.silence();

  /// Right channel (index 1 or same as left for mono).
  NleAudioMeterChannel get right =>
      channels.length > 1 ? channels[1] : left;

  /// True if any channel is clipping.
  bool get isClipping => channels.any((c) => c.isClipping);
}

/// State emitted by the AudioMeterController.
class NleAudioMeterState {
  final NleAudioMeterReading reading;
  final bool isActive;

  const NleAudioMeterState({
    required this.reading,
    this.isActive = false,
  });

  factory NleAudioMeterState.idle(String projectId) {
    return NleAudioMeterState(
      reading: NleAudioMeterReading.silence(projectId),
    );
  }
}
