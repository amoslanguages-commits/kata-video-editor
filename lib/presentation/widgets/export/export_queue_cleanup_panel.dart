import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/export_pipeline_providers.dart';

class ExportQueueCleanupPanel extends ConsumerWidget {
  final String projectId;

  const ExportQueueCleanupPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(projectExportQueueSummaryProvider(projectId));

    return Container(
      color: AppTheme.editorBackground,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _CleanupHeader(),
          const SizedBox(height: 16),
          _CleanupStatsCard(
            completed: summary.completedJobs,
            failed: summary.failedJobs + summary.cancelledJobs,
            active: summary.runningJobs,
            total: summary.totalJobs,
          ),
          const SizedBox(height: 16),
          _CleanupActionCard(
            title: 'Clear completed exports',
            message:
                'Remove completed export records from history. Exported video files are not deleted.',
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.success,
            enabled: summary.completedJobs > 0,
            onPressed: () => _confirmAndRun(
              context: context,
              title: 'Clear completed exports?',
              message:
                  'This removes completed export records from history, but keeps the actual video files on device.',
              onConfirm: () async {
                final count = await ref
                    .read(exportRepositoryProvider)
                    .deleteCompletedExports(projectId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed $count completed export record(s).')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          _CleanupActionCard(
            title: 'Clear failed and cancelled exports',
            message:
                'Remove failed or cancelled export records after you no longer need their error details.',
            icon: Icons.error_outline_rounded,
            color: AppTheme.error,
            enabled: (summary.failedJobs + summary.cancelledJobs) > 0,
            onPressed: () => _confirmAndRun(
              context: context,
              title: 'Clear failed exports?',
              message:
                  'This removes failed and cancelled export records from history. It does not delete media files.',
              onConfirm: () async {
                final count = await ref
                    .read(exportRepositoryProvider)
                    .deleteFailedExports(projectId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed $count failed or cancelled export record(s).')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          const _CleanupNote(),
        ],
      ),
    );
  }

  Future<void> _confirmAndRun({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await onConfirm();
    }
  }
}

class _CleanupHeader extends StatelessWidget {
  const _CleanupHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: AppTheme.accentPrimary),
            SizedBox(width: 10),
            Text(
              'Export Queue Cleanup',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Keep export history useful by removing old completed, failed, or cancelled records.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _CleanupStatsCard extends StatelessWidget {
  final int completed;
  final int failed;
  final int active;
  final int total;

  const _CleanupStatsCard({
    required this.completed,
    required this.failed,
    required this.active,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(child: _Stat(label: 'Total', value: total)),
          Expanded(child: _Stat(label: 'Active', value: active)),
          Expanded(child: _Stat(label: 'Done', value: completed)),
          Expanded(child: _Stat(label: 'Failed', value: failed)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _CleanupActionCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _CleanupActionCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: enabled ? onPressed : null,
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanupNote extends StatelessWidget {
  const _CleanupNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Cleanup only removes export history rows. It does not delete exported video files from device storage.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
