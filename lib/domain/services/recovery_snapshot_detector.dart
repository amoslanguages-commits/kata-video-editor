import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:nle_editor/domain/recovery/recovery_snapshot_info.dart';
import 'package:nle_editor/domain/services/project_session_service.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// Inspects a project's storage folder to detect:
///   - An autosave snapshot (`autosaves/latest.autosave.json`)
///   - A session state file (`session_state.json`)
///
/// These files indicate the app did not shut down cleanly for this project and
/// the user should be offered a recovery prompt.
class RecoverySnapshotDetector {
  final ProjectStorageService projectStorageService;
  final ProjectSessionService projectSessionService;

  RecoverySnapshotDetector({
    required this.projectStorageService,
    required this.projectSessionService,
  });

  Future<RecoverySnapshotInfo> inspectProject(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);

    final autosaveFile = File(
      p.join(folders.autosaves, 'latest.autosave.json'),
    );

    final sessionFile = File(
      p.join(folders.root, 'session_state.json'),
    );

    final hasAutosave = await autosaveFile.exists();
    final hasSession = await sessionFile.exists();

    DateTime? autosaveModifiedAt;
    DateTime? sessionSavedAt;
    int autosaveSize = 0;

    if (hasAutosave) {
      final stat = await autosaveFile.stat();
      autosaveModifiedAt = stat.modified;
      autosaveSize = stat.size;
    }

    if (hasSession) {
      final session = await projectSessionService.readSession(projectId);
      sessionSavedAt =
          session?.savedAt ?? (await sessionFile.stat()).modified;
    }

    return RecoverySnapshotInfo(
      projectId: projectId,
      hasAutosave: hasAutosave,
      hasSession: hasSession,
      autosavePath: hasAutosave ? autosaveFile.path : null,
      sessionPath: hasSession ? sessionFile.path : null,
      autosaveModifiedAt: autosaveModifiedAt,
      sessionSavedAt: sessionSavedAt,
      autosaveSizeBytes: autosaveSize,
    );
  }

  /// Clears the session file so the recovery prompt is not shown again.
  Future<void> dismissRecovery(String projectId) async {
    await projectSessionService.clearSession(projectId);
  }
}
