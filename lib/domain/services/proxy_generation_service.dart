import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// Decommissioned production guard.
///
/// Proxy generation is owned by the canonical native proxy queue:
/// `domain/proxy/proxy_generation_service.dart`, `ProxyRepository`,
/// `ProxyQueueRunner`, and `NativeProxyGeneratorService`.
///
/// This class remains only so older provider wiring cannot silently recreate a
/// Flutter/FFmpeg proxy path. Calling it is an architecture error.
class ProxyGenerationService {
  final AssetRepository assetRepository;
  final ProjectStorageService storageService;

  const ProxyGenerationService({
    required this.assetRepository,
    required this.storageService,
  });

  Future<String?> generateProxy({
    required String projectId,
    required String assetId,
    int height = 720,
  }) {
    throw StateError(
      'ProxyGenerationService is decommissioned. Use the canonical native proxy queue backed by MediaAssets.',
    );
  }
}
