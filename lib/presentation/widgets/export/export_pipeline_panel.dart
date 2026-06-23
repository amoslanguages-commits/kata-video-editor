import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/export/export_pipeline_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
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
                          return _ExportJobTile(
                            projectId: projectId,
                            job: sortedJobs[index],
                          );
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

class _ExportJobTile extends ConsumerWidget {
  final String projectId;
  final ExportJob job;

  const _ExportJobTile({required this.projectId, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = _decodeSettings(job.settings);
    final viewModel = NleExportJobViewModel(job: job, settings: settings);
    final color = _statusColor(job.status);
    final progress = job.progress.clamp(0, 100) / 100.0;
    final outputPath = job.outputPath;
    final hasOutput = outputPath != null && outputPath.isNotEmpty;
    final outputExists = hasOutput && File(outputPath).existsSync();

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
                  '${viewModel.presetName} • ${viewModel.resolutionLabel}',
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
          if (hasOutput) ...[
            const SizedBox(height: 8),
            Text(
              outputPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
          if (job.errorMessage != null && job.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              job.errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _showDetails(context, viewModel),
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('Details'),
              ),
              if (hasOutput)
                TextButton.icon(
                  onPressed: () => _copyOutputPath(context, outputPath),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Path'),
                ),
              if (outputExists && viewModel.isCompleted)
                TextButton.icon(
                  onPressed: () => _shareOutput(context, outputPath),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share'),
                ),
              if (viewModel.isFailed)
                TextButton.icon(
                  onPressed: () => _retryExport(context, ref, settings),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _decodeSettings(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  Future<void> _copyOutputPath(BuildContext context, String outputPath) async {
    await Clipboard.setData(ClipboardData(text: outputPath));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export output path copied.')),
      );
    }
  }

  Future<void> _shareOutput(BuildContext context, String outputPath) async {
    final file = File(outputPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export file is no longer available.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(outputPath)],
      text: 'Exported from Kata Video Editor',
    );
  }

  Future<void> _retryExport(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> settings,
  ) async {
    try {
      await ref.read(nativeExportServiceProvider).startExport(
            projectId: projectId,
            settings: settings,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retry export started.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showDetails(BuildContext context, NleExportJobViewModel viewModel) {
    final job = viewModel.job;
    final settingsText = const JsonEncoder.withIndent('  ').convert(viewModel.settings);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.accentPrimary),
                      SizedBox(width: 10),
                      Text(
                        'Export Job Details',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Status', value: job.status),
                  _DetailRow(label: 'Stage', value: job.stage),
                  _DetailRow(label: 'Progress', value: '${job.progress.clamp(0, 100)}%'),
                  _DetailRow(label: 'Preset', value: viewModel.presetName),
                  _DetailRow(label: 'Resolution', value: viewModel.resolutionLabel),
                  _DetailRow(label: 'Bitrate', value: viewModel.bitrateLabel),
                  if (job.outputPath != null && job.outputPath!.isNotEmpty)
                    _DetailRow(label: 'Output', value: job.outputPath!),
                  if (job.errorMessage != null && job.errorMessage!.isNotEmpty)
                    _DetailRow(label: 'Error', value: job.errorMessage!),
                  const SizedBox(height: 12),
                  const Text(
                    'Settings JSON',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.editorBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Text(
                      settingsText,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
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
