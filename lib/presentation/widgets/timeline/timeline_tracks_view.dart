import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/utils/time_utils.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_ruler.dart';

class TimelineTracksView extends ConsumerWidget {
  final String projectId;
  final double zoom;

  const TimelineTracksView({
    super.key,
    required this.projectId,
    required this.zoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(projectTracksProvider(projectId));
    final clipsAsync = ref.watch(projectClipsProvider(projectId));
    final editorState = ref.watch(editorStateProvider);

    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(
            child: Text(
              'No tracks. Tap New Project again to recreate.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        final clips = clipsAsync.value ?? [];

        // Find max timeline end to determine layout width
        int maxEndMicros = 60 * 1000000; // default 60s minimum
        for (final clip in clips) {
          if (!clip.isDisabled && clip.timelineEndMicros > maxEndMicros) {
            maxEndMicros = clip.timelineEndMicros;
          }
        }

        // Add 10 seconds of padding at the end
        final totalDurationMicros = maxEndMicros + 10 * 1000000;
        final double secondWidth = 80.0 * zoom;
        final timelineScale = TimelineScale(pixelsPerSecond: secondWidth);
        final double totalWidth =
            (totalDurationMicros / 1000000.0) * secondWidth;

        return Container(
          color: AppTheme.timelineBackground,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Left column for track headers
                Column(
                  children: [
                    Container(
                      height: 32,
                      width: 90,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceDark,
                        border: Border(
                          bottom: BorderSide(
                              color: AppTheme.borderSubtle, width: 0.5),
                          right: BorderSide(
                              color: AppTheme.borderSubtle, width: 0.5),
                        ),
                      ),
                    ),
                    for (final track in tracks)
                      Container(
                        height: 72,
                        width: 90,
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceDark,
                          border: Border(
                            bottom: BorderSide(
                                color: AppTheme.borderSubtle, width: 0.5),
                            right: BorderSide(
                                color: AppTheme.borderSubtle, width: 0.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _getTrackIcon(track.type),
                                  size: 13,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  track.isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  size: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Scrollable timeline ruler and clips area
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalWidth,
                      child: Stack(
                        children: [
                          // Grid columns in background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: TimelineGridPainter(zoom: zoom),
                            ),
                          ),

                          Column(
                            children: [
                              TimelineRuler(
                                projectId: projectId,
                                totalWidth: totalWidth,
                                scale: timelineScale,
                                durationMicros: maxEndMicros,
                              ),
                              for (final track in tracks)
                                _buildTrackRow(
                                    context, ref, track, clips, editorState),
                            ],
                          ),

                          // Playhead vertical line
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: (editorState.currentTimeMicros / 1000000.0) *
                                secondWidth,
                            child: IgnorePointer(
                              child: Container(
                                width: 2,
                                color: AppTheme.playhead,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.playhead,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPrimary)),
      error: (e, _) => Center(child: Text('Error rendering timeline: $e')),
    );
  }

  Widget _buildTrackRow(
    BuildContext context,
    WidgetRef ref,
    Track track,
    List<Clip> allClips,
    EditorState editorState,
  ) {
    final trackClips = allClips.where((c) => c.trackId == track.id).toList();
    Color trackBgColor = AppTheme.trackVideo;
    if (track.type == 'audio') trackBgColor = AppTheme.trackAudio;
    if (track.type == 'text') trackBgColor = AppTheme.trackText;
    if (track.type == 'overlay') trackBgColor = AppTheme.trackOverlay;

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background shading
          Container(color: trackBgColor.withOpacity(0.08)),

          // Clips stack
          ...trackClips.map(
            (clip) => _TimelineClipWidget(
              projectId: projectId,
              clip: clip,
              allClips: allClips,
              zoom: zoom,
              editorState: editorState,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTrackIcon(String type) {
    switch (type) {
      case 'audio':
        return Icons.music_note_rounded;
      case 'text':
        return Icons.title_rounded;
      case 'overlay':
        return Icons.layers_rounded;
      default:
        return Icons.videocam_rounded;
    }
  }
}

class _TimelineClipWidget extends ConsumerStatefulWidget {
  final String projectId;
  final Clip clip;
  final List<Clip> allClips;
  final double zoom;
  final EditorState editorState;

  const _TimelineClipWidget({
    required this.projectId,
    required this.clip,
    required this.allClips,
    required this.zoom,
    required this.editorState,
  });

  @override
  ConsumerState<_TimelineClipWidget> createState() =>
      _TimelineClipWidgetState();
}

class _TimelineClipWidgetState extends ConsumerState<_TimelineClipWidget> {
  int? _draggedStartMicros;
  int? _draggedEndMicros;
  bool _isMoving = false;
  bool _isTrimmingLeft = false;
  bool _isTrimmingRight = false;

  int _findSnapPosition(int currentTry, int duration) {
    if (!widget.editorState.snapEnabled) return currentTry;

    final snapThresholdMicros = (0.15 * 1000000).round(); // 150ms
    int closest = currentTry;
    int minDiff = snapThresholdMicros;

    final playhead = widget.editorState.currentTimeMicros;

    // Check playhead snap
    int diffPlayheadStart = (currentTry - playhead).abs();
    if (diffPlayheadStart < minDiff) {
      minDiff = diffPlayheadStart;
      closest = playhead;
    }
    int diffPlayheadEnd = (currentTry + duration - playhead).abs();
    if (diffPlayheadEnd < minDiff) {
      minDiff = diffPlayheadEnd;
      closest = playhead - duration;
    }

    // Check other clips snap
    for (final other in widget.allClips) {
      if (other.id == widget.clip.id || other.trackId != widget.clip.trackId)
        continue;

      int diffStartStart = (currentTry - other.timelineStartMicros).abs();
      if (diffStartStart < minDiff) {
        minDiff = diffStartStart;
        closest = other.timelineStartMicros;
      }
      int diffStartEnd = (currentTry - other.timelineEndMicros).abs();
      if (diffStartEnd < minDiff) {
        minDiff = diffStartEnd;
        closest = other.timelineEndMicros;
      }
      int diffEndStart =
          (currentTry + duration - other.timelineStartMicros).abs();
      if (diffEndStart < minDiff) {
        minDiff = diffEndStart;
        closest = other.timelineStartMicros - duration;
      }
      int diffEndEnd = (currentTry + duration - other.timelineEndMicros).abs();
      if (diffEndEnd < minDiff) {
        minDiff = diffEndEnd;
        closest = other.timelineEndMicros - duration;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final isSelected = widget.editorState.selectedClipId == clip.id;
    final double secondWidth = 80.0 * widget.zoom;

    // Use dragged positions if dragging is in progress
    final int startMicros = _draggedStartMicros ?? clip.timelineStartMicros;
    final int endMicros = _draggedEndMicros ?? clip.timelineEndMicros;
    final int durationMicros = endMicros - startMicros;

    final double left = (startMicros / 1000000.0) * secondWidth;
    final double width = (durationMicros / 1000000.0) * secondWidth;

    Color clipColor = AppTheme.clipVideo;
    if (clip.clipType == 'audio') clipColor = AppTheme.clipAudio;
    if (clip.clipType == 'text') clipColor = AppTheme.clipText;
    if (clip.clipType == 'image') clipColor = AppTheme.clipImage;

    return Positioned(
      left: left,
      width: width.clamp(20, double.maxFinite),
      top: 6,
      bottom: 6,
      child: GestureDetector(
        onTap: () {
          ref
              .read(editorStateProvider.notifier)
              .selectClip(clip.id, clip.trackId);
        },
        onHorizontalDragStart: (_) {
          ref
              .read(editorStateProvider.notifier)
              .selectClip(clip.id, clip.trackId);
          setState(() {
            _isMoving = true;
            _draggedStartMicros = clip.timelineStartMicros;
            _draggedEndMicros = clip.timelineEndMicros;
          });
        },
        onHorizontalDragUpdate: (details) {
          if (!_isMoving) return;
          final currentStart = _draggedStartMicros ?? clip.timelineStartMicros;
          final duration = clip.timelineEndMicros - clip.timelineStartMicros;

          final deltaMicros =
              (details.delta.dx / secondWidth * 1000000).round();
          final tryStart = (currentStart + deltaMicros).clamp(0, 1 << 62);

          final snappedStart = _findSnapPosition(tryStart, duration);
          setState(() {
            _draggedStartMicros = snappedStart;
            _draggedEndMicros = snappedStart + duration;
          });
        },
        onHorizontalDragEnd: (_) async {
          if (!_isMoving) return;
          final finalStart = _draggedStartMicros ?? clip.timelineStartMicros;
          setState(() {
            _isMoving = false;
            _draggedStartMicros = null;
            _draggedEndMicros = null;
          });

          await ref.read(timelineCommandServiceProvider).moveClip(
                projectId: widget.projectId,
                clipId: clip.id,
                newTimelineStartMicros: finalStart,
              );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentPrimary : clipColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : AppTheme.borderHighlight.withOpacity(0.5),
              width: isSelected ? 1.5 : 0.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.accentPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Display clip details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      _getClipIcon(clip.clipType),
                      size: 13,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        clip.clipType == 'text'
                            ? (clip.textContent ?? 'Text')
                            : 'Media Clip',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      TimeUtils.formatMicros(durationMicros),
                      style: TextStyle(
                        fontSize: 8,
                        color: isSelected ? Colors.black54 : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Visual edge trim handles if selected
              if (isSelected) ...[
                // Left trim handle
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 12,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) {
                      setState(() {
                        _isTrimmingLeft = true;
                        _draggedStartMicros = clip.timelineStartMicros;
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      if (!_isTrimmingLeft) return;
                      final currentStart =
                          _draggedStartMicros ?? clip.timelineStartMicros;
                      final deltaMicros =
                          (details.delta.dx / secondWidth * 1000000).round();

                      final tryStart = (currentStart + deltaMicros).clamp(
                          0,
                          clip.timelineEndMicros -
                              500000); // min 500ms duration
                      setState(() {
                        _draggedStartMicros = tryStart;
                      });
                    },
                    onHorizontalDragEnd: (_) async {
                      if (!_isTrimmingLeft) return;
                      final finalStart =
                          _draggedStartMicros ?? clip.timelineStartMicros;
                      setState(() {
                        _isTrimmingLeft = false;
                        _draggedStartMicros = null;
                      });

                      final shift = finalStart - clip.timelineStartMicros;
                      final newSrcIn =
                          clip.sourceInMicros + (shift * clip.speed).round();

                      await ref.read(timelineCommandServiceProvider).trimClip(
                            projectId: widget.projectId,
                            clipId: clip.id,
                            timelineStartMicros: finalStart,
                            timelineEndMicros: clip.timelineEndMicros,
                            sourceInMicros: newSrcIn,
                            sourceOutMicros: clip.sourceOutMicros,
                          );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.drag_indicator_rounded,
                            size: 8, color: Colors.black),
                      ),
                    ),
                  ),
                ),

                // Right trim handle
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 12,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) {
                      setState(() {
                        _isTrimmingRight = true;
                        _draggedEndMicros = clip.timelineEndMicros;
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      if (!_isTrimmingRight) return;
                      final currentEnd =
                          _draggedEndMicros ?? clip.timelineEndMicros;
                      final deltaMicros =
                          (details.delta.dx / secondWidth * 1000000).round();

                      final tryEnd = (currentEnd + deltaMicros)
                          .clamp(clip.timelineStartMicros + 500000, 1 << 62);
                      setState(() {
                        _draggedEndMicros = tryEnd;
                      });
                    },
                    onHorizontalDragEnd: (_) async {
                      if (!_isTrimmingRight) return;
                      final finalEnd =
                          _draggedEndMicros ?? clip.timelineEndMicros;
                      setState(() {
                        _isTrimmingRight = false;
                        _draggedEndMicros = null;
                      });

                      final delta = finalEnd - clip.timelineEndMicros;
                      final newSrcOut =
                          clip.sourceOutMicros + (delta * clip.speed).round();

                      await ref.read(timelineCommandServiceProvider).trimClip(
                            projectId: widget.projectId,
                            clipId: clip.id,
                            timelineStartMicros: clip.timelineStartMicros,
                            timelineEndMicros: finalEnd,
                            sourceInMicros: clip.sourceInMicros,
                            sourceOutMicros: newSrcOut,
                          );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.drag_indicator_rounded,
                            size: 8, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getClipIcon(String type) {
    switch (type) {
      case 'audio':
        return Icons.volume_up_rounded;
      case 'text':
        return Icons.text_fields_rounded;
      case 'image':
        return Icons.image_rounded;
      default:
        return Icons.video_file_rounded;
    }
  }
}

class TimelineGridPainter extends CustomPainter {
  final double zoom;

  TimelineGridPainter({required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.borderSubtle.withOpacity(0.12)
      ..strokeWidth = 0.5;

    final secondWidth = 80.0 * zoom;
    final maxSeconds = size.width / secondWidth;

    // Draw major grid line every 5 seconds
    for (double sec = 5.0; sec <= maxSeconds; sec += 5.0) {
      final x = sec * secondWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimelineGridPainter oldDelegate) {
    return oldDelegate.zoom != zoom;
  }
}
