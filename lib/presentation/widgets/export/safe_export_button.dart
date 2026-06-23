import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
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
