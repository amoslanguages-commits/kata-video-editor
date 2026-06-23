import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';

class VectorscopePainter extends CustomPainter {
  final List<NleVectorPoint> points;
  final bool showGrid;
  final bool showSkinToneLine;

  const VectorscopePainter({
    required this.points,
    required this.showGrid,
    required this.showSkinToneLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050814),
    );

    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.42;

    if (showGrid) _drawGrid(canvas, center, radius);
    if (showSkinToneLine) _drawSkinToneLine(canvas, center, radius);

    _drawTargets(canvas, center, radius);
    _drawPoints(canvas, center, radius);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.5, paint);

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  void _drawSkinToneLine(Canvas canvas, Offset center, double radius) {
    final angle = -math.pi / 5.7;

    final paint = Paint()
      ..color = const Color(0xFFFFD166).withOpacity(0.75)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      ),
      paint,
    );
  }

  void _drawTargets(Canvas canvas, Offset center, double radius) {
    final labels = [
      ('R', 0.0, const Color(0xFFFF4040)),
      ('Mg', 60.0, const Color(0xFFFF40FF)),
      ('B', 120.0, const Color(0xFF60A5FA)),
      ('Cy', 180.0, const Color(0xFF22D3EE)),
      ('G', 240.0, const Color(0xFF22C55E)),
      ('Yl', 300.0, const Color(0xFFFFD166)),
    ];

    for (final label in labels) {
      final angle = label.$2 * math.pi / 180.0;
      final pos = Offset(
        center.dx + math.cos(angle) * radius * 0.92,
        center.dy + math.sin(angle) * radius * 0.92,
      );

      final painter = TextPainter(
        text: TextSpan(
          text: label.$1,
          style: TextStyle(
            color: label.$3.withOpacity(0.85),
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        pos - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  void _drawPoints(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (final point in points) {
      final x = center.dx + point.x.clamp(-1.0, 1.0) * radius;
      final y = center.dy - point.y.clamp(-1.0, 1.0) * radius;

      paint.color = const Color(0xFFE879F9)
          .withOpacity((0.08 + point.intensity * 0.65).clamp(0.08, 0.75));

      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant VectorscopePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showSkinToneLine != showSkinToneLine;
  }
}
