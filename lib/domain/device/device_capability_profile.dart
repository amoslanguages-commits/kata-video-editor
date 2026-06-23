class DeviceTier {
  DeviceTier._();

  static const String lowEnd = 'low_end';
  static const String midRange = 'mid_range';
  static const String highEnd = 'high_end';
  static const String flagship = 'flagship';
}

class PreviewQualityMode {
  PreviewQualityMode._();

  static const String auto = 'auto';
  static const String draft = 'draft';
  static const String balanced = 'balanced';
  static const String high = 'high';
  static const String adaptive = 'adaptive';
}

class ProxyMode {
  ProxyMode._();

  static const String auto = 'auto';
  static const String always = 'always';
  static const String onlyLargeFiles = 'only_large_files';
  static const String never = 'never';
}

class ExportPreference {
  ExportPreference._();

  static const String compatibility = 'compatibility';
  static const String smallerFile = 'smaller_file';
  static const String highestQuality = 'highest_quality';
  static const String fastestExport = 'fastest_export';
}

class CodecSupport {
  final bool h264Decode;
  final bool h264Encode;
  final bool hevcDecode;
  final bool hevcEncode;
  final bool tenBitDecode;
  final bool tenBitEncode;
  final bool hdrPreview;
  final bool hdrExport;

  const CodecSupport({
    required this.h264Decode,
    required this.h264Encode,
    required this.hevcDecode,
    required this.hevcEncode,
    required this.tenBitDecode,
    required this.tenBitEncode,
    required this.hdrPreview,
    required this.hdrExport,
  });

  factory CodecSupport.safeDefault() {
    return const CodecSupport(
      h264Decode: true,
      h264Encode: true,
      hevcDecode: false,
      hevcEncode: false,
      tenBitDecode: false,
      tenBitEncode: false,
      hdrPreview: false,
      hdrExport: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'h264Decode': h264Decode,
      'h264Encode': h264Encode,
      'hevcDecode': hevcDecode,
      'hevcEncode': hevcEncode,
      'tenBitDecode': tenBitDecode,
      'tenBitEncode': tenBitEncode,
      'hdrPreview': hdrPreview,
      'hdrExport': hdrExport,
    };
  }
}

class DeviceLimits {
  final int safePreviewHeight;
  final int recommendedProxyHeight;
  final int maxExportHeight;
  final int maxExportFrameRate;
  final int maxRealtimeVideoTracks;
  final int maxRealtimeAudioTracks;
  final bool proxyRequiredFor4k;
  final bool advancedEffectsEnabled;
  final bool backgroundProxyEnabled;
  final bool allow4kExport;

  const DeviceLimits({
    required this.safePreviewHeight,
    required this.recommendedProxyHeight,
    required this.maxExportHeight,
    required this.maxExportFrameRate,
    required this.maxRealtimeVideoTracks,
    required this.maxRealtimeAudioTracks,
    required this.proxyRequiredFor4k,
    required this.advancedEffectsEnabled,
    required this.backgroundProxyEnabled,
    required this.allow4kExport,
  });

  Map<String, dynamic> toJson() {
    return {
      'safePreviewHeight': safePreviewHeight,
      'recommendedProxyHeight': recommendedProxyHeight,
      'maxExportHeight': maxExportHeight,
      'maxExportFrameRate': maxExportFrameRate,
      'maxRealtimeVideoTracks': maxRealtimeVideoTracks,
      'maxRealtimeAudioTracks': maxRealtimeAudioTracks,
      'proxyRequiredFor4k': proxyRequiredFor4k,
      'advancedEffectsEnabled': advancedEffectsEnabled,
      'backgroundProxyEnabled': backgroundProxyEnabled,
      'allow4kExport': allow4kExport,
    };
  }
}

class DeviceRuntimeState {
  final int? batteryPercent;
  final bool isCharging;
  final String thermalState;
  final int? availableStorageBytes;
  final bool lowPowerMode;
  final bool memoryPressure;

  const DeviceRuntimeState({
    this.batteryPercent,
    required this.isCharging,
    required this.thermalState,
    this.availableStorageBytes,
    required this.lowPowerMode,
    required this.memoryPressure,
  });

  factory DeviceRuntimeState.safeDefault() {
    return const DeviceRuntimeState(
      batteryPercent: null,
      isCharging: false,
      thermalState: 'unknown',
      availableStorageBytes: null,
      lowPowerMode: false,
      memoryPressure: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batteryPercent': batteryPercent,
      'isCharging': isCharging,
      'thermalState': thermalState,
      'availableStorageBytes': availableStorageBytes,
      'lowPowerMode': lowPowerMode,
      'memoryPressure': memoryPressure,
    };
  }
}

class DeviceCapabilityProfile {
  final String profileVersion;
  final String source;

  final String platform;
  final String deviceModel;
  final String osVersion;

  final int cpuCores;
  final int? ramMb;
  final String gpuName;

  final String tier;
  final String recommendedPreviewQuality;
  final String recommendedProxyMode;
  final String recommendedExportPreference;

  final CodecSupport codecSupport;
  final DeviceLimits limits;
  final DeviceRuntimeState runtime;

  final DateTime detectedAt;

  const DeviceCapabilityProfile({
    required this.profileVersion,
    required this.source,
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.cpuCores,
    required this.ramMb,
    required this.gpuName,
    required this.tier,
    required this.recommendedPreviewQuality,
    required this.recommendedProxyMode,
    required this.recommendedExportPreference,
    required this.codecSupport,
    required this.limits,
    required this.runtime,
    required this.detectedAt,
  });

  bool get isLowEnd => tier == DeviceTier.lowEnd;

  bool get isMidRange => tier == DeviceTier.midRange;

  bool get isHighEnd => tier == DeviceTier.highEnd;

  bool get isFlagship => tier == DeviceTier.flagship;

  bool get shouldUseProxyFor1080p {
    return isLowEnd && limits.recommendedProxyHeight <= 720;
  }

  bool shouldCreateProxyForMedia({
    required int? width,
    required int? height,
    required int fileSize,
    required String codec,
  }) {
    if (recommendedProxyMode == ProxyMode.never) {
      return false;
    }

    if (recommendedProxyMode == ProxyMode.always) {
      return true;
    }

    final mediaWidth = width ?? 0;
    final mediaHeight = height ?? 0;
    final is4k = mediaWidth >= 3840 || mediaHeight >= 2160;
    final isLarge1080 = mediaWidth >= 1920 || mediaHeight >= 1080;
    final isHugeFile = fileSize >= 300 * 1024 * 1024;
    final isHevc = codec.toLowerCase().contains('hevc') || codec.toLowerCase().contains('h265');

    if (isLowEnd) {
      return isLarge1080 || isHugeFile || isHevc;
    }

    if (isMidRange) {
      return is4k || isHugeFile || isHevc;
    }

    if (isHighEnd) {
      return is4k || isHugeFile;
    }

    return isHugeFile;
  }

  String recommendedExportCodec({
    required bool userRequestedHevc,
  }) {
    if (userRequestedHevc && codecSupport.hevcEncode) {
      return 'hevc';
    }

    return 'h264';
  }

  int clampExportHeight(int requestedHeight) {
    return requestedHeight.clamp(360, limits.maxExportHeight);
  }

  int clampExportFrameRate(int requestedFrameRate) {
    return requestedFrameRate.clamp(24, limits.maxExportFrameRate);
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVersion': profileVersion,
      'source': source,
      'platform': platform,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'cpuCores': cpuCores,
      'ramMb': ramMb,
      'gpuName': gpuName,
      'tier': tier,
      'recommendedPreviewQuality': recommendedPreviewQuality,
      'recommendedProxyMode': recommendedProxyMode,
      'recommendedExportPreference': recommendedExportPreference,
      'codecSupport': codecSupport.toJson(),
      'limits': limits.toJson(),
      'runtime': runtime.toJson(),
      'detectedAt': detectedAt.toIso8601String(),
    };
  }
}
