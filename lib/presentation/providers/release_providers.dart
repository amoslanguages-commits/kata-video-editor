import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/release/build_metadata.dart';
import 'package:nle_editor/core/release/build_metadata_service.dart';
import 'package:nle_editor/presentation/controllers/release_checklist_controller.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';

final buildMetadataServiceProvider = Provider<BuildMetadataService>((ref) {
  return BuildMetadataService(
    config: ref.watch(appConfigProvider),
  );
});

final buildMetadataProvider = FutureProvider<BuildMetadata>((ref) {
  return ref.watch(buildMetadataServiceProvider).load();
});

final releaseChecklistProvider =
    StateNotifierProvider<ReleaseChecklistController, Set<String>>((ref) {
  return ReleaseChecklistController();
});
