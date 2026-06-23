import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/project_media/project_archive_service.dart';
import 'package:nle_editor/domain/project_media/project_media_health_service.dart';
import 'package:nle_editor/domain/project_media/project_media_management_models.dart';
import 'package:nle_editor/domain/project_media/project_relink_cleanup_service.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

/// 34C-PRO: Isolated providers for Project Archive / Relink / Media Management.
///
/// Kept outside editor_providers.dart so this feature can evolve without
/// increasing risk in the large editor shell provider file.

final projectMediaHealthServiceProvider = Provider<ProjectMediaHealthService>((ref) {
  return ProjectMediaHealthService(
    mediaRepository: ref.watch(mediaAssetRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    storageService: ref.watch(projectStorageServiceProvider),
  );
});

final projectArchiveServiceProvider = Provider<ProjectArchiveService>((ref) {
  return ProjectArchiveService(
    projectRepository: ref.watch(projectRepositoryProvider),
    mediaRepository: ref.watch(mediaAssetRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    storageService: ref.watch(projectStorageServiceProvider),
    healthService: ref.watch(projectMediaHealthServiceProvider),
  );
});

final projectRelinkCleanupServiceProvider = Provider<ProjectRelinkCleanupService>((ref) {
  return ProjectRelinkCleanupService(
    mediaRepository: ref.watch(mediaAssetRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    storageService: ref.watch(projectStorageServiceProvider),
  );
});

final projectMediaHealthReportProvider =
    FutureProvider.family<NleProjectMediaHealthReport, String>((ref, projectId) {
  return ref.watch(projectMediaHealthServiceProvider).scanProject(projectId);
});
