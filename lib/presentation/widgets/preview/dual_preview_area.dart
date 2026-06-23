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
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';
import 'package:nle_editor/presentation/widgets/preview/social_safe_zone_overlay.dart';
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

    // Sync scrubbing: when the playhead moves and we're NOT playing, render a frame.
    ref.listen(
      editorStateProvider.select((s) => s.currentTimeMicros),
      (previous, next) {
        if (previous != next && !ref.read(editorStateProvider).isPlaying) {
          ref
              .read(nativeTruePreviewControllerProvider(projectId).notifier)
              .renderFrame(next);
        }
      },
    );

    // Sync playback: when global playback starts/stops, start/stop the preview loop.
    ref.listen(
      editorStateProvider.select((s) => s.isPlaying),
      (previous, next) {
        if (previous != next) {
          final controller =
              ref.read(nativeTruePreviewControllerProvider(projectId).notifier);
          if (next) {
            controller.playFrom(ref.read(editorStateProvider).currentTimeMicros);
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

// ── Side-by-side layout (tablet / landscape) ────────────────────────────────

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
        // Source Monitor
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

        // Program Monitor
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

// ── Tabbed layout (phone portrait) ──────────────────────────────────────────

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
        // Social Safe Zone Overlay (Toggled via settings or UI)
        const Positioned.fill(
          child: SocialSafeZoneOverlay(
            platform: SocialPlatform.tiktok,
            isVisible: true, // Hardcoded for demo, normally bound to a provider
          ),
        ),
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
        // ── Tab bar ──────────────────────────────────────────────────────
        _MonitorTabBar(
          active: layoutState.activeMonitor,
          onChanged: layoutNotifier.setActive,
        ),

        // ── Active monitor ────────────────────────────────────────────────
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

// ── Monitor tab bar (Segmented sliding pill switcher) ────────────────────────
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
                // Sliding selection indicator background
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

                // Interactive tabs
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isSource ? Colors.black : AppTheme.textSecondary,
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
                                Icons.smart_display_outlined,
                                size: 14,
                                color: !isSource ? Colors.black : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PROGRAM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: !isSource ? Colors.black : AppTheme.textSecondary,
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

// ── Monitor frame label (side-by-side mode) ─────────────────────────────────

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
    return Column(
      children: [
        // Label strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: AppTheme.surfaceDark,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),

        Expanded(child: child),
      ],
    );
  }
}
