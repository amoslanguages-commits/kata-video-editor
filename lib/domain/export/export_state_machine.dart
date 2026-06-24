class ExportJobState {
  static const String created = 'created';
  static const String accepted = 'accepted';
  static const String preflighting = 'preflighting';
  static const String queued = 'queued';
  static const String preparing = 'preparing';
  static const String rendering = 'rendering';
  static const String muxing = 'muxing';
  static const String finalizing = 'finalizing';
  static const String completed = 'completed';
  static const String cancelRequested = 'cancel_requested';
  static const String cancelled = 'cancelled';
  static const String failed = 'failed';

  static const Set<String> terminalStates = {
    completed,
    cancelled,
    failed,
  };

  static const Map<String, Set<String>> allowedTransitions = {
    created: {accepted, preflighting, queued, failed},
    accepted: {preflighting, queued, preparing, cancelRequested, failed},
    preflighting: {queued, preparing, cancelRequested, failed},
    queued: {preparing, cancelRequested, failed},
    preparing: {rendering, muxing, finalizing, cancelRequested, failed},
    rendering: {muxing, finalizing, cancelRequested, failed},
    muxing: {finalizing, cancelRequested, failed},
    finalizing: {completed, cancelRequested, failed},
    cancelRequested: {cancelled, failed},
    completed: {},
    cancelled: {},
    failed: {},
  };

  static bool isTerminal(String state) => terminalStates.contains(state);

  static bool canTransition(String from, String to) {
    if (from == to) return true;
    return allowedTransitions[from]?.contains(to) ?? false;
  }

  const ExportJobState._();
}

class ExportErrorSeverity {
  static const String info = 'info';
  static const String warning = 'warning';
  static const String recoverable = 'recoverable';
  static const String fatal = 'fatal';

  const ExportErrorSeverity._();
}

class ExportErrorCode {
  static const String invalidTransition = 'export_invalid_transition';
  static const String preflightFailed = 'export_preflight_failed';
  static const String missingAsset = 'export_missing_asset';
  static const String outputNotWritable = 'export_output_not_writable';
  static const String encoderFailed = 'export_encoder_failed';
  static const String decoderFailed = 'export_decoder_failed';
  static const String muxerFailed = 'export_muxer_failed';
  static const String cancelled = 'export_cancelled';
  static const String nativeFailed = 'export_native_failed';
  static const String unknown = 'export_unknown_error';

  const ExportErrorCode._();
}

class ExportFailure {
  final String code;
  final String severity;
  final String userMessage;
  final String? technicalMessage;
  final String? recoverySuggestion;
  final bool retryable;
  final Map<String, Object?> context;

  const ExportFailure({
    required this.code,
    required this.severity,
    required this.userMessage,
    this.technicalMessage,
    this.recoverySuggestion,
    this.retryable = false,
    this.context = const {},
  });

  factory ExportFailure.fromJson(Map<String, Object?> json) {
    return ExportFailure(
      code: json['code']?.toString() ?? ExportErrorCode.unknown,
      severity: json['severity']?.toString() ?? ExportErrorSeverity.fatal,
      userMessage: json['userMessage']?.toString() ??
          json['message']?.toString() ??
          'Export failed.',
      technicalMessage: json['technicalMessage']?.toString(),
      recoverySuggestion: json['recoverySuggestion']?.toString(),
      retryable: json['retryable'] == true,
      context: _objectMap(json['context']),
    );
  }

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity,
        'userMessage': userMessage,
        if (technicalMessage != null) 'technicalMessage': technicalMessage,
        if (recoverySuggestion != null) 'recoverySuggestion': recoverySuggestion,
        'retryable': retryable,
        'context': context,
      };
}

class ExportStateTransition {
  final String from;
  final String to;
  final int progress;
  final String stage;
  final DateTime at;
  final ExportFailure? failure;
  final Map<String, Object?> context;

  const ExportStateTransition({
    required this.from,
    required this.to,
    required this.progress,
    required this.stage,
    required this.at,
    this.failure,
    this.context = const {},
  });

  Map<String, Object?> toJson() => {
        'from': from,
        'to': to,
        'progress': progress,
        'stage': stage,
        'at': at.toIso8601String(),
        if (failure != null) 'failure': failure!.toJson(),
        'context': context,
      };
}

class ExportStateSnapshot {
  final String state;
  final String previousState;
  final int progress;
  final String stage;
  final bool terminal;
  final ExportFailure? failure;
  final Map<String, Object?> rawPayload;

  const ExportStateSnapshot({
    required this.state,
    required this.previousState,
    required this.progress,
    required this.stage,
    required this.terminal,
    this.failure,
    this.rawPayload = const {},
  });

  factory ExportStateSnapshot.fromNativePayload(Map<String, Object?> payload) {
    final state = payload['exportState']?.toString() ??
        payload['state']?.toString() ??
        ExportJobState.created;
    final error = _objectMap(payload['error']);
    return ExportStateSnapshot(
      state: state,
      previousState: payload['previousState']?.toString() ?? state,
      progress: _int(payload['progress']) ?? 0,
      stage: payload['stage']?.toString() ?? 'Waiting',
      terminal: payload['terminal'] == true || ExportJobState.isTerminal(state),
      failure: error.isEmpty ? null : ExportFailure.fromJson(error),
      rawPayload: payload,
    );
  }
}

class ExportStateMachine {
  String _state;
  int _progress;
  String _stage;
  final List<ExportStateTransition> _history;

  ExportStateMachine({
    String initialState = ExportJobState.created,
    int initialProgress = 0,
    String initialStage = 'Created',
  })  : _state = initialState,
        _progress = initialProgress,
        _stage = initialStage,
        _history = <ExportStateTransition>[];

  String get state => _state;
  int get progress => _progress;
  String get stage => _stage;
  bool get terminal => ExportJobState.isTerminal(_state);
  List<ExportStateTransition> get history => List.unmodifiable(_history);

  ExportStateTransition transitionTo(
    String nextState, {
    required String stage,
    int? progress,
    ExportFailure? failure,
    Map<String, Object?> context = const {},
  }) {
    if (!ExportJobState.canTransition(_state, nextState)) {
      throw StateError('Invalid export transition: $_state -> $nextState');
    }

    final nextProgress = _normalizeProgress(nextState, progress ?? _progress);
    final transition = ExportStateTransition(
      from: _state,
      to: nextState,
      progress: nextProgress,
      stage: stage,
      at: DateTime.now(),
      failure: failure,
      context: context,
    );

    _state = nextState;
    _progress = nextProgress;
    _stage = stage;
    _history.add(transition);
    return transition;
  }

  ExportStateTransition applyNativeSnapshot(ExportStateSnapshot snapshot) {
    return transitionTo(
      snapshot.state,
      stage: snapshot.stage,
      progress: snapshot.progress,
      failure: snapshot.failure,
      context: snapshot.rawPayload,
    );
  }

  int _normalizeProgress(String state, int progress) {
    if (state == ExportJobState.completed) return 100;
    return progress.clamp(0, 99).toInt();
  }
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, Object?>{};
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
