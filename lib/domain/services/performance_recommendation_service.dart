import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/device/device_capability_profile.dart';

class PerformanceRecommendationService {
  const PerformanceRecommendationService();

  String recommendedProxyStatusForAsset({
    required Asset asset,
    required DeviceCapabilityProfile profile,
  }) {
    if (asset.fileType != 'video') {
      return 'not_needed';
    }

    final shouldCreate = profile.shouldCreateProxyForMedia(
      width: asset.width,
      height: asset.height,
      fileSize: asset.fileSize,
      codec: asset.codec ?? '',
    );

    return shouldCreate ? 'needed' : 'not_needed';
  }

  int recommendedProxyHeight(DeviceCapabilityProfile profile) {
    return profile.limits.recommendedProxyHeight;
  }

  String recommendedPreviewMode(DeviceCapabilityProfile profile) {
    return profile.recommendedPreviewQuality;
  }

  bool shouldDisableAdvancedEffects(DeviceCapabilityProfile profile) {
    return !profile.limits.advancedEffectsEnabled;
  }

  bool shouldWarnBefore4kExport(DeviceCapabilityProfile profile) {
    return !profile.limits.allow4kExport;
  }

  String exportWarningForSettings({
    required DeviceCapabilityProfile profile,
    required int exportHeight,
    required int frameRate,
    required String codec,
  }) {
    if (exportHeight > profile.limits.maxExportHeight) {
      return 'This device profile recommends exporting at ${profile.limits.maxExportHeight}p or lower.';
    }

    if (frameRate > profile.limits.maxExportFrameRate) {
      return 'This device profile recommends ${profile.limits.maxExportFrameRate}fps or lower.';
    }

    if (codec == 'hevc' && !profile.codecSupport.hevcEncode) {
      return 'HEVC export may not be supported. H.264 is safer for this device.';
    }

    return '';
  }
}
