import 'dart:io';

import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/proxy_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

class NleProxyCleanupResult {
  final int deletedProxyCount;
  final int freedBytes;
  final List<String> errors;

  const NleProxyCleanupResult({
    required this.deletedProxyCount,
    required this.freedBytes,
    required this.errors,
  });
}

class ProxyCleanupService {
  final MediaAssetRepository mediaRepository;
  final ProxyRepository proxyRepository;

  const ProxyCleanupService({
    required this.mediaRepository,
    required this.proxyRepository,
  });

  Future<NleProxyCleanupResult> deleteAllProxies(String projectId) async {
    final assets = await mediaRepository.getAssets(projectId);

    var count = 0;
    var freed = 0;
    final errors = <String>[];

    for (final asset in assets) {
      final path = asset.proxyPath;

      if (path == null || path.isEmpty) continue;

      try {
        final file = File(path);

        if (await file.exists()) {
          final stat = await file.stat();
          freed += stat.size;
          await file.delete();
        }

        await proxyRepository.clearAssetProxy(asset.id);
        count++;
      } catch (error) {
        errors.add('${asset.displayName}: $error');
      }
    }

    return NleProxyCleanupResult(
      deletedProxyCount: count,
      freedBytes: freed,
      errors: errors,
    );
  }

  Future<NleProxyCleanupResult> deleteUnusedProxies(String projectId) async {
    final assets = await mediaRepository.getAssets(projectId);

    var count = 0;
    var freed = 0;
    final errors = <String>[];

    for (final asset in assets) {
      if (asset.usageState != NleMediaUsageState.unused) continue;

      final path = asset.proxyPath;
      if (path == null || path.isEmpty) continue;

      try {
        final file = File(path);

        if (await file.exists()) {
          final stat = await file.stat();
          freed += stat.size;
          await file.delete();
        }

        await proxyRepository.clearAssetProxy(asset.id);
        count++;
      } catch (error) {
        errors.add('${asset.displayName}: $error');
      }
    }

    return NleProxyCleanupResult(
      deletedProxyCount: count,
      freedBytes: freed,
      errors: errors,
    );
  }
}
