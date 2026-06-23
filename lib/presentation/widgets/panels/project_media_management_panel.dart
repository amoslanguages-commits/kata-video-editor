import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/project_media/project_media_management_models.dart';
import 'package:nle_editor/presentation/providers/project_media_management_providers.dart';

/// 34C-PRO: Project Archive / Relink / Media Management panel.
///
/// This panel is intentionally self-contained. It can be mounted from the
/// existing tool panel, project settings screen, or a future media-management
/// workspace without modifying editor core code.
class ProjectMediaManagementPanel extends ConsumerWidget {
  final String projectId;

  const ProjectMediaManagementPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(projectMediaHealthReportProvider(projectId));

    return Container(
      color: AppTheme.surfaceDark,
      child: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageState(
          icon: Icons.error_outline_rounded,
          title: 'Media scan failed',
          message: error.toString(),
        ),
        data: (report) => _ProjectMediaManagementContent(
          projectId: projectId,
          report: report,
        ),
      ),
    );
  }
}

class _ProjectMediaManagementContent extends ConsumerWidget {
  final String projectId;
  final NleProjectMediaHealthReport report;

  const _ProjectMediaManagementContent({
    required this.projectId,
    required this.report,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            const Icon(Icons.folder_copy_rounded, color: AppTheme.accentPrimary, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Project Media Management',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh scan',
              onPressed: () => ref.invalidate(projectMediaHealthReportProvider(projectId)),
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HealthSummaryCard(report: report),
        const SizedBox(height: 12),
        _ActionGrid(
          projectId: projectId,
          report: report,
        ),
        const SizedBox(height: 12),
        _StorageBreakdownCard(storage: report.storage),
        const SizedBox(height: 12),
        _MissingMediaList(report: report),
      ],
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  final NleProjectMediaHealthReport report;

  const _HealthSummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = report.canExport ? AppTheme.success : AppTheme.error;
    final title = report.canExport ? 'Ready for export' : 'Media needs attention';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(
            report.canExport ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.usedCount} used • ${report.unusedCount} unused • ${report.missingCount} missing • ${report.corruptedCount} corrupted',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends ConsumerWidget {
  final String projectId;
  final NleProjectMediaHealthReport report;

  const _ActionGrid({
    required this.projectId,
    required this.report,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionButton(
          icon: Icons.archive_rounded,
          label: 'Archive Used Media',
          onTap: () => _archive(
            context,
            ref,
            NleProjectArchiveMode.usedMediaOnly,
          ),
        ),
        _ActionButton(
          icon: Icons.inventory_2_rounded,
          label: 'Archive Full Project',
          onTap: () => _archive(
            context,
            ref,
            NleProjectArchiveMode.fullProject,
          ),
        ),
        _ActionButton(
          icon: Icons.link_rounded,
          label: 'Batch Relink',
          onTap: () => _batchRelink(context, ref),
        ),
        _ActionButton(
          icon: Icons.cleaning_services_rounded,
          label: 'Dry Run Cleanup',
          onTap: () => _cleanup(context, ref, dryRun: true),
        ),
      ],
    );
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    NleProjectArchiveMode mode,
  ) async {
    final result = await ref.read(projectArchiveServiceProvider).createArchive(
          projectId: projectId,
          mode: mode,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Archive created: ${result.copiedFiles} files copied to ${result.archiveRootPath}',
        ),
      ),
    );
  }

  Future<void> _batchRelink(BuildContext context, WidgetRef ref) async {
    final root = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose folder to search for missing media',
    );
    if (root == null) return;

    final result = await ref.read(projectRelinkCleanupServiceProvider).relinkAutomatically(
          projectId: projectId,
          searchRootPath: root,
        );

    ref.invalidate(projectMediaHealthReportProvider(projectId));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Relink complete: ${result.relinkedCount} relinked, ${result.skippedCount} skipped.',
        ),
      ),
    );
  }

  Future<void> _cleanup(
    BuildContext context,
    WidgetRef ref, {
    required bool dryRun,
  }) async {
    final result = await ref.read(projectRelinkCleanupServiceProvider).cleanupProject(
      projectId: projectId,
      dryRun: dryRun,
      scopes: const {
        NleProjectCleanupScope.unusedCopiedFiles,
        NleProjectCleanupScope.proxies,
        NleProjectCleanupScope.tempFiles,
      },
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          dryRun
              ? 'Dry run: ${_formatBytes(result.freedBytes)} could be freed.'
              : 'Cleanup complete: ${_formatBytes(result.freedBytes)} freed.',
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accentPrimary,
          side: const BorderSide(color: AppTheme.accentPrimary, width: 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        ),
      ),
    );
  }
}

class _StorageBreakdownCard extends StatelessWidget {
  final NleProjectStorageBreakdown storage;

  const _StorageBreakdownCard({required this.storage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage Breakdown',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _StorageRow('Used media', storage.usedMediaBytes),
          _StorageRow('Unused media', storage.unusedMediaBytes),
          _StorageRow('Proxies', storage.proxyBytes),
          _StorageRow('Thumbnails', storage.thumbnailBytes),
          _StorageRow('Waveforms', storage.waveformBytes),
          _StorageRow('Exports', storage.exportBytes),
          _StorageRow('Temp', storage.tempBytes),
          const Divider(color: AppTheme.borderSubtle),
          _StorageRow('Total', storage.totalBytes, strong: true),
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  final String label;
  final int bytes;
  final bool strong;

  const _StorageRow(this.label, this.bytes, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatBytes(bytes),
            style: TextStyle(
              color: strong ? Colors.white : AppTheme.textMuted,
              fontSize: 11,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingMediaList extends StatelessWidget {
  final NleProjectMediaHealthReport report;

  const _MissingMediaList({required this.report});

  @override
  Widget build(BuildContext context) {
    final items = report.items
        .where((item) => item.status != NleMediaHealthStatus.healthy)
        .toList();

    if (items.isEmpty) {
      return const _MessageState(
        icon: Icons.check_circle_rounded,
        title: 'No media issues',
        message: 'All project media paths are currently healthy.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const ListTile(
            dense: true,
            title: Text(
              'Media Issues',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          ...items.map(
            (item) => ListTile(
              dense: true,
              leading: Icon(
                item.blocksExport ? Icons.error_rounded : Icons.warning_rounded,
                color: item.blocksExport ? AppTheme.error : AppTheme.warning,
                size: 18,
              ),
              title: Text(
                item.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                item.message,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.accentPrimary, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(2)} GB';
}
