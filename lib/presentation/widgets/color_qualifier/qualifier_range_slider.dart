import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';

class QualifierRangeSlider extends StatelessWidget {
  final String label;
  final NleRangeControl value;
  final ValueChanged<NleRangeControl> onChanged;

  const QualifierRangeSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safe = value.clamp();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(
                    (safe.center - safe.width / 2).clamp(0.0, 1.0),
                    (safe.center + safe.width / 2).clamp(0.0, 1.0),
                  ),
                  min: 0.0,
                  max: 1.0,
                  onChanged: (range) {
                    final center = (range.start + range.end) / 2.0;
                    final width = (range.end - range.start).clamp(0.0, 1.0);

                    onChanged(
                      safe.copyWith(
                        center: center,
                        width: width,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 92),
              const Text(
                'Soft',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Slider(
                  value: safe.softness,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) {
                    onChanged(safe.copyWith(softness: v));
                  },
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  safe.softness.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
