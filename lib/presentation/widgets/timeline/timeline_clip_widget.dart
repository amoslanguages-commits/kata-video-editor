import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_clip_actions.dart';
import 'package:nle_editor/presentation/widgets/timeline/waveform_placeholder.dart';

class TimelineClipWidget extends ConsumerStatefulWidget {
  final MultitrackClip clip;
  final MultitrackTrack track;
  final List<MultitrackTrack> allTracks;
  final TimelineScale scale;
  final double trackHeight;

  final ValueChanged<String>? onSelected;
  final ValueChanged<double>? onMovePreviewDeltaPx;
  final ValueChanged<double>? onTrimLeftPreviewDeltaPx;
  final ValueChanged<double>? onTrimRightPreviewDeltaPx;
  final VoidCallback? onDragPreviewEnd;
  final Function(String, Offset)? onLongPress;

  final Future<void> Function(double deltaPx, String? targetTrackId)?
      onMoveDeltaPx;
  final Future<void> Function(double deltaPx)? onTrimLeftDeltaPx;
  final Future<void> Function(double deltaPx)? onTrimRightDeltaPx;
  final void Function(String clipId, TimelineClipAction action)? onAction;

  const TimelineClipWidget({
    super.key,
    required this.clip,
    required this.track,
    required this.allTracks,
    required this.scale,
    required this.trackHeight,
    this.onSelected,
    this.onMovePreviewDeltaPx,
    this.onTrimLeftPreviewDeltaPx,
    this.onTrimRightPreviewDeltaPx,
    this.onDragPreviewEnd,
    this.onLongPress,
    this.onMoveDeltaPx,
    this.onTrimLeftDeltaPx,
    this.onTrimRightDeltaPx,
    this.onAction,
  });

  @override
  ConsumerState<TimelineClipWidget> createState() => _TimelineClipWidgetState();
}

class _TimelineClipWidgetState extends ConsumerState<TimelineClipWidget> {
  double _dragDeltaX = 0;
  double _dragDeltaY = 0;
  bool _isDragging = false;
  bool _isTrimmingLeft = false;
  bool _isTrimmingRight = false;

  Color _getClipColor() {
    if (widget.clip.isDisabled) {
      return AppTheme.surfaceDark.withValues(alpha: 0.5);
    }
    switch (widget.clip.type) {
      case MultitrackClipType.video:
        return const Color(0xFF0052CC); // Deep NLE Blue
      case MultitrackClipType.image:
        return const Color(0xFF00875A); // Forest green
      case MultitrackClipType.audio:
        return const Color(0xFF5243AA); // Audio Purple
      case MultitrackClipType.text:
        return const Color(0xFFDE350B); // Amber / Red-Orange
      case MultitrackClipType.adjustment:
        return const Color(0xFF8777D9); // Indigo
      default:
        return const Color(0xFF42526E); // Slate
    }
  }

  IconData _getClipIcon() {
    switch (widget.clip.type) {
      case MultitrackClipType.video:
        return Icons.videocam_rounded;
      case MultitrackClipType.image:
        return Icons.image_rounded;
      case MultitrackClipType.audio:
        return Icons.audiotrack_rounded;
      case MultitrackClipType.text:
        return Icons.title_rounded;
      case MultitrackClipType.adjustment:
        return Icons.tune_rounded;
      default:
        return Icons.movie_creation_rounded;
    }
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) async {
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final action = await showMenu<TimelineClipAction>(
      context: context,
      position: position,
      color: const Color(0xFF0F1622),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      items: [
        const PopupMenuItem(
          value: TimelineClipAction.split,
          child: Row(
            children: [
              Icon(Icons.content_cut_rounded,
                  color: Colors.cyanAccent, size: 18),
              SizedBox(width: 10),
              Text('Split at Playhead',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: TimelineClipAction.duplicate,
          child: Row(
            children: [
              Icon(Icons.copy_rounded, color: Colors.amberAccent, size: 18),
              SizedBox(width: 10),
              Text('Duplicate Clip',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: TimelineClipAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_forever_rounded,
                  color: Colors.redAccent, size: 18),
              SizedBox(width: 10),
              Text('Delete Clip',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );

    if (action != null && widget.onAction != null) {
      widget.onAction!(widget.clip.id, action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.clip.leftPx(widget.scale);
    final width = widget.clip.widthPx(widget.scale);
    final isSelected = widget.clip.isSelected;

    final uiState = ref.watch(multitrackTimelineControllerProvider);
    final activeSnap = uiState.activeSnapPoint;

    double displayLeft = left + (_isDragging ? _dragDeltaX : 0);
    double displayWidth = width +
        (_isTrimmingLeft ? -_dragDeltaX : 0) +
        (_isTrimmingRight ? _dragDeltaX : 0);

    // Apply visual magnetic snapping preview if a snap target is active
    if (activeSnap != null && isSelected && uiState.snappingEnabled) {
      final snapPx = widget.scale.microsToPx(activeSnap.micros);

      if (_isDragging) {
        final movedStartPx = left + _dragDeltaX;
        final movedEndPx = movedStartPx + width;

        final distStart = (movedStartPx - snapPx).abs();
        final distEnd = (movedEndPx - snapPx).abs();

        if (distStart < distEnd) {
          displayLeft = snapPx;
        } else {
          displayLeft = snapPx - width;
        }
      } else if (_isTrimmingLeft) {
        displayLeft = snapPx;
        displayWidth = (left + width) - snapPx;
      } else if (_isTrimmingRight) {
        displayWidth = snapPx - left;
      }
    }

    // Clamping to avoid visual artifacts
    final minWidthPx = widget.scale.microsToPx(100000); // 0.1s minimum
    final displayLeftClamped = math.max(0.0, displayLeft);
    final displayWidthClamped = math.max(minWidthPx, displayWidth);

    final clipColor = _getClipColor();
    final clipIcon = _getClipIcon();

    final deltaMicros = widget.scale.pxToMicros(_dragDeltaX);
    final deltaSeconds = deltaMicros / 1000000.0;
    final sign = deltaSeconds >= 0 ? '+' : '';
    final deltaText = '$sign${deltaSeconds.toStringAsFixed(2)}s';
    final showBadge = _isDragging || _isTrimmingLeft || _isTrimmingRight;

    // Reactively watch assets and load the folders/waveform if available
    final assetsAsync = ref.watch(projectAssetsProvider(widget.clip.projectId));
    final assets = assetsAsync.value ?? [];
    Asset? asset;
    for (final a in assets) {
      if (a.id == widget.clip.assetId) {
        asset = a;
        break;
      }
    }

    final foldersAsync =
        ref.watch(projectStoragePathsProvider(widget.clip.projectId));
    final folders = foldersAsync.value;

    final waveformAsync = asset?.waveformPath != null
        ? ref.watch(assetWaveformProvider(asset!.waveformPath!))
        : const AsyncValue<List<double>>.data([]);
    final waveformData = waveformAsync.value;

    Widget? backgroundContent;
    if (widget.clip.type == MultitrackClipType.video &&
        asset != null &&
        folders != null) {
      if (asset.thumbnailStatus == 'ready') {
        final durationMicros =
            asset.durationMicros ?? widget.clip.durationMicros;
        final timestamps = _getThumbnailTimestamps(durationMicros);

        backgroundContent = LayoutBuilder(
          builder: (context, constraints) {
            final clipWidth = constraints.maxWidth;
            const thumbWidth = 60.0;
            final numThumbs = (clipWidth / thumbWidth).ceil();

            final speed = widget.clip.speed == 0 ? 1.0 : widget.clip.speed;
            final sourceDurationMs =
                ((widget.clip.durationMicros * speed).round()) ~/ 1000;
            final sourceStartMs = widget.clip.sourceStartMicros ~/ 1000;
            final sourceEndMs = sourceStartMs + sourceDurationMs;

            return Row(
              children: List.generate(numThumbs, (index) {
                final ratio = (index + 0.5) / numThumbs;
                final timeMs =
                    (sourceStartMs + ratio * (sourceEndMs - sourceStartMs))
                        .round();
                final closest = _findClosestTimestamp(timeMs, timestamps);

                final thumbName = closest == 0
                    ? '${asset!.id}.jpg'
                    : '${asset!.id}_$closest.jpg';
                final path = p.join(folders.thumbnails, thumbName);

                return Expanded(
                  child: Container(
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(
                          right: BorderSide(color: Colors.black26, width: 0.5)),
                    ),
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: clipColor),
                    ),
                  ),
                );
              }),
            );
          },
        );
      } else if (asset.thumbnailStatus == 'generating') {
        backgroundContent = const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.white54),
          ),
        );
      }
    } else if (widget.clip.type == MultitrackClipType.image && asset != null) {
      if (asset.thumbnailStatus == 'ready' && asset.thumbnailPath != null) {
        backgroundContent = Image.file(
          File(asset.thumbnailPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: clipColor),
        );
      }
    }

    double startRatio = 0.0;
    double endRatio = 1.0;
    if (widget.clip.type == MultitrackClipType.audio && asset != null) {
      final assetDur = asset.durationMicros ?? widget.clip.durationMicros;
      if (assetDur > 0) {
        final speed = widget.clip.speed == 0 ? 1.0 : widget.clip.speed;
        final sourceDuration = (widget.clip.durationMicros * speed).round();
        startRatio = (widget.clip.sourceStartMicros / assetDur).clamp(0.0, 1.0);
        endRatio = ((widget.clip.sourceStartMicros + sourceDuration) / assetDur)
            .clamp(0.0, 1.0);
      }
    }

    return Positioned(
      left: displayLeftClamped,
      top: 4,
      width: displayWidthClamped,
      height: widget.trackHeight - 8,
      child: RepaintBoundary(
        child: GestureDetector(
          onTapDown: (_) {
            ref
                .read(multitrackTimelineControllerProvider.notifier)
                .selectClip(widget.clip.id);
            ref
                .read(editorStateProvider.notifier)
                .selectClip(widget.clip.id, widget.track.id);
            if (widget.onSelected != null) {
              widget.onSelected!(widget.clip.id);
            }
          },
          onLongPressStart: (details) {
            if (widget.track.isLocked) {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cannot edit clip on a locked track.')),
              );
              return;
            }
            if (widget.onLongPress != null) {
              widget.onLongPress!(widget.clip.id, details.globalPosition);
            } else {
              _showContextMenu(context, details.globalPosition);
            }
          },
          onPanStart: (details) {
            if (widget.track.isLocked) {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cannot edit clip on a locked track.')),
              );
              return;
            }

            final localX = details.localPosition.dx;
            const handleWidth = 18.0;

            if (isSelected && localX < handleWidth) {
              _isTrimmingLeft = true;
            } else if (isSelected &&
                localX > displayWidthClamped - handleWidth) {
              _isTrimmingRight = true;
            } else {
              _isDragging = true;
            }

            setState(() {
              _dragDeltaX = 0;
              _dragDeltaY = 0;
            });
            HapticFeedback.lightImpact();
          },
          onPanUpdate: (details) {
            if (widget.track.isLocked) return;

            setState(() {
              _dragDeltaX += details.delta.dx;
              _dragDeltaY += details.delta.dy;
            });

            if (_isDragging) {
              widget.onMovePreviewDeltaPx?.call(_dragDeltaX);
            } else if (_isTrimmingLeft) {
              widget.onTrimLeftPreviewDeltaPx?.call(_dragDeltaX);
            } else if (_isTrimmingRight) {
              widget.onTrimRightPreviewDeltaPx?.call(_dragDeltaX);
            }
          },
          onPanEnd: (_) async {
            if (widget.track.isLocked) {
              widget.onDragPreviewEnd?.call();
              setState(() {
                _isDragging = false;
                _isTrimmingLeft = false;
                _isTrimmingRight = false;
                _dragDeltaX = 0;
                _dragDeltaY = 0;
              });
              return;
            }

            final delta = _dragDeltaX;

            if (_isDragging) {
              final trackOffset = (_dragDeltaY / widget.trackHeight).round();
              String? targetTrackId;
              if (trackOffset != 0) {
                final currentIdx = widget.allTracks.indexOf(widget.track);
                if (currentIdx != -1) {
                  final targetIdx = (currentIdx + trackOffset)
                      .clamp(0, widget.allTracks.length - 1);
                  final targetTrack = widget.allTracks[targetIdx];
                  if (!targetTrack.isLocked) {
                    targetTrackId = targetTrack.id;
                  }
                }
              }

              if (widget.onMoveDeltaPx != null) {
                await widget.onMoveDeltaPx!(delta, targetTrackId);
              }
            } else if (_isTrimmingLeft) {
              if (widget.onTrimLeftDeltaPx != null) {
                await widget.onTrimLeftDeltaPx!(delta);
              }
            } else if (_isTrimmingRight) {
              if (widget.onTrimRightDeltaPx != null) {
                await widget.onTrimRightDeltaPx!(delta);
              }
            }

            if (widget.onDragPreviewEnd != null) {
              widget.onDragPreviewEnd!.call();
            }

            if (!mounted) return;

            setState(() {
              _isDragging = false;
              _isTrimmingLeft = false;
              _isTrimmingRight = false;
              _dragDeltaX = 0;
              _dragDeltaY = 0;
            });
            HapticFeedback.mediumImpact();
          },
          child: Container(
            decoration: BoxDecoration(
              color: clipColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : clipColor.withValues(alpha: 0.8),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                children: [
                  // Render the thumbnail strip or image background if available
                  if (backgroundContent != null)
                    Positioned.fill(child: backgroundContent),

                  // Waveform background for audio tracks/clips
                  if (widget.clip.type == MultitrackClipType.audio)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: WaveformPlaceholder(
                          isMuted: widget.track.isMuted,
                          isSelected: isSelected,
                          seed: widget.clip.id,
                          waveformData: waveformData,
                          startRatio: startRatio,
                          endRatio: endRatio,
                        ),
                      ),
                    ),

                  // Subtle content preview overlay
                  if (displayWidthClamped > 35)
                    Positioned.fill(
                      child: Container(
                        color:
                            Colors.black26, // 15% opacity overlay for legibility
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(
                              clipIcon,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.clip.textContent ?? widget.clip.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Floating badge showing timecode changes
                  if (showBadge)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1622),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.cyanAccent, width: 0.5),
                          ),
                          child: Text(
                            _isDragging
                                ? 'Move: $deltaText'
                                : _isTrimmingLeft
                                    ? 'Trim Left: $deltaText'
                                    : 'Trim Right: $deltaText',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Trim Handles
                  if (isSelected) ...[
                    // Left Handle
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 14,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.9),
                        child: const Center(
                          child: VerticalDivider(
                            color: Colors.black54,
                            width: 2,
                            thickness: 1.5,
                            indent: 8,
                            endIndent: 8,
                          ),
                        ),
                      ),
                    ),
                    // Right Handle
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 14,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.9),
                        child: const Center(
                          child: VerticalDivider(
                            color: Colors.black54,
                            width: 2,
                            thickness: 1.5,
                            indent: 8,
                            endIndent: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<int> _getThumbnailTimestamps(int durationMicros) {
  final durationMs = durationMicros ~/ 1000;
  const intervalMs = 2000;
  final timestamps = <int>[];

  if (durationMs <= intervalMs) {
    timestamps.addAll([0, durationMs ~/ 2, durationMs]);
  } else {
    int time = 0;
    while (time < durationMs && timestamps.length < 10) {
      timestamps.add(time);
      time += intervalMs;
    }
    if (timestamps.isNotEmpty &&
        timestamps.last != durationMs &&
        timestamps.length < 10) {
      timestamps.add(durationMs);
    }
  }
  return timestamps;
}

int _findClosestTimestamp(int timeMs, List<int> timestamps) {
  if (timestamps.isEmpty) return 0;
  int closest = timestamps.first;
  int minDiff = (timeMs - closest).abs();
  for (final t in timestamps) {
    final diff = (timeMs - t).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closest = t;
    }
  }
  return closest;
}
