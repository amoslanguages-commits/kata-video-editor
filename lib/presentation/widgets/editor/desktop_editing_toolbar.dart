import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class DesktopEditingToolbar extends ConsumerWidget {
  final String projectId;
  const DesktopEditingToolbar({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final selectedClipId = editorState.selectedClipId;

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Timeline manipulation
          _ToolIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            onTap: () => ref.read(timelineCommandServiceProvider).undo(projectId),
          ),
          _ToolIconButton(
            icon: Icons.redo_rounded,
            tooltip: 'Redo',
            onTap: () => ref.read(timelineCommandServiceProvider).redo(projectId),
          ),
          const SizedBox(width: 16),
          const VerticalDivider(color: AppTheme.borderSubtle, indent: 8, endIndent: 8),
          const SizedBox(width: 16),
          _ToolIconButton(
            icon: Icons.content_cut_rounded,
            tooltip: 'Split Clip',
            enabled: selectedClipId != null,
            onTap: selectedClipId == null
                ? null
                : () async {
                    await ref.read(timelineCommandServiceProvider).splitClip(
                          projectId: projectId,
                          clipId: selectedClipId,
                          splitTimelineMicros: editorState.currentTimeMicros,
                        );
                  },
          ),
          _ToolIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete Clip',
            enabled: selectedClipId != null,
            onTap: selectedClipId == null
                ? null
                : () async {
                    await ref.read(timelineCommandServiceProvider).deleteClip(
                          projectId: projectId,
                          clipId: selectedClipId,
                        );
                    ref.read(editorStateProvider.notifier).deselectClip();
                  },
          ),
          const SizedBox(width: 16),
          const VerticalDivider(color: AppTheme.borderSubtle, indent: 8, endIndent: 8),
          const SizedBox(width: 16),
          _ToolIconButton(
            icon: Icons.space_bar_rounded,
            tooltip: 'Selection Tool',
            onTap: () => ref.read(editorStateProvider.notifier).setTool('media'),
            isActive: editorState.activeTool == 'media',
          ),
          _ToolIconButton(
            icon: Icons.switch_left_rounded,
            tooltip: 'Slip Edit',
            onTap: () => ref.read(editorStateProvider.notifier).setTool('slip'),
            isActive: editorState.activeTool == 'slip',
          ),
          _ToolIconButton(
            icon: Icons.open_with_rounded,
            tooltip: 'Slide Edit',
            onTap: () => ref.read(editorStateProvider.notifier).setTool('slide'),
            isActive: editorState.activeTool == 'slide',
          ),
          _ToolIconButton(
            icon: Icons.compress_rounded,
            tooltip: 'Ripple Edit',
            onTap: () => ref.read(editorStateProvider.notifier).setTool('ripple'),
            isActive: editorState.activeTool == 'ripple',
          ),
          _ToolIconButton(
            icon: Icons.sync_alt_rounded,
            tooltip: 'Roll Edit',
            onTap: () => ref.read(editorStateProvider.notifier).setTool('roll'),
            isActive: editorState.activeTool == 'roll',
          ),
          const SizedBox(width: 16),
          const VerticalDivider(color: AppTheme.borderSubtle, indent: 8, endIndent: 8),
          const SizedBox(width: 16),
                    _ToolIconButton(
            icon: editorState.snapEnabled ? Icons.bolt : Icons.do_not_touch_rounded,
            tooltip: 'Toggle Snapping',
            onTap: () => ref.read(editorStateProvider.notifier).toggleSnap(),
            isActive: editorState.snapEnabled,
          ),
          _ToolIconButton(
            icon: editorState.showSafeArea ? Icons.grid_3x3_rounded : Icons.grid_off_rounded,
            tooltip: 'Safe Area Guides',
            onTap: () => ref.read(editorStateProvider.notifier).toggleSafeArea(),
            isActive: editorState.showSafeArea,
          ),
          _ToolIconButton(
            icon: Icons.link_rounded,
            tooltip: 'Linked Selection',
            onTap: () => ref.read(editorStateProvider.notifier).toggleLinkedSelection(),
            isActive: editorState.linkedSelectionEnabled,
          ),
          const Spacer(),
          // Zoom controls
          _ToolIconButton(
            icon: Icons.zoom_out_rounded,
            tooltip: 'Zoom Out',
            onTap: () => ref.read(editorStateProvider.notifier).setZoom(editorState.timelineZoom - 0.25),
          ),
          SizedBox(
            width: 120,
            child: Slider(
              value: editorState.timelineZoom,
              min: 0.2,
              max: 12.0,
              activeColor: AppTheme.accentPrimary,
              inactiveColor: AppTheme.surfaceElevated,
              onChanged: (v) => ref.read(editorStateProvider.notifier).setZoom(v),
            ),
          ),
          _ToolIconButton(
            icon: Icons.zoom_in_rounded,
            tooltip: 'Zoom In',
            onTap: () => ref.read(editorStateProvider.notifier).setZoom(editorState.timelineZoom + 0.25),
          ),
        ],
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isActive;

  const _ToolIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.enabled = true,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      color: isActive ? AppTheme.accentPrimary : (enabled ? AppTheme.textPrimary : AppTheme.textDisabled),
      iconSize: 20,
      splashRadius: 20,
    );
  }
}
