import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/clip_interactions_repository.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_refresh_bridge.dart';
import 'package:nle_editor/presentation/controllers/clip_interactions_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_render_graph_providers.dart';
import 'package:nle_editor/presentation/providers/native_graph_update_providers.dart';

final clipInteractionsRepositoryProvider =
    Provider<ClipInteractionsRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ClipInteractionsRepository(database: database);
});

final timelineEditRefreshBridgeProvider =
    Provider<TimelineEditRefreshBridge>((ref) {
  return TimelineEditRefreshBridge(
    invalidateTimeline: (projectId) {
      ref.invalidate(realProjectTimelineProvider(projectId));
      ref.invalidate(projectTimelineOnceProvider(projectId));
      ref.invalidate(projectRenderGraphProvider(projectId));
      ref.invalidate(projectRenderGraphJsonProvider(projectId));
      ref.invalidate(projectRenderGraphValidationProvider(projectId));
    },
    refreshNativeGraph: (projectId, reason) async {
      ref.read(nativeGraphUpdateSchedulerProvider).schedule(
            projectId: projectId,
            reason: reason,
          );
    },
  );
});

final clipInteractionsControllerProvider =
    Provider.family<ClipInteractionsController, String>((ref, projectId) {
  return ClipInteractionsController(
    projectId: projectId,
    repository: ref.watch(clipInteractionsRepositoryProvider),
    refreshBridge: ref.watch(timelineEditRefreshBridgeProvider),
    ref: ref,
    database: ref.watch(databaseProvider),
  );
});
