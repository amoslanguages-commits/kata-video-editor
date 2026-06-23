import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_settings_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class NleResolvedProxyMediaPath {
  final String? path;
  final bool usingProxy;
  final bool missing;
  final String reason;

  const NleResolvedProxyMediaPath({
    required this.path,
    required this.usingProxy,
    required this.missing,
    required this.reason,
  });
}

class ProxyResolutionService {
  const ProxyResolutionService();

  NleResolvedProxyMediaPath resolveForPreview({
    required NleMediaAsset asset,
    required NleProjectProxySettings settings,
  }) {
    if (asset.availability != NleMediaAvailability.available) {
      return const NleResolvedProxyMediaPath(
        path: null,
        usingProxy: false,
        missing: true,
        reason: 'Media missing',
      );
    }

    if (!settings.enabled || settings.previewMode == NleProxyPreviewMode.off) {
      return NleResolvedProxyMediaPath(
        path: asset.resolvedEditPath,
        usingProxy: false,
        missing: false,
        reason: 'Proxy disabled',
      );
    }

    final proxyReady =
        asset.proxyStatus == NleProxyStatus.ready &&
        asset.proxyPath != null &&
        asset.proxyPath!.isNotEmpty;

    if (proxyReady) {
      return NleResolvedProxyMediaPath(
        path: asset.proxyPath,
        usingProxy: true,
        missing: false,
        reason: 'Proxy ready',
      );
    }

    return NleResolvedProxyMediaPath(
      path: asset.resolvedEditPath,
      usingProxy: false,
      missing: false,
      reason: 'Proxy not ready',
    );
  }

  NleResolvedProxyMediaPath resolveForExport({
    required NleMediaAsset asset,
    required NleProjectProxySettings settings,
  }) {
    if (asset.availability != NleMediaAvailability.available) {
      return const NleResolvedProxyMediaPath(
        path: null,
        usingProxy: false,
        missing: true,
        reason: 'Media missing',
      );
    }

    if (settings.exportMode == NleProxyExportMode.proxyDraft &&
        asset.proxyStatus == NleProxyStatus.ready &&
        asset.proxyPath != null &&
        asset.proxyPath!.isNotEmpty) {
      return NleResolvedProxyMediaPath(
        path: asset.proxyPath,
        usingProxy: true,
        missing: false,
        reason: 'Draft proxy export',
      );
    }

    return NleResolvedProxyMediaPath(
      path: asset.resolvedOriginalPath,
      usingProxy: false,
      missing: false,
      reason: 'Original export',
    );
  }
}
