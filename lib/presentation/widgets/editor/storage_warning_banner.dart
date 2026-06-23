import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/storage/project_storage_report.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

/// A slim banner shown at the top of the editor screen when available
/// storage is critically low (<200MB headroom estimated).
class StorageWarningBanner extends ConsumerWidget {
  final String projectId;

  const StorageWarningBanner({
    super.key,
    required this.projectId,
  });

  // Show warning when cache + temp files exceed 1 GB or when total is large.
  static const _warnThresholdBytes = 1024 * 1024 * 1024; // 1 GB

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(projectStorageReportProvider(projectId));

    return reportAsync.when(
      data: (report) {
        final showWarning = report.tempBytes > 500 * 1024 * 1024 ||
            report.totalBytes > _warnThresholdBytes;

        if (!showWarning) return const SizedBox.shrink();

        return _StorageBanner(
          report: report,
          onClearCache: () async {
            await ref
                .read(cacheStorageServiceProvider)
                .clearTemporaryExportFiles(projectId);
            ref.invalidate(projectStorageReportProvider(projectId));
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StorageBanner extends StatelessWidget {
  final ProjectStorageReport report;
  final VoidCallback onClearCache;

  const _StorageBanner({
    required this.report,
    required this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    final tempMb = (report.tempBytes / 1024 / 1024).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.warning.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage_rounded,
              color: AppTheme.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              report.tempBytes > 500 * 1024 * 1024
                  ? '${tempMb}MB of temporary render files are using disk space.'
                  : 'Project is using over 1 GB of generated files.',
              style: const TextStyle(
                color: AppTheme.warning,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onClearCache,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.warning,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
