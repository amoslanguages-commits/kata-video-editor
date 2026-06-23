import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

/// Shows a slim banner when media library or gallery save permission is missing,
/// with a one-tap shortcut to open the system settings.
class PermissionWarningBanner extends ConsumerWidget {
  const PermissionWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync =
        ref.watch(appPermissionStateProvider(AppPermissionType.mediaLibrary));
    final galleryAsync =
        ref.watch(appPermissionStateProvider(AppPermissionType.gallerySave));

    final mediaOk = mediaAsync.when(
      data: (s) => s.hasAccess,
      loading: () => true, // don't flash banner while loading
      error: (_, __) => true,
    );
    final galleryOk = galleryAsync.when(
      data: (s) => s.hasAccess,
      loading: () => true,
      error: (_, __) => true,
    );

    if (mediaOk && galleryOk) return const SizedBox.shrink();

    final missingLabels = <String>[];
    if (!mediaOk) missingLabels.add('Media Library');
    if (!galleryOk) missingLabels.add('Gallery Save');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.10),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.error.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${missingLabels.join(' & ')} permission required.',
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(appPermissionServiceProvider).openSettings(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Open Settings',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
