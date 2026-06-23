class TimelineDiagnosticSeverity {
  static const String info = 'info';
  static const String warning = 'warning';
  static const String error = 'error';
}

class TimelineDiagnosticIssue {
  final String code;
  final String severity;
  final String message;
  final String? clipId;
  final String? trackId;

  const TimelineDiagnosticIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.clipId,
    this.trackId,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'severity': severity,
      'message': message,
      'clipId': clipId,
      'trackId': trackId,
    };
  }
}

class TimelineRepairAction {
  final String code;
  final String message;
  final String? clipId;
  final String? trackId;

  const TimelineRepairAction({
    required this.code,
    required this.message,
    this.clipId,
    this.trackId,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'clipId': clipId,
      'trackId': trackId,
    };
  }
}

class TimelineDiagnosticsReport {
  final String projectId;
  final List<TimelineDiagnosticIssue> issues;
  final List<TimelineRepairAction> repairs;

  const TimelineDiagnosticsReport({
    required this.projectId,
    required this.issues,
    this.repairs = const [],
  });

  bool get hasErrors => issues.any((issue) => issue.severity == TimelineDiagnosticSeverity.error);
  bool get hasWarnings => issues.any((issue) => issue.severity == TimelineDiagnosticSeverity.warning);
  bool get repaired => repairs.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'hasErrors': hasErrors,
      'hasWarnings': hasWarnings,
      'repaired': repaired,
      'issues': issues.map((issue) => issue.toJson()).toList(),
      'repairs': repairs.map((repair) => repair.toJson()).toList(),
    };
  }
}
