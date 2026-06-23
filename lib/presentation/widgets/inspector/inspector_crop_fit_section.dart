import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_section_card.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';

class InspectorCropFitSection extends StatelessWidget {
  final ClipInspectorState clip;
  final ValueChanged<ClipFitMode> onFitModeChanged;
  final ValueChanged<double> onCropLeftChanged;
  final ValueChanged<double> onCropTopChanged;
  final ValueChanged<double> onCropRightChanged;
  final ValueChanged<double> onCropBottomChanged;

  const InspectorCropFitSection({
    super.key,
    required this.clip,
    required this.onFitModeChanged,
    required this.onCropLeftChanged,
    required this.onCropTopChanged,
    required this.onCropRightChanged,
    required this.onCropBottomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InspectorSectionCard(
      icon: Icons.crop_rounded,
      title: 'Crop & Fit',
      children: [
        Row(
          children: [
            for (final mode in ClipFitMode.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(mode.label),
                    selected: clip.fitMode == mode,
                    onSelected: (_) => onFitModeChanged(mode),
                    selectedColor: AppTheme.accentPrimary,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: clip.fitMode == mode
                          ? Colors.black
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        InspectorSliderRow(
          label: 'Left',
          value: clip.cropLeft,
          min: 0.0,
          max: 0.45,
          divisions: 45,
          onChanged: onCropLeftChanged,
        ),
        InspectorSliderRow(
          label: 'Top',
          value: clip.cropTop,
          min: 0.0,
          max: 0.45,
          divisions: 45,
          onChanged: onCropTopChanged,
        ),
        InspectorSliderRow(
          label: 'Right',
          value: clip.cropRight,
          min: 0.0,
          max: 0.45,
          divisions: 45,
          onChanged: onCropRightChanged,
        ),
        InspectorSliderRow(
          label: 'Bottom',
          value: clip.cropBottom,
          min: 0.0,
          max: 0.45,
          divisions: 45,
          onChanged: onCropBottomChanged,
        ),
      ],
    );
  }
}
