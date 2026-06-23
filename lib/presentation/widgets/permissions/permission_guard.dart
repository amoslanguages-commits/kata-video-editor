import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/permissions/permission_denied_card.dart';

class PermissionGuard extends ConsumerWidget {
  final String permissionType;
  final String? projectId;
  final String? source;
  final Widget child;
  final Widget? loading;
  final Widget? denied;

  const PermissionGuard({
    super.key,
    required this.permissionType,
    required this.child,
    this.projectId,
    this.source,
    this.loading,
    this.denied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync =
        ref.watch(appPermissionStateProvider(permissionType));

    return permissionAsync.when(
      data: (state) {
        if (state.hasAccess) {
          return child;
        }

        return denied ??
            Padding(
              padding: const EdgeInsets.all(16),
              child: PermissionDeniedCard(
                permissionType: permissionType,
                state: state,
                projectId: projectId,
                source: source,
                onGranted: () {
                  ref.invalidate(appPermissionStateProvider(permissionType));
                },
              ),
            );
      },
      loading: () {
        return loading ??
            const Center(
              child: CircularProgressIndicator(color: AppTheme.accentPrimary),
            );
      },
      error: (err, stack) {
        return Center(
          child: Text(
            'Permission check failed: $err',
            style: const TextStyle(color: AppTheme.error),
          ),
        );
      },
    );
  }
}
