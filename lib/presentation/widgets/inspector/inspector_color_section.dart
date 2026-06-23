import 'package:flutter/material.dart';

import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_section_card.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';

class InspectorColorSection extends StatelessWidget {
  final ClipInspectorState clip;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onSaturationChanged;

  const InspectorColorSection({
    super.key,
    required this.clip,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onSaturationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InspectorSectionCard(
      icon: Icons.tune_rounded,
      title: 'Color Adjustments',
      children: [
        InspectorSliderRow(
          label: 'Brightness',
          value: clip.brightness,
          min: -1.0,
          max: 1.0,
          divisions: 200,
          onChanged: onBrightnessChanged,
        ),
        InspectorSliderRow(
          label: 'Contrast',
          value: clip.contrast,
          min: 0.0,
          max: 3.0,
          divisions: 300,
          onChanged: onContrastChanged,
        ),
        InspectorSliderRow(
          label: 'Saturation',
          value: clip.saturation,
          min: 0.0,
          max: 3.0,
          divisions: 300,
          onChanged: onSaturationChanged,
        ),
      ],
    );
  }
}
