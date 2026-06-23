import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class PermissionExplanationScreen extends ConsumerWidget {
  final String permissionType;
  final String? projectId;
  final String? source;
  final VoidCallback? onGranted;
  final VoidCallback? onSkip;

  const PermissionExplanationScreen({
    super.key,
    required this.permissionType,
    this.projectId,
    this.source,
    this.onGranted,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purpose = AppPermissionPurposes.forType(permissionType);

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Permission'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForName(purpose.iconName),
                  color: AppTheme.accentPrimary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                purpose.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                purpose.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: Text(purpose.primaryButton),
                  onPressed: () async {
                    final state = await ref
                        .read(appPermissionServiceProvider)
                        .request(
                          permissionType,
                          projectId: projectId,
                          source: source ?? 'permission_explanation_screen',
                        );

                    if (state.hasAccess) {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }

                      onGranted?.call();
                    } else if (context.mounted) {
                      await _showDeniedDialog(context, ref, state);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onSkip?.call();
                },
                child: Text(purpose.secondaryButton),
              ),
              const Spacer(),
              const Text(
                'You can change this later in settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textDisabled,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeniedDialog(
    BuildContext context,
    WidgetRef ref,
    AppPermissionState state,
  ) async {
    final purpose = AppPermissionPurposes.forType(permissionType);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text(purpose.deniedTitle),
          content: Text(
            state.shouldOpenSettings
                ? purpose.settingsMessage
                : purpose.deniedMessage,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (state.shouldOpenSettings)
              ElevatedButton(
                onPressed: () async {
                  await ref.read(appPermissionServiceProvider).openSettings();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Open Settings'),
              ),
          ],
        );
      },
    );
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'video_library':
        return Icons.video_library_rounded;
      case 'save_alt':
        return Icons.save_alt_rounded;
      case 'mic':
        return Icons.mic_rounded;
      case 'notifications':
        return Icons.notifications_rounded;
      case 'lock':
      default:
        return Icons.lock_rounded;
    }
  }
}
