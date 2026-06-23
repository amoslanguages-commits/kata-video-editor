import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';

class VirtualJogWheel extends ConsumerStatefulWidget {
  final String projectId;
  
  const VirtualJogWheel({super.key, required this.projectId});

  @override
  ConsumerState<VirtualJogWheel> createState() => _VirtualJogWheelState();
}

class _VirtualJogWheelState extends ConsumerState<VirtualJogWheel> {
  double _rotation = 0.0;
  double _accumulatedDelta = 0.0;
  
  // Every time we drag 10 pixels, we snap the playhead by 1 frame (approx 33ms or 33333 micros for 30fps)
  static const double _pixelsPerTick = 8.0;
  static const int _microsPerTick = 33333; // 1 frame at 30fps
  
  void _onPanUpdate(DragUpdateDetails details) async {
    setState(() {
      _rotation += details.delta.dx * 0.02;
      _accumulatedDelta += details.delta.dx;
    });
    
    if (_accumulatedDelta.abs() >= _pixelsPerTick) {
      final ticks = (_accumulatedDelta / _pixelsPerTick).truncate();
      _accumulatedDelta -= ticks * _pixelsPerTick;
      
      final currentMicros = ref.read(editorStateProvider).currentTimeMicros;
      int newMicros = currentMicros + (ticks * _microsPerTick);
      if (newMicros < 0) newMicros = 0;
      
      // Update local state for fast UI feedback
      ref.read(multitrackTimelineControllerProvider.notifier).setPlayheadMicros(newMicros);
      
      // Trigger haptic click
      ref.read(hapticServiceProvider).selection();
      
      // Send command to engine
      await ref.read(nativeCommandServiceProvider).seek(
        projectId: widget.projectId,
        timelineMicros: newMicros,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The background track for the wheel
          Positioned.fill(
            child: CustomPaint(
              painter: _JogWheelTrackPainter(),
            ),
          ),
          
          // The interactive wheel
          GestureDetector(
            onPanUpdate: _onPanUpdate,
            child: Container(
              color: Colors.transparent, // Capture touches
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: _rotation,
                child: Container(
                  width: 200,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppTheme.surfaceMedium, AppTheme.surfaceMedium],
                      stops: [0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      15,
                      (index) => Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: index == 7 
                              ? AppTheme.accentPrimary 
                              : AppTheme.borderSubtle.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Center Indicator Arrow
          const Positioned(
            top: 4,
            child: Icon(Icons.arrow_drop_down, color: AppTheme.accentPrimary, size: 16),
          ),
        ],
      ),
    );
  }
}

class _JogWheelTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.editorBackground
      ..style = PaintingStyle.fill;
    
    // Draw a subtle curved background to make it look like a physical dial embedded in the console
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height + 20),
      width: size.width * 0.8,
      height: size.height * 2,
    );
    
    canvas.drawArc(rect, 3.14, 3.14, true, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
