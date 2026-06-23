// 33A-PRO: Audio Engine Foundation — Core Domain Models
//
// Architecture:
//   AudioTrack → AudioClip → WaveformCache → AudioGraph → Native Mixer
//
// The NleAudioGraph is the single source-of-truth that is serialised and sent
// to the native Android audio engine via the method channel. It mirrors the
// structure of RenderGraphDto so the same call path (loadRenderGraph /
// updateRenderGraph) can carry audio data.

import 'dart:math' as math;

// ── Enumerations ──────────────────────────────────────────────────────────────

/// The semantic role of an audio track in the timeline.
enum NleAudioTrackRole {
  /// Embedded audio from a video clip (primary track audio).
  videoAudio,

  /// A standalone audio-only track (music, SFX, VO).
  standalone,

  /// A voiceover-specific track.
  voiceover,

  /// Music / background music.
  music,

  /// Sound effects.
  sfx,
}

extension NleAudioTrackRoleX on NleAudioTrackRole {
  String get value {
    switch (this) {
      case NleAudioTrackRole.videoAudio:
        return 'video_audio';
      case NleAudioTrackRole.standalone:
        return 'standalone';
      case NleAudioTrackRole.voiceover:
        return 'voiceover';
      case NleAudioTrackRole.music:
        return 'music';
      case NleAudioTrackRole.sfx:
        return 'sfx';
    }
  }

  static NleAudioTrackRole fromString(String v) {
    switch (v) {
      case 'video_audio':
        return NleAudioTrackRole.videoAudio;
      case 'voiceover':
        return NleAudioTrackRole.voiceover;
      case 'music':
        return NleAudioTrackRole.music;
      case 'sfx':
        return NleAudioTrackRole.sfx;
      default:
        return NleAudioTrackRole.standalone;
    }
  }
}

/// The source type of an audio clip.
enum NleAudioClipKind {
  /// Extracted from a video asset's embedded audio stream.
  videoEmbedded,

  /// An independent audio file (mp3, aac, wav …).
  audioFile,

  /// Recorded voice-over captured inside the app.
  voiceRecording,

  /// A generated tone / silence / test signal.
  generated,

  /// Recorded voice-over.
  voiceOver,
}

extension NleAudioClipKindX on NleAudioClipKind {
  String get value {
    switch (this) {
      case NleAudioClipKind.videoEmbedded:
        return 'video_embedded';
      case NleAudioClipKind.audioFile:
        return 'audio_file';
      case NleAudioClipKind.voiceRecording:
        return 'voice_recording';
      case NleAudioClipKind.generated:
        return 'generated';
      case NleAudioClipKind.voiceOver:
        return 'voice_over';
    }
  }

  static NleAudioClipKind fromString(String v) {
    switch (v) {
      case 'video_embedded':
        return NleAudioClipKind.videoEmbedded;
      case 'voice_recording':
        return NleAudioClipKind.voiceRecording;
      case 'voice_over':
        return NleAudioClipKind.voiceOver;
      case 'generated':
        return NleAudioClipKind.generated;
      default:
        return NleAudioClipKind.audioFile;
    }
  }
}

/// Fade curve shape.
enum NleAudioFadeCurve {
  linear,
  logarithmic,
  exponential,
  sCurve,
  instant,
}

extension NleAudioFadeCurveX on NleAudioFadeCurve {
  String get value {
    switch (this) {
      case NleAudioFadeCurve.linear:
        return 'linear';
      case NleAudioFadeCurve.logarithmic:
        return 'logarithmic';
      case NleAudioFadeCurve.exponential:
        return 'exponential';
      case NleAudioFadeCurve.sCurve:
        return 's_curve';
      case NleAudioFadeCurve.instant:
        return 'instant';
    }
  }

  static NleAudioFadeCurve fromString(String v) {
    switch (v) {
      case 'logarithmic':
        return NleAudioFadeCurve.logarithmic;
      case 'exponential':
        return NleAudioFadeCurve.exponential;
      case 's_curve':
        return NleAudioFadeCurve.sCurve;
      case 'instant':
        return NleAudioFadeCurve.instant;
      default:
        return NleAudioFadeCurve.linear;
    }
  }
}

// ── Value Objects ─────────────────────────────────────────────────────────────

/// Describes the audio format of an asset or clip.
class NleAudioFormatInfo {
  final int sampleRate;   // e.g. 48000
  final int channels;     // 1 = mono, 2 = stereo
  final int bitDepth;     // 16, 24, 32
  final String codec;     // aac, mp3, pcm, etc.
  final int bitrate;      // bps

  const NleAudioFormatInfo({
    this.sampleRate = 48000,
    this.channels   = 2,
    this.bitDepth   = 16,
    this.codec      = 'aac',
    this.bitrate    = 192000,
  });

  factory NleAudioFormatInfo.fromJson(Map<String, dynamic> json) {
    return NleAudioFormatInfo(
      sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 48000,
      channels:   (json['channels']   as num?)?.toInt() ?? 2,
      bitDepth:   (json['bitDepth']   as num?)?.toInt() ?? 16,
      codec:      json['codec']  as String? ?? 'aac',
      bitrate:    (json['bitrate'] as num?)?.toInt() ?? 192000,
    );
  }

  Map<String, dynamic> toJson() => {
    'sampleRate': sampleRate,
    'channels':   channels,
    'bitDepth':   bitDepth,
    'codec':      codec,
    'bitrate':    bitrate,
  };
}

/// Describes a single fade (in or out) applied to a clip.
class NleAudioFade {
  final int durationMicros;
  final NleAudioFadeCurve curve;

  const NleAudioFade({
    required this.durationMicros,
    this.curve = NleAudioFadeCurve.logarithmic,
  });

  static const NleAudioFade none = NleAudioFade(durationMicros: 0);

  factory NleAudioFade.fromJson(Map<String, dynamic> json) {
    return NleAudioFade(
      durationMicros: (json['durationMicros'] as num?)?.toInt() ?? 0,
      curve: NleAudioFadeCurveX.fromString(json['curve'] as String? ?? 'linear'),
    );
  }

  Map<String, dynamic> toJson() => {
    'durationMicros': durationMicros,
    'curve':          curve.value,
  };

  NleAudioFade copyWith({int? durationMicros, NleAudioFadeCurve? curve}) {
    return NleAudioFade(
      durationMicros: durationMicros ?? this.durationMicros,
      curve:          curve          ?? this.curve,
    );
  }
}

// ── Aggregate Models ──────────────────────────────────────────────────────────

/// Represents an audio track lane in the timeline.
class NleAudioTrack {
  final String id;
  final String projectId;
  final String name;
  final NleAudioTrackRole role;
  final int index;

  final bool isMuted;
  final bool isSolo;
  final bool isLocked;

  /// Linear gain [0.0 … 2.0], 1.0 = unity.
  final double volume;

  /// Pan: -1.0 = hard left, 0.0 = centre, 1.0 = hard right.
  final double pan;

  final String? colorHex;

  /// The DB track id that backs this audio track (for embedded video audio).
  final String? linkedVideoTrackId;

  const NleAudioTrack({
    required this.id,
    required this.projectId,
    required this.name,
    required this.role,
    required this.index,
    this.isMuted            = false,
    this.isSolo             = false,
    this.isLocked           = false,
    this.volume             = 1.0,
    this.pan                = 0.0,
    this.colorHex,
    this.linkedVideoTrackId,
  });

  NleAudioTrack copyWith({
    String? name,
    NleAudioTrackRole? role,
    int? index,
    bool? isMuted,
    bool? isSolo,
    bool? isLocked,
    double? volume,
    double? pan,
    String? colorHex,
    String? linkedVideoTrackId,
  }) {
    return NleAudioTrack(
      id:                  id,
      projectId:           projectId,
      name:                name                ?? this.name,
      role:                role                ?? this.role,
      index:               index               ?? this.index,
      isMuted:             isMuted             ?? this.isMuted,
      isSolo:              isSolo              ?? this.isSolo,
      isLocked:            isLocked            ?? this.isLocked,
      volume:              volume              ?? this.volume,
      pan:                 pan                 ?? this.pan,
      colorHex:            colorHex            ?? this.colorHex,
      linkedVideoTrackId:  linkedVideoTrackId  ?? this.linkedVideoTrackId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                  id,
    'projectId':           projectId,
    'name':                name,
    'role':                role.value,
    'index':               index,
    'isMuted':             isMuted,
    'isSolo':              isSolo,
    'isLocked':            isLocked,
    'volume':              volume,
    'pan':                 pan,
    'colorHex':            colorHex,
    'linkedVideoTrackId':  linkedVideoTrackId,
  };
}

/// Represents a single audio clip in a track.
class NleAudioClip {
  final String id;
  final String projectId;
  final String trackId;
  final String? assetId;

  final NleAudioClipKind kind;

  /// Position in the timeline (µs).
  final int timelineStartMicros;
  final int timelineEndMicros;

  /// Trim handles inside the source file (µs).
  final int sourceInMicros;
  final int sourceOutMicros;

  /// Linear gain [0.0 … 2.0], 1.0 = unity.
  final double volume;

  /// Pan: -1.0 … 1.0.
  final double pan;

  final bool isMuted;

  final NleAudioFade fadeIn;
  final NleAudioFade fadeOut;

  /// Playback speed multiplier.
  final double speed;

  final NleAudioFormatInfo? format;

  final String? voiceTakeId;
  final bool isVoiceRecording;

  const NleAudioClip({
    required this.id,
    required this.projectId,
    required this.trackId,
    required this.assetId,
    required this.kind,
    required this.timelineStartMicros,
    required this.timelineEndMicros,
    required this.sourceInMicros,
    required this.sourceOutMicros,
    this.volume  = 1.0,
    this.pan     = 0.0,
    this.isMuted = false,
    this.fadeIn  = NleAudioFade.none,
    this.fadeOut = NleAudioFade.none,
    this.speed   = 1.0,
    this.format,
    this.voiceTakeId,
    required this.isVoiceRecording,
  });

  int get timelineDurationMicros => timelineEndMicros - timelineStartMicros;
  int get sourceDurationMicros   => sourceOutMicros - sourceInMicros;

  NleAudioClip copyWith({
    String? trackId,
    String? assetId,
    NleAudioClipKind? kind,
    int? timelineStartMicros,
    int? timelineEndMicros,
    int? sourceInMicros,
    int? sourceOutMicros,
    double? volume,
    double? pan,
    bool? isMuted,
    NleAudioFade? fadeIn,
    NleAudioFade? fadeOut,
    double? speed,
    NleAudioFormatInfo? format,
    String? voiceTakeId,
    bool? isVoiceRecording,
  }) {
    return NleAudioClip(
      id:                   id,
      projectId:            projectId,
      trackId:              trackId              ?? this.trackId,
      assetId:              assetId              ?? this.assetId,
      kind:                 kind                 ?? this.kind,
      timelineStartMicros:  timelineStartMicros  ?? this.timelineStartMicros,
      timelineEndMicros:    timelineEndMicros    ?? this.timelineEndMicros,
      sourceInMicros:       sourceInMicros       ?? this.sourceInMicros,
      sourceOutMicros:      sourceOutMicros      ?? this.sourceOutMicros,
      volume:               volume               ?? this.volume,
      pan:                  pan                  ?? this.pan,
      isMuted:              isMuted              ?? this.isMuted,
      fadeIn:               fadeIn               ?? this.fadeIn,
      fadeOut:              fadeOut              ?? this.fadeOut,
      speed:                speed                ?? this.speed,
      format:               format               ?? this.format,
      voiceTakeId:          voiceTakeId          ?? this.voiceTakeId,
      isVoiceRecording:     isVoiceRecording     ?? this.isVoiceRecording,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                  id,
    'projectId':           projectId,
    'trackId':             trackId,
    'assetId':             assetId,
    'kind':                kind.value,
    'timelineStartMicros': timelineStartMicros,
    'timelineEndMicros':   timelineEndMicros,
    'sourceInMicros':      sourceInMicros,
    'sourceOutMicros':     sourceOutMicros,
    'volume':              volume,
    'pan':                 pan,
    'isMuted':             isMuted,
    'fadeIn':              fadeIn.toJson(),
    'fadeOut':             fadeOut.toJson(),
    'speed':               speed,
    if (format != null) 'format': format!.toJson(),
    if (voiceTakeId != null) 'voiceTakeId': voiceTakeId,
    'isVoiceRecording':    isVoiceRecording,
  };

  factory NleAudioClip.fromJson(Map<String, dynamic> json) {
    return NleAudioClip(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      trackId: json['trackId']?.toString() ?? '',
      assetId: json['assetId']?.toString(),
      kind: NleAudioClipKindX.fromString(json['kind']?.toString() ?? ''),
      timelineStartMicros: (json['timelineStartMicros'] as num?)?.toInt() ?? 0,
      timelineEndMicros: (json['timelineEndMicros'] as num?)?.toInt() ?? 0,
      sourceInMicros: (json['sourceInMicros'] as num?)?.toInt() ?? 0,
      sourceOutMicros: (json['sourceOutMicros'] as num?)?.toInt() ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      pan: (json['pan'] as num?)?.toDouble() ?? 0.0,
      isMuted: json['isMuted'] == true,
      fadeIn: json['fadeIn'] != null ? NleAudioFade.fromJson(Map<String, dynamic>.from(json['fadeIn'] as Map)) : NleAudioFade.none,
      fadeOut: json['fadeOut'] != null ? NleAudioFade.fromJson(Map<String, dynamic>.from(json['fadeOut'] as Map)) : NleAudioFade.none,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      format: json['format'] != null ? NleAudioFormatInfo.fromJson(Map<String, dynamic>.from(json['format'] as Map)) : null,
      voiceTakeId: json['voiceTakeId']?.toString(),
      isVoiceRecording: json['isVoiceRecording'] == true,
    );
  }
}

/// Cached waveform data for a single audio asset.
class NleWaveformCache {
  final String assetId;

  /// Path to the waveform peak data file on device.
  final String? peakDataPath;

  /// Inline peak samples normalised to [-1.0, 1.0].
  final List<double> samples;

  /// Number of samples per second stored in [samples].
  final int samplesPerSecond;

  final String status; // 'pending' | 'ready' | 'error'

  const NleWaveformCache({
    required this.assetId,
    this.peakDataPath,
    this.samples           = const [],
    this.samplesPerSecond  = 100,
    this.status            = 'pending',
  });

  bool get isReady => status == 'ready' && samples.isNotEmpty;
}

// ── Audio Graph ───────────────────────────────────────────────────────────────

/// The complete audio representation of a project — serialised and sent to
/// the native audio mixer for both preview and export.
///
/// This is the single source of truth that must be identical for preview and
/// export (per 33A-PRO design principle).
class NleAudioGraph {
  final String projectId;
  final List<NleAudioTrackNode> tracks;

  /// Project-level master volume [0.0 … 2.0].
  final double masterVolume;

  /// Output sample rate (always 48 kHz for export compatibility).
  final int sampleRate;

  /// Number of output channels (2 = stereo).
  final int channels;

  /// Whether auto-ducking of music when VO/dialogue is present is enabled.
  final bool autoDuckingEnabled;

  /// Ducking amount in dB (negative). E.g. -12.0 dB.
  final double duckingAmountDb;

  const NleAudioGraph({
    required this.projectId,
    required this.tracks,
    this.masterVolume      = 1.0,
    this.sampleRate        = 48000,
    this.channels          = 2,
    this.autoDuckingEnabled = false,
    this.duckingAmountDb   = -12.0,
  });

  Map<String, dynamic> toJson() => {
    'projectId':           projectId,
    'masterVolume':        masterVolume,
    'sampleRate':          sampleRate,
    'channels':            channels,
    'autoDuckingEnabled':  autoDuckingEnabled,
    'duckingAmountDb':     duckingAmountDb,
    'tracks':              tracks.map((t) => t.toJson()).toList(),
  };
}

/// A track node inside the audio graph.
class NleAudioTrackNode {
  final String id;
  final String name;
  final String role; // NleAudioTrackRole.value
  final double volume;
  final double pan;
  final bool isMuted;
  final bool isSolo;
  final List<NleAudioClipNode> clips;

  const NleAudioTrackNode({
    required this.id,
    required this.name,
    required this.role,
    required this.volume,
    required this.pan,
    required this.isMuted,
    required this.isSolo,
    required this.clips,
  });

  Map<String, dynamic> toJson() => {
    'id':      id,
    'name':    name,
    'role':    role,
    'volume':  volume,
    'pan':     pan,
    'isMuted': isMuted,
    'isSolo':  isSolo,
    'clips':   clips.map((c) => c.toJson()).toList(),
  };
}

/// A clip node inside the audio graph.
class NleAudioClipNode {
  final String id;
  final String? assetId;
  final String kind;
  final int timelineStartMicros;
  final int timelineEndMicros;
  final int sourceInMicros;
  final int sourceOutMicros;
  final double volume;
  final double pan;
  final bool isMuted;
  final double speed;
  final Map<String, dynamic> fadeIn;
  final Map<String, dynamic> fadeOut;

  const NleAudioClipNode({
    required this.id,
    required this.assetId,
    required this.kind,
    required this.timelineStartMicros,
    required this.timelineEndMicros,
    required this.sourceInMicros,
    required this.sourceOutMicros,
    required this.volume,
    required this.pan,
    required this.isMuted,
    required this.speed,
    required this.fadeIn,
    required this.fadeOut,
  });

  Map<String, dynamic> toJson() => {
    'id':                  id,
    'assetId':             assetId,
    'kind':                kind,
    'timelineStartMicros': timelineStartMicros,
    'timelineEndMicros':   timelineEndMicros,
    'sourceInMicros':      sourceInMicros,
    'sourceOutMicros':     sourceOutMicros,
    'volume':              volume,
    'pan':                 pan,
    'isMuted':             isMuted,
    'speed':               speed,
    'fadeIn':              fadeIn,
    'fadeOut':             fadeOut,
  };
}

// ── Audio Gain Utils ──────────────────────────────────────────────────────────

/// Pure utility methods for gain / dB / fade calculations.
///
/// All methods are stateless and can be called from any layer.
abstract final class AudioGainUtils {
  AudioGainUtils._();

  static const double _minDb = -96.0;

  /// Convert linear gain [0.0 … ∞] to dB.
  static double linearToDb(double linear) {
    if (linear <= 0.0) return _minDb;
    return 20.0 * math.log(linear) / math.ln10;
  }

  /// Convert dB to linear gain.
  static double dbToLinear(double db) {
    if (db <= _minDb) return 0.0;
    return math.pow(10.0, db / 20.0).toDouble();
  }

  /// Clamp volume to the valid editor range [0.0, 2.0].
  static double clampVolume(double v) => v.clamp(0.0, 2.0);

  /// Clamp pan to [-1.0, 1.0].
  static double clampPan(double v) => v.clamp(-1.0, 1.0);

  /// Evaluate a fade gain at a normalised position [0.0, 1.0] inside a fade.
  ///
  /// [t] is 0 = start of fade → 1 = end of fade.
  /// Returns a linear gain multiplier [0.0, 1.0].
  static double evaluateFadeGain(NleAudioFadeCurve curve, double t) {
    final tc = t.clamp(0.0, 1.0);
    switch (curve) {
      case NleAudioFadeCurve.linear:
        return tc;
      case NleAudioFadeCurve.logarithmic:
        // Logarithmic fade: fast initial rise / fall.
        return (tc == 0.0) ? 0.0 : math.log(1.0 + tc * 9.0) / math.log(10.0);
      case NleAudioFadeCurve.exponential:
        // Exponential fade: slow initial, fast end.
        return math.pow(tc, 2.0).toDouble();
      case NleAudioFadeCurve.sCurve:
        // S-curve using smoothstep.
        return tc * tc * (3.0 - 2.0 * tc);
      case NleAudioFadeCurve.instant:
        return tc < 1.0 ? 0.0 : 1.0;
    }
  }

  /// Compute the effective gain of a clip at [sampleTimeMicros] within the
  /// clip's timeline window, factoring in fadeIn and fadeOut.
  ///
  /// Returns a multiplier [0.0, 1.0] to apply on top of the clip's own volume.
  static double clipFadeGainAt({
    required NleAudioClip clip,
    required int sampleTimeMicros,
  }) {
    final relMicros = sampleTimeMicros - clip.timelineStartMicros;
    final durationMicros = clip.timelineDurationMicros;

    if (durationMicros <= 0) return 1.0;

    // Fade in
    final fadeInDur = clip.fadeIn.durationMicros;
    if (fadeInDur > 0 && relMicros < fadeInDur) {
      final t = relMicros / fadeInDur.toDouble();
      return evaluateFadeGain(clip.fadeIn.curve, t);
    }

    // Fade out
    final fadeOutDur = clip.fadeOut.durationMicros;
    if (fadeOutDur > 0) {
      final remainingMicros = durationMicros - relMicros;
      if (remainingMicros < fadeOutDur) {
        final t = 1.0 - (remainingMicros / fadeOutDur.toDouble());
        return 1.0 - evaluateFadeGain(clip.fadeOut.curve, t);
      }
    }

    return 1.0;
  }
}
