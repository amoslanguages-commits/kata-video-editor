import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/domain/services/app_permission_service.dart';
import 'package:nle_editor/domain/services/interrupted_job_recovery_service.dart';
import 'package:nle_editor/domain/services/missing_media_service.dart';

/// Summarises the outcome of all safety checks run when the app comes back
/// to the foreground while a project is open.
class ResumeProjectSafetyReport {
  final int missingAssets;
  final int interruptedJobs;
  final bool mediaPermissionAvailable;

  const ResumeProjectSafetyReport({
    required this.missingAssets,
    required this.interruptedJobs,
    required this.mediaPermissionAvailable,
  });

  bool get hasWarnings {
    return missingAssets > 0 ||
        interruptedJobs > 0 ||
        !mediaPermissionAvailable;
  }
}

/// Runs all project-level safety checks on [AppLifecycleState.resumed]:
///   1. Re-checks media permission.
///   2. Verifies asset files still exist on disk.
///   3. Marks any interrupted background jobs as failed.
class ResumeProjectSafetyCheckService {
  final MissingMediaService missingMediaService;
  final AppPermissionService permissionService;
  final InterruptedJobRecoveryService interruptedJobRecoveryService;

  ResumeProjectSafetyCheckService({
    required this.missingMediaService,
    required this.permissionService,
    required this.interruptedJobRecoveryService,
  });

  Future<ResumeProjectSafetyReport> checkProjectOnResume(
    String projectId,
  ) async {
    final mediaPermission = await permissionService.check(
      AppPermissionType.mediaLibrary,
    );

    final missingReport =
        await missingMediaService.checkProjectMedia(projectId);

    final interruptedJobs =
        await interruptedJobRecoveryService.markInterruptedJobs(
      projectId: projectId,
      notify: false,
    );

    return ResumeProjectSafetyReport(
      missingAssets: missingReport.missingAssets,
      interruptedJobs: interruptedJobs,
      mediaPermissionAvailable: mediaPermission.hasAccess,
    );
  }
}
