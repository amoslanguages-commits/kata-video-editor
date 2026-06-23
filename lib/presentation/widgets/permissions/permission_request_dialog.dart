import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class PermissionRequestDialog extends ConsumerWidget {
  final String permissionType;
  final String? projectId;
  final String? source;

  const PermissionRequestDialog({
    super.key,
    required this.permissionType,
    this.projectId,
    this.source,
  });

  static Future<AppPermissionState?> show(
    BuildContext context, {
    required String permissionType,
    String? projectId,
    String? source,
  }) {
    return showDialog<AppPermissionState>(
      context: context,
      builder: (_) => PermissionRequestDialog(
        permissionType: permissionType,
        projectId: projectId,
        source: source,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purpose = AppPermissionPurposes.forType(permissionType);

    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Row(
        children: [
          Icon(
            _iconForType(permissionType),
            color: AppTheme.accentPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(purpose.title)),
        ],
      ),
      content: Text(
        purpose.message,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          height: 1.35,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(purpose.secondaryButton),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await ref.read(appPermissionServiceProvider).request(
                  permissionType,
                  projectId: projectId,
                  source: source ?? 'permission_request_dialog',
                );

            if (context.mounted) {
              Navigator.pop(context, result);
            }
          },
          child: Text(purpose.primaryButton),
        ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case AppPermissionType.mediaLibrary:
        return Icons.video_library_rounded;
      case AppPermissionType.gallerySave:
        return Icons.save_alt_rounded;
      case AppPermissionType.microphone:
        return Icons.mic_rounded;
      case AppPermissionType.notifications:
        return Icons.notifications_rounded;
      default:
        return Icons.lock_rounded;
    }
  }
}
