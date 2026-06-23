import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/errors/app_error.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/errors/app_error_dialog.dart';
import 'package:nle_editor/presentation/screens/settings/settings_screen.dart';

class AppErrorListener extends ConsumerWidget {
  final Widget child;

  const AppErrorListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AppError>>(appErrorEventsProvider, (previous, next) {
      next.whenData((error) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;

        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: _colorForSeverity(error.severity),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            content: Row(
              children: [
                Icon(
                  error.severity == AppErrorSeverity.critical ||
                          error.severity == AppErrorSeverity.error
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error.userMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                AppErrorDialog.show(
                  context,
                  error,
                  onAction: () => _handleErrorAction(context, ref, error),
                );
              },
            ),
          ),
        );
      });
    });

    return child;
  }

  void _handleErrorAction(BuildContext context, WidgetRef ref, AppError error) {
    final action = error.action;
    if (action == null) return;

    final messenger = ScaffoldMessenger.of(context);

    switch (action.actionId) {
      case AppErrorActionId.openSettings:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;

      case AppErrorActionId.clearCache:
        final pId = error.projectId;
        if (pId != null) {
          ref.read(cacheStorageServiceProvider).deleteProjectCacheSafely(pId).then((_) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Caches cleared successfully.'),
                backgroundColor: AppTheme.success,
              ),
            );
          });
        }
        break;

      case AppErrorActionId.useH264:
        ref.read(appSettingsProvider.notifier).update((s) {
          return s.copyWith(defaultExportCodec: 'h264');
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Preferences updated to use H.264 export.'),
            backgroundColor: AppTheme.success,
          ),
        );
        break;

      default:
        messenger.showSnackBar(
          SnackBar(
            content: Text('Triggered: ${action.label}'),
            backgroundColor: AppTheme.surfaceOverlay,
          ),
        );
        break;
    }
  }

  Color _colorForSeverity(String severity) {
    switch (severity) {
      case AppErrorSeverity.info:
        return AppTheme.surfaceElevated;
      case AppErrorSeverity.warning:
        return AppTheme.warning;
      case AppErrorSeverity.critical:
        return AppTheme.error;
      case AppErrorSeverity.error:
      default:
        return AppTheme.error;
    }
  }
}
