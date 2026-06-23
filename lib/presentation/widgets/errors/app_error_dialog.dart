import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/errors/app_error.dart';

class AppErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onAction;

  const AppErrorDialog({
    super.key,
    required this.error,
    this.onAction,
  });

  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onAction,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AppErrorDialog(
        error: error,
        onAction: onAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Icon(
            _iconForCategory(error.category),
            color: _colorForSeverity(error.severity),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _titleForCategory(error.category),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.userMessage,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            if (error.recoverySuggestion != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _colorForSeverity(error.severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(
                    color: _colorForSeverity(error.severity).withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: _colorForSeverity(error.severity),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error.recoverySuggestion!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _DetailRow(label: 'Code', value: error.code),
            if (error.nativeCode != null)
              _DetailRow(label: 'Native Code', value: error.nativeCode!),
            if (error.source != null)
              _DetailRow(label: 'Source Module', value: error.source!),
            if (error.technicalMessage != null) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text(
                  'Technical Details',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                collapsedIconColor: AppTheme.textMuted,
                iconColor: AppTheme.accentPrimary,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
                    ),
                    child: Text(
                      error.technicalMessage!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        if (error.action != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorForSeverity(error.severity),
              foregroundColor: error.severity == AppErrorSeverity.warning ? Colors.black : Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              onAction?.call();
            },
            child: Text(error.action!.label),
          ),
      ],
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case AppErrorCategory.permission:
        return Icons.lock_rounded;
      case AppErrorCategory.missingFile:
        return Icons.link_off_rounded;
      case AppErrorCategory.unsupportedCodec:
        return Icons.movie_filter_rounded;
      case AppErrorCategory.storage:
        return Icons.storage_rounded;
      case AppErrorCategory.export:
        return Icons.upload_file_rounded;
      case AppErrorCategory.proxy:
        return Icons.movie_creation_outlined;
      case AppErrorCategory.timeline:
        return Icons.timeline_rounded;
      case AppErrorCategory.nativeEngine:
        return Icons.memory_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  String _titleForCategory(String category) {
    switch (category) {
      case AppErrorCategory.permission:
        return 'Permission Needed';
      case AppErrorCategory.missingFile:
        return 'Missing Media';
      case AppErrorCategory.unsupportedCodec:
        return 'Unsupported Format';
      case AppErrorCategory.storage:
        return 'Storage Issue';
      case AppErrorCategory.export:
        return 'Export Failed';
      case AppErrorCategory.proxy:
        return 'Proxy Interrupted';
      case AppErrorCategory.timeline:
        return 'Editing Error';
      case AppErrorCategory.nativeEngine:
        return 'Rendering Engine Error';
      default:
        return 'System Alert';
    }
  }

  Color _colorForSeverity(String severity) {
    switch (severity) {
      case AppErrorSeverity.info:
        return AppTheme.accentPrimary;
      case AppErrorSeverity.warning:
        return AppTheme.warning;
      case AppErrorSeverity.critical:
      case AppErrorSeverity.error:
      default:
        return AppTheme.error;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
