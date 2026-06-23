import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/export_readiness_provider.dart';

class SafeExportButton extends ConsumerWidget {
  final String projectId;
  final VoidCallback onTriggerExport;

  const SafeExportButton({
    super.key,
    required this.projectId,
    required this.onTriggerExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(exportReadinessProvider(projectId));
    final export = ref.watch(exportStateProvider);

    if (export.isExporting) {
      return _ExportStatusChip(
        progress: export.progress,
        stage: export.stage.isEmpty ? 'Exporting' : export.stage,
      );
    }

    if (export.error != null && export.error!.isNotEmpty) {
      return _ExportFailedChip(error: export.error!);
    }

    final isReady = readiness.isReady;

    return Tooltip(
      message: readiness.userMessage,
      child: Opacity(
        opacity: isReady ? 1.0 : 0.5,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: isReady ? AppTheme.accentPrimary : AppTheme.surfaceDark,
            foregroundColor: isReady ? Colors.black : AppTheme.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isReady
                  ? BorderSide.none
                  : const BorderSide(color: AppTheme.borderSubtle, width: 1),
            ),
          ),
          icon: Icon(
            Icons.ios_share_rounded,
            size: 15,
            color: isReady ? Colors.black : AppTheme.textMuted,
          ),
          label: const Text(
            'Export',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          onPressed: () {
            if (isReady) {
              onTriggerExport();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(readiness.userMessage),
                  backgroundColor: AppTheme.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _ExportStatusChip extends StatelessWidget {
  final int progress;
  final String stage;

  const _ExportStatusChip({
    required this.progress,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0, 100);

    return Tooltip(
      message: '$stage • $safeProgress%',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.accentPrimary.withOpacity(0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                value: safeProgress / 100,
                strokeWidth: 2.4,
                color: AppTheme.accentPrimary,
                backgroundColor: AppTheme.surfaceOverlay,
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$safeProgress% Exporting',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    stage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportFailedChip extends StatelessWidget {
  final String error;

  const _ExportFailedChip({required this.error});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: error,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.error.withOpacity(0.12),
          foregroundColor: AppTheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppTheme.error.withOpacity(0.35)),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        },
        icon: const Icon(Icons.error_outline_rounded, size: 15),
        label: const Text(
          'Export Failed',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}
