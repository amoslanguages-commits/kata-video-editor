import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/track_controls_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/high_end_multitrack_timeline.dart';
import 'package:nle_editor/presentation/widgets/timeline/rename_track_dialog.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_track_header.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/clip_interactions_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_clip_actions.dart';
import 'package:nle_editor/presentation/widgets/timeline/pie_menu_overlay.dart';

class RealProjectMultitrackTimeline extends ConsumerStatefulWidget {
  final String projectId;
  final ValueChanged<int>? onSeek;
  final ValueChanged<String>? onClipSelected;
  final ValueChanged<String>? onTrackSelected;

  const RealProjectMultitrackTimeline({
    super.key,
    required this.projectId,
    this.onSeek,
    this.onClipSelected,
    this.onTrackSelected,
  });

  @override
  ConsumerState<RealProjectMultitrackTimeline> createState() => _RealProjectMultitrackTimelineState();
}

class _RealProjectMultitrackTimelineState extends ConsumerState<RealProjectMultitrackTimeline> {
  OverlayEntry? _pieMenuEntry;

  void _showPieMenu(BuildContext context, String clipId, Offset position) {
    if (_pieMenuEntry != null) {
      _pieMenuEntry!.remove();
      _pieMenuEntry = null;
    }

    _pieMenuEntry = OverlayEntry(
      builder: (context) => PieMenuOverlay(
        projectId: widget.projectId,
        clipId: clipId,
        position: position,
        onClose: () {
          _pieMenuEntry?.remove();
          _pieMenuEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_pieMenuEntry!);
  }

  @override
  void dispose() {
    _pieMenuEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ensureTracks = ref.watch(
      ensureDefaultMultitrackTracksProvider(widget.projectId),
    );

    return ensureTracks.when(
      loading: () => const _TimelineLoadingState(
        message: 'Preparing multitrack workspace...',
      ),
      error: (error, stackTrace) => _TimelineErrorState(
        title: 'Could not prepare timeline',
        message: error.toString(),
        onRetry: () {
          ref.invalidate(ensureDefaultMultitrackTracksProvider(widget.projectId));
        },
      ),
      data: (_) {
        final timeline = ref.watch(realProjectTimelineProvider(widget.projectId));

        return timeline.when(
          loading: () => const _TimelineLoadingState(
            message: 'Loading timeline...',
          ),
          error: (error, stackTrace) => _TimelineErrorState(
            title: 'Could not load timeline',
            message: error.toString(),
            onRetry: () {
              ref.invalidate(realProjectTimelineProvider(widget.projectId));
            },
          ),
          data: (model) {
            if (!model.isReadyForTimeline) {
              return _TimelineEmptyState(
                onCreateTracks: () {
                  ref.invalidate(
                    ensureDefaultMultitrackTracksProvider(widget.projectId),
                  );
                },
              );
            }

            final selectedClipId = ref.watch(
              editorStateProvider.select((s) => s.selectedClipId),
            );
            final clipsWithSelection = model.clips.map((clip) {
              return clip.copyWith(isSelected: clip.id == selectedClipId);
            }).toList();

            return HighEndMultitrackTimeline(
              projectId: model.projectId,
              durationMicros: model.durationMicros,
              tracks: model.tracks,
              clips: clipsWithSelection,
              onSeek: widget.onSeek,
              onClipSelected: widget.onClipSelected,
              onTrackSelected: widget.onTrackSelected,
              onTrackControl: (trackId, action) async {
                await _handleTrackControl(
                  context: context,
                  ref: ref,
                  modelTracks: model.tracks,
                  trackId: trackId,
                  action: action,
                );
              },
              onClipMove: (
                  {required clipId,
                  required targetTrackId,
                  required deltaMicros}) async {
                await _handleClipMove(
                  context: context,
                  ref: ref,
                  clipId: clipId,
                  targetTrackId: targetTrackId,
                  deltaMicros: deltaMicros,
                );
              },
              onClipTrimLeft: ({required clipId, required deltaMicros}) async {
                await _handleClipTrimLeft(
                  context: context,
                  ref: ref,
                  clipId: clipId,
                  deltaMicros: deltaMicros,
                );
              },
              onClipTrimRight: ({required clipId, required deltaMicros}) async {
                await _handleClipTrimRight(
                  context: context,
                  ref: ref,
                  clipId: clipId,
                  deltaMicros: deltaMicros,
                );
              },
              onClipAction: (clipId, action) async {
                await _handleClipAction(
                  context: context,
                  ref: ref,
                  clipId: clipId,
                  action: action,
                );
              },
              onClipLongPress: (clipId, position) {
                _showPieMenu(context, clipId, position);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleTrackControl({
    required BuildContext context,
    required WidgetRef ref,
    required List<MultitrackTrack> modelTracks,
    required String trackId,
    required TrackControlAction action,
  }) async {
    final controller = ref.read(
      trackControlsControllerProvider(widget.projectId),
    );

    final haptics = ref.read(hapticServiceProvider);

    try {
      if (action == TrackControlAction.rename) {
        final track = modelTracks.firstWhere(
          (track) => track.id == trackId,
        );

        final newName = await RenameTrackDialog.show(
          context,
          track: track,
        );

        if (newName == null || newName.trim().isEmpty) {
          return;
        }

        await controller.renameTrack(
          trackId: trackId,
          name: newName,
        );

        await haptics.success();
        return;
      }

      await controller.performAction(
        trackId: trackId,
        action: action,
      );

      await haptics.light();
    } catch (error) {
      await haptics.warning();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Track control failed: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleClipMove({
    required BuildContext context,
    required WidgetRef ref,
    required String clipId,
    required String? targetTrackId,
    required int deltaMicros,
  }) async {
    final controller = ref.read(clipInteractionsControllerProvider(widget.projectId));
    final haptics = ref.read(hapticServiceProvider);

    try {
      if (targetTrackId != null) {
        final timelineAsync = ref.read(realProjectTimelineProvider(widget.projectId));
        final model = timelineAsync.value;
        if (model != null) {
          final clip = model.clips.firstWhere((c) => c.id == clipId);
          final newStart = clip.timelineStartMicros + deltaMicros;
          await controller.moveClipTo(
            clipId: clipId,
            targetTrackId: targetTrackId,
            newStartMicros: newStart,
          );
        }
      } else {
        await controller.moveClipBy(
          clipId: clipId,
          deltaMicros: deltaMicros,
        );
      }
      await haptics.light();
    } catch (error) {
      await haptics.warning();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Move failed: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleClipTrimLeft({
    required BuildContext context,
    required WidgetRef ref,
    required String clipId,
    required int deltaMicros,
  }) async {
    final controller = ref.read(clipInteractionsControllerProvider(widget.projectId));
    final haptics = ref.read(hapticServiceProvider);

    try {
      await controller.trimLeftBy(
        clipId: clipId,
        deltaMicros: deltaMicros,
      );
      await haptics.light();
    } catch (error) {
      await haptics.warning();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trim failed: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleClipTrimRight({
    required BuildContext context,
    required WidgetRef ref,
    required String clipId,
    required int deltaMicros,
  }) async {
    final controller = ref.read(clipInteractionsControllerProvider(widget.projectId));
    final haptics = ref.read(hapticServiceProvider);

    try {
      await controller.trimRightBy(
        clipId: clipId,
        deltaMicros: deltaMicros,
      );
      await haptics.light();
    } catch (error) {
      await haptics.warning();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trim failed: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleClipAction({
    required BuildContext context,
    required WidgetRef ref,
    required String clipId,
    required TimelineClipAction action,
  }) async {
    final controller = ref.read(clipInteractionsControllerProvider(widget.projectId));
    final haptics = ref.read(hapticServiceProvider);

    try {
      switch (action) {
        case TimelineClipAction.split:
          final splitMicros = ref.read(editorStateProvider).currentTimeMicros;
          final result = await controller.splitClipAt(
            clipId: clipId,
            splitMicros: splitMicros,
          );
          if (result.newClipId != null) {
            ref
                .read(editorStateProvider.notifier)
                .selectClip(result.newClipId!, null);
          }
          await haptics.success();
          break;
        case TimelineClipAction.duplicate:
          final result = await controller.duplicateClip(clipId: clipId);
          if (result.newClipId != null) {
            ref
                .read(editorStateProvider.notifier)
                .selectClip(result.newClipId!, null);
          }
          await haptics.success();
          break;
        case TimelineClipAction.delete:
          final confirm = await _showDeleteConfirmation(context);
          if (confirm == true) {
            await controller.deleteClip(clipId: clipId);
            ref.read(editorStateProvider.notifier).deselectClip();
            await haptics.success();
          }
          break;
      }
    } catch (error) {
      await haptics.warning();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1622),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: const Text(
          'Delete Clip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this clip from the timeline?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TimelineLoadingState extends StatelessWidget {
  final String message;

  const _TimelineLoadingState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070A11),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _TimelineErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF070A11),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.error.withOpacity(0.45)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 38,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  final VoidCallback onCreateTracks;

  const _TimelineEmptyState({
    required this.onCreateTracks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF070A11),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: PremiumGradients.brandGlow,
                  boxShadow: PremiumShadows.glow(AppTheme.accentPrimary),
                ),
                child: const Icon(
                  Icons.view_timeline_rounded,
                  color: Colors.black,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Create your multitrack workspace',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This project needs V/A tracks before clips can appear on the professional timeline.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreateTracks,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create V/A Tracks'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
