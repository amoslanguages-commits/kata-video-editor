import 'dart:convert';

import 'package:nle_editor/domain/export/export_state_machine.dart';

class ExportJobPersistencePatch {
  final String status;
  final int progress;
  final String stage;
  final String? errorMessage;
  final String errorJson;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const ExportJobPersistencePatch({
    required this.status,
    required this.progress,
    required this.stage,
    required this.errorJson,
    required this.updatedAt,
    this.errorMessage,
    this.completedAt,
  });

  Map<String, Object?> toJson() => {
        'status': status,
        'progress': progress,
        'stage': stage,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'errorJson': errorJson,
        'updatedAt': updatedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };
}

class ExportJobPersistenceMapper {
  const ExportJobPersistenceMapper();

  ExportJobPersistencePatch fromSnapshot(ExportStateSnapshot snapshot) {
    final now = DateTime.now();
    return ExportJobPersistencePatch(
      status: snapshot.state,
      progress: snapshot.progress,
      stage: snapshot.stage,
      errorMessage: snapshot.failure?.userMessage,
      errorJson: jsonEncode(snapshot.failure?.toJson() ?? const <String, Object?>{}),
      updatedAt: now,
      completedAt: snapshot.terminal ? now : null,
    );
  }

  ExportStateSnapshot recoverInterruptedJob({
    required String persistedStatus,
    required int persistedProgress,
    required String persistedStage,
    required Map<String, Object?> context,
  }) {
    if (ExportJobState.isTerminal(persistedStatus)) {
      return ExportStateSnapshot(
        state: persistedStatus,
        previousState: persistedStatus,
        progress: persistedProgress,
        stage: persistedStage,
        terminal: true,
        rawPayload: context,
      );
    }

    return ExportStateSnapshot(
      state: ExportJobState.failed,
      previousState: persistedStatus,
      progress: persistedProgress,
      stage: 'Interrupted',
      terminal: true,
      failure: const ExportFailure(
        code: ExportErrorCode.nativeFailed,
        severity: ExportErrorSeverity.recoverable,
        userMessage: 'Export was interrupted before it finished.',
        technicalMessage: 'Recovered a non-terminal export job after app restart.',
        recoverySuggestion: 'Start the export again.',
        retryable: true,
      ),
      rawPayload: context,
    );
  }
}
