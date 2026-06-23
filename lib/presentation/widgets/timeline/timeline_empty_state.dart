import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_button.dart';
import 'package:nle_editor/presentation/helpers/permission_flow_helper.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';

class TimelineEmptyState extends ConsumerWidget {
  const TimelineEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider).value;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Stack / Visual
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.borderSubtle,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.movie_filter_outlined,
                  size: 32,
                  color: AppTheme.accentPrimary,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Your Timeline is Empty',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const SizedBox(
                width: 280,
                child: Text(
                  'Import video, audio, or image clips to start editing, or drag clips from the Media Bin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Open Media Bin
                    PremiumButton(
                      label: 'Media Bin',
                      icon: Icons.photo_library_outlined,
                      secondary: true,
                      onPressed: () {
                        ref.read(editorStateProvider.notifier).setTool('media');
                      },
                    ),

                    const SizedBox(width: 12),

                    // Import Media
                    PremiumButton(
                      label: 'Import Media',
                      icon: Icons.add_rounded,
                      onPressed: project == null
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
