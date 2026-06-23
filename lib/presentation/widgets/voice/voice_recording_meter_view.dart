import 'package:flutter/material.dart';
import 'package:nle_editor/domain/voice/voice_recording_value_models.dart';

class VoiceRecordingMeterView extends StatelessWidget {
  final NleVoiceRecordingMeter meter;

  const VoiceRecordingMeterView({
    super.key,
    required this.meter,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VoiceRecordingMeterPainter(meter),
      child: const SizedBox(
        width: double.infinity,
        height: 12,
      ),
    );
  }
}

class _VoiceRecordingMeterPainter extends CustomPainter {
  final NleVoiceRecordingMeter meter;

  _VoiceRecordingMeterPainter(this.meter);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    // Draw background track
    final rrectBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrectBg, paintBg);

    // Peak width calculation
    final peakWidth = size.width * meter.peak.clamp(0.0, 1.0);
    final rmsWidth = size.width * meter.rms.clamp(0.0, 1.0);

    if (peakWidth > 0) {
      final paintPeak = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF10B981), // Emerald
            const Color(0xFFF59E0B), // Amber
            meter.clipping ? const Color(0xFFEF4444) : const Color(0xFFF87171), // Red
          ],
          stops: const [0.6, 0.85, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      final rrectPeak = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, peakWidth, size.height),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrectPeak, paintPeak);
    }

    // Draw RMS indicator bar
    if (rmsWidth > 0) {
      final paintRms = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(rmsWidth - 1.5, 0, 1.5, size.height),
        paintRms,
      );
    }

    // Clip indicator at the far right
    if (meter.clipping) {
      final paintClip = Paint()
        ..color = const Color(0xFFEF4444)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width - 6, size.height / 2),
        3,
        paintClip,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceRecordingMeterPainter oldDelegate) {
    return oldDelegate.meter.peak != meter.peak ||
        oldDelegate.meter.rms != meter.rms ||
        oldDelegate.meter.clipping != meter.clipping;
  }
}
