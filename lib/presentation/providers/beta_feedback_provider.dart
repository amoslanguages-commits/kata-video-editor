import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/beta/beta_feedback_service.dart';

final betaFeedbackServiceProvider = Provider<BetaFeedbackService>((ref) {
  return const BetaFeedbackService();
});
