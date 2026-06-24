enum MediaSourcePolicy {
  original,
  proxy,
  automatic,
}

enum NleProxyGenerationStatus {
  none,
  queued,
  generating,
  ready,
  failed,
  cancelled,
}

enum NleProxyResolutionPreset {
  p360,
  p540,
  p720,
  p1080,
}

enum NleProxyCodec {
  h264,
  hevc,
}

enum NleProxyContainer {
  mp4,
}

enum NleProxyPreviewMode {
  off,
  automatic,
  alwaysUseProxyWhenAvailable,
}

enum NleProxyExportMode {
  original,
  proxyDraft,
}

enum NleProxyGenerationReason {
  manual,
  importAuto,
  performanceRecommendation,
  batchOptimize,
}

enum NleProxyJobPriority {
  low,
  normal,
  high,
}

enum NleProxyStoragePolicy {
  keepUntilDeleted,
  deleteWhenProjectCloses,
  deleteUnusedAfterCleanup,
}

class NleProxyVideoSpec {
  final int maxWidth;
  final int maxHeight;
  final int bitrate;
  final double fpsLimit;
  final NleProxyCodec codec;
  final NleProxyContainer container;

  const NleProxyVideoSpec({
    required this.maxWidth,
    required this.maxHeight,
    required this.bitrate,
    required this.fpsLimit,
    required this.codec,
    required this.container,
  });

  factory NleProxyVideoSpec.fromPreset(NleProxyResolutionPreset preset) {
    switch (preset) {
      case NleProxyResolutionPreset.p360:
        return const NleProxyVideoSpec(
          maxWidth: 640,
          maxHeight: 360,
          bitrate: 850000,
          fpsLimit: 30.0,
          codec: NleProxyCodec.h264,
          container: NleProxyContainer.mp4,
        );

      case NleProxyResolutionPreset.p540:
        return const NleProxyVideoSpec(
          maxWidth: 960,
          maxHeight: 540,
          bitrate: 1400000,
          fpsLimit: 30.0,
          codec: NleProxyCodec.h264,
          container: NleProxyContainer.mp4,
        );

      case NleProxyResolutionPreset.p720:
        return const NleProxyVideoSpec(
          maxWidth: 1280,
          maxHeight: 720,
          bitrate: 2500000,
          fpsLimit: 30.0,
          codec: NleProxyCodec.h264,
          container: NleProxyContainer.mp4,
        );

      case NleProxyResolutionPreset.p1080:
        return const NleProxyVideoSpec(
          maxWidth: 1920,
          maxHeight: 1080,
          bitrate: 5000000,
          fpsLimit: 30.0,
          codec: NleProxyCodec.h264,
          container: NleProxyContainer.mp4,
        );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'bitrate': bitrate,
      'fpsLimit': fpsLimit,
      'codec': codec.name,
      'container': container.name,
    };
  }

  factory NleProxyVideoSpec.fromJson(Map<String, dynamic> json) {
    return NleProxyVideoSpec(
      maxWidth: (json['maxWidth'] as num?)?.toInt() ?? 1280,
      maxHeight: (json['maxHeight'] as num?)?.toInt() ?? 720,
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 2500000,
      fpsLimit: (json['fpsLimit'] as num?)?.toDouble() ?? 30.0,
      codec: _enumByName(
        NleProxyCodec.values,
        json['codec'],
        NleProxyCodec.h264,
      ),
      container: _enumByName(
        NleProxyContainer.values,
        json['container'],
        NleProxyContainer.mp4,
      ),
    );
  }
}

class NleProxyMetadata {
  final String proxyPath;
  final int width;
  final int height;
  final double fps;
  final int bitrate;
  final int fileSizeBytes;
  final int durationMicros;
  final String codec;
  final DateTime createdAt;

  const NleProxyMetadata({
    required this.proxyPath,
    required this.width,
    required this.height,
    required this.fps,
    required this.bitrate,
    required this.fileSizeBytes,
    required this.durationMicros,
    required this.codec,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'proxyPath': proxyPath,
      'width': width,
      'height': height,
      'fps': fps,
      'bitrate': bitrate,
      'fileSizeBytes': fileSizeBytes,
      'durationMicros': durationMicros,
      'codec': codec,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NleProxyMetadata.fromJson(Map<String, dynamic> json) {
    return NleProxyMetadata(
      proxyPath: json['proxyPath']?.toString() ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      fps: (json['fps'] as num?)?.toDouble() ?? 0.0,
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      durationMicros: (json['durationMicros'] as num?)?.toInt() ?? 0,
      codec: json['codec']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
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
