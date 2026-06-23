import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/permissions/permission_request_dialog.dart';
import 'package:nle_editor/core/theme/app_theme.dart';

class PermissionFlowHelper {
  PermissionFlowHelper._();

  static Future<bool> ensureWithDialog(
    BuildContext context,
    WidgetRef ref, {
    required String permissionType,
    String? projectId,
    String? source,
  }) async {
    final service = ref.read(appPermissionServiceProvider);

    final current = await service.check(permissionType);

    if (current.hasAccess) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final result = await PermissionRequestDialog.show(
      context,
      permissionType: permissionType,
      projectId: projectId,
      source: source,
    );

    if (result == null) return false;

    if (!result.hasAccess && result.shouldOpenSettings) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permission denied. Opening settings...'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                service.openSettings();
              },
            ),
          ),
        );
        // Automatically open settings since they just clicked "Allow" in our modal
        await service.openSettings();
      }
    }

    return result.hasAccess;
  }
}
