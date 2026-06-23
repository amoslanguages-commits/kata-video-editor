import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';

class PremiumLoadingState extends StatelessWidget {
  final String title;
  final String? message;

  const PremiumLoadingState({
    super.key,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PremiumSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.accentPrimary,
              ),
            ),
            const SizedBox(height: PremiumSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: PremiumSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
