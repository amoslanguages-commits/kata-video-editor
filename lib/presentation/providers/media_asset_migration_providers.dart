import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/media_library/media_asset_migration_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final mediaAssetMigrationServiceProvider = Provider<MediaAssetMigrationService>((ref) {
  return MediaAssetMigrationService(database: ref.watch(databaseProvider));
});

final projectMediaAssetMigrationProvider = FutureProvider.family<int, String>((ref, projectId) {
  return ref.watch(mediaAssetMigrationServiceProvider).migrateProject(projectId);
});
