import 'package:flutter/foundation.dart';

import 'package:nle_editor/domain/beta/beta_feedback_models.dart';

class BetaFeedbackService {
  const BetaFeedbackService();

  Future<void> submitFeedback(BetaFeedbackSubmission submission) async {
    // Mock API submission by printing details to local console / developer logs
    debugPrint('=== BETA FEEDBACK SUBMISSION ===');
    debugPrint('ID: ${submission.id}');
    debugPrint('Type: ${submission.type.name}');
    debugPrint('Email: ${submission.email}');
    debugPrint('Description: ${submission.description}');
    debugPrint('Context: ${submission.deviceContext}');
    debugPrint('Submitted At: ${submission.submittedAt}');
    debugPrint('================================');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
  }
}
