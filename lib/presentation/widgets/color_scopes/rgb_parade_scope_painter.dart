import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';

class RgbParadeScopePainter extends CustomPainter {
  final List<NleRgbParadePoint> points;
  final bool showGrid;

  const RgbParadeScopePainter({
    required this.points,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050814),
    );

    if (showGrid) _drawGrid(canvas, size);

    final segmentWidth = size.width / 3.0;

    _drawChannel(
      canvas,
      size,
      points,
      channel: 0,
      color: const Color(0xFFFF4040),
      segmentOffset: 0.0,
      segmentWidth: segmentWidth,
    );

    _drawChannel(
      canvas,
      size,
      points,
      channel: 1,
      color: const Color(0xFF22C55E),
      segmentOffset: segmentWidth,
      segmentWidth: segmentWidth,
    );

    _drawChannel(
      canvas,
      size,
      points,
      channel: 2,
      color: const Color(0xFF60A5FA),
      segmentOffset: segmentWidth * 2.0,
      segmentWidth: segmentWidth,
    );

    _drawLabels(canvas, size, segmentWidth);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    canvas.drawLine(
      Offset(size.width / 3.0, 0),
      Offset(size.width / 3.0, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 2.0 / 3.0, 0),
      Offset(size.width * 2.0 / 3.0, size.height),
      paint,
    );
  }

  void _drawChannel(
    Canvas canvas,
    Size size,
    List<NleRgbParadePoint> points, {
    required int channel,
    required Color color,
    required double segmentOffset,
    required double segmentWidth,
  }) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (final p in points) {
      final level = switch (channel) {
        0 => p.red,
        1 => p.green,
        _ => p.blue,
      };

      final x = segmentOffset + p.x.clamp(0.0, 1.0) * segmentWidth;
      final y = (1.0 - level.clamp(0.0, 1.0)) * size.height;

      paint.color = color.withOpacity(0.45);

      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
    }
  }

  void _drawLabels(Canvas canvas, Size size, double segmentWidth) {
    final labels = [
      ('R', const Color(0xFFFF4040)),
      ('G', const Color(0xFF22C55E)),
      ('B', const Color(0xFF60A5FA)),
    ];

    for (var i = 0; i < labels.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i].$1,
          style: TextStyle(
            color: labels[i].$2,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(segmentWidth * i + 8, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RgbParadeScopePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.showGrid != showGrid;
  }
}
