import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/color_scope_providers.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_tool_tabs.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_editing_toolbar.dart';
import 'package:nle_editor/presentation/widgets/panels/tool_panel.dart';
import 'package:nle_editor/presentation/widgets/preview/dual_preview_area.dart';
import 'package:nle_editor/presentation/widgets/timeline/real_project_multitrack_timeline.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_empty_state.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/professional_scopes_panel.dart';
import 'package:nle_editor/presentation/providers/dual_preview_layout_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';

class DesktopEditorLayout extends ConsumerWidget {
  final String projectId;

  const DesktopEditorLayout({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3-pane layout: 
    // Row top: Left (Tabs + ToolPanel), Right (Preview)
    // Bottom: DesktopEditingToolbar + Full width Timeline
    
    return Column(
      children: [
        // Top section
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Pane: Tool Panel
              Container(
                width: 380, // Fixed width for desktop tool panel
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
                  ),
                ),
                child: const Column(
                  children: [
                    DesktopToolTabs(),
                    Expanded(
                      child: ToolPanel(),
                    ),
                  ],
                ),
              ),
              
              // Right Pane: Preview + Scopes
              Expanded(
                child: Container(
                  color: AppTheme.editorBackground,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final scopesSettings = ref.watch(colorScopeControllerProvider).settings;
                      final previewWidget = DualPreviewArea(
                        projectId: projectId,
                        onClipInserted: (_) {
                          ref
                              .read(nativeTruePreviewControllerProvider(projectId).notifier)
                              .refreshGraphAndRender(
                                timelineTimeMicros:
                                    ref.read(editorStateProvider).currentTimeMicros,
                              );
                        },
                      );
                      
                      if (scopesSettings.enabled) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: previewWidget),
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 360,
                              child: ProfessionalScopesPanel(),
                            ),
                          ],
                        );
                      }
                      
                      return previewWidget;
                    }
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Middle Toolbar
        DesktopEditingToolbar(projectId: projectId),
        
        // Bottom section: Timeline
        Expanded(
          flex: 4,
          child: ref.watch(realProjectTimelineProvider(projectId)).when(
            data: (timeline) {
              if (timeline.clips.isEmpty) {
                return const TimelineEmptyState();
              }
              return RealProjectMultitrackTimeline(
                projectId: projectId,
                onSeek: (micros) async {
                  ref.read(dualPreviewLayoutControllerProvider.notifier).showProgram();
                  ref.read(multitrackTimelineControllerProvider.notifier).setPlayheadMicros(micros);
                  await ref.read(nativeCommandServiceProvider).seek(
                        projectId: projectId,
                        timelineMicros: micros,
                      );
                },
                onClipSelected: (clipId) async {
                  ref.read(dualPreviewLayoutControllerProvider.notifier).showProgram();
                  ref.read(editorStateProvider.notifier).selectClip(clipId, null);
                  final clip = await ref.read(timelineRepositoryProvider).getClip(clipId);
                  if (clip != null) {
                    final tool = clip.clipType == 'text' ? 'text' : 'edit';
                    ref.read(editorStateProvider.notifier).setTool(tool);
                  }
                },
                onTrackSelected: (trackId) {
                  ref.read(dualPreviewLayoutControllerProvider.notifier).showProgram();
                  ref.read(editorStateProvider.notifier).selectClip(null, trackId);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
            error: (err, _) => Center(child: Text('Timeline error: $err', style: const TextStyle(color: AppTheme.error))),
          ),
        ),
      ],
    );
  }
}
