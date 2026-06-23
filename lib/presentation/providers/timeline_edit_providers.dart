import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/timeline/timeline_edit_engine.dart';
import 'package:nle_editor/presentation/controllers/timeline_edit_command_controller.dart';
import 'package:nle_editor/presentation/providers/clip_interactions_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final timelineEditProvider = Provider<TimelineEditEngine>((ref) {
  return TimelineEditEngine(repository: ref.watch(timelineRepositoryProvider));
});

final timelineEditCommandControllerProvider =
    Provider.family<TimelineEditCommandController, String>((ref, projectId) {
  return TimelineEditCommandController(
    projectId: projectId,
    engine: ref.watch(timelineEditProvider),
    refreshBridge: ref.watch(timelineEditRefreshBridgeProvider),
  );
});
