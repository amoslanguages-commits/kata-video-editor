import 'package:flutter/material.dart';

import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_section_card.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';

class InspectorTransformSection extends StatelessWidget {
  final ClipInspectorState clip;
  final ValueChanged<double> onPositionXChanged;
  final ValueChanged<double> onPositionYChanged;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<double> onOpacityChanged;

  const InspectorTransformSection({
    super.key,
    required this.clip,
    required this.onPositionXChanged,
    required this.onPositionYChanged,
    required this.onScaleChanged,
    required this.onRotationChanged,
    required this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InspectorSectionCard(
      icon: Icons.open_with_rounded,
      title: 'Transform',
      children: [
        InspectorSliderRow(
          label: 'X',
          value: clip.positionX,
          min: -1.0,
          max: 1.0,
          divisions: 200,
          onChanged: onPositionXChanged,
        ),
        InspectorSliderRow(
          label: 'Y',
          value: clip.positionY,
          min: -1.0,
          max: 1.0,
          divisions: 200,
          onChanged: onPositionYChanged,
        ),
        InspectorSliderRow(
          label: 'Scale',
          value: clip.scale,
          min: 0.1,
          max: 4.0,
          divisions: 390,
          onChanged: onScaleChanged,
        ),
        InspectorSliderRow(
          label: 'Rotate',
          value: clip.rotation,
          min: -180.0,
          max: 180.0,
          divisions: 360,
          suffix: '°',
          onChanged: onRotationChanged,
        ),
        InspectorSliderRow(
          label: 'Opacity',
          value: clip.opacity,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          onChanged: onOpacityChanged,
        ),
      ],
    );
  }
}
