import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';

class WaveformScopePainter extends CustomPainter {
  final List<NleWaveformPoint> points;
  final bool showGrid;

  const WaveformScopePainter({
    required this.points,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    if (showGrid) _drawGrid(canvas, size);
    _drawScale(canvas, size);
    _drawWaveform(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050814),
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6.0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawScale(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.35),
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    final labels = {
      0.0: '100',
      0.25: '75',
      0.5: '50',
      0.75: '25',
      1.0: '0',
    };

    for (final entry in labels.entries) {
      final painter = TextPainter(
        text: TextSpan(text: entry.value, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(4, size.height * entry.key - painter.height / 2),
      );
    }
  }

  void _drawWaveform(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF20E3B2).withOpacity(0.42);

    for (final p in points) {
      final x = p.x.clamp(0.0, 1.0) * size.width;
      final y = (1.0 - p.y.clamp(0.0, 1.0)) * size.height;

      paint.color = const Color(0xFF20E3B2)
          .withOpacity((0.08 + p.intensity * 0.65).clamp(0.08, 0.75));

      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformScopePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.showGrid != showGrid;
  }
}
