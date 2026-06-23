import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';

class KeyframePropertyLane extends StatelessWidget {
  final NleAnimatableProperty property;
  final int clipDurationMicros;
  final int playheadMicros;
  final String? selectedKeyframeId;
  final ValueChanged<String> onSelectKeyframe;

  const KeyframePropertyLane({
    super.key,
    required this.property,
    required this.clipDurationMicros,
    required this.playheadMicros,
    this.selectedKeyframeId,
    required this.onSelectKeyframe,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: 48,
          color: const Color(0xFF070B12),
          child: Stack(
            children: [
              // Horizontal axis line
              Positioned(
                left: 0,
                right: 0,
                top: 23,
                child: Container(
                  height: 2,
                  color: AppTheme.borderSubtle,
                ),
              ),
              // Playhead line
              Positioned(
                left: (playheadMicros / clipDurationMicros * width).clamp(0.0, width),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.red,
                ),
              ),
              // Keyframes
              ...property.keyframes.map((kf) {
                final x = (kf.timeOffsetMicros / clipDurationMicros * width).clamp(0.0, width);
                final isSelected = kf.id == selectedKeyframeId;
                return Positioned(
                  left: x - 6,
                  top: 18,
                  child: GestureDetector(
                    onTap: () => onSelectKeyframe(kf.id),
                    child: Transform.rotate(
                      angle: 3.14159 / 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentPrimary : Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
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
    );
  }
}
