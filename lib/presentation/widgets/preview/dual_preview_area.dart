// lib/presentation/widgets/preview/dual_preview_area.dart
//
// 29F: Dual-monitor preview widget.
//
// Phone portrait  → tabbed  [Source | Program]
// Tablet/landscape → side-by-side [Source | Program]

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/preview/preview_monitor.dart';
import 'package:nle_editor/presentation/providers/dual_preview_layout_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/real_native_preview_provider.dart';
import 'package:nle_editor/presentation/widgets/preview/native_true_preview_view.dart';
import 'package:nle_editor/presentation/widgets/preview/source_preview_view.dart';
import 'package:nle_editor/presentation/widgets/preview/true_preview_controls.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';

/// Drop-in replacement for [PreviewArea] that adds a Source monitor.
///
/// Pass [projectId] so both monitors know which project they belong to.
class DualPreviewArea extends ConsumerWidget {
  final String projectId;

  /// Called when the user inserts a source range onto the timeline.
  final void Function(String clipId)? onClipInserted;

  const DualPreviewArea({
    super.key,
    required this.projectId,
    this.onClipInserted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > 640;

    ref.listen(
      editorStateProvider.select((s) => s.currentTimeMicros),
      (previous, next) {
        if (previous != next && !ref.read(editorStateProvider).isPlaying) {
          ref
              .read(realNativePreviewProvider(projectId).notifier)
              .requestFrame(next);
        }
      },
    );

    ref.listen(
      editorStateProvider.select((s) => s.isPlaying),
      (previous, next) {
        if (previous != next) {
          final controller =
              ref.read(realNativePreviewProvider(projectId).notifier);
          if (next) {
            controller.play();
          } else {
            controller.pause();
          }
        }
      },
    );

    if (isLandscape) {
      return _SideBySideLayout(
        projectId: projectId,
        onClipInserted: onClipInserted,
      );
    } else {
      return _TabbedLayout(
        projectId: projectId,
        onClipInserted: onClipInserted,
      );
    }
  }
}

class _SideBySideLayout extends ConsumerWidget {
  final String projectId;
  final void Function(String)? onClipInserted;

  const _SideBySideLayout({
    required this.projectId,
    this.onClipInserted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);

    return Row(
      children: [
        Expanded(
          child: _MonitorFrame(
            label: 'SOURCE',
            accentColor: const Color(0xFF00B8D4),
            child: SourcePreviewView(
              projectId: projectId,
              onInserted: onClipInserted,
              timelinePlayheadMicros: editorState.currentTimeMicros,
            ),
          ),
        ),
        Container(width: 2, color: AppTheme.borderSubtle),
        Expanded(
          child: _MonitorFrame(
            label: 'PROGRAM',
            accentColor: AppTheme.accentPrimary,
            child: _ProgramPreview(projectId: projectId),
          ),
        ),
      ],
    );
  }
}

class _ProgramPreview extends StatelessWidget {
  final String projectId;

  const _ProgramPreview({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        NativeTruePreviewView(projectId: projectId),
        Positioned(
          bottom: 16,
          child: TruePreviewControls(projectId: projectId),
        ),
      ],
    );
  }
}

class _TabbedLayout extends ConsumerWidget {
  final String projectId;
  final void Function(String)? onClipInserted;

  const _TabbedLayout({
    required this.projectId,
    this.onClipInserted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutState = ref.watch(dualPreviewLayoutControllerProvider);
    final layoutNotifier =
        ref.read(dualPreviewLayoutControllerProvider.notifier);
    final editorState = ref.watch(editorStateProvider);
    final isSource = layoutState.activeMonitor == PreviewMonitor.source;

    return Column(
      children: [
        _MonitorTabBar(
          active: layoutState.activeMonitor,
          onChanged: layoutNotifier.setActive,
        ),
        Expanded(
          child: IndexedStack(
            index: isSource ? 0 : 1,
            children: [
              SourcePreviewView(
                projectId: projectId,
                onInserted: onClipInserted,
                timelinePlayheadMicros: editorState.currentTimeMicros,
              ),
              _ProgramPreview(projectId: projectId),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonitorTabBar extends StatelessWidget {
  final PreviewMonitor active;
  final void Function(PreviewMonitor) onChanged;

  const _MonitorTabBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSource = active == PreviewMonitor.source;

    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1524),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 2;

            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOutCubic,
                  left: isSource ? 0 : tabWidth,
                  top: 2,
                  bottom: 2,
                  width: tabWidth,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: isSource
                          ? const LinearGradient(
                              colors: [Color(0xFF00B8D4), Color(0xFF00E5FF)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFFFD36A), Color(0xFFFF8A00)],
                            ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (isSource
                                  ? const Color(0xFF00B8D4)
                                  : const Color(0xFFFF8A00))
                              .withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: PremiumBounceButton(
                        onTap: () => onChanged(PreviewMonitor.source),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_file_outlined,
                                size: 14,
                                color: isSource ? Colors.black : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SOURCE',
                                style: TextStyle(
                                  color: isSource ? Colors.black : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PremiumBounceButton(
                        onTap: () => onChanged(PreviewMonitor.program),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.live_tv_rounded,
                                size: 14,
                                color: !isSource ? Colors.black : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PROGRAM',
                                style: TextStyle(
                                  color: !isSource ? Colors.black : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonitorFrame extends StatelessWidget {
  final String label;
  final Color accentColor;
  final Widget child;

  const _MonitorFrame({
    required this.label,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.editorBackground,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withOpacity(0.55)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
