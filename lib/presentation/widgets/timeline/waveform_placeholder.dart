import 'dart:math';
import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';

class WaveformPlaceholder extends StatelessWidget {
  final bool isMuted;
  final bool isSelected;
  final String seed;
  final List<double>? waveformData;
  final double startRatio;
  final double endRatio;

  const WaveformPlaceholder({
    super.key,
    required this.isMuted,
    required this.isSelected,
    required this.seed,
    this.waveformData,
    this.startRatio = 0.0,
    this.endRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(
        isMuted: isMuted,
        isSelected: isSelected,
        seed: seed,
        waveformData: waveformData,
        startRatio: startRatio,
        endRatio: endRatio,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final bool isMuted;
  final bool isSelected;
  final String seed;
  final List<double>? waveformData;
  final double startRatio;
  final double endRatio;

  const _WaveformPainter({
    required this.isMuted,
    required this.isSelected,
    required this.seed,
    this.waveformData,
    required this.startRatio,
    required this.endRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double width = size.width;

    if (width <= 0 || size.height <= 0) return;

    // Determine colors
    Color waveColor;
    if (isMuted) {
      waveColor = AppTheme.textMuted.withValues(alpha: 0.4);
    } else if (isSelected) {
      waveColor = AppTheme.selection;
    } else {
      waveColor = const Color(0xFF64B5F6).withValues(alpha: 0.85); // Nice waveform blue
    }

    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const double spacing = 4.0;
    const double barWidth = 2.0;

    int numBars = (width / (barWidth + spacing)).floor();
    if (numBars <= 0) return;

    final hasRealData = waveformData != null && waveformData!.isNotEmpty;

    // Deterministic random generator using seed hash
    Random? random;
    if (!hasRealData) {
      int hash = 0;
      for (int i = 0; i < seed.length; i++) {
        hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
      }
      random = Random(hash);
    }

    for (int i = 0; i < numBars; i++) {
      final double x = i * (barWidth + spacing) + (barWidth / 2);

      double amplitude;
      if (hasRealData) {
        final double progress = i / numBars;
        final double ratio = (startRatio + progress * (endRatio - startRatio)).clamp(0.0, 1.0);
        final int dataIdx = (ratio * (waveformData!.length - 1)).round();
        amplitude = waveformData![dataIdx];
      } else {
        final double r1 = random!.nextDouble();
        final double r2 = random.nextDouble();
        final double val = (r1 + r2) / 2.0;

        // Add a envelope to taper the start and end of the waveform slightly
        final double progress = i / numBars;
        final double envelope = sin(progress * pi); // 0 at start, 1 at mid, 0 at end

        amplitude = (0.1 + val * 0.8) * envelope;
      }

      final double barHeight = size.height * 0.7 * amplitude;

      canvas.drawLine(
        Offset(x, midY - barHeight / 2),
        Offset(x, midY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.isMuted != isMuted ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.seed != seed ||
        oldDelegate.waveformData != waveformData ||
        oldDelegate.startRatio != startRatio ||
        oldDelegate.endRatio != endRatio;
  }
}
