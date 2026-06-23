// 33B-PRO: Advanced Audio Automation — Automation Lane View
//
// A timeline lane showing automation keyframe dots and interpolated curve for
// a single [NleAnimatableProperty]. Double-tap to add a keyframe; drag dots to
// move them.

import 'package:flutter/material.dart';

import 'package:nle_editor/domain/keyframes/keyframe_models.dart';

// ── Lane View ─────────────────────────────────────────────────────────────────

class AudioAutomationLaneView extends StatelessWidget {
  final NleAnimatableProperty property;
  final int durationMicros;
  final int playheadMicros;
  final ValueChanged<String> onKeyframeTap;
  final void Function(String keyframeId, int timeMicros) onKeyframeDrag;
  final void Function(int timeMicros, double value) onAddKeyframe;
  final String? selectedKeyframeId;

  const AudioAutomationLaneView({
    super.key,
    required this.property,
    required this.durationMicros,
    required this.playheadMicros,
    required this.onKeyframeTap,
    required this.onKeyframeDrag,
    required this.onAddKeyframe,
    this.selectedKeyframeId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFF08101D),
        border: Border.all(color: const Color(0xFF1A2535)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return GestureDetector(
            onDoubleTapDown: (details) {
              final x = details.localPosition.dx.clamp(0.0, w);
              final y = details.localPosition.dy.clamp(0.0, h);
              final time = (x / w * durationMicros).round();
              final value = _valueFromY(y, h);
              onAddKeyframe(time, value);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AutomationLanePainter(
                      property: property,
                      durationMicros: durationMicros,
                      playheadMicros: playheadMicros,
                    ),
                  ),
                ),
                // Lane header label
                Positioned(
                  left: 8,
                  top: 4,
                  child: Text(
                    property.label,
                    style: const TextStyle(
                      color: Color(0xFF29D884),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                // Keyframe diamonds
                ...property.orderedKeyframes.map((kf) {
                  final effDuration = durationMicros == 0 ? 1 : durationMicros;
                  final x = kf.timeOffsetMicros / effDuration * w;
                  final y = _yFromValue(kf.value.numberOrZero, h);
                  final isSelected = kf.id == selectedKeyframeId;

                  return Positioned(
                    left: x - 8,
                    top: y - 8,
                    child: GestureDetector(
                      onTap: () => onKeyframeTap(kf.id),
                      onPanUpdate: (details) {
                        final box =
                            context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final local =
                            box.globalToLocal(details.globalPosition);
                        final nextTime = (local.dx / w * durationMicros)
                            .round()
                            .clamp(0, durationMicros);
                        onKeyframeDrag(kf.id, nextTime);
                      },
                      child: Transform.rotate(
                        angle: 0.785398, // 45°
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF29D884),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF29D884)
                                  : Colors.white.withAlpha(71),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF29D884)
                                          .withAlpha(102),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  double _yFromValue(double value, double height) {
    final min = property.min ?? 0.0;
    final max = property.max ?? 1.0;
    final range = (max - min).abs();
    final t =
        range == 0 ? 0.5 : ((value - min) / range).clamp(0.0, 1.0);
    return height - t * height;
  }

  double _valueFromY(double y, double height) {
    final min = property.min ?? 0.0;
    final max = property.max ?? 1.0;
    final t = (1.0 - y / height).clamp(0.0, 1.0);
    return min + (max - min) * t;
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _AutomationLanePainter extends CustomPainter {
  final NleAnimatableProperty property;
  final int durationMicros;
  final int playheadMicros;

  _AutomationLanePainter({
    required this.property,
    required this.durationMicros,
    required this.playheadMicros,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawCurve(canvas, size);
    _drawPlayhead(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Zero / unity line
    final unitPaint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..strokeWidth = 1.0;

    final min = property.min ?? 0.0;
    final max = property.max ?? 1.0;
    final range = (max - min).abs();
    final defaultVal = property.defaultValue.numberOrZero;
    final t = range == 0 ? 0.5 : ((defaultVal - min) / range).clamp(0.0, 1.0);
    final y = size.height - t * size.height;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), unitPaint);
  }

  void _drawCurve(Canvas canvas, Size size) {
    final keyframes = property.orderedKeyframes;
    final min = property.min ?? 0.0;
    final max = property.max ?? 1.0;
    final range = (max - min).abs();
    final effRange = range == 0 ? 1.0 : range;
    final effDuration = durationMicros == 0 ? 1 : durationMicros;

    final paint = Paint()
      ..color = const Color(0xFF29D884)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (keyframes.isEmpty) {
      final value = property.defaultValue.numberOrZero;
      final t = ((value - min) / effRange).clamp(0.0, 1.0);
      final y = size.height - t * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }

    final path = Path();
    const steps = 120;

    for (var s = 0; s <= steps; s++) {
      final fraction = s / steps;
      final timeMicros = (fraction * effDuration).round();
      final value = _sampleAt(timeMicros, keyframes);
      final t = ((value - min) / effRange).clamp(0.0, 1.0);
      final x = fraction * size.width;
      final y = size.height - t * size.height;

      if (s == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawPlayhead(Canvas canvas, Size size) {
    if (durationMicros == 0) return;
    final x = (playheadMicros / durationMicros).clamp(0.0, 1.0) * size.width;
    final paint = Paint()
      ..color = Colors.white.withAlpha(128)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  double _sampleAt(int timeMicros, List<NleKeyframe> keyframes) {
    if (keyframes.isEmpty) {
      return property.defaultValue.numberOrZero;
    }

    if (timeMicros <= keyframes.first.timeOffsetMicros) {
      return keyframes.first.value.numberOrZero;
    }

    if (timeMicros >= keyframes.last.timeOffsetMicros) {
      return keyframes.last.value.numberOrZero;
    }

    for (var i = 0; i < keyframes.length - 1; i++) {
      final a = keyframes[i];
      final b = keyframes[i + 1];
      if (timeMicros >= a.timeOffsetMicros &&
          timeMicros <= b.timeOffsetMicros) {
        final duration = b.timeOffsetMicros - a.timeOffsetMicros;
        if (duration == 0) return a.value.numberOrZero;

        final rawT = (timeMicros - a.timeOffsetMicros) / duration;

        // Simple lerp (full easing handled by KeyframeInterpolationEngine
        // in the sampler; here we just need a visual approximation).
        return a.value.numberOrZero +
            (b.value.numberOrZero - a.value.numberOrZero) *
                rawT.clamp(0.0, 1.0);
      }
    }

    return property.defaultValue.numberOrZero;
  }

  @override
  bool shouldRepaint(_AutomationLanePainter old) {
    return old.property != property ||
        old.durationMicros != durationMicros ||
        old.playheadMicros != playheadMicros;
  }
}

// ── Lane Container ────────────────────────────────────────────────────────────

/// Wraps [AudioAutomationLaneView] with a label sidebar and resize handle.
class AudioAutomationLaneContainer extends StatelessWidget {
  final NleAnimatableProperty property;
  final int durationMicros;
  final int playheadMicros;
  final String? selectedKeyframeId;
  final ValueChanged<String> onKeyframeTap;
  final void Function(String keyframeId, int timeMicros) onKeyframeDrag;
  final void Function(int timeMicros, double value) onAddKeyframe;

  const AudioAutomationLaneContainer({
    super.key,
    required this.property,
    required this.durationMicros,
    required this.playheadMicros,
    required this.onKeyframeTap,
    required this.onKeyframeDrag,
    required this.onAddKeyframe,
    this.selectedKeyframeId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: AudioAutomationLaneView(
        property: property,
        durationMicros: durationMicros,
        playheadMicros: playheadMicros,
        onKeyframeTap: onKeyframeTap,
        onKeyframeDrag: onKeyframeDrag,
        onAddKeyframe: onAddKeyframe,
        selectedKeyframeId: selectedKeyframeId,
      ),
    );
  }
}
