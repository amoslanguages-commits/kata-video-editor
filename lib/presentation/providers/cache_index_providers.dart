import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/cache/cache_index_models.dart';
import 'package:nle_editor/domain/cache/cache_index_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final cacheIndexServiceProvider = Provider<CacheIndexService>((ref) {
  return CacheIndexService(
    projectStorageService: ref.watch(projectStorageServiceProvider),
    assetRepository: ref.watch(assetRepositoryProvider),
  );
});

final projectCacheIndexProvider =
    FutureProvider.family<CacheIndexSnapshot, String>((ref, projectId) {
  return ref.watch(cacheIndexServiceProvider).loadIndex(projectId);
});

final projectCacheIndexRebuildProvider =
    FutureProvider.family<CacheIndexSnapshot, String>((ref, projectId) {
  return ref.watch(cacheIndexServiceProvider).rebuildIndex(projectId);
});

final projectCacheCleanupPreviewProvider =
    FutureProvider.family<CacheCleanupReport, String>((ref, projectId) {
  return ref.watch(cacheIndexServiceProvider).cleanupProjectCache(
        projectId,
        policy: const CacheCleanupPolicy(dryRun: true),
      );
});
