import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/sync/sync_qa_models.dart';
import 'package:nle_editor/presentation/providers/sync_qa_controller.dart';

/// Debug panel for 29D: Android Audio/Video Sync QA.
///
/// Shows export and preview sync reports with per-issue details.
/// Triggered manually via Run buttons.
class SyncQaPanel extends ConsumerWidget {
  const SyncQaPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state      = ref.watch(syncQaControllerProvider);
    final controller = ref.read(syncQaControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        _SyncQaHeader(
          allPassed: state.hasAnyReport ? state.allPassed : null,
        ),
        const SizedBox(height: PremiumSpacing.md),

        // ── Action buttons ───────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _QaButton(
                label: 'Run Export Sync QA',
                icon: Icons.movie_filter_rounded,
                onTap: state.loading ? null : controller.runExportQa,
              ),
            ),
            const SizedBox(width: PremiumSpacing.sm),
            Expanded(
              child: _QaButton(
                label: 'Run Preview Sync QA',
                icon: Icons.play_circle_rounded,
                onTap: state.loading ? null : controller.runPreviewQa,
              ),
            ),
            const SizedBox(width: PremiumSpacing.sm),
            _ClearButton(
              onTap: state.loading ? null : controller.clearTelemetry,
            ),
          ],
        ),

        const SizedBox(height: PremiumSpacing.md),

        if (state.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (state.error != null)
          _ErrorBanner(message: state.error!)
        else if (!state.hasAnyReport)
          const _EmptyState()
        else
          Expanded(
            child: ListView(
              children: [
                if (state.exportReport != null) ...[
                  _ReportSection(
                    title:  '📦 Export Sync Report',
                    report: state.exportReport!,
                  ),
                  const SizedBox(height: PremiumSpacing.lg),
                ],
                if (state.previewReport != null)
                  _ReportSection(
                    title:  '▶️ Preview Sync Report',
                    report: state.previewReport!,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SyncQaHeader extends StatelessWidget {
  final bool? allPassed;

  const _SyncQaHeader({this.allPassed});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (allPassed == null) {
      color = AppTheme.textMuted;
      label = '29D: Android A/V Sync QA';
      icon  = Icons.sync_rounded;
    } else if (allPassed!) {
      color = AppTheme.success;
      label = '29D: Sync QA Passed ✓';
      icon  = Icons.verified_rounded;
    } else {
      color = AppTheme.error;
      label = '29D: Sync QA Issues Found';
      icon  = Icons.warning_amber_rounded;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color:      color,
            fontSize:   16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _QaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _QaButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical:   PremiumSpacing.sm,
          horizontal: PremiumSpacing.md,
        ),
        decoration: BoxDecoration(
          color:        onTap != null
              ? AppTheme.accentPrimary.withOpacity(0.12)
              : AppTheme.textMuted.withOpacity(0.06),
          borderRadius: BorderRadius.circular(PremiumRadius.md),
          border:       Border.all(
            color: onTap != null
                ? AppTheme.accentPrimary.withOpacity(0.40)
                : AppTheme.textMuted.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.accentPrimary, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color:      AppTheme.textPrimary,
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ClearButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(PremiumSpacing.sm),
        decoration: BoxDecoration(
          color:        AppTheme.error.withOpacity(0.10),
          borderRadius: BorderRadius.circular(PremiumRadius.md),
          border:       Border.all(color: AppTheme.error.withOpacity(0.30)),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.error,
          size:  18,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: const [
          Icon(Icons.sync_disabled_rounded, color: AppTheme.textMuted, size: 36),
          SizedBox(height: 12),
          Text(
            'No sync report yet.\nRun an export or preview first,\nthen tap a QA button.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color:        AppTheme.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(PremiumRadius.md),
        border:       Border.all(color: AppTheme.error.withOpacity(0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.error, height: 1.4),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final SyncQaReport report;

  const _ReportSection({
    required this.title,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final color = report.passed ? AppTheme.success : AppTheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title + summary
        Container(
          padding: const EdgeInsets.all(PremiumSpacing.md),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(PremiumRadius.lg),
            border:       Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color:      AppTheme.textPrimary,
                  fontSize:   14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                report.passed
                    ? '✅ All checks passed'
                    : '❌ ${report.failCount} failure(s) · ${report.warningCount} warning(s)',
                style: TextStyle(
                  color:      color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (report.videoTiming != null) ...[
                const SizedBox(height: 8),
                _MetaRow(
                  label: 'Frames',
                  value: '${report.videoTiming!.totalFrames} total · '
                      '${report.videoTiming!.droppedFrameCount} dropped · '
                      'max drift ${_usToMs(report.videoTiming!.maxDriftUs)}ms',
                ),
              ],
              if (report.audioTiming != null) ...[
                const SizedBox(height: 4),
                _MetaRow(
                  label: 'Audio',
                  value: '${report.audioTiming!.totalSamples} samples · '
                      '${report.audioTiming!.gapCount} gaps · '
                      'max gap ${_usToMs(report.audioTiming!.maxGapUs)}ms',
                ),
              ],
              if (report.drift != null) ...[
                const SizedBox(height: 4),
                _MetaRow(
                  label: 'Drift',
                  value: 'cumulative ${_usToMs(report.drift!.cumulativeDriftUs)}ms '
                      'over ${report.drift!.sampleCount} samples',
                ),
              ],
            ],
          ),
        ),

        // Issue list
        if (report.issues.isNotEmpty) ...[
          const SizedBox(height: PremiumSpacing.sm),
          ...report.issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _IssueRow(issue: issue),
            ),
          ),
        ],
      ],
    );
  }

  String _usToMs(int us) => (us / 1000).toStringAsFixed(1);
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color:      AppTheme.textSecondary,
            fontSize:   12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color:    AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _IssueRow extends StatelessWidget {
  final SyncQaIssue issue;

  const _IssueRow({required this.issue});

  @override
  Widget build(BuildContext context) {
    final color = issue.isFail ? AppTheme.error : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical:   8,
        horizontal: PremiumSpacing.md,
      ),
      decoration: BoxDecoration(
        color:        const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.md),
        border:       Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            issue.isFail
                ? Icons.cancel_rounded
                : Icons.error_outline_rounded,
            color: color,
            size:  16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.id,
                  style: const TextStyle(
                    color:      AppTheme.textSecondary,
                    fontSize:   11,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  issue.message,
                  style: const TextStyle(
                    color:  AppTheme.textPrimary,
                    height: 1.3,
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
