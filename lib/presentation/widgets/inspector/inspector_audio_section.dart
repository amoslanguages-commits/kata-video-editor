import 'package:flutter/material.dart';

import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_section_card.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';

class InspectorAudioSection extends StatelessWidget {
  final ClipInspectorState clip;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<int> onFadeInChanged;
  final ValueChanged<int> onFadeOutChanged;

  const InspectorAudioSection({
    super.key,
    required this.clip,
    required this.onVolumeChanged,
    required this.onFadeInChanged,
    required this.onFadeOutChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxFadeSeconds = (clip.durationMicros / 1000000.0 / 2).clamp(0.1, 30.0);

    return InspectorSectionCard(
      icon: Icons.graphic_eq_rounded,
      title: 'Audio',
      children: [
        InspectorSliderRow(
          label: 'Volume',
          value: clip.volume,
          min: 0.0,
          max: 2.0,
          divisions: 200,
          onChanged: onVolumeChanged,
        ),
        InspectorSliderRow(
          label: 'Fade In',
          value: clip.fadeInMicros / 1000000.0,
          min: 0.0,
          max: maxFadeSeconds,
          divisions: (maxFadeSeconds * 10).round(),
          suffix: 's',
          onChanged: (seconds) {
            onFadeInChanged((seconds * 1000000).round());
          },
        ),
        InspectorSliderRow(
          label: 'Fade Out',
          value: clip.fadeOutMicros / 1000000.0,
          min: 0.0,
          max: maxFadeSeconds,
          divisions: (maxFadeSeconds * 10).round(),
          suffix: 's',
          onChanged: (seconds) {
            onFadeOutChanged((seconds * 1000000).round());
          },
        ),
      ],
    );
  }
}
