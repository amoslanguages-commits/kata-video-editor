import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';
import 'package:nle_editor/presentation/providers/primary_grade_controller_provider.dart';
import 'package:nle_editor/presentation/widgets/color_grade/mobile_color_wheel.dart';


class PrimaryGradePanel extends ConsumerWidget {
  final String? selectedClipId;

  const PrimaryGradePanel({
    super.key,
    required this.selectedClipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipId = selectedClipId;

    if (clipId == null) {
      return const Center(
        child: Text(
          'Select a clip to grade.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final state = ref.watch(primaryGradeControllerProvider(clipId));
    final controller =
        ref.read(primaryGradeControllerProvider(clipId).notifier);

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final grade = state.grade;

    return ListView(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Primary Grade',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Switch(
              value: grade.enabled,
              onChanged: controller.setEnabled,
            ),
            IconButton(
              onPressed: controller.reset,
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'Reset primary grade',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<NlePrimaryGradeMode>(
          segments: const [
            ButtonSegment(
              value: NlePrimaryGradeMode.linear,
              label: Text('Linear'),
            ),
            ButtonSegment(
              value: NlePrimaryGradeMode.log,
              label: Text('Log'),
            ),
          ],
          selected: {grade.mode},
          onSelectionChanged: (set) {
            controller.setMode(set.first);
          },
        ),
        const SizedBox(height: 12),
        _GradeSlider(
          label: 'Intensity',
          value: grade.intensity,
          min: 0.0,
          max: 1.0,
          neutral: 1.0,
          onChanged: controller.setIntensity,
        ),
        _GradeSlider(
          label: 'Contrast',
          value: grade.contrast,
          min: 0.0,
          max: 3.0,
          neutral: 1.0,
          onChanged: controller.setContrast,
        ),
        _GradeSlider(
          label: 'Pivot',
          value: grade.pivot,
          min: 0.01,
          max: 1.0,
          neutral: 0.18,
          onChanged: controller.setPivot,
        ),
        _GradeSlider(
          label: 'Saturation',
          value: grade.saturation,
          min: 0.0,
          max: 3.0,
          neutral: 1.0,
          onChanged: controller.setSaturation,
        ),
        const SizedBox(height: 14),
        MobileColorWheel(
          label: 'Lift',
          value: grade.lift,
          minMaster: -0.5,
          maxMaster: 0.5,
          onChanged: controller.setLift,
          onReset: () {
            controller.setLift(const NlePrimaryWheelControl.zero());
          },
        ),
        const SizedBox(height: 12),
        MobileColorWheel(
          label: 'Gamma',
          value: grade.gamma,
          multiplicative: true,
          minMaster: 0.1,
          maxMaster: 4.0,
          onChanged: controller.setGamma,
          onReset: () {
            controller.setGamma(const NlePrimaryWheelControl.one());
          },
        ),
        const SizedBox(height: 12),
        MobileColorWheel(
          label: 'Gain',
          value: grade.gain,
          multiplicative: true,
          minMaster: 0.1,
          maxMaster: 4.0,
          onChanged: controller.setGain,
          onReset: () {
            controller.setGain(const NlePrimaryWheelControl.one());
          },
        ),
        const SizedBox(height: 12),
        MobileColorWheel(
          label: 'Offset',
          value: grade.offset,
          minMaster: -0.5,
          maxMaster: 0.5,
          onChanged: controller.setOffset,
          onReset: () {
            controller.setOffset(const NlePrimaryWheelControl.zero());
          },
        ),
      ],
    );
  }
}

class _GradeSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double neutral;
  final ValueChanged<double> onChanged;

  const _GradeSlider({
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
          width: 88,
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
          onLongPress: () {
            onChanged(neutral);
            HapticFeedback.mediumImpact();
          },
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
