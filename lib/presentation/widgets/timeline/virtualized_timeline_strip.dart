import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/performance/timeline_viewport.dart';

class VirtualizedTimelineStrip extends StatelessWidget {
  final List<Clip> clips;
  final List<Track> tracks;
  final ScrollController scrollController;
  final double pixelsPerSecond;
  final int durationMicros;
  final void Function(Clip clip)? onClipTap;

  const VirtualizedTimelineStrip({
    super.key,
    required this.clips,
    required this.tracks,
    required this.scrollController,
    required this.pixelsPerSecond,
    required this.durationMicros,
    this.onClipTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: scrollController,
          builder: (context, _) {
            final scrollOffset =
                scrollController.hasClients ? scrollController.offset : 0.0;

            final window = TimelineViewportCalculator.calculate(
              scrollOffset: scrollOffset,
              viewportWidth: constraints.maxWidth,
              pixelsPerSecond: pixelsPerSecond,
            );

            final visibleClips = clips
                .where(window.clipVisible)
                .take(160)
                .toList(growable: false);

            final width = math.max(
              constraints.maxWidth,
              (durationMicros / 1000000.0) * pixelsPerSecond,
            );

            return SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: math.max(240, tracks.length * 72),
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      ...tracks.asMap().entries.map(
                            (entry) => Positioned(
                              left: 0,
                              right: 0,
                              top: entry.key * 72.0,
                              height: 68,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: entry.key.isEven
                                      ? AppTheme.surface
                                      : AppTheme.surfaceElevated,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.borderSubtle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ...visibleClips.map(
                        (clip) {
                          final trackIndex = tracks.indexWhere(
                            (t) => t.id == clip.trackId,
                          );

                          if (trackIndex < 0) {
                            return const SizedBox.shrink();
                          }

                          final left = (clip.timelineStartMicros / 1000000.0) *
                              pixelsPerSecond;
                          final clipWidth = math.max(
                            24.0,
                            ((clip.timelineEndMicros -
                                        clip.timelineStartMicros) /
                                    1000000.0) *
                                pixelsPerSecond,
                          );

                          return Positioned(
                            left: left,
                            top: trackIndex * 72.0 + 8,
                            width: clipWidth,
                            height: 52,
                            child: RepaintBoundary(
                              child: GestureDetector(
                                onTap: () => onClipTap?.call(clip),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: clip.clipType == 'text'
                                        ? AppTheme.accentPrimary.withOpacity(0.22)
                                        : AppTheme.accentPrimary.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          AppTheme.accentPrimary.withOpacity(0.45),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    clip.clipType == 'text'
                                        ? (clip.textContent ?? 'Text')
                                        : 'Media Clip',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
