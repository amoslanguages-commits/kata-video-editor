import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';
import 'package:nle_editor/presentation/providers/monetization_providers.dart';
import 'package:nle_editor/presentation/screens/monetization/pro_paywall_screen.dart';

class ProUpgradeSheet extends ConsumerWidget {
  final String? featureTitle;

  const ProUpgradeSheet({
    super.key,
    this.featureTitle,
  });

  static Future<void> show(
    BuildContext context, {
    String? featureTitle,
  }) {
    return ProPaywallScreen.show(
      context,
      requiredFeatureTitle:
          featureTitle == null ? null : 'Unlock $featureTitle',
      requiredFeatureDescription: featureTitle == null
          ? null
          : 'Get $featureTitle and all premium packs, no watermark, 4K export, and advanced tools.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final showDevUnlock = config.safeToShowDevUnlock;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFC857),
              size: 46,
            ),
            const SizedBox(height: 14),
            Text(
              featureTitle == null ? 'Unlock Pro' : 'Unlock $featureTitle',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Get premium transitions, cinematic text, creator effects, 4K export, and no watermark.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const _ProFeatureRow(
              icon: Icons.auto_awesome_rounded,
              text: 'Premium effects and color packs',
            ),
            const _ProFeatureRow(
              icon: Icons.title_rounded,
              text: 'Cinematic text and title styles',
            ),
            const _ProFeatureRow(
              icon: Icons.movie_filter_rounded,
              text: 'Premium transitions and templates',
            ),
            const _ProFeatureRow(
              icon: Icons.high_quality_rounded,
              text: '4K export and no watermark',
            ),
            const SizedBox(height: 20),
            if (showDevUnlock) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(monetizationProvider.notifier).startTrial();

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Unlock Pro Locally'),
              ),
              const SizedBox(height: 8),
              const Text(
                'V1 uses local unlock only. Real payment/subscription validation comes later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Premium Checkout Coming Soon'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Subscription/monetization validation will be enabled for the App Store release.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProFeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
