import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/timeline_snap_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/timeline_snap_providers.dart';

class TimelineRuler extends ConsumerWidget {
  final String? projectId;
  final double totalWidth;
  final TimelineScale scale;
  final int durationMicros;
  final ValueChanged<int>? onSeek;

  const TimelineRuler({
    super.key,
    this.projectId,
    required this.totalWidth,
    required this.scale,
    required this.durationMicros,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(multitrackTimelineControllerProvider.notifier);
    final editorNotifier = ref.read(editorStateProvider.notifier);
    final markers = projectId != null
        ? ref.watch(timelineMarkerSnapPointsProvider(projectId!))
        : const <TimelineMarkerSnapPoint>[];

    return GestureDetector(
      onHorizontalDragStart: (_) => editorNotifier.setScrubbing(true),
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localX = box.globalToLocal(details.globalPosition).dx;
        final playheadMicros =
            scale.pxToMicros(localX).clamp(0, durationMicros);
        controller.setPlayheadMicros(playheadMicros);
        if (onSeek != null) {
          onSeek!(playheadMicros);
        } else {
          editorNotifier.seekTo(playheadMicros);
        }
      },
      onHorizontalDragEnd: (_) => editorNotifier.setScrubbing(false),
      onTapDown: (details) {
        final playheadMicros =
            scale.pxToMicros(details.localPosition.dx).clamp(0, durationMicros);
        controller.setPlayheadMicros(playheadMicros);
        if (onSeek != null) {
          onSeek!(playheadMicros);
        } else {
          editorNotifier.seekTo(playheadMicros);
        }
      },
      child: Container(
        height: 36,
        width: totalWidth,
        color: AppTheme.timelineBackground,
        child: CustomPaint(
          size: Size(totalWidth, 36),
          painter: MultitrackRulerPainter(
            scale: scale,
            durationMicros: durationMicros,
            markers: markers,
          ),
        ),
      ),
    );
  }
}

class MultitrackRulerPainter extends CustomPainter {
  final TimelineScale scale;
  final int durationMicros;
  final List<TimelineMarkerSnapPoint> markers;

  MultitrackRulerPainter({
    required this.scale,
    required this.durationMicros,
    this.markers = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = AppTheme.textMuted.withOpacity(0.2)
      ..strokeWidth = 1.0;

    final majorTickPaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.4)
      ..strokeWidth = 1.5;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final pxPerSec = scale.pixelsPerSecond;
    double intervalSeconds = 1.0;
    int subTicks = 5;

    if (pxPerSec < 30) {
      intervalSeconds = 10.0;
      subTicks = 10;
    } else if (pxPerSec < 60) {
      intervalSeconds = 5.0;
      subTicks = 5;
    } else if (pxPerSec > 180) {
      intervalSeconds = 0.5;
      subTicks = 5;
    } else if (pxPerSec > 300) {
      intervalSeconds = 0.1;
      subTicks = 10;
    }

    final maxSeconds = durationMicros / 1000000.0;
    final viewMaxSeconds = size.width / pxPerSec;
    final endSeconds =
        maxSeconds < viewMaxSeconds ? viewMaxSeconds : maxSeconds;

    for (double sec = 0.0; sec <= endSeconds; sec += intervalSeconds) {
      final x = sec * pxPerSec;
      if (x > size.width) break;

      canvas.drawLine(
        Offset(x, 18),
        Offset(x, 36),
        majorTickPaint,
      );

      final label = TimelineTime((sec * 1000000).round()).timecode;

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.7),
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 4, 4));

      final minorStep = intervalSeconds / subTicks;
      for (int i = 1; i < subTicks; i++) {
        final minorX = x + (i * minorStep) * pxPerSec;
        if (minorX > size.width) break;

        canvas.drawLine(
          Offset(minorX, 26),
          Offset(minorX, 36),
          tickPaint,
        );
      }
    }

    // Draw gold beat markers on ruler
    final beatPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    for (final marker in markers) {
      final x = scale.microsToPx(marker.timelineMicros);
      if (x < 0 || x > size.width) continue;

      // Draw a gold diamond-shaped beat tick at the bottom of the ruler height
      final path = Path()
        ..moveTo(x, 24)
        ..lineTo(x + 4, 28)
        ..lineTo(x, 32)
        ..lineTo(x - 4, 28)
        ..close();

      canvas.drawPath(path, beatPaint);
    }

    final borderPaint = Paint()
      ..color = AppTheme.borderSubtle
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, 35.5), Offset(size.width, 35.5), borderPaint);
  }

  @override
  bool shouldRepaint(covariant MultitrackRulerPainter oldDelegate) {
    return oldDelegate.scale.pixelsPerSecond != scale.pixelsPerSecond ||
        oldDelegate.durationMicros != durationMicros ||
        oldDelegate.markers != markers;
  }
}
