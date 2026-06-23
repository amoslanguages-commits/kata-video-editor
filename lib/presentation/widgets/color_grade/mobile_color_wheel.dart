import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';
import 'package:nle_editor/presentation/widgets/premium/premium_bounce_button.dart';

class MobileColorWheel extends StatefulWidget {
  final String label;
  final NlePrimaryWheelControl value;
  final bool multiplicative;
  final double minMaster;
  final double maxMaster;
  final ValueChanged<NlePrimaryWheelControl> onChanged;
  final VoidCallback? onReset;

  const MobileColorWheel({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onReset,
    this.multiplicative = false,
    this.minMaster = -1.0,
    this.maxMaster = 1.0,
  });

  @override
  State<MobileColorWheel> createState() => _MobileColorWheelState();
}

class _MobileColorWheelState extends State<MobileColorWheel> {
  late Offset _handle;

  @override
  void initState() {
    super.initState();
    _handle = _rgbToHandle(widget.value.rgb);
  }

  @override
  void didUpdateWidget(covariant MobileColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.rgb != widget.value.rgb) {
      _handle = _rgbToHandle(widget.value.rgb);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (widget.onReset != null)
                Tooltip(
                  message: 'Reset ${widget.label}',
                  child: PremiumBounceButton(
                    onTap: widget.onReset,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest.shortestSide;
                final center = Offset(size / 2, size / 2);
                final radius = size / 2;

                return GestureDetector(
                  onPanDown: (details) {
                    _updateFromPosition(details.localPosition, center, radius);
                  },
                  onPanUpdate: (details) {
                    _updateFromPosition(details.localPosition, center, radius);
                  },
                  onDoubleTap: () {
                    widget.onChanged(
                      widget.value.copyWith(
                        rgb: widget.multiplicative
                            ? const NleRgbVector.one()
                            : const NleRgbVector.zero(),
                      ),
                    );
                    HapticFeedback.mediumImpact();
                  },
                  child: CustomPaint(
                    painter: _ColorWheelPainter(
                      handle: _handle,
                    ),
                    size: Size.square(size),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Master',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Slider(
                  value: widget.value.master
                      .clamp(widget.minMaster, widget.maxMaster),
                  min: widget.minMaster,
                  max: widget.maxMaster,
                  onChanged: (value) {
                    widget.onChanged(
                      widget.value.copyWith(master: value),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  widget.value.master.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateFromPosition(
    Offset position,
    Offset center,
    double radius,
  ) {
    final delta = position - center;
    final distance = delta.distance;
    final normalizedDistance = (distance / radius).clamp(0.0, 1.0);

    final angle = math.atan2(delta.dy, delta.dx);

    final rgb = _angleDistanceToRgb(
      angle: angle,
      distance: normalizedDistance,
      multiplicative: widget.multiplicative,
    );

    setState(() {
      _handle = Offset(
        math.cos(angle) * normalizedDistance,
        math.sin(angle) * normalizedDistance,
      );
    });

    widget.onChanged(
      widget.value.copyWith(rgb: rgb),
    );
  }

  Offset _rgbToHandle(NleRgbVector rgb) {
    final r = rgb.r;
    final g = rgb.g;
    final b = rgb.b;

    if (widget.multiplicative) {
      // Gamma/Gain: centered around 1.0
      final biasR = r - 1.0;
      final biasG = g - 1.0;
      final biasB = b - 1.0;

      final angle = math.atan2(
        math.sqrt(3.0) * (biasG - biasB),
        2.0 * biasR - biasG - biasB,
      );

      final maxChannel = math.max(biasR, math.max(biasG, biasB));
      final minChannel = math.min(biasR, math.min(biasG, biasB));
      final distance = (maxChannel - minChannel).abs().clamp(0.0, 1.0);

      return Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );
    } else {
      // Lift/Offset: centered around 0.0
      final angle = math.atan2(
        math.sqrt(3.0) * (g - b),
        2.0 * r - g - b,
      );

      final maxChannel = math.max(r, math.max(g, b));
      final minChannel = math.min(r, math.min(g, b));
      final distance = (maxChannel - minChannel).abs().clamp(0.0, 1.0);

      return Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );
    }
  }

  NleRgbVector _angleDistanceToRgb({
    required double angle,
    required double distance,
    required bool multiplicative,
  }) {
    final rBias = math.cos(angle);
    final gBias = math.cos(angle - 2.0 * math.pi / 3.0);
    final bBias = math.cos(angle + 2.0 * math.pi / 3.0);

    if (multiplicative) {
      final strength = distance * 0.5;

      return NleRgbVector(
        r: (1.0 + rBias * strength).clamp(0.01, 4.0),
        g: (1.0 + gBias * strength).clamp(0.01, 4.0),
        b: (1.0 + bBias * strength).clamp(0.01, 4.0),
      );
    }

    final strength = distance * 0.35;

    return NleRgbVector(
      r: (rBias * strength).clamp(-1.0, 1.0),
      g: (gBias * strength).clamp(-1.0, 1.0),
      b: (bBias * strength).clamp(-1.0, 1.0),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final Offset handle;

  const _ColorWheelPainter({
    required this.handle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(rect);

    canvas.drawCircle(center, radius, sweepPaint);

    final whitePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(rect);

    canvas.drawCircle(center, radius, whitePaint);

    final border = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, border);

    final handlePosition = Offset(
      center.dx + handle.dx * radius,
      center.dy + handle.dy * radius,
    );

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(handlePosition, 7, handlePaint);
    canvas.drawCircle(
      handlePosition,
      4,
      Paint()..color = Colors.black.withOpacity(0.65),
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.handle != handle;
  }
}
