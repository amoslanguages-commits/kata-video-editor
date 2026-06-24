import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/domain/storage/project_storage_report.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class CacheControlPanel extends ConsumerWidget {
  final String projectId;

  const CacheControlPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(projectStorageReportProvider(projectId));

    return reportAsync.when(
      data: (report) => _CacheControlView(projectId: projectId, report: report),
      loading: () => const _CacheLoadingPanel(),
      error: (error, stack) => _CacheErrorPanel(message: 'Cache report unavailable: $error'),
    );
  }
}

class _CacheControlView extends ConsumerWidget {
  final String projectId;
  final ProjectStorageReport report;

  const _CacheControlView({
    required this.projectId,
    required this.report,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reclaimableBytes = report.thumbnailsBytes +
        report.timelineThumbnailsBytes +
        report.waveformsBytes +
        report.tempBytes +
        report.proxiesBytes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cleaning_services_rounded,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cache Control',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${TimeUtils.formatFileSize(reclaimableBytes)} reclaimable generated files',
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
                color: AppTheme.textSecondary,
                onPressed: () => ref.invalidate(projectStorageReportProvider(projectId)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CacheBar(report: report),
          const SizedBox(height: 14),
          _CacheMetricRow(
            label: 'Proxies',
            value: TimeUtils.formatFileSize(report.proxiesBytes),
            color: AppTheme.accentPrimary,
          ),
          _CacheMetricRow(
            label: 'Preview cache',
            value: TimeUtils.formatFileSize(
              report.thumbnailsBytes + report.timelineThumbnailsBytes + report.waveformsBytes,
            ),
            color: AppTheme.success,
          ),
          _CacheMetricRow(
            label: 'Temporary render files',
            value: TimeUtils.formatFileSize(report.tempBytes),
            color: AppTheme.error,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CacheActionButton(
                label: 'Clear temp',
                icon: Icons.delete_sweep_rounded,
                onPressed: report.tempBytes <= 0
                    ? null
                    : () => _runAction(
                          context,
                          ref,
                          () => ref
                              .read(cacheStorageServiceProvider)
                              .clearTemporaryExportFiles(projectId),
                        ),
              ),
              _CacheActionButton(
                label: 'Clear previews',
                icon: Icons.image_not_supported_rounded,
                onPressed: (report.thumbnailsBytes + report.timelineThumbnailsBytes + report.waveformsBytes) <= 0
                    ? null
                    : () async {
                        await _runAction(
                          context,
                          ref,
                          () => ref.read(cacheStorageServiceProvider).clearThumbnails(projectId),
                        );
                        if (context.mounted) {
                          await _runAction(
                            context,
                            ref,
                            () => ref.read(cacheStorageServiceProvider).clearWaveforms(projectId),
                          );
                        }
                      },
              ),
              _CacheActionButton(
                label: 'Clear proxies',
                icon: Icons.movie_filter_rounded,
                danger: true,
                onPressed: report.proxiesBytes <= 0
                    ? null
                    : () async {
                        final confirmed = await _confirmProxyClear(context);
                        if (confirmed == true && context.mounted) {
                          await _runAction(
                            context,
                            ref,
                            () => ref.read(cacheStorageServiceProvider).clearProxies(projectId),
                          );
                        }
                      },
              ),
            ],
          ),
        ],
      ),
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
          '${result.message ?? 'Cache updated'} Freed ${TimeUtils.formatFileSize(result.deletedBytes)}.',
        ),
      ),
    );
  }

  Future<bool?> _confirmProxyClear(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Clear proxy files?'),
          content: const Text(
            'This deletes generated proxy files only. Original media stays safe, but preview may become slower until proxies are rebuilt.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear proxies'),
            ),
          ],
        );
      },
    );
  }
}

class _CacheBar extends StatelessWidget {
  final ProjectStorageReport report;

  const _CacheBar({required this.report});

  @override
  Widget build(BuildContext context) {
    final total = report.totalBytes <= 0 ? 1 : report.totalBytes;
    final items = [
      _BarItem(report.proxiesBytes / total, AppTheme.accentPrimary),
      _BarItem(
        (report.thumbnailsBytes + report.timelineThumbnailsBytes + report.waveformsBytes) / total,
        AppTheme.success,
      ),
      _BarItem(report.tempBytes / total, AppTheme.error),
      _BarItem(report.exportsBytes / total, AppTheme.accentSecondary),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 9,
        child: Row(
          children: items
              .where((item) => item.fraction > 0)
              .map((item) => Expanded(
                    flex: (item.fraction * 1000).round().clamp(1, 1000),
                    child: Container(color: item.color),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _BarItem {
  final double fraction;
  final Color color;

  const _BarItem(this.fraction, this.color);
}

class _CacheMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CacheMetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CacheActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger;
  final VoidCallback? onPressed;

  const _CacheActionButton({
    required this.label,
    required this.icon,
    this.danger = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.error : AppTheme.accentPrimary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: onPressed == null ? AppTheme.textDisabled : color,
        side: BorderSide(
          color: onPressed == null ? AppTheme.borderSubtle : color.withValues(alpha: 0.65),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CacheLoadingPanel extends StatelessWidget {
  const _CacheLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accentPrimary,
            ),
          ),
          SizedBox(width: 12),
          Text('Scanning cache...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _CacheErrorPanel extends StatelessWidget {
  final String message;

  const _CacheErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.error)),
    );
  }
}
