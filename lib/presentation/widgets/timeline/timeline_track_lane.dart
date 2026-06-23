import 'package:flutter/material.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';

class TimelineTrackLane extends StatelessWidget {
  final MultitrackTrack track;
  final double totalWidth;
  final Widget child;

  const TimelineTrackLane({
    super.key,
    required this.track,
    required this.totalWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: track.height,
      width: totalWidth,
      decoration: BoxDecoration(
        color: track.isAudio
            ? AppTheme.timelineBackground.withOpacity(0.4)
            : AppTheme.timelineBackground.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderSubtle,
            width: 1.0,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Background grid lines (optional/subtle)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: LaneBackgroundPainter(
                  isLocked: track.isLocked,
                  isMuted: track.isMuted,
                  trackColor: track.color,
                ),
              ),
            ),
          ),
          if (track.isHidden || track.isMuted)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                ),
              ),
            ),
          Opacity(
            opacity: (track.isHidden || track.isMuted) ? 0.55 : 1.0,
            child: child,
          ),
        ],
      ),
    );
  }
}

class LaneBackgroundPainter extends CustomPainter {
  final bool isLocked;
  final bool isMuted;
  final Color trackColor;

  LaneBackgroundPainter({
    required this.isLocked,
    required this.isMuted,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isLocked) {
      // Draw subtle diagonal warning lines to indicate locked state
      final paint = Paint()
        ..color = Colors.amber.withOpacity(0.04)
        ..strokeWidth = 2.0;

      const spacing = 16.0;
      for (double i = -size.height; i < size.width; i += spacing) {
        canvas.drawLine(
          Offset(i, 0),
          Offset(i + size.height, size.height),
          paint,
        );
      }
    } else if (isMuted) {
      // Draw subtle muted lines
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.04)
        ..strokeWidth = 2.0;

      const spacing = 16.0;
      for (double i = -size.height; i < size.width; i += spacing) {
        canvas.drawLine(
          Offset(i, 0),
          Offset(i + size.height, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LaneBackgroundPainter oldDelegate) {
    return oldDelegate.isLocked != isLocked ||
        oldDelegate.isMuted != isMuted ||
        oldDelegate.trackColor != trackColor;
  }
}
