// lib/domain/source_preview/source_preview_models.dart

/// 29F: Domain models for the Source Preview monitor.

class SourcePreviewAsset {
  final String id;
  final String projectId;
  final String name;
  final String assetType; // video | image | audio | music | voice | sfx
  final String? originalPath;
  final String? proxyPath;
  final String? thumbnailPath;
  final int durationMicros;
  final int width;
  final int height;
  final bool hasVideo;
  final bool hasAudio;

  const SourcePreviewAsset({
    required this.id,
    required this.projectId,
    required this.name,
    required this.assetType,
    required this.originalPath,
    required this.proxyPath,
    required this.thumbnailPath,
    required this.durationMicros,
    required this.width,
    required this.height,
    required this.hasVideo,
    required this.hasAudio,
  });

  bool get isVisual {
    final t = assetType.toLowerCase();
    return t == 'video' || t == 'image' || t == 'photo';
  }

  bool get isAudioOnly => !isVisual && hasAudio;
}

class SourcePreviewState {
  final SourcePreviewAsset? asset;
  final int playheadMicros;
  final int inPointMicros;
  final int outPointMicros;
  final bool isPlaying;
  final int? textureId;
  final bool isPreviewReady;

  const SourcePreviewState({
    required this.asset,
    required this.playheadMicros,
    required this.inPointMicros,
    required this.outPointMicros,
    required this.isPlaying,
    this.textureId,
    this.isPreviewReady = false,
  });

  const SourcePreviewState.empty()
      : asset = null,
        playheadMicros = 0,
        inPointMicros = 0,
        outPointMicros = 0,
        isPlaying = false,
        textureId = null,
        isPreviewReady = false;

  bool get hasAsset => asset != null;

  int get selectedDurationMicros {
    final d = outPointMicros - inPointMicros;
    return d < 0 ? 0 : d;
  }

  bool get hasValidRange {
    return asset != null &&
        selectedDurationMicros > 0 &&
        inPointMicros >= 0 &&
        outPointMicros <= asset!.durationMicros;
  }

  SourcePreviewState copyWith({
    SourcePreviewAsset? asset,
    bool clearAsset = false,
    int? playheadMicros,
    int? inPointMicros,
    int? outPointMicros,
    bool? isPlaying,
    int? textureId,
    bool? isPreviewReady,
  }) {
    return SourcePreviewState(
      asset: clearAsset ? null : asset ?? this.asset,
      playheadMicros: playheadMicros ?? this.playheadMicros,
      inPointMicros: inPointMicros ?? this.inPointMicros,
      outPointMicros: outPointMicros ?? this.outPointMicros,
      isPlaying: isPlaying ?? this.isPlaying,
      textureId: textureId ?? this.textureId,
      isPreviewReady: isPreviewReady ?? this.isPreviewReady,
    );
  }
}
