import 'package:flutter/material.dart';

import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';

class HistogramScopePainter extends CustomPainter {
  final NleHistogramData histogram;
  final bool showGrid;

  const HistogramScopePainter({
    required this.histogram,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050814),
    );

    if (showGrid) _drawGrid(canvas, size);

    _drawBars(
      canvas,
      size,
      histogram.luma,
      Colors.white.withOpacity(0.35),
      0,
    );

    _drawBars(
      canvas,
      size,
      histogram.red,
      const Color(0xFFFF4040).withOpacity(0.50),
      1,
    );

    _drawBars(
      canvas,
      size,
      histogram.green,
      const Color(0xFF22C55E).withOpacity(0.50),
      2,
    );

    _drawBars(
      canvas,
      size,
      histogram.blue,
      const Color(0xFF60A5FA).withOpacity(0.50),
      3,
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
  }

  void _drawBars(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color,
    int offsetIndex,
  ) {
    if (values.isEmpty) return;

    final maxValue = values.reduce((a, b) => a > b ? a : b).clamp(0.0001, 1.0);
    final width = size.width / values.length;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] / maxValue).clamp(0.0, 1.0);
      final barHeight = normalized * size.height;

      final x = i * width + offsetIndex * width * 0.12;

      canvas.drawRect(
        Rect.fromLTWH(
          x,
          size.height - barHeight,
          width * 0.28,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HistogramScopePainter oldDelegate) {
    return oldDelegate.histogram != histogram ||
        oldDelegate.showGrid != showGrid;
  }
}
