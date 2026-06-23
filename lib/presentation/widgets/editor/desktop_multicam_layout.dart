import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_editing_toolbar.dart';
import 'package:nle_editor/presentation/widgets/preview/dual_preview_area.dart';
import 'package:nle_editor/presentation/widgets/timeline/real_project_multitrack_timeline.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_empty_state.dart';
import 'package:nle_editor/presentation/widgets/preview/multicam_grid_view.dart';
import 'package:nle_editor/presentation/widgets/panels/media_pool_panel.dart';
import 'package:nle_editor/presentation/widgets/panels/proxy_settings_panel.dart';
import 'package:nle_editor/presentation/providers/dual_preview_layout_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';

class DesktopMulticamLayout extends ConsumerWidget {
  final String projectId;

  const DesktopMulticamLayout({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Top section: Media + Proxies | Multicam Grid | Program Preview
        Expanded(
          flex: 6,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Pane: Media & Proxies
              Container(
                width: 380,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: AppTheme.borderSubtle, width: 1.0)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: const MediaPoolPanel(),
                    ),
                    Container(height: 1, color: AppTheme.borderSubtle),
                    Expanded(
                      flex: 4,
                      child: ProxySettingsPanel(projectId: projectId),
                    ),
                  ],
                ),
              ),
              
              // Center Pane: Multicam Angles Grid
              Expanded(
                flex: 5,
                child: MulticamGridView(projectId: projectId),
              ),
              
              // Right Pane: Dual Preview (Program Monitor)
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppTheme.borderSubtle, width: 1.0)),
                    color: AppTheme.editorBackground,
                  ),
                  child: DualPreviewArea(
                    projectId: projectId,
                    onClipInserted: (_) {
                      ref
                          .read(nativeTruePreviewControllerProvider(projectId).notifier)
                          .refreshGraphAndRender(
                            timelineTimeMicros: ref.read(editorStateProvider).currentTimeMicros,
                          );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Middle Toolbar
        DesktopEditingToolbar(projectId: projectId),
        
        // Bottom section: Timeline (Specialized for Multicam)
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
