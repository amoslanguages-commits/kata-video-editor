import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/timeline/timeline_diagnostics_service.dart';
import 'package:nle_editor/presentation/controllers/timeline_integrity_controller.dart';
import 'package:nle_editor/presentation/providers/clip_interactions_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final timelineDiagnosticsServiceProvider = Provider<TimelineDiagnosticsService>((ref) {
  return TimelineDiagnosticsService(
    repository: ref.watch(timelineRepositoryProvider),
  );
});

final timelineIntegrityProvider =
    Provider.family<TimelineIntegrityController, String>((ref, projectId) {
  return TimelineIntegrityController(
    projectId: projectId,
    service: ref.watch(timelineDiagnosticsServiceProvider),
    refreshBridge: ref.watch(timelineEditRefreshBridgeProvider),
  );
});
