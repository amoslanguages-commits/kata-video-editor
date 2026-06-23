import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';

class InspectorSliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  const InspectorSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final formatted = _format(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppTheme.accentPrimary,
                inactiveTrackColor: AppTheme.surfaceOverlay,
                thumbColor: AppTheme.accentPrimary,
                overlayColor: AppTheme.accentPrimary.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                label: '$formatted$suffix',
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 54,
            child: Text(
              '$formatted$suffix',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    if (value.abs() >= 10) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
