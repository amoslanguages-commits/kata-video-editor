import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/store_readiness/beta_testing_plan.dart';
import 'package:nle_editor/core/store_readiness/content_rating_prep.dart';
import 'package:nle_editor/core/store_readiness/permission_justification.dart';
import 'package:nle_editor/core/store_readiness/privacy_label_draft.dart';
import 'package:nle_editor/core/store_readiness/promo_video_plan.dart';
import 'package:nle_editor/core/store_readiness/review_risk.dart';
import 'package:nle_editor/core/store_readiness/screenshot_plan.dart';
import 'package:nle_editor/core/store_readiness/store_checklist.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/store_readiness_providers.dart';

class StoreReadinessScreen extends ConsumerStatefulWidget {
  const StoreReadinessScreen({
    super.key,
  });

  @override
  ConsumerState<StoreReadinessScreen> createState() =>
      _StoreReadinessScreenState();
}

class _StoreReadinessScreenState extends ConsumerState<StoreReadinessScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _StoreTab(
        title: 'Checklist',
        icon: Icons.fact_check_rounded,
        builder: (_) => const _StoreChecklistTab(),
      ),
      _StoreTab(
        title: 'Listing',
        icon: Icons.storefront_rounded,
        builder: (_) => const _ListingTab(),
      ),
      _StoreTab(
        title: 'Screenshots',
        icon: Icons.screenshot_monitor_rounded,
        builder: (_) => const _ScreenshotsTab(),
      ),
      _StoreTab(
        title: 'Privacy',
        icon: Icons.privacy_tip_rounded,
        builder: (_) => const _PrivacyTab(),
      ),
      _StoreTab(
        title: 'Beta',
        icon: Icons.science_rounded,
        builder: (_) => const _BetaTab(),
      ),
      _StoreTab(
        title: 'Risks',
        icon: Icons.warning_amber_rounded,
        builder: (_) => const _RisksTab(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Store Readiness'),
        actions: [
          IconButton(
            tooltip: 'Reset checklist',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(storeReadinessProvider.notifier).reset();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _tab,
            backgroundColor: AppTheme.surface,
            onDestinationSelected: (index) {
              setState(() => _tab = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final tab in tabs)
                NavigationRailDestination(
                  icon: Icon(tab.icon),
                  label: Text(tab.title),
                ),
            ],
          ),
          Expanded(
            child: tabs[_tab].builder(context),
          ),
        ],
      ),
    );
  }
}

class _StoreTab {
  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  const _StoreTab({
    required this.title,
    required this.icon,
    required this.builder,
  });
}

class _StoreChecklistTab extends ConsumerWidget {
  const _StoreChecklistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(storeReadinessProvider);
    final allItems =
        StoreChecklistCatalog.groups.expand((g) => g.items).toList();
    final progress = allItems.isEmpty ? 0.0 : done.length / allItems.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProgressHeader(
          title: 'Store Submission Readiness',
          subtitle: '${done.length}/${allItems.length} checks complete',
          progress: progress,
        ),
        const SizedBox(height: 16),
        for (final group in StoreChecklistCatalog.groups)
          _ChecklistGroupCard(
            group: group,
            done: done,
          ),
      ],
    );
  }
}

class _ChecklistGroupCard extends ConsumerWidget {
  final StoreChecklistGroup group;
  final Set<String> done;

  const _ChecklistGroupCard({
    required this.group,
    required this.done,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StoreCard(
      title: group.title,
      icon: Icons.checklist_rounded,
      child: Column(
        children: [
          for (final item in group.items)
            Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: done.contains(item.id),
                onChanged: (value) {
                  ref
                      .read(storeReadinessProvider.notifier)
                      .toggle(item.id, value == true);
                },
                title: Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${item.description}\nRisk: ${item.riskIfMissing}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListingTab extends ConsumerWidget {
  const _ListingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(storeListingDraftProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StoreCard(
          title: 'Store Listing Draft',
          icon: Icons.article_rounded,
          action: TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: listing.toMarkdown()),
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listing copied.')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldBlock(label: 'App Name', value: listing.appName),
              _FieldBlock(
                  label: 'Short Description', value: listing.shortDescription),
              _FieldBlock(label: 'Subtitle', value: listing.subtitle),
              _FieldBlock(
                  label: 'Promotional Text', value: listing.promotionalText),
              _FieldBlock(
                  label: 'Full Description', value: listing.fullDescription),
              _FieldBlock(
                  label: 'Keywords', value: listing.keywords.join(', ')),
              _FieldBlock(label: 'Support Email', value: listing.supportEmail),
              _FieldBlock(
                  label: 'Privacy Policy', value: listing.privacyPolicyUrl),
            ],
          ),
        ),
        const _PromoVideoPlanCard(),
      ],
    );
  }
}

class _ScreenshotsTab extends StatelessWidget {
  const _ScreenshotsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StoreCard(
          title: 'Screenshot Shot List',
          icon: Icons.screenshot_rounded,
          child: Column(
            children: [
              for (final shot in StoreScreenshotPlan.phoneScreenshots)
                _InfoTile(
                  title: shot.title,
                  subtitle:
                      '${shot.caption}\nScene: ${shot.scene}\nState: ${shot.requiredUiState}',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyTab extends StatelessWidget {
  const _PrivacyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _PermissionJustificationCard(),
        _PrivacyLabelDraftCard(),
        _ContentRatingCard(),
      ],
    );
  }
}

class _BetaTab extends StatelessWidget {
  const _BetaTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final phase in BetaTestingPlan.phases)
          _StoreCard(
            title: phase.title,
            icon: Icons.science_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldBlock(label: 'Goal', value: phase.goal),
                _FieldBlock(
                  label: 'Duration',
                  value: '${phase.duration.inDays} days',
                ),
                _FieldBlock(
                  label: 'Target testers',
                  value: phase.targetTesterCount.toString(),
                ),
                _FieldBlock(
                  label: 'Tester tasks',
                  value: phase.testerTasks.map((e) => '• $e').join('\n'),
                ),
                _FieldBlock(
                  label: 'Exit criteria',
                  value: phase.exitCriteria.map((e) => '• $e').join('\n'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RisksTab extends StatelessWidget {
  const _RisksTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final risk in StoreReviewRiskCatalog.risks)
          _StoreCard(
            title: risk.title,
            icon: Icons.warning_amber_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RiskPill(level: risk.level),
                const SizedBox(height: 10),
                Text(
                  risk.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mitigation: ${risk.mitigation}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PromoVideoPlanCard extends StatelessWidget {
  const _PromoVideoPlanCard();

  @override
  Widget build(BuildContext context) {
    return _StoreCard(
      title: 'Promo Video Plan',
      icon: Icons.video_camera_back_rounded,
      child: Column(
        children: [
          for (final segment in PromoVideoPlan.segments)
            _InfoTile(
              title:
                  '${segment.start.inSeconds}s–${segment.end.inSeconds}s • ${segment.onScreenText}',
              subtitle:
                  '${segment.scene}\nMotion: ${segment.motion}\nNotes: ${segment.notes}',
            ),
        ],
      ),
    );
  }
}

class _PermissionJustificationCard extends StatelessWidget {
  const _PermissionJustificationCard();

  @override
  Widget build(BuildContext context) {
    return _StoreCard(
      title: 'Permission Justifications',
      icon: Icons.admin_panel_settings_rounded,
      child: Column(
        children: [
          for (final permission in PermissionJustificationCatalog.permissions)
            _InfoTile(
              title: permission.permission,
              subtitle:
                  'Store: ${permission.storeReason}\nUser: ${permission.userFacingReason}\nCore feature: ${permission.requiredForCoreFeature ? 'Yes' : 'No'}',
            ),
        ],
      ),
    );
  }
}

class _PrivacyLabelDraftCard extends StatelessWidget {
  const _PrivacyLabelDraftCard();

  @override
  Widget build(BuildContext context) {
    return _StoreCard(
      title: 'Privacy Label / Data Safety Draft',
      icon: Icons.privacy_tip_rounded,
      child: Column(
        children: [
          for (final answer in PrivacyLabelDraft.answers)
            _InfoTile(
              title: '${answer.section}: ${answer.suggestedAnswer}',
              subtitle: '${answer.question}\n${answer.explanation}',
            ),
        ],
      ),
    );
  }
}

class _ContentRatingCard extends StatelessWidget {
  const _ContentRatingCard();

  @override
  Widget build(BuildContext context) {
    return _StoreCard(
      title: 'Content Rating Prep',
      icon: Icons.verified_user_rounded,
      child: Column(
        children: [
          for (final item in ContentRatingPrep.questions)
            _InfoTile(
              title: item.topic,
              subtitle:
                  'Suggested: ${item.suggestedAnswer}\n${item.explanation}',
            ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  const _StoreCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentPrimary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
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
    return _StoreCard(
      title: title,
      icon: Icons.rocket_launch_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final String value;

  const _FieldBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.accentPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskPill extends StatelessWidget {
  final String level;

  const _RiskPill({
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level) {
      case StoreReviewRiskLevel.high:
        color = AppTheme.error;
        break;
      case StoreReviewRiskLevel.medium:
        color = AppTheme.warning;
        break;
      case StoreReviewRiskLevel.low:
      default:
        color = AppTheme.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
