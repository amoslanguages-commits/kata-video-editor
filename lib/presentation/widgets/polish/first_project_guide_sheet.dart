import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_button.dart';

class FirstProjectGuideSheet extends ConsumerWidget {
  const FirstProjectGuideSheet({
    super.key,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PremiumRadius.lg),
        ),
      ),
      builder: (_) => const FirstProjectGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PremiumSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(PremiumRadius.pill),
              ),
            ),
            const SizedBox(height: PremiumSpacing.xl),
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.accentPrimary,
              size: 44,
            ),
            const SizedBox(height: PremiumSpacing.lg),
            const Text(
              'Your editing workflow',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: PremiumSpacing.md),
            const _GuideStep(
              number: '1',
              title: 'Import media',
              body: 'Add videos, images, or audio from your device.',
            ),
            const _GuideStep(
              number: '2',
              title: 'Build timeline',
              body: 'Trim, move, split, add text, and apply transitions.',
            ),
            const _GuideStep(
              number: '3',
              title: 'Export',
              body: 'Choose a social preset and render your final video.',
            ),
            const SizedBox(height: PremiumSpacing.lg),
            PremiumButton(
              label: 'Start Editing',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: () async {
                await ref
                    .read(onboardingStateServiceProvider)
                    .markFirstProjectGuideSeen();
                ref.invalidate(hasSeenFirstProjectGuideProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: PremiumSpacing.md),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: PremiumGradients.cyanGlow,
              borderRadius: BorderRadius.circular(PremiumRadius.pill),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: PremiumSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
