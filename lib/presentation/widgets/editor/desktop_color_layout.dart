import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';
import 'package:nle_editor/presentation/providers/color_scope_providers.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_editing_toolbar.dart';
import 'package:nle_editor/presentation/widgets/preview/dual_preview_area.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/professional_scopes_panel.dart';
import 'package:nle_editor/presentation/widgets/color_grade/primary_grade_panel.dart';
import 'package:nle_editor/presentation/widgets/color_curves/color_curves_panel.dart';
import 'package:nle_editor/presentation/widgets/color_qualifier/hsl_qualifier_panel.dart';
import 'package:nle_editor/presentation/widgets/color_lut/lut_panel.dart';
import 'package:nle_editor/presentation/widgets/film_look/film_look_panel.dart';

class DesktopColorLayout extends ConsumerStatefulWidget {
  final String projectId;

  const DesktopColorLayout({super.key, required this.projectId});

  @override
  ConsumerState<DesktopColorLayout> createState() => _DesktopColorLayoutState();
}

class _DesktopColorLayoutState extends ConsumerState<DesktopColorLayout> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);
    final selectedClipId = editorState.selectedClipId;

    return Column(
      children: [
        // Top Section: Preview + Scopes
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Media Pool / Gallery placeholder
              Container(
                width: 250,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
                  ),
                  color: AppTheme.surfaceDark,
                ),
                child: const Center(
                  child: Text(
                    'Gallery / Clips',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
              
              // Center: Dual Preview
              Expanded(
                child: Container(
                  color: AppTheme.editorBackground,
                  child: DualPreviewArea(
                    projectId: widget.projectId,
                    onClipInserted: (_) {
                      ref
                          .read(nativeTruePreviewControllerProvider(widget.projectId).notifier)
                          .refreshGraphAndRender(
                            timelineTimeMicros:
                                ref.read(editorStateProvider).currentTimeMicros,
                          );
                    },
                  ),
                ),
              ),
              
              // Right: Scopes
              const SizedBox(
                width: 380,
                child: ProfessionalScopesPanel(),
              ),
            ],
          ),
        ),
        
        // Divider
        Container(
          height: 1,
          color: AppTheme.borderSubtle,
        ),

        // Bottom Section: Color Grading Workspace
        Expanded(
          flex: 4,
          child: selectedClipId == null
              ? const Center(
                  child: Text(
                    'Select a clip on the timeline to grade',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Primary Grade (Wheels)
                    Container(
                      width: 400,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
                        ),
                        color: AppTheme.surfaceDark,
                      ),
                      child: PrimaryGradePanel(selectedClipId: selectedClipId),
                    ),

                    // Center: Advanced Tools (Tabs)
                    Expanded(
                      child: Container(
                        color: AppTheme.surfaceDark,
                        child: Column(
                          children: [
                            // Tabs
                            Container(
                              height: 48,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _TabItem(title: 'Curves', isActive: _activeTabIndex == 0, onTap: () => setState(() => _activeTabIndex = 0)),
                                  _TabItem(title: 'Qualifiers', isActive: _activeTabIndex == 1, onTap: () => setState(() => _activeTabIndex = 1)),
                                  _TabItem(title: 'LUTs', isActive: _activeTabIndex == 2, onTap: () => setState(() => _activeTabIndex = 2)),
                                  _TabItem(title: 'Film Look', isActive: _activeTabIndex == 3, onTap: () => setState(() => _activeTabIndex = 3)),
                                ],
                              ),
                            ),
                            // Content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildActiveTabContent(selectedClipId),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right: Mini Timeline / Keyframes placeholder
                    Container(
                      width: 300,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
                        ),
                        color: AppTheme.surfaceDark,
                      ),
                      child: const Center(
                        child: Text(
                          'Keyframes & Nodes',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent(String clipId) {
    switch (_activeTabIndex) {
      case 0:
        return ColorCurvesPanel(selectedClipId: clipId);
      case 1:
        return HslQualifierPanel(selectedClipId: clipId);
      case 2:
        return LutPanel(selectedClipId: clipId);
      case 3:
        return FilmLookPanel(selectedClipId: clipId);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
