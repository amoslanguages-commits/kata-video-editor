import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/controllers/project_autosave_controller.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';

class HistoryToolbar extends ConsumerWidget {
  final String projectId;

  const HistoryToolbar({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(editorHistoryControllerProvider(projectId));
    final autosave = ref.watch(editorAutosaveControllerProvider(projectId));

    final canUndo = history.canUndo;
    final canRedo = history.canRedo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Undo Button
        IconButton(
          tooltip: 'Undo',
          icon: const Icon(Icons.undo),
          onPressed: canUndo
              ? () async {
                  await ref
                      .read(editorHistoryControllerProvider(projectId).notifier)
                      .undo();
                }
              : null,
          color: canUndo ? AppTheme.textPrimary : AppTheme.textDisabled,
        ),

        // Redo Button
        IconButton(
          tooltip: 'Redo',
          icon: const Icon(Icons.redo),
          onPressed: canRedo
              ? () async {
                  await ref
                      .read(editorHistoryControllerProvider(projectId).notifier)
                      .redo();
                }
              : null,
          color: canRedo ? AppTheme.textPrimary : AppTheme.textDisabled,
        ),

        const SizedBox(width: 8),

        // Autosave Status Badge
        _buildStatusBadge(autosave),
      ],
    );
  }

  Widget _buildStatusBadge(ProjectAutosaveState autosave) {
    Color badgeColor;
    String label;
    IconData icon;
    bool isPulsing = false;

    switch (autosave.status) {
      case AutosaveStatus.clean:
        badgeColor = AppTheme.textMuted;
        label = 'Saved';
        icon = Icons.check_circle_outline;
        break;
      case AutosaveStatus.saved:
        badgeColor = AppTheme.success;
        label = 'Saved';
        icon = Icons.check_circle;
        break;
      case AutosaveStatus.dirty:
        badgeColor = AppTheme.warning;
        label = 'Unsaved Changes';
        icon = Icons.pending_actions;
        break;
      case AutosaveStatus.saving:
        badgeColor = AppTheme.accentPrimary;
        label = 'Saving...';
        icon = Icons.sync;
        isPulsing = true;
        break;
      case AutosaveStatus.error:
        badgeColor = AppTheme.error;
        label = 'Autosave failed';
        icon = Icons.error_outline;
        break;
    }

    Widget iconWidget = Icon(icon, size: 14, color: badgeColor);

    if (isPulsing) {
      iconWidget = _PulsingWidget(child: iconWidget);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingWidget extends StatefulWidget {
  final Widget child;

  const _PulsingWidget({required this.child});

  @override
  State<_PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<_PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}
