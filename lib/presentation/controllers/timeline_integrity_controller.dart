import 'package:nle_editor/domain/timeline/timeline_diagnostics.dart';
import 'package:nle_editor/domain/timeline/timeline_diagnostics_service.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_refresh_bridge.dart';

class TimelineIntegrityController {
  final String projectId;
  final TimelineDiagnosticsService service;
  final TimelineEditRefreshBridge refreshBridge;

  const TimelineIntegrityController({
    required this.projectId,
    required this.service,
    required this.refreshBridge,
  });

  Future<TimelineDiagnosticsReport> inspect() {
    return service.inspectProject(projectId);
  }

  Future<TimelineDiagnosticsReport> applySafeFixes() async {
    final report = await service.repairProject(projectId);
    if (report.repairs.isNotEmpty) {
      await refreshBridge.refresh(
        projectId: projectId,
        reason: 'timeline_integrity_fix',
      );
    }
    return report;
  }
}
