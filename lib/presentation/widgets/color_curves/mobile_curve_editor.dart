import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/color_curves/color_curve_models.dart';

class MobileCurveEditor extends StatefulWidget {
  final NleColorCurve curve;
  final ValueChanged<NleColorCurve> onChanged;

  const MobileCurveEditor({
    super.key,
    required this.curve,
    required this.onChanged,
  });

  @override
  State<MobileCurveEditor> createState() => _MobileCurveEditorState();
}

class _MobileCurveEditorState extends State<MobileCurveEditor> {
  int? _draggingPointIndex;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;

          return GestureDetector(
            onTapDown: (details) {
              _handleTap(details.localPosition, size);
            },
            onPanStart: (details) {
              _draggingPointIndex =
                  _nearestPointIndex(details.localPosition, size);
            },
            onPanUpdate: (details) {
              final index = _draggingPointIndex;
              if (index == null) return;

              _movePoint(index, details.localPosition, size);
            },
            onPanEnd: (_) {
              _draggingPointIndex = null;
            },
            onLongPressStart: (details) {
              _removeNearestPoint(details.localPosition, size);
            },
            child: CustomPaint(
              painter: _CurvePainter(
                curve: widget.curve,
              ),
              size: size,
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset position, Size size) {
    final nearest = _nearestPointIndex(position, size);
    final nearestDistance = _distanceToPoint(nearest, position, size);

    if (nearestDistance < 22) {
      _draggingPointIndex = nearest;
      return;
    }

    final point = _positionToPoint(position, size);

    final nextPoints = [
      ...widget.curve.points,
      point,
    ]..sort((a, b) => a.x.compareTo(b.x));

    widget.onChanged(
      widget.curve.copyWith(points: nextPoints),
    );
  }

  int _nearestPointIndex(Offset position, Size size) {
    final points = widget.curve.sortedPoints;

    var bestIndex = 0;
    var bestDistance = double.infinity;

    for (var i = 0; i < points.length; i++) {
      final p = _pointToPosition(points[i], size);
      final d = (p - position).distance;

      if (d < bestDistance) {
        bestDistance = d;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  double _distanceToPoint(int index, Offset position, Size size) {
    final points = widget.curve.sortedPoints;
    if (points.isEmpty) return double.infinity;

    return (_pointToPosition(points[index], size) - position).distance;
  }

  void _movePoint(int index, Offset position, Size size) {
    final sorted = widget.curve.sortedPoints;
    if (index < 0 || index >= sorted.length) return;

    final moved = _positionToPoint(position, size);

    final next = [...sorted];

    if (index == 0) {
      next[index] = NleCurvePoint(x: 0.0, y: moved.y);
    } else if (index == next.length - 1) {
      next[index] = NleCurvePoint(x: 1.0, y: moved.y);
    } else {
      final left = next[index - 1].x + 0.01;
      final right = next[index + 1].x - 0.01;

      next[index] = NleCurvePoint(
        x: moved.x.clamp(left, right),
        y: moved.y,
      );
    }

    widget.onChanged(
      widget.curve.copyWith(points: next),
    );
  }

  void _removeNearestPoint(Offset position, Size size) {
    final points = widget.curve.sortedPoints;
    if (points.length <= 2) return;

    final index = _nearestPointIndex(position, size);

    if (index == 0 || index == points.length - 1) return;

    final next = [...points]..removeAt(index);

    widget.onChanged(
      widget.curve.copyWith(points: next),
    );
  }

  NleCurvePoint _positionToPoint(Offset position, Size size) {
    final x = (position.dx / size.width).clamp(0.0, 1.0);
    final y = (1.0 - position.dy / size.height).clamp(0.0, 1.0);

    return NleCurvePoint(x: x, y: y);
  }

  Offset _pointToPosition(NleCurvePoint point, Size size) {
    return Offset(
      point.x * size.width,
      (1.0 - point.y) * size.height,
    );
  }
}

class _CurvePainter extends CustomPainter {
  final NleColorCurve curve;

  const _CurvePainter({
    required this.curve,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final background = Paint()
      ..color = const Color(0xFF0D1320)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      background,
    );

    _drawGrid(canvas, size);
    _drawDiagonal(canvas, size);
    _drawCurve(canvas, size);
    _drawPoints(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      final y = size.height * i / 4;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDiagonal(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      paint,
    );
  }

  void _drawCurve(Canvas canvas, Size size) {
    final points = curve.sortedPoints;
    if (points.length < 2) return;

    final path = Path();

    for (var i = 0; i < 256; i++) {
      final x = i / 255.0;
      final y = _evaluate(points, x);

      final pos = Offset(
        x * size.width,
        (1.0 - y) * size.height,
      );

      if (i == 0) {
        path.moveTo(pos.dx, pos.dy);
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
    }

    final paint = Paint()
      ..color = _curveColor(curve.type)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  void _drawPoints(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = _curveColor(curve.type)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in curve.sortedPoints) {
      final pos = Offset(
        point.x * size.width,
        (1.0 - point.y) * size.height,
      );

      canvas.drawCircle(pos, 6, paint);
      canvas.drawCircle(pos, 8, stroke);
    }
  }

  double _evaluate(List<NleCurvePoint> points, double x) {
    if (x <= points.first.x) return points.first.y;
    if (x >= points.last.x) return points.last.y;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];

      if (x >= a.x && x <= b.x) {
        final span = math.max(b.x - a.x, 0.00001);
        final tRaw = (x - a.x) / span;
        final t = tRaw * tRaw * (3.0 - 2.0 * tRaw);
        return a.y + (b.y - a.y) * t;
      }
    }

    return x;
  }

  Color _curveColor(NleCurveType type) {
    switch (type) {
      case NleCurveType.red:
        return const Color(0xFFFF4D4D);
      case NleCurveType.green:
        return const Color(0xFF22C55E);
      case NleCurveType.blue:
        return const Color(0xFF60A5FA);
      case NleCurveType.hueVsSat:
      case NleCurveType.hueVsHue:
      case NleCurveType.hueVsLum:
        return const Color(0xFFFFD166);
      case NleCurveType.lumVsSat:
      case NleCurveType.satVsSat:
        return const Color(0xFFC084FC);
      case NleCurveType.rgbMaster:
      case NleCurveType.luma:
        return AppTheme.accentPrimary;
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) {
    return oldDelegate.curve != curve;
  }
}
