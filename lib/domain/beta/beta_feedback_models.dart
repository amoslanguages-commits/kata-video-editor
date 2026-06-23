enum BetaFeedbackType {
  bug,
  exportProblem,
  previewProblem,
  performanceProblem,
  suggestion,
}

class BetaFeedbackSubmission {
  final String id;
  final BetaFeedbackType type;
  final String email;
  final String description;
  final Map<String, dynamic> deviceContext;
  final DateTime submittedAt;

  const BetaFeedbackSubmission({
    required this.id,
    required this.type,
    required this.email,
    required this.description,
    required this.deviceContext,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'email': email,
      'description': description,
      'deviceContext': deviceContext,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case BetaFeedbackType.bug:
        return 'Bug';
      case BetaFeedbackType.exportProblem:
        return 'Export Issue';
      case BetaFeedbackType.previewProblem:
        return 'Preview/Playback Issue';
      case BetaFeedbackType.performanceProblem:
        return 'Performance Lag';
      case BetaFeedbackType.suggestion:
        return 'Suggestion/Request';
    }
  }
}
