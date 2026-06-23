/// Describes what recovery data exists for a project when it is opened.
class RecoverySnapshotInfo {
  final String projectId;
  final bool hasAutosave;
  final bool hasSession;
  final String? autosavePath;
  final String? sessionPath;
  final DateTime? autosaveModifiedAt;
  final DateTime? sessionSavedAt;
  final int autosaveSizeBytes;

  const RecoverySnapshotInfo({
    required this.projectId,
    required this.hasAutosave,
    required this.hasSession,
    required this.autosavePath,
    required this.sessionPath,
    required this.autosaveModifiedAt,
    required this.sessionSavedAt,
    required this.autosaveSizeBytes,
  });

  bool get hasRecovery => hasAutosave || hasSession;

  bool get autosaveLooksUseful {
    if (!hasAutosave) return false;
    if (autosaveSizeBytes <= 10) return false;
    return true;
  }
}

/// The user's answer to the recovery prompt.
class ProjectRecoveryDecision {
  final bool shouldRestoreSession;
  final bool shouldKeepAutosave;
  final bool dismissed;

  const ProjectRecoveryDecision({
    required this.shouldRestoreSession,
    required this.shouldKeepAutosave,
    required this.dismissed,
  });

  factory ProjectRecoveryDecision.restoreSession() {
    return const ProjectRecoveryDecision(
      shouldRestoreSession: true,
      shouldKeepAutosave: true,
      dismissed: false,
    );
  }

  factory ProjectRecoveryDecision.dismiss() {
    return const ProjectRecoveryDecision(
      shouldRestoreSession: false,
      shouldKeepAutosave: false,
      dismissed: true,
    );
  }
}
