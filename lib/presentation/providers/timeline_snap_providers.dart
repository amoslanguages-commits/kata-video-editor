import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/timeline/timeline_snap_engine.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_models.dart';
import 'package:nle_editor/presentation/controllers/timeline_snap_settings_controller.dart';

final timelineSnapEngineProvider = Provider<TimelineSnapEngine>((ref) {
  return const TimelineSnapEngine();
});

final timelineSnapSettingsProvider =
    StateNotifierProvider<TimelineSnapSettingsController, TimelineSnapSettings>(
  (ref) => TimelineSnapSettingsController(),
);

final beatMarkersStateProvider =
    StateProvider.family<List<TimelineMarkerSnapPoint>, String>((ref, projectId) {
  return const [];
});

final timelineMarkerSnapPointsProvider =
    Provider.family<List<TimelineMarkerSnapPoint>, String>((ref, projectId) {
  return ref.watch(beatMarkersStateProvider(projectId));
});
