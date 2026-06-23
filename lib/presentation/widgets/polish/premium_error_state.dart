import 'package:flutter/material.dart';

import 'package:nle_editor/core/copy/app_copy.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_empty_state.dart';

class PremiumErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const PremiumErrorState({
    super.key,
    this.title = AppCopy.somethingWentWrong,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      icon: Icons.error_rounded,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : AppCopy.retry,
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
    );
  }
}
