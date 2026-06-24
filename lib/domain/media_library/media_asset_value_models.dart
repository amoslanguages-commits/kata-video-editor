enum NleMediaAssetType {
  video,
  audio,
  image,
  unknown,
}

enum NleMediaImportSource {
  filePicker,
  photoLibrary,
  camera,
  voiceRecording,
  generated,
  externalReference,
}

enum NleMediaStorageMode {
  copiedIntoProject,
  referencedExternal,
}

enum NleMediaAvailability {
  available,
  missing,
  offline,
  corrupted,
}

enum NleMediaLifecycleState {
  imported,
  analyzed,
  proxyNeeded,
  proxyReady,
  missing,
  relinked,
}

enum NleMediaSortMode {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  duration,
  fileSize,
  type,
  usedFirst,
  unusedFirst,
}

enum NleMediaViewMode {
  grid,
  list,
  compact,
}

enum NleProxyStatus {
  none,
  queued,
  generating,
  ready,
  failed,
}

enum NleMediaUsageState {
  unused,
  used,
  partiallyUsed,
}

class NleMediaTimecodeInfo {
  final double fps;
  final int durationMicros;
  final int startTimecodeMicros;

  const NleMediaTimecodeInfo({
    required this.fps,
    required this.durationMicros,
    required this.startTimecodeMicros,
  });

  const NleMediaTimecodeInfo.empty()
      : fps = 30.0,
        durationMicros = 0,
        startTimecodeMicros = 0;

  Map<String, dynamic> toJson() {
    return {
      'fps': fps,
      'durationMicros': durationMicros,
      'startTimecodeMicros': startTimecodeMicros,
    };
  }

  factory NleMediaTimecodeInfo.fromJson(Map<String, dynamic> json) {
    return NleMediaTimecodeInfo(
      fps: (json['fps'] as num?)?.toDouble() ?? 30.0,
      durationMicros: (json['durationMicros'] as num?)?.toInt() ?? 0,
      startTimecodeMicros:
          (json['startTimecodeMicros'] as num?)?.toInt() ?? 0,
    );
  }
}

class NleMediaVideoInfo {
  final int width;
  final int height;
  final double fps;
  final String codec;
  final String colorSpace;
  final bool hasHdr;

  const NleMediaVideoInfo({
    required this.width,
    required this.height,
    required this.fps,
    required this.codec,
    required this.colorSpace,
    required this.hasHdr,
  });

  const NleMediaVideoInfo.empty()
      : width = 0,
        height = 0,
        fps = 0.0,
        codec = '',
        colorSpace = '',
        hasHdr = false;

  bool get hasResolution => width > 0 && height > 0;

  String get resolutionLabel {
    if (!hasResolution) return 'Unknown';
    return '${width}x$height';
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'fps': fps,
      'codec': codec,
      'colorSpace': colorSpace,
      'hasHdr': hasHdr,
    };
  }

  factory NleMediaVideoInfo.fromJson(Map<String, dynamic> json) {
    return NleMediaVideoInfo(
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      fps: (json['fps'] as num?)?.toDouble() ?? 0.0,
      codec: json['codec']?.toString() ?? '',
      colorSpace: json['colorSpace']?.toString() ?? '',
      hasHdr: json['hasHdr'] == true,
    );
  }
}

class NleMediaAudioInfo {
  final int sampleRate;
  final int channelCount;
  final String codec;
  final int bitrate;

  const NleMediaAudioInfo({
    required this.sampleRate,
    required this.channelCount,
    required this.codec,
    required this.bitrate,
  });

  const NleMediaAudioInfo.empty()
      : sampleRate = 0,
        channelCount = 0,
        codec = '',
        bitrate = 0;

  Map<String, dynamic> toJson() {
    return {
      'sampleRate': sampleRate,
      'channelCount': channelCount,
      'codec': codec,
      'bitrate': bitrate,
    };
  }

  factory NleMediaAudioInfo.fromJson(Map<String, dynamic> json) {
    return NleMediaAudioInfo(
      sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 0,
      channelCount: (json['channelCount'] as num?)?.toInt() ?? 0,
      codec: json['codec']?.toString() ?? '',
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
    );
  }
}

class NleMediaFileInfo {
  final String fileName;
  final String extension;
  final int fileSizeBytes;
  final String? checksum;
  final DateTime? fileCreatedAt;
  final DateTime? fileModifiedAt;

  const NleMediaFileInfo({
    required this.fileName,
    required this.extension,
    required this.fileSizeBytes,
    this.checksum,
    this.fileCreatedAt,
    this.fileModifiedAt,
  });

  const NleMediaFileInfo.empty()
      : fileName = '',
        extension = '',
        fileSizeBytes = 0,
        checksum = null,
        fileCreatedAt = null,
        fileModifiedAt = null;

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'extension': extension,
      'fileSizeBytes': fileSizeBytes,
      'checksum': checksum,
      'fileCreatedAt': fileCreatedAt?.toIso8601String(),
      'fileModifiedAt': fileModifiedAt?.toIso8601String(),
    };
  }

  factory NleMediaFileInfo.fromJson(Map<String, dynamic> json) {
    return NleMediaFileInfo(
      fileName: json['fileName']?.toString() ?? '',
      extension: json['extension']?.toString() ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      checksum: json['checksum']?.toString(),
      fileCreatedAt:
          DateTime.tryParse(json['fileCreatedAt']?.toString() ?? ''),
      fileModifiedAt:
          DateTime.tryParse(json['fileModifiedAt']?.toString() ?? ''),
    );
  }
}
