import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/monetization/product_model.dart';
import 'package:nle_editor/domain/monetization/pro_entitlement.dart';
import 'package:nle_editor/domain/monetization/purchase_result.dart';
import 'package:nle_editor/presentation/providers/monetization_providers.dart';
import 'package:nle_editor/presentation/providers/supabase_auth_providers.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/screens/auth/auth_screen.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_button.dart';

class ProPaywallScreen extends ConsumerWidget {
  final String? requiredFeatureTitle;
  final String? requiredFeatureDescription;

  const ProPaywallScreen({
    super.key,
    this.requiredFeatureTitle,
    this.requiredFeatureDescription,
  });

  static Future<void> show(
    BuildContext context, {
    String? requiredFeatureTitle,
    String? requiredFeatureDescription,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProPaywallScreen(
          requiredFeatureTitle: requiredFeatureTitle,
          requiredFeatureDescription: requiredFeatureDescription,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monetization = ref.watch(monetizationProvider);
    final controller = ref.read(monetizationProvider.notifier);

    final products = monetization.products;
    final isPending = monetization.status == PurchaseFlowStatus.pending;

    // Pop the screen once a purchase is successfully complete
    ref.listen(monetizationProvider, (previous, next) {
      if ((next.status == PurchaseFlowStatus.purchased ||
              next.status == PurchaseFlowStatus.restored) &&
          next.entitlement.isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Pro status updated!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Unlock Pro'),
        actions: [
          PremiumBounceButton(
            onTap: isPending ? null : controller.restorePurchases,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Restore',
                style: TextStyle(color: AppTheme.accentPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _HeroCard(
            title: requiredFeatureTitle ?? 'Unlock Kata Pro',
            subtitle: requiredFeatureDescription ??
                'Get premium packs, no watermark, 4K export, advanced audio, batch proxies, and creator tools.',
          ),
          const SizedBox(height: 18),
          const _BenefitList(),
          const SizedBox(height: 18),
          const _CloudAuthStatusCard(),
          const SizedBox(height: 18),
          if (monetization.loadingProducts)
            const Center(child: CircularProgressIndicator())
          else if (products.isEmpty)
            _StoreUnavailableCard(
              onRetry: controller.loadProducts,
            )
          else
            ...products.map(
              (product) => _ProductCard(
                product: product,
                pending: isPending,
                onTap: () => controller.buy(product),
              ),
            ),
          const SizedBox(height: 12),
          PremiumBounceButton(
            onTap: isPending
                ? null
                : () async {
                    await controller.startTrial();
                  },
            child: IgnorePointer(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.timer_rounded),
                label: const Text('Start Local Trial'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            monetization.message ??
                'Subscriptions renew automatically unless cancelled in your store account. V1 uses mock purchases outside production.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF151B2A),
            Color(0xFF2D1B4A),
            Color(0xFF111827),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x55FFD36A)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 58,
            color: Color(0xFFFFD36A),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList();

  static const benefits = [
    'Remove watermark',
    'Premium effects, transitions, text, and color packs',
    '4K export support',
    'Batch proxy generation',
    'Advanced audio tools',
    'Premium social templates',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
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

class _ProductCard extends StatelessWidget {
  final MonetizationProduct product;
  final bool pending;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.pending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final recommended = product.recommended;

    return PremiumBounceButton(
      onTap: pending ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: recommended
              ? const Color(0xFFFFD36A).withOpacity(0.10)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: recommended ? const Color(0xFFFFD36A) : AppTheme.borderSubtle,
            width: recommended ? 1.4 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(
                product.isLifetime
                    ? Icons.all_inclusive_rounded
                    : Icons.calendar_month_rounded,
                color: recommended
                    ? const Color(0xFFFFD36A)
                    : AppTheme.accentPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD36A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.priceText,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  if (product.trialDays != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${product.trialDays} days free',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreUnavailableCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _StoreUnavailableCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 36),
          const SizedBox(height: 10),
          const Text(
            'Store Products Unavailable',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'We could not load store products. Please check your internet connection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          PremiumButton(
            label: 'Retry',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _CloudAuthStatusCard extends ConsumerWidget {
  const _CloudAuthStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(supabaseAuthStateProvider);
    final monetization = ref.watch(monetizationProvider);
    final isPending = monetization.status == PurchaseFlowStatus.pending;

    if (authState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(PremiumRadius.md),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (authState.isAuthenticated) {
      final user = authState.user;
      final entitlement = monetization.entitlement;
      final isPro = entitlement.isPro;

      String statusName = 'FREE';
      if (isPro) {
        if (entitlement.status == ProPlanStatus.lifetime) {
          statusName = 'LIFETIME PRO';
        } else if (entitlement.status == ProPlanStatus.trial) {
          statusName = 'TRIAL ACTIVE';
        } else {
          statusName = 'PRO ACTIVE';
        }
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(PremiumRadius.md),
          border: Border.all(
            color: isPro
                ? AppTheme.accentPrimary.withOpacity(0.3)
                : AppTheme.borderSubtle,
          ),
          boxShadow: isPro
              ? PremiumShadows.glow(AppTheme.accentPrimary.withOpacity(0.08))
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPro
                    ? AppTheme.accentPrimary.withOpacity(0.1)
                    : AppTheme.surface,
              ),
              child: Icon(
                isPro ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                color: isPro ? AppTheme.accentPrimary : AppTheme.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.email ?? 'Logged In',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPro
                              ? AppTheme.accentPrimary.withOpacity(0.2)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusName,
                          style: TextStyle(
                            color: isPro
                                ? AppTheme.accentPrimary
                                : AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Cloud Sync Active',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PremiumBounceButton(
              onTap: isPending
                  ? null
                  : () async {
                      ref.read(hapticServiceProvider).medium();
                      await ref.read(supabaseAuthServiceProvider).signOut();
                    },
              child: IgnorePointer(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout_rounded,
                      size: 16, color: AppTheme.error),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Unauthenticated
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(PremiumRadius.md),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Cloud Synchronization',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PremiumButton(
            label: 'Sign In',
            secondary: true,
            onPressed: isPending
                ? null
                : () {
                    ref.read(hapticServiceProvider).selection();
                    AuthScreen.show(context);
                  },
          ),
        ],
      ),
    );
  }
}
