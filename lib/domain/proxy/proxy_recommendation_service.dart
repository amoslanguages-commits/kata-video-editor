import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_settings_models.dart';

class ProxyRecommendationService {
  const ProxyRecommendationService();

  bool shouldGenerateProxy({
    required NleMediaAsset asset,
    required NleProjectProxySettings settings,
  }) {
    if (!settings.enabled) return false;
    if (!asset.isVideo) return false;
    if (asset.availability != NleMediaAvailability.available) return false;
    if (asset.proxyStatus == NleProxyStatus.ready) return false;
    if (asset.proxyStatus == NleProxyStatus.generating) return false;
    if (asset.proxyStatus == NleProxyStatus.queued) return false;

    final is4k = asset.videoInfo.width >= 3840 || asset.videoInfo.height >= 2160;

    final highBitrate =
        asset.audioInfo.bitrate >= settings.highBitrateThreshold ||
            asset.fileInfo.fileSizeBytes > 600 * 1024 * 1024;

    final hdr = asset.videoInfo.hasHdr;

    final longClip =
        asset.timecodeInfo.durationMicros >= settings.longClipThresholdMicros;

    if (settings.autoGenerateFor4k && is4k) return true;
    if (settings.autoGenerateForHighBitrate && highBitrate) return true;
    if (settings.autoGenerateForHdr && hdr) return true;
    if (settings.autoGenerateForLongClips && longClip) return true;

    return false;
  }

  String reasonLabel({
    required NleMediaAsset asset,
    required NleProjectProxySettings settings,
  }) {
    if (asset.videoInfo.width >= 3840 || asset.videoInfo.height >= 2160) {
      return '4K media';
    }

    if (asset.videoInfo.hasHdr) {
      return 'HDR media';
    }

    if (asset.timecodeInfo.durationMicros >= settings.longClipThresholdMicros) {
      return 'Long clip';
    }

    return 'Optimized editing';
  }
}
