import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/qa/multitrack_qa_models.dart';
import 'package:nle_editor/presentation/providers/multitrack_qa_providers.dart';

class MultitrackQaPanel extends ConsumerWidget {
  final String projectId;

  const MultitrackQaPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(projectMultitrackQaReportProvider(projectId));

    return report.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stackTrace) => _QaError(error: error),
      data: (report) {
        return Column(
          children: [
            _QaSummary(report: report),
            const SizedBox(height: PremiumSpacing.md),
            Expanded(
              child: ListView.separated(
                itemCount: report.checks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _QaCheckTile(
                    check: report.checks[index],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QaSummary extends StatelessWidget {
  final MultitrackQaReport report;

  const _QaSummary({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final color = report.passed ? AppTheme.success : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Icon(
            report.passed
                ? Icons.verified_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.passed
                      ? '29B Multitrack QA Passed'
                      : '29B Multitrack QA Needs Fixes',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.passCount} passed • ${report.warningCount} warnings • ${report.failCount} failed',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
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

class _QaCheckTile extends StatelessWidget {
  final MultitrackQaCheck check;

  const _QaCheckTile({
    required this.check,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(check.severity);

    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconFor(check.severity),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  check.message,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.3,
                  ),
                ),
                if (check.details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    check.details.toString(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(MultitrackQaSeverity severity) {
    switch (severity) {
      case MultitrackQaSeverity.pass:
        return AppTheme.success;
      case MultitrackQaSeverity.warning:
        return AppTheme.warning;
      case MultitrackQaSeverity.fail:
        return AppTheme.error;
    }
  }

  IconData _iconFor(MultitrackQaSeverity severity) {
    switch (severity) {
      case MultitrackQaSeverity.pass:
        return Icons.check_circle_rounded;
      case MultitrackQaSeverity.warning:
        return Icons.error_outline_rounded;
      case MultitrackQaSeverity.fail:
        return Icons.cancel_rounded;
    }
  }
}

class _QaError extends StatelessWidget {
  final Object error;

  const _QaError({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'QA error: $error',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.error),
      ),
    );
  }
}
