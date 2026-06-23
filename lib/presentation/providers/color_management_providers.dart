// lib/presentation/providers/color_management_providers.dart
//
// 30A-PRO: Riverpod providers for the color management subsystem.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/project_color_settings_repository.dart';
import 'package:nle_editor/domain/color/project_color_settings.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

/// Repository provider — thin wrapper so tests can override the DB.
final projectColorSettingsRepositoryProvider =
    Provider<ProjectColorSettingsRepository>((ref) {
  return ProjectColorSettingsRepository(
    database: ref.watch(databaseProvider),
  );
});

/// Async provider that loads the color settings for a specific project.
///
/// Returns [ProjectColorSettings.defaultForProject] on any parse failure so
/// that a missing or corrupted JSON never blocks the editor from opening.
final projectColorSettingsProvider =
    FutureProvider.family<ProjectColorSettings, String>((ref, projectId) {
  return ref
      .watch(projectColorSettingsRepositoryProvider)
      .getProjectColorSettings(projectId);
});
