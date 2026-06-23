import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/ui/ux_review_checklist.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';

class UxReviewChecklistScreen extends ConsumerWidget {
  const UxReviewChecklistScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(uxReviewChecklistProvider);
    final allItems = UxReviewChecklistCatalog.items;
    final progress = allItems.isEmpty ? 0.0 : done.length / allItems.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('UX Review Checklist'),
        actions: [
          IconButton(
            tooltip: 'Reset checklist',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(uxReviewChecklistProvider.notifier).reset();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(PremiumSpacing.lg),
        children: [
          _ProgressHeader(
            title: 'UX Polish Readiness',
            subtitle: '${done.length}/${allItems.length} checks complete',
            progress: progress,
          ),
          const SizedBox(height: PremiumSpacing.lg),
          Container(
            padding: const EdgeInsets.all(PremiumSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(PremiumRadius.lg),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                for (final item in allItems)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: done.contains(item.id),
                    activeColor: AppTheme.accentPrimary,
                    onChanged: (value) {
                      ref
                          .read(uxReviewChecklistProvider.notifier)
                          .toggle(item.id, value == true);
                      ref.read(hapticServiceProvider).selection();
                    },
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${item.description}\nVerification: ${item.verificationSteps}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        height: 1.35,
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

class _ProgressHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;

  const _ProgressHeader({
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: AppTheme.accentPrimary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: PremiumSpacing.md),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            color: AppTheme.accentPrimary,
            backgroundColor: AppTheme.borderSubtle,
          ),
          const SizedBox(height: PremiumSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
