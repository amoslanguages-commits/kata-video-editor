import 'package:nle_editor/domain/performance/project_asset_index.dart';
import 'package:nle_editor/domain/performance/performance_mode.dart';

class ProxyRecommendationReason {
  ProxyRecommendationReason._();

  static const String highResolution = 'high_resolution';
  static const String longDuration = 'long_duration';
  static const String largeFile = 'large_file';
  static const String lowMemoryMode = 'low_memory_mode';
  static const String weakDevice = 'weak_device';
}

class ProxyRecommendation {
  final String assetId;
  final bool recommended;
  final String targetProfile;
  final List<String> reasons;

  const ProxyRecommendation({
    required this.assetId,
    required this.recommended,
    required this.targetProfile,
    required this.reasons,
  });
}

class ProxyRecommendationEngine {
  List<ProxyRecommendation> recommend({
    required ProjectAssetIndex index,
    required PerformanceModeState performanceMode,
  }) {
    return index.assetsById.values
        .where((asset) => asset.fileType == 'video')
        .map((asset) => recommendForAsset(
              asset: asset,
              performanceMode: performanceMode,
            ))
        .where((r) => r.recommended)
        .toList();
  }

  ProxyRecommendation recommendForAsset({
    required IndexedAssetInfo asset,
    required PerformanceModeState performanceMode,
  }) {
    final reasons = <String>[];

    final width = asset.width ?? 0;
    final height = asset.height ?? 0;
    final duration = asset.durationMicros ?? 0;

    if (width >= 1920 || height >= 1080) {
      reasons.add(ProxyRecommendationReason.highResolution);
    }

    if (duration >= 60 * 1000000) {
      reasons.add(ProxyRecommendationReason.longDuration);
    }

    if (asset.fileSizeBytes >= 500 * 1024 * 1024) {
      reasons.add(ProxyRecommendationReason.largeFile);
    }

    if (performanceMode.lowMemoryMode) {
      reasons.add(ProxyRecommendationReason.lowMemoryMode);
    }

    if (performanceMode.deviceTier == DevicePerformanceTier.low) {
      reasons.add(ProxyRecommendationReason.weakDevice);
    }

    return ProxyRecommendation(
      assetId: asset.assetId,
      recommended: reasons.isNotEmpty && !asset.hasProxy,
      targetProfile: performanceMode.deviceTier == DevicePerformanceTier.low
          ? 'draft_540p'
          : 'standard_720p',
      reasons: reasons,
    );
  }
}
