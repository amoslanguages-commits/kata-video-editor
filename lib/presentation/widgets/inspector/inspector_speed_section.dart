import 'package:flutter/material.dart';

import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_section_card.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';

class InspectorSpeedSection extends StatelessWidget {
  final ClipInspectorState clip;
  final ValueChanged<double> onSpeedChanged;

  const InspectorSpeedSection({
    super.key,
    required this.clip,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InspectorSectionCard(
      icon: Icons.speed_rounded,
      title: 'Speed',
      children: [
        InspectorSliderRow(
          label: 'Speed',
          value: clip.speed,
          min: 0.1,
          max: 4.0,
          divisions: 390,
          suffix: 'x',
          onChanged: onSpeedChanged,
        ),
      ],
    );
  }
}
