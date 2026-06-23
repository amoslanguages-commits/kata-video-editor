import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/clip_inspector_repository.dart';
import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/presentation/controllers/clip_inspector_controller.dart';
import 'package:nle_editor/presentation/providers/clip_interactions_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';

final clipInspectorRepositoryProvider =
    Provider<ClipInspectorRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return ClipInspectorRepository(
    database: database,
  );
});

final clipInspectorControllerProvider =
    Provider.family<ClipInspectorController, String>((ref, projectId) {
  final controller = ClipInspectorController(
    projectId: projectId,
    repository: ref.watch(clipInspectorRepositoryProvider),
    refreshBridge: ref.watch(timelineEditRefreshBridgeProvider),
    ref: ref,
    database: ref.watch(databaseProvider),
  );

  ref.onDispose(controller.dispose);

  return controller;
});

final selectedClipIdProvider = Provider<String?>((ref) {
  final ui = ref.watch(multitrackTimelineControllerProvider);
  return ui.selectedClipId;
});

final selectedClipInspectorProvider =
    StreamProvider.family<ClipInspectorState?, String>((ref, projectId) {
  final clipId = ref.watch(selectedClipIdProvider);

  if (clipId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(clipInspectorRepositoryProvider);

  return repository.watchClip(clipId);
});
