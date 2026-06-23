import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/export/export_pipeline_models.dart';
import 'package:nle_editor/presentation/providers/export_pipeline_providers.dart';

class ExportPipelinePanel extends ConsumerWidget {
  final String projectId;

  const ExportPipelinePanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(projectExportJobsProvider(projectId));
    final summary = ref.watch(projectExportQueueSummaryProvider(projectId));

    return Container(
      color: AppTheme.editorBackground,
      child: jobsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPrimary),
        ),
        error: (error, _) => _EmptyExports(message: error.toString()),
        data: (jobs) {
          final sortedJobs = [...jobs]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              _ExportHeader(summary: summary),
              Expanded(
                child: sortedJobs.isEmpty
                    ? const _EmptyExports(
                        message:
                            'No export jobs yet. Completed, running, and failed renders will appear here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: sortedJobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _ExportJobTile(job: sortedJobs[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExportHeader extends StatelessWidget {
  final NleExportQueueSummary summary;

  const _ExportHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.ios_share_rounded, color: AppTheme.accentPrimary),
              SizedBox(width: 10),
              Text(
                'Export Pipeline',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Monitor render jobs, output status, progress, and errors.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: 'Total', value: summary.totalJobs),
              const SizedBox(width: 8),
              _Metric(label: 'Active', value: summary.runningJobs),
              const SizedBox(width: 8),
              _Metric(label: 'Done', value: summary.completedJobs),
              const SizedBox(width: 8),
              _Metric(label: 'Failed', value: summary.failedJobs),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportJobTile extends StatelessWidget {
  final ExportJob job;

  const _ExportJobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(job.status);
    final progress = job.progress.clamp(0, 100) / 100.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(job.status), color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Export job',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                job.status,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.stage,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: AppTheme.surfaceOverlay,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${job.progress.clamp(0, 100)}% complete',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          if (job.outputPath != null && job.outputPath!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              job.outputPath!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
          if (job.errorMessage != null && job.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              job.errorMessage!,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'completed' || normalized == 'done' || normalized == 'success') {
      return AppTheme.success;
    }
    if (normalized == 'failed' || normalized == 'error') {
      return AppTheme.error;
    }
    if (normalized == 'cancelled' || normalized == 'canceled') {
      return AppTheme.warning;
    }
    return AppTheme.accentPrimary;
  }

  IconData _statusIcon(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'completed' || normalized == 'done' || normalized == 'success') {
      return Icons.check_circle_rounded;
    }
    if (normalized == 'failed' || normalized == 'error') {
      return Icons.error_rounded;
    }
    if (normalized == 'cancelled' || normalized == 'canceled') {
      return Icons.cancel_rounded;
    }
    return Icons.autorenew_rounded;
  }
}

class _EmptyExports extends StatelessWidget {
  final String message;

  const _EmptyExports({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ios_share_rounded, size: 44, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Export History',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
