import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';

class SecondaryCorrectionPanel extends StatelessWidget {
  final NleSecondaryCorrection correction;
  final ValueChanged<NleSecondaryCorrection> onChanged;

  const SecondaryCorrectionPanel({
    super.key,
    required this.correction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Intensity',
          value: correction.intensity,
          min: 0.0,
          max: 1.0,
          neutral: 1.0,
          onChanged: (v) => onChanged(correction.copyWith(intensity: v)),
        ),
        _SliderRow(
          label: 'Exposure',
          value: correction.exposure,
          min: -2.0,
          max: 2.0,
          neutral: 0.0,
          onChanged: (v) => onChanged(correction.copyWith(exposure: v)),
        ),
        _SliderRow(
          label: 'Contrast',
          value: correction.contrast,
          min: 0.0,
          max: 3.0,
          neutral: 1.0,
          onChanged: (v) => onChanged(correction.copyWith(contrast: v)),
        ),
        _SliderRow(
          label: 'Saturation',
          value: correction.saturation,
          min: 0.0,
          max: 3.0,
          neutral: 1.0,
          onChanged: (v) => onChanged(correction.copyWith(saturation: v)),
        ),
        _SliderRow(
          label: 'Temp',
          value: correction.temperature,
          min: -1.0,
          max: 1.0,
          neutral: 0.0,
          onChanged: (v) => onChanged(correction.copyWith(temperature: v)),
        ),
        _SliderRow(
          label: 'Tint',
          value: correction.tint,
          min: -1.0,
          max: 1.0,
          neutral: 0.0,
          onChanged: (v) => onChanged(correction.copyWith(tint: v)),
        ),
        _SliderRow(
          label: 'Lift',
          value: correction.lift,
          min: -0.5,
          max: 0.5,
          neutral: 0.0,
          onChanged: (v) => onChanged(correction.copyWith(lift: v)),
        ),
        _SliderRow(
          label: 'Gamma',
          value: correction.gamma,
          min: 0.1,
          max: 4.0,
          neutral: 1.0,
          onChanged: (v) => onChanged(correction.copyWith(gamma: v)),
        ),
        _SliderRow(
          label: 'Gain',
          value: correction.gain,
          min: 0.1,
          max: 4.0,
          neutral: 1.0,
          onChanged: (v) => onChanged(correction.copyWith(gain: v)),
        ),
        _SliderRow(
          label: 'Offset',
          value: correction.offset,
          min: -0.5,
          max: 0.5,
          neutral: 0.0,
          onChanged: (v) => onChanged(correction.copyWith(offset: v)),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double neutral;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.neutral,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        GestureDetector(
          onLongPress: () => onChanged(neutral),
          child: SizedBox(
            width: 48,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
