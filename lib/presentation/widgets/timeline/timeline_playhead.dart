import 'package:flutter/material.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';

class TimelinePlayhead extends StatelessWidget {
  final int playheadMicros;
  final TimelineScale scale;
  final double timelineHeight;

  const TimelinePlayhead({
    super.key,
    required this.playheadMicros,
    required this.scale,
    required this.timelineHeight,
  });

  @override
  Widget build(BuildContext context) {
    final x = scale.microsToPx(playheadMicros);
    final timecode = TimelineTime(playheadMicros).timecode;

    return Positioned(
      left: x - 30.0, // Center of 60px wide playhead area
      top: 0,
      bottom: 0,
      width: 60.0,
      child: IgnorePointer(
        child: Column(
          children: [
            // Playhead handle with timecode bubble
            Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent.shade700,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                timecode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // Playhead pointer tip
            CustomPaint(
              size: const Size(12, 6),
              painter: PlayheadPointerPainter(),
            ),
            // Vertical playhead needle line
            Expanded(
              child: Container(
                width: 2.0,
                color: Colors.redAccent.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayheadPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent.shade700
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
