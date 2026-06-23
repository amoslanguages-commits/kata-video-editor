import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/config/app_environment.dart';
import 'package:nle_editor/core/release/release_checklist.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';
import 'package:nle_editor/presentation/providers/release_providers.dart';
import 'package:nle_editor/presentation/screens/release/privacy_data_screen.dart';
import 'package:nle_editor/presentation/providers/device_qa_controller.dart';
import 'package:nle_editor/domain/device_qa/device_qa_models.dart';

class ReleaseChecklistScreen extends ConsumerWidget {
  const ReleaseChecklistScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(releaseChecklistProvider);
    final config = ref.watch(appConfigProvider);
    final build = ref.watch(buildMetadataProvider);

    final allItems =
        ReleaseChecklistCatalog.groups.expand((g) => g.items).toList();
    final progress = allItems.isEmpty ? 0.0 : done.length / allItems.length;

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Release Preparation'),
        actions: [
          IconButton(
            tooltip: 'Privacy Data',
            icon: const Icon(Icons.privacy_tip_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyDataScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(releaseChecklistProvider.notifier).reset();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.appName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Environment: ${config.environment.displayName}',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 10),
                build.when(
                  data: (metadata) => Text(
                    'Build: ${metadata.fullVersion} • ${metadata.packageName}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    e.toString(),
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                const SizedBox(height: 8),
                Text(
                  '${done.length}/${allItems.length} release checks complete',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...ReleaseChecklistCatalog.groups.map(
            (group) => _ChecklistGroupCard(
              group: group,
              done: done,
            ),
          ),
          if (progress >= 1.0) const _BetaReadinessGateCard(),
        ],
      ),
    );
  }
}

class _ChecklistGroupCard extends ConsumerWidget {
  final ReleaseChecklistGroup group;
  final Set<String> done;

  const _ChecklistGroupCard({
    required this.group,
    required this.done,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Text(
            group.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...group.items.map(
            (item) {
              final checked = done.contains(item.id);

              return Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: checked,
                  onChanged: (value) {
                    ref
                        .read(releaseChecklistProvider.notifier)
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
                    item.description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BetaReadinessGateCard extends ConsumerWidget {
  const _BetaReadinessGateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceQaControllerProvider);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPrimary.withValues(alpha: 0.15),
            AppTheme.accentSecondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_rounded,
                  color: AppTheme.accentPrimary, size: 22),
              SizedBox(width: 8),
              Text(
                'Beta Readiness Gate',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'All release preparation checks are complete! Run the hardware and performance QA gate to qualify this device configuration for beta release.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (deviceState.loading)
            const Column(
              children: [
                LinearProgressIndicator(color: AppTheme.accentPrimary),
                SizedBox(height: 8),
                Text(
                  'Running Hardware Capability & Performance Benchmarks...',
                  style: TextStyle(
                      color: AppTheme.accentPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            )
          else if (deviceState.qaReport != null)
            _buildQaReportSummary(context, ref, deviceState.qaReport!)
          else
            ElevatedButton.icon(
              onPressed: () {
                ref.read(deviceQaControllerProvider.notifier).runFullQa();
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
              label: const Text('Run QA Benchmarks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQaReportSummary(
      BuildContext context, WidgetRef ref, DeviceQaReport report) {
    final passed = report.passed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: passed
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: passed
                  ? AppTheme.success.withValues(alpha: 0.3)
                  : AppTheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: passed ? AppTheme.success : AppTheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  passed
                      ? 'PASSED: READY FOR BETA BUILD'
                      : 'FAILED: HARDWARE DEFICIENCIES DETECTED',
                  style: TextStyle(
                    color: passed ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Device: ${report.capabilityReport.brand} ${report.capabilityReport.model} (Tier: ${report.capabilityReport.tierLabel})',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Decoder/Encoder: H.264 ${report.capabilityReport.codec.hasH264Decoder ? "✅" : "❌"} / ${report.capabilityReport.codec.hasH264Encoder ? "✅" : "❌"}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        Text(
          'OpenGL: GLES ${report.capabilityReport.egl.glesVersion} (Max texture: ${report.capabilityReport.egl.maxTextureSize}px)',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        if (report.issues.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Identified issues:',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          ...report.issues.map((issue) {
            final color = issue.isFail ? AppTheme.error : AppTheme.warning;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      issue.message,
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                ref.read(deviceQaControllerProvider.notifier).clear();
              },
              child: const Text('Reset Gate',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(deviceQaControllerProvider.notifier).runFullQa();
              },
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: Colors.black),
              label: const Text('Rerun', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
