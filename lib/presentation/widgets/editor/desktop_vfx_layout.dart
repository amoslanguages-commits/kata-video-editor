import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/preview/dual_preview_area.dart';
import 'package:nle_editor/presentation/widgets/inspector/clip_inspector_panel.dart';
import 'package:nle_editor/presentation/widgets/keyframes/keyframe_panel.dart';
import 'package:nle_editor/presentation/widgets/keyframes/keyframe_graph_editor_panel.dart';
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';

class DesktopVfxLayout extends ConsumerWidget {
  final String projectId;

  const DesktopVfxLayout({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedClipAsync = ref.watch(selectedClipProvider);
    final editorState = ref.watch(editorStateProvider);
    
    return Column(
      children: [
        // Top Section: Inspector + Preview
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Pane: Inspector (Focus on Transform & Compositing)
              Container(
                width: 380,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
                  ),
                  color: AppTheme.surfaceDark,
                ),
                child: ClipInspectorPanel(projectId: projectId),
              ),
              
              // Right Pane: Dual Preview Area
              Expanded(
                child: Container(
                  color: AppTheme.editorBackground,
                  child: DualPreviewArea(
                    projectId: projectId,
                    onClipInserted: (_) {
                      ref
                          .read(nativeTruePreviewControllerProvider(projectId).notifier)
                          .refreshGraphAndRender(
                            timelineTimeMicros:
                                ref.read(editorStateProvider).currentTimeMicros,
                          );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Divider
        Container(
          height: 1,
          color: AppTheme.borderSubtle,
        ),
        
        // Bottom Section: Animation & Keyframes
        Expanded(
          flex: 4,
          child: Container(
            color: AppTheme.surfaceDark,
            child: selectedClipAsync.when(
              data: (clip) {
                if (clip == null) {
                  return const Center(
                    child: Text(
                      'Select a clip to animate',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                    ),
                  );
                }

                final clipDurationMicros = clip.timelineEndMicros - clip.timelineStartMicros;
                // Compute local playhead within the clip's timeline space (0 to duration)
                final localPlayheadMicros = editorState.currentTimeMicros - clip.timelineStartMicros;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Traditional Keyframe Timeline panel
                    Container(
                      width: 400,
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppTheme.borderSubtle, width: 1.0)),
                      ),
                      child: const KeyframePanel(),
                    ),
                    
                    // Right: Powerful Graph Editor for easing and velocity
                    Expanded(
                      child: KeyframeGraphEditorPanel(
                        clipId: clip.id,
                        clipType: clip.clipType,
                        clipDurationMicros: clipDurationMicros,
                        localPlayheadMicros: localPlayheadMicros,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppTheme.error))),
            ),
          ),
        ),
      ],
    );
  }
}
