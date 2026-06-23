enum MultitrackQaSeverity {
  pass,
  warning,
  fail,
}

class MultitrackQaCheck {
  final String id;
  final String title;
  final String message;
  final MultitrackQaSeverity severity;
  final Map<String, dynamic> details;

  const MultitrackQaCheck({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.details = const {},
  });

  bool get passed => severity == MultitrackQaSeverity.pass;
  bool get failed => severity == MultitrackQaSeverity.fail;
  bool get warning => severity == MultitrackQaSeverity.warning;
}

class MultitrackQaReport {
  final String projectId;
  final DateTime generatedAt;
  final List<MultitrackQaCheck> checks;

  const MultitrackQaReport({
    required this.projectId,
    required this.generatedAt,
    required this.checks,
  });

  bool get passed => checks.every((check) => !check.failed);

  int get passCount {
    return checks.where((check) => check.passed).length;
  }

  int get warningCount {
    return checks.where((check) => check.warning).length;
  }

  int get failCount {
    return checks.where((check) => check.failed).length;
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'generatedAt': generatedAt.toIso8601String(),
      'passed': passed,
      'passCount': passCount,
      'warningCount': warningCount,
      'failCount': failCount,
      'checks': checks.map((check) {
        return {
          'id': check.id,
          'title': check.title,
          'message': check.message,
          'severity': check.severity.name,
          'details': check.details,
        };
      }).toList(),
    };
  }
}
