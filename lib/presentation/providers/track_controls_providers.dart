import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/track_controls_repository.dart';
import 'package:nle_editor/domain/timeline/track_graph_refresh_bridge.dart';
import 'package:nle_editor/presentation/controllers/track_controls_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_render_graph_providers.dart';
import 'package:nle_editor/presentation/providers/native_graph_update_providers.dart';

final trackControlsRepositoryProvider =
    Provider<TrackControlsRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return TrackControlsRepository(
    database: database,
  );
});

final trackGraphRefreshBridgeProvider =
    Provider<TrackGraphRefreshBridge>((ref) {
  return TrackGraphRefreshBridge(
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

final trackControlsControllerProvider =
    Provider.family<TrackControlsController, String>((ref, projectId) {
  return TrackControlsController(
    projectId: projectId,
    repository: ref.watch(trackControlsRepositoryProvider),
    refreshBridge: ref.watch(trackGraphRefreshBridgeProvider),
    ref: ref,
    database: ref.watch(databaseProvider),
  );
});
