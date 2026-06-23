import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class PermissionDeniedCard extends ConsumerWidget {
  final String permissionType;
  final AppPermissionState? state;
  final String? projectId;
  final String? source;
  final VoidCallback? onGranted;

  const PermissionDeniedCard({
    super.key,
    required this.permissionType,
    this.state,
    this.projectId,
    this.source,
    this.onGranted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purpose = AppPermissionPurposes.forType(permissionType);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_rounded,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  purpose.deniedTitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state?.shouldOpenSettings == true
                ? purpose.settingsMessage
                : purpose.deniedMessage,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final result =
                        await ref.read(appPermissionServiceProvider).request(
                              permissionType,
                              projectId: projectId,
                              source: source ?? 'permission_denied_card',
                            );

                    if (result.hasAccess) {
                      onGranted?.call();
                    }
                  },
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(appPermissionServiceProvider).openSettings();
                  },
                  child: const Text('Settings'),
                ),
              ),
            ],
          ),
          if (state?.isLimited == true) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Manage Limited Access'),
                onPressed: () async {
                  await ref
                      .read(appPermissionServiceProvider)
                      .presentLimitedMediaPicker();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
