import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';

/// Small debug overlay that shows how many tracks / clips are currently
/// rendered vs. the total in the project.
///
/// Useful during development and QA to verify virtualization is working.
/// Wrap this in [IgnorePointer] so it does not intercept gestures.
class TimelinePerformanceBadge extends StatelessWidget {
  final int totalTracks;
  final int visibleTracks;
  final int totalClips;
  final int visibleClips;
  final double pixelsPerSecond;

  const TimelinePerformanceBadge({
    super.key,
    required this.totalTracks,
    required this.visibleTracks,
    required this.totalClips,
    required this.visibleClips,
    required this.pixelsPerSecond,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.60),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Text(
          'Visible $visibleClips/$totalClips clips  •  '
          '$visibleTracks/$totalTracks tracks  •  '
          '${pixelsPerSecond.round()} px/s',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
