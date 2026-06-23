import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/domain/storage/project_storage_report.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class ProjectStoragePanel extends ConsumerWidget {
  final String projectId;

  const ProjectStoragePanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(projectStorageReportProvider(projectId));

    return Container(
      color: AppTheme.editorBackground,
      child: reportAsync.when(
        data: (report) {
          return _StorageReportView(
            projectId: projectId,
            report: report,
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentPrimary),
          );
        },
        error: (err, stack) {
          return Center(
            child: Text(
              'Storage error: $err',
              style: const TextStyle(color: AppTheme.error),
            ),
          );
        },
      ),
    );
  }
}

class _StorageReportView extends ConsumerWidget {
  final String projectId;
  final ProjectStorageReport report;

  const _StorageReportView({
    required this.projectId,
    required this.report,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: AppTheme.accentPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Project Storage',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${TimeUtils.formatFileSize(report.totalBytes)} used by generated project files',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.invalidate(projectStorageReportProvider(projectId));
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _StorageBar(report: report),
        const SizedBox(height: 24),
        _StorageRow(
          label: 'Thumbnails',
          icon: Icons.image_rounded,
          bytes: report.thumbnailsBytes,
          files: report.thumbnailFileCount,
          color: AppTheme.warning,
          actionLabel: 'Clear',
          onAction: () async {
            await _runAction(
              context,
              ref,
              () => ref.read(cacheStorageServiceProvider).clearThumbnails(projectId),
            );
          },
        ),
        _StorageRow(
          label: 'Timeline thumbnails',
          icon: Icons.view_timeline_rounded,
          bytes: report.timelineThumbnailsBytes,
          files: report.timelineThumbnailFileCount,
          color: AppTheme.warning,
          actionLabel: 'Clear',
          onAction: () async {
            await _runAction(
              context,
              ref,
              () => ref.read(cacheStorageServiceProvider).clearThumbnails(projectId),
            );
          },
        ),
        _StorageRow(
          label: 'Waveforms',
          icon: Icons.graphic_eq_rounded,
          bytes: report.waveformsBytes,
          files: report.waveformFileCount,
          color: AppTheme.success,
          actionLabel: 'Clear',
          onAction: () async {
            await _runAction(
              context,
              ref,
              () => ref.read(cacheStorageServiceProvider).clearWaveforms(projectId),
            );
          },
        ),
        _StorageRow(
          label: 'Proxies',
          icon: Icons.movie_filter_rounded,
          bytes: report.proxiesBytes,
          files: report.proxyFileCount,
          color: AppTheme.accentPrimary,
          actionLabel: 'Clear',
          onAction: () async {
            await _confirmAndRun(
              context,
              ref,
              title: 'Clear proxies?',
              message:
                  'This deletes generated proxy files only. Your original videos will not be touched.',
              action: () => ref.read(cacheStorageServiceProvider).clearProxies(projectId),
            );
          },
        ),
        _StorageRow(
          label: 'Exports',
          icon: Icons.file_download_done_rounded,
          bytes: report.exportsBytes,
          files: report.exportFileCount,
          color: AppTheme.accentSecondary,
          actionLabel: 'Keep',
          onAction: null,
        ),
        _StorageRow(
          label: 'Temporary render files',
          icon: Icons.cleaning_services_rounded,
          bytes: report.tempBytes,
          files: report.tempFileCount,
          color: AppTheme.error,
          actionLabel: 'Clear',
          onAction: () async {
            await _runAction(
              context,
              ref,
              () => ref.read(cacheStorageServiceProvider).clearTemporaryExportFiles(projectId),
            );
          },
        ),
        _StorageRow(
          label: 'Autosaves',
          icon: Icons.history_rounded,
          bytes: report.autosavesBytes,
          files: report.autosaveFileCount,
          color: AppTheme.textSecondary,
          actionLabel: 'Trim',
          onAction: () async {
            await _runAction(
              context,
              ref,
              () => ref.read(cacheStorageServiceProvider).clearOldAutosaves(projectId),
            );
          },
        ),
        if (report.otherBytes > 0)
          _StorageRow(
            label: 'Other generated files',
            icon: Icons.folder_rounded,
            bytes: report.otherBytes,
            files: report.otherFileCount,
            color: AppTheme.textMuted,
            actionLabel: 'View',
            onAction: null,
          ),
        const SizedBox(height: 24),
        _DangerCleanupCard(projectId: projectId),
      ],
    );
  }

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref,
    Future<CacheClearResult> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await action();

    ref.invalidate(projectStorageReportProvider(projectId));

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.message ?? 'Done'} Freed ${TimeUtils.formatFileSize(result.deletedBytes)}.',
        ),
      ),
    );
  }

  Future<void> _confirmAndRun(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required Future<CacheClearResult> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text(title),
          content: Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
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

    if (confirmed == true && context.mounted) {
      await _runAction(context, ref, action);
    }
  }
}

class _StorageBar extends StatelessWidget {
  final ProjectStorageReport report;

  const _StorageBar({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final total = report.totalBytes <= 0 ? 1 : report.totalBytes;

    final items = [
      _BarItem(report.proxiesBytes / total, AppTheme.accentPrimary),
      _BarItem(report.thumbnailsBytes / total, AppTheme.warning),
      _BarItem(report.timelineThumbnailsBytes / total, AppTheme.warning.withValues(alpha: 0.65)),
      _BarItem(report.waveformsBytes / total, AppTheme.success),
      _BarItem(report.exportsBytes / total, AppTheme.accentSecondary),
      _BarItem(report.tempBytes / total, AppTheme.error),
      _BarItem(report.autosavesBytes / total, AppTheme.textMuted),
    ];

    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(99),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: items.map((item) {
          if (item.fraction <= 0) {
            return const SizedBox.shrink();
          }

          return Expanded(
            flex: (item.fraction * 1000).round().clamp(1, 1000),
            child: Container(color: item.color),
          );
        }).toList(),
      ),
    );
  }
}

class _BarItem {
  final double fraction;
  final Color color;

  const _BarItem(this.fraction, this.color);
}

class _StorageRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int bytes;
  final int files;
  final Color color;
  final String actionLabel;
  final VoidCallback? onAction;

  const _StorageRow({
    required this.label,
    required this.icon,
    required this.bytes,
    required this.files,
    required this.color,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${TimeUtils.formatFileSize(bytes)} • $files files',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _DangerCleanupCard extends ConsumerWidget {
  final String projectId;

  const _DangerCleanupCard({
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Safe cache cleanup',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Deletes generated thumbnails, waveforms, proxies, temp files, and old autosaves. Original videos, images, and audio files are never deleted.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('Clear Project Cache'),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: AppTheme.surfaceDark,
                      title: const Text('Clear project cache?'),
                      content: const Text(
                        'This removes only generated cache files. Your original media files will not be touched. Export files will be kept.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear Cache'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed != true) return;

                final messenger = ScaffoldMessenger.of(context);

                final result = await ref
                    .read(cacheStorageServiceProvider)
                    .deleteProjectCacheSafely(projectId);

                ref.invalidate(projectStorageReportProvider(projectId));

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cleared ${TimeUtils.formatFileSize(result.deletedBytes)}.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
