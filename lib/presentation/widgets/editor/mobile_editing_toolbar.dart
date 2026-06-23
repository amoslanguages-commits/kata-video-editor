import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/clip_interactions_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/screens/settings/settings_screen.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';
import 'package:nle_editor/presentation/helpers/permission_flow_helper.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/domain/services/silence_removal_service.dart';

class MobileEditingToolbar extends ConsumerWidget {
  final String projectId;
  final VoidCallback? onActionCompleted;

  const MobileEditingToolbar({
    super.key,
    required this.projectId,
    this.onActionCompleted,
  });

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
    if (onActionCompleted != null) {
      onActionCompleted!();
    }
  }

  void _showAspectRatioDialog(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.read(selectedProjectProvider);
    final currentRatio = projectAsync.value?.aspectRatio ?? '16:9';

    final ratios = [
      {'ratio': '16:9', 'name': 'Widescreen (16:9)', 'icon': Icons.crop_16_9},
      {'ratio': '9:16', 'name': 'Portrait (9:16)', 'icon': Icons.crop_portrait},
      {'ratio': '1:1', 'name': 'Square (1:1)', 'icon': Icons.crop_square},
      {'ratio': '4:5', 'name': 'Vertical (4:5)', 'icon': Icons.crop_5_4},
      {'ratio': '21:9', 'name': 'Cinematic (21:9)', 'icon': Icons.crop_7_5},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Choose Aspect Ratio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              ...ratios.map((item) {
                final isSelected = item['ratio'] == currentRatio;
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isSelected
                        ? AppTheme.accentPrimary
                        : AppTheme.textSecondary,
                  ),
                  title: Text(
                    item['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.accentPrimary)
                      : null,
                  onTap: () async {
                    await ref
                        .read(projectRepositoryProvider)
                        .updateProjectFields(
                          projectId,
                          ProjectsCompanion(
                            aspectRatio: Value(item['ratio'] as String),
                          ),
                        );
                    _triggerHaptic();
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final selectedClipAsync = ref.watch(selectedClipProvider);
    final clip = selectedClipAsync.value;

    final controller = ref.read(clipInteractionsControllerProvider(projectId));
    final editorNotifier = ref.read(editorStateProvider.notifier);

    // List of tools depends on context
    final List<Widget> items = [];

    if (clip == null) {
      // General Mode (No selection)
      items.addAll([
        _buildItem(
          icon: Icons.perm_media_rounded,
          label: 'Media',
          onTap: () async {
            _triggerHaptic();
            final hasPerm = await PermissionFlowHelper.ensureWithDialog(
              context,
              ref,
              permissionType: AppPermissionType.mediaLibrary,
              projectId: projectId,
            );
            if (!hasPerm) return;

            await ref
                .read(mediaImportServiceProvider)
                .pickAndImportMedia(projectId);
            editorNotifier.setTool('media');
          },
        ),
        _buildItem(
          icon: Icons.text_fields_rounded,
          label: 'Text',
          onTap: () async {
            _triggerHaptic();
            final clipId =
                await ref.read(timelineCommandServiceProvider).addTextClip(
                      projectId: projectId,
                      timelineStartMicros: editorState.currentTimeMicros,
                    );
            editorNotifier.selectClip(clipId, null);
            editorNotifier.setTool('text');
          },
        ),
        _buildItem(
          icon: Icons.aspect_ratio_rounded,
          label: 'Aspect',
          onTap: () {
            _triggerHaptic();
            _showAspectRatioDialog(context, ref);
          },
        ),
        _buildItem(
          icon: editorState.snapEnabled
              ? Icons.bolt
              : Icons.offline_bolt_outlined,
          label: 'Snap',
          onTap: () {
            _triggerHaptic();
            editorNotifier.toggleSnap();
          },
          color: editorState.snapEnabled ? AppTheme.accentPrimary : null,
        ),
        _buildItem(
          icon: Icons.link_rounded,
          label: 'Link Select',
          onTap: () {
            _triggerHaptic();
            editorNotifier.toggleLinkedSelection();
          },
          color: editorState.linkedSelectionEnabled ? AppTheme.accentPrimary : null,
        ),
        _buildItem(
          icon: Icons.undo_rounded,
          label: 'Undo',
          onTap: () async {
            _triggerHaptic();
            await ref.read(timelineCommandServiceProvider).undo(projectId);
          },
        ),
        _buildItem(
          icon: Icons.redo_rounded,
          label: 'Redo',
          onTap: () async {
            _triggerHaptic();
            await ref.read(timelineCommandServiceProvider).redo(projectId);
          },
        ),
        _buildItem(
          icon: Icons.settings_rounded,
          label: 'Settings',
          onTap: () {
            _triggerHaptic();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ]);
    } else {
      // Selection Mode (A clip is active)
      // Back button to clear selection
      items.add(
        _buildItem(
          icon: Icons.arrow_back_ios_new_rounded,
          label: 'Back',
          onTap: () {
            _triggerHaptic();
            editorNotifier.deselectClip();
            ref
                .read(multitrackTimelineControllerProvider.notifier)
                .clearSelection();
          },
        ),
      );

      // Split (Applicable to Video, Audio if playhead is within bounds)
      final playhead = editorState.currentTimeMicros;
      final insideClip = playhead > clip.timelineStartMicros &&
          playhead < clip.timelineEndMicros;
      final canSplit =
          (clip.clipType == 'video' || clip.clipType == 'audio') && insideClip;

      items.add(
        _buildItem(
          icon: Icons.content_cut_rounded,
          label: 'Split',
          enabled: canSplit,
          onTap: () async {
            _triggerHaptic();
            final result = await controller.splitClipAt(
              clipId: clip.id,
              splitMicros: playhead,
            );
            if (result.newClipId != null) {
              editorNotifier.selectClip(result.newClipId!, null);
            }
          },
        ),
      );

      items.add(
        _buildItem(
          icon: Icons.format_align_left_rounded,
          label: 'Top',
          enabled: canSplit,
          onTap: () async {
            _triggerHaptic();
            await ref.read(timelineCommandServiceProvider).trimToPlayheadTop(
              projectId: projectId,
              clipId: clip.id,
              playheadMicros: playhead,
              ripple: editorState.magneticTimelineEnabled,
            );
          },
        ),
      );

      items.add(
        _buildItem(
          icon: Icons.format_align_right_rounded,
          label: 'Tail',
          enabled: canSplit,
          onTap: () async {
            _triggerHaptic();
            await ref.read(timelineCommandServiceProvider).trimToPlayheadTail(
              projectId: projectId,
              clipId: clip.id,
              playheadMicros: playhead,
              ripple: editorState.magneticTimelineEnabled,
            );
          },
        ),
      );

      items.add(
        _buildItem(
          icon: Icons.auto_awesome_rounded,
          label: 'Auto Cut',
          enabled: canSplit,
          onTap: () async {
            _triggerHaptic();
            await ref.read(silenceRemovalServiceProvider).removeSilenceFromClip(projectId, clip.id);
          },
          color: AppTheme.accentPrimary,
        ),
      );

      if (clip.clipType == 'video') {
        items.addAll([
          _buildItem(
            icon: Icons.compare_arrows_rounded,
            label: 'Transitions',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('transitions');
            },
          ),
          _buildItem(
            icon: Icons.animation_rounded,
            label: 'Keyframes',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('keyframes');
            },
          ),
          _buildItem(
            icon: Icons.volume_up_rounded,
            label: 'Volume',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('audio');
            },
          ),
          _buildItem(
            icon: Icons.switch_left_rounded,
            label: 'Slip',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('slip');
            },
          ),
          _buildItem(
            icon: Icons.open_with_rounded,
            label: 'Slide',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('slide');
            },
          ),
          _buildItem(
            icon: Icons.compress_rounded,
            label: 'Ripple',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('ripple');
            },
          ),
          _buildItem(
            icon: Icons.sync_alt_rounded,
            label: 'Roll',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('roll');
            },
          ),
          _buildItem(
            icon: Icons.crop_rounded,
            label: 'Crop',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('edit');
            },
          ),
          _buildItem(
            icon: Icons.speed_rounded,
            label: 'Speed',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('edit');
            },
          ),
          _buildItem(
            icon: Icons.tune_rounded,
            label: 'Adjust',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('adjust');
            },
          ),
          _buildItem(
            icon: Icons.filter_b_and_w_rounded,
            label: 'Filters',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('filters');
            },
          ),
        ]);
      } else if (clip.clipType == 'audio') {
        items.addAll([
          _buildItem(
            icon: Icons.volume_up_rounded,
            label: 'Volume',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('audio');
            },
          ),
          _buildItem(
            icon: Icons.trending_up_rounded,
            label: 'Fades',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('audio');
            },
          ),
        ]);
      } else if (clip.clipType == 'text') {
        items.addAll([
          _buildItem(
            icon: Icons.title_rounded,
            label: 'Text Style',
            onTap: () {
              _triggerHaptic();
              editorNotifier.setTool('text');
            },
          ),
        ]);
      }

      // Duplicate & Delete (Generic to all clips)
      items.addAll([
        _buildItem(
          icon: Icons.copy_rounded,
          label: 'Duplicate',
          onTap: () async {
            _triggerHaptic();
            final result = await controller.duplicateClip(clipId: clip.id);
            if (result.newClipId != null) {
              editorNotifier.selectClip(result.newClipId!, null);
            }
          },
        ),
        _buildItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          color: Colors.redAccent,
          onTap: () async {
            _triggerHaptic();
            await controller.deleteClip(clipId: clip.id);
            editorNotifier.deselectClip();
            ref
                .read(multitrackTimelineControllerProvider.notifier)
                .clearSelection();
          },
        ),
      ]);
    }

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: items,
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
    Color? color,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: PremiumBounceButton(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color ?? AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      color != null ? FontWeight.bold : FontWeight.normal,
                  color: color ?? AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
