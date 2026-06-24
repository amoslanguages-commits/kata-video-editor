import 'package:nle_editor/domain/export/export_state_machine.dart';

class ExportJobViewState {
  final String jobId;
  final String projectId;
  final String state;
  final String stage;
  final int progress;
  final bool terminal;
  final ExportFailure? failure;
  final DateTime updatedAt;

  const ExportJobViewState({
    required this.jobId,
    required this.projectId,
    required this.state,
    required this.stage,
    required this.progress,
    required this.terminal,
    required this.updatedAt,
    this.failure,
  });

  factory ExportJobViewState.created({
    required String jobId,
    required String projectId,
  }) {
    return ExportJobViewState(
      jobId: jobId,
      projectId: projectId,
      state: ExportJobState.created,
      stage: 'Created',
      progress: 0,
      terminal: false,
      updatedAt: DateTime.now(),
    );
  }

  ExportJobViewState copyWith({
    String? state,
    String? stage,
    int? progress,
    bool? terminal,
    ExportFailure? failure,
    DateTime? updatedAt,
  }) {
    return ExportJobViewState(
      jobId: jobId,
      projectId: projectId,
      state: state ?? this.state,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      terminal: terminal ?? this.terminal,
      failure: failure ?? this.failure,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'jobId': jobId,
        'projectId': projectId,
        'state': state,
        'stage': stage,
        'progress': progress,
        'terminal': terminal,
        'updatedAt': updatedAt.toIso8601String(),
        if (failure != null) 'failure': failure!.toJson(),
      };
}

class ExportEventReducer {
  const ExportEventReducer();

  ExportJobViewState reduceNativeEvent({
    required ExportJobViewState current,
    required String eventType,
    required Map<String, Object?> payload,
  }) {
    final snapshot = ExportStateSnapshot.fromNativePayload(payload);
    final nextState = _stateFromEventType(eventType, snapshot.state);

    if (!ExportJobState.canTransition(current.state, nextState)) {
      if (current.state == nextState) {
        return current.copyWith(
          stage: snapshot.stage,
          progress: snapshot.progress,
          terminal: snapshot.terminal,
          failure: snapshot.failure,
          updatedAt: DateTime.now(),
        );
      }

      final failure = ExportFailure(
        code: ExportErrorCode.invalidTransition,
        severity: ExportErrorSeverity.fatal,
        userMessage: 'Export entered an invalid state.',
        technicalMessage: 'Invalid transition ${current.state} -> $nextState from $eventType',
        recoverySuggestion: 'Restart the export job.',
        retryable: true,
        context: payload,
      );
      return current.copyWith(
        state: ExportJobState.failed,
        stage: 'Failed',
        progress: current.progress,
        terminal: true,
        failure: failure,
        updatedAt: DateTime.now(),
      );
    }

    return current.copyWith(
      state: nextState,
      stage: snapshot.stage,
      progress: snapshot.progress,
      terminal: snapshot.terminal || ExportJobState.isTerminal(nextState),
      failure: snapshot.failure,
      updatedAt: DateTime.now(),
    );
  }

  String _stateFromEventType(String eventType, String payloadState) {
    if (payloadState != ExportJobState.created) return payloadState;
    switch (eventType) {
      case 'export_accepted':
        return ExportJobState.accepted;
      case 'export_started':
        return ExportJobState.preparing;
      case 'export_progress':
        return ExportJobState.rendering;
      case 'export_cancel_requested':
        return ExportJobState.cancelRequested;
      case 'export_cancelled':
        return ExportJobState.cancelled;
      case 'export_completed':
        return ExportJobState.completed;
      case 'export_failed':
        return ExportJobState.failed;
      default:
        return payloadState;
    }
  }
}
