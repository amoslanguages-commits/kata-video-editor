import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/proxy_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_recommendation_service.dart';
import 'package:nle_editor/domain/proxy/proxy_settings_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class ProxyGenerationService {
  final MediaAssetRepository mediaRepository;
  final ProxyRepository proxyRepository;
  final ProxyRecommendationService recommendationService;

  const ProxyGenerationService({
    required this.mediaRepository,
    required this.proxyRepository,
    this.recommendationService = const ProxyRecommendationService(),
  });

  Future<int> queueRecommendedProxies(String projectId) async {
    final settings = await proxyRepository.getSettings(projectId);
    final assets = await mediaRepository.getAssets(projectId);

    var count = 0;

    for (final asset in assets) {
      final shouldGenerate = recommendationService.shouldGenerateProxy(
        asset: asset,
        settings: settings,
      );

      if (!shouldGenerate) continue;

      await proxyRepository.createJobForAsset(
        asset: asset,
        settings: settings,
        reason: NleProxyGenerationReason.performanceRecommendation,
        priority: NleProxyJobPriority.normal,
      );

      count++;
    }

    return count;
  }

  Future<void> queueManualProxy(NleMediaAsset asset) async {
    final settings = await proxyRepository.getSettings(asset.projectId);

    await proxyRepository.createJobForAsset(
      asset: asset,
      settings: settings,
      reason: NleProxyGenerationReason.manual,
      priority: NleProxyJobPriority.high,
    );
  }

  Future<void> queueProxyAfterImport(NleMediaAsset asset) async {
    final settings = await proxyRepository.getSettings(asset.projectId);

    if (!settings.autoGenerateOnImport) return;

    final shouldGenerate = recommendationService.shouldGenerateProxy(
      asset: asset,
      settings: settings,
    );

    if (!shouldGenerate) return;

    await proxyRepository.createJobForAsset(
      asset: asset,
      settings: settings,
      reason: NleProxyGenerationReason.importAuto,
      priority: NleProxyJobPriority.normal,
    );
  }

  bool canGenerateForAsset(NleMediaAsset asset) {
    return asset.type == NleMediaAssetType.video &&
        asset.availability == NleMediaAvailability.available;
  }
}
