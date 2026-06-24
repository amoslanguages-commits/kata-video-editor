import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

extension NleMediaAssetLifecycle on NleMediaAsset {
  NleMediaLifecycleStage get lifecycleStage {
    switch (availability) {
      case NleMediaAvailability.missing:
        return NleMediaLifecycleStage.missing;
      case NleMediaAvailability.offline:
        return NleMediaLifecycleStage.offline;
      case NleMediaAvailability.corrupted:
        return NleMediaLifecycleStage.corrupted;
      case NleMediaAvailability.available:
        break;
    }

    switch (proxyStatus) {
      case NleProxyStatus.ready:
        return NleMediaLifecycleStage.proxyReady;
      case NleProxyStatus.generating:
        return NleMediaLifecycleStage.proxyGenerating;
      case NleProxyStatus.queued:
        return NleMediaLifecycleStage.proxyQueued;
      case NleProxyStatus.failed:
        return NleMediaLifecycleStage.proxyNeeded;
      case NleProxyStatus.none:
        break;
    }

    final analyzed = fileInfo.hasFileIdentity ||
        videoInfo.hasResolution ||
        videoInfo.hasCodec ||
        audioInfo.hasFormat ||
        timecodeInfo.hasDuration;
    return analyzed ? NleMediaLifecycleStage.analyzed : NleMediaLifecycleStage.imported;
  }

  bool get needsProxy =>
      availability == NleMediaAvailability.available &&
      isVideo &&
      proxyStatus != NleProxyStatus.ready &&
      proxyStatus != NleProxyStatus.queued &&
      proxyStatus != NleProxyStatus.generating;

  Map<String, dynamic> lifecycleJson() => {
        'assetId': id,
        'stage': lifecycleStage.name,
        'availability': availability.name,
        'proxyStatus': proxyStatus.name,
        'hasOriginalPath': originalPath?.trim().isNotEmpty == true,
        'hasProjectPath': projectPath?.trim().isNotEmpty == true,
        'hasProxyPath': proxyPath?.trim().isNotEmpty == true,
      };
}
