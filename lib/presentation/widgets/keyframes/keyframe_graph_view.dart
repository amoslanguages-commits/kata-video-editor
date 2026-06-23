import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';

class KeyframeGraphView extends StatelessWidget {
  final NleAnimatableProperty property;
  final int clipDurationMicros;
  final int playheadMicros;

  const KeyframeGraphView({
    super.key,
    required this.property,
    required this.clipDurationMicros,
    required this.playheadMicros,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: CustomPaint(
        painter: _GraphPainter(
          property: property,
          durationMicros: clipDurationMicros,
          playheadMicros: playheadMicros,
        ),
        child: Container(),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final NleAnimatableProperty property;
  final int durationMicros;
  final int playheadMicros;

  _GraphPainter({
    required this.property,
    required this.durationMicros,
    required this.playheadMicros,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.borderSubtle.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw horizontal grids
    final steps = 4;
    for (var i = 0; i <= steps; i++) {
      final y = size.height * (i / steps);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final keyframes = property.orderedKeyframes;
    if (keyframes.isEmpty) return;

    final minVal = property.min ?? 0.0;
    final maxVal = property.max ?? 1.0;
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    Offset getOffset(NleKeyframe kf) {
      final x = (kf.timeOffsetMicros / durationMicros) * size.width;
      final normVal = (kf.value.numberOrZero - minVal) / range;
      final y = size.height - (normVal * size.height);
      return Offset(x.clamp(0.0, size.width), y.clamp(0.0, size.height));
    }

    final path = Path();
    final points = keyframes.map((kf) => getOffset(kf)).toList();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      // Draw spline or line
      path.cubicTo(
        p1.dx + (p2.dx - p1.dx) * 0.42, p1.dy,
        p1.dx + (p2.dx - p1.dx) * 0.58, p2.dy,
        p2.dx, p2.dy,
      );
    }

    final curvePaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, curvePaint);

    // Draw keyframe dots
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final p in points) {
      canvas.drawCircle(p, 5.0, dotPaint);
      canvas.drawCircle(p, 5.0, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
