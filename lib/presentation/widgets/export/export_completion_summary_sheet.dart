import 'dart:io';

import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/export/export_pipeline_models.dart';

Future<void> showExportCompletionSummary({
  required BuildContext context,
  required NleExportJobViewModel viewModel,
}) async {
  final job = viewModel.job;
  final outputPath = job.outputPath ?? 'No output path saved';
  final outputFileName = viewModel.settings['outputFileName']?.toString() ??
      outputPath.split(Platform.pathSeparator).last;
  final file = job.outputPath == null ? null : File(job.outputPath!);
  final fileSize = file != null && file.existsSync()
      ? _formatBytes(file.lengthSync())
      : 'Unavailable';

  await showModalBottomSheet<void>(
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
                    Icon(Icons.check_circle_rounded, color: AppTheme.success),
                    SizedBox(width: 10),
                    Text(
                      'Export Complete',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your render finished successfully. Use the queue actions to copy the path or share the exported file.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  fileName: outputFileName,
                  fileSize: fileSize,
                  preset: viewModel.presetName,
                  resolution: viewModel.resolutionLabel,
                  bitrate: viewModel.bitrateLabel,
                  status: job.status,
                  outputPath: outputPath,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Next actions: review the exported video, share it, or keep the project open for another version.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SummaryCard extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final String preset;
  final String resolution;
  final String bitrate;
  final String status;
  final String outputPath;

  const _SummaryCard({
    required this.fileName,
    required this.fileSize,
    required this.preset,
    required this.resolution,
    required this.bitrate,
    required this.status,
    required this.outputPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.editorBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(label: 'File', value: fileName),
          _Row(label: 'Size', value: fileSize),
          _Row(label: 'Status', value: status),
          _Row(label: 'Preset', value: preset),
          _Row(label: 'Resolution', value: resolution),
          _Row(label: 'Bitrate', value: bitrate),
          _Row(label: 'Path', value: outputPath),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: label == 'Path' ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  const gb = 1024 * 1024 * 1024;
  const mb = 1024 * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '$bytes B';
}
