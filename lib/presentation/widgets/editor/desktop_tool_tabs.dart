import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class DesktopToolTabs extends ConsumerWidget {
  const DesktopToolTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final activeTool = editorState.activeTool;

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _TabItem(title: 'Media Pool', tool: 'media', isActive: activeTool == 'media'),
          _TabItem(title: 'Effects', tool: 'effects', isActive: activeTool == 'effects'),
          _TabItem(title: 'Transitions', tool: 'transitions', isActive: activeTool == 'transitions'),
          _TabItem(title: 'Text & Titles', tool: 'text', isActive: activeTool == 'text'),
          _TabItem(title: 'Audio', tool: 'audio', isActive: activeTool == 'audio'),
          _TabItem(title: 'Color & Filters', tool: 'filters', isActive: activeTool == 'filters'),
          _TabItem(title: 'Inspector', tool: 'edit', isActive: activeTool == 'edit'),
          _TabItem(title: 'Keyframes', tool: 'keyframes', isActive: activeTool == 'keyframes'),
        ],
      ),
    );
  }
}

class _TabItem extends ConsumerWidget {
  final String title;
  final String tool;
  final bool isActive;

  const _TabItem({
    required this.title,
    required this.tool,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(editorStateProvider.notifier).setTool(tool);
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.accentPrimary : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
