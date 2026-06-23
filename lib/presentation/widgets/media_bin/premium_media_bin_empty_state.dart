import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/helpers/permission_flow_helper.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';

class PremiumMediaBinEmptyState extends ConsumerStatefulWidget {
  const PremiumMediaBinEmptyState({super.key});

  @override
  ConsumerState<PremiumMediaBinEmptyState> createState() =>
      _PremiumMediaBinEmptyStateState();
}

class _PremiumMediaBinEmptyStateState extends ConsumerState<PremiumMediaBinEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(selectedProjectProvider).value;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pulse Animated Icon Box
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                final glow = _pulseController.value * 6.0;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.1 + (_pulseController.value * 0.05)),
                          blurRadius: glow + 10.0,
                          spreadRadius: glow * 0.5,
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.2 + (_pulseController.value * 0.2)),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.video_library_outlined,
                      size: 34,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Text Header
            const Text(
              'Import Media Assets',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 8),

            // Text Subtitle
            const SizedBox(
              width: 240,
              child: Text(
                'Drag and drop media files or click import to add videos, audio, and images to your workspace.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Import Button
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              onTap: project == null
                  ? null
                  : () async {
                      try {
                        final hasPerm = await PermissionFlowHelper.ensureWithDialog(
                          context,
                          ref,
                          permissionType: AppPermissionType.mediaLibrary,
                          projectId: project.id,
                        );
                        if (!hasPerm) return;

                        await ref
                            .read(mediaImportServiceProvider)
                            .pickAndImportMedia(project.id);
                        ref.invalidate(projectMediaAssetsProvider(project.id));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Import failed: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.accentGradientStart,
                      AppTheme.accentGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.black,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Import Files',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
