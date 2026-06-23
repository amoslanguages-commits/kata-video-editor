import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/color_curves/color_curve_models.dart';
import 'package:nle_editor/presentation/providers/color_curve_controller_provider.dart';
import 'package:nle_editor/presentation/widgets/color_curves/mobile_curve_editor.dart';

class ColorCurvesPanel extends ConsumerWidget {
  final String? selectedClipId;

  const ColorCurvesPanel({
    super.key,
    required this.selectedClipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipId = selectedClipId;

    if (clipId == null) {
      return const Center(
        child: Text(
          'Select a clip to edit curves.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final state = ref.watch(colorCurveControllerProvider(clipId));
    final controller = ref.read(
      colorCurveControllerProvider(clipId).notifier,
    );

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final selectedCurve = state.stack.curve(state.selectedType);

    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(PremiumSpacing.md),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'RGB + HSL Curves',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Switch(
              value: state.stack.enabled,
              onChanged: controller.setEnabled,
            ),
            IconButton(
              onPressed: controller.resetAll,
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'Reset all curves',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<NleCurveEvaluationSpace>(
          segments: const [
            ButtonSegment(
              value: NleCurveEvaluationSpace.sceneLinear,
              label: Text('Scene'),
            ),
            ButtonSegment(
              value: NleCurveEvaluationSpace.displayReferred,
              label: Text('Display'),
            ),
          ],
          selected: {state.stack.evaluationSpace},
          onSelectionChanged: (set) {
            controller.setEvaluationSpace(set.first);
          },
        ),
        const SizedBox(height: 14),
        _CurveTypeChips(
          selected: state.selectedType,
          onSelected: controller.selectType,
        ),
        const SizedBox(height: 14),
        _CurveHeader(
          curve: selectedCurve,
          onReset: controller.resetSelectedCurve,
          onToggle: (enabled) {
            controller.updateCurve(
              selectedCurve.copyWith(enabled: enabled),
            );
          },
          onIntensity: (value) {
            controller.updateCurve(
              selectedCurve.copyWith(
                intensity: value.clamp(0.0, 1.0),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        MobileCurveEditor(
          curve: selectedCurve,
          onChanged: controller.updateCurve,
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap to add a point. Drag points to shape the curve. Long press a middle point to remove it.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CurveTypeChips extends StatelessWidget {
  final NleCurveType selected;
  final ValueChanged<NleCurveType> onSelected;

  const _CurveTypeChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final groups = [
      const [
        NleCurveType.rgbMaster,
        NleCurveType.red,
        NleCurveType.green,
        NleCurveType.blue,
        NleCurveType.luma,
      ],
      const [
        NleCurveType.hueVsSat,
        NleCurveType.hueVsHue,
        NleCurveType.hueVsLum,
        NleCurveType.lumVsSat,
        NleCurveType.satVsSat,
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(
          label: 'RGB',
          types: groups[0],
          selected: selected,
          onSelected: onSelected,
        ),
        const SizedBox(height: 8),
        _ChipRow(
          label: 'HSL',
          types: groups[1],
          selected: selected,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<NleCurveType> types;
  final NleCurveType selected;
  final ValueChanged<NleCurveType> onSelected;

  const _ChipRow({
    required this.label,
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        ...types.map((type) {
          final active = type == selected;

          return ChoiceChip(
            selected: active,
            label: Text(_label(type)),
            onSelected: (_) => onSelected(type),
          );
        }),
      ],
    );
  }

  String _label(NleCurveType type) {
    switch (type) {
      case NleCurveType.rgbMaster:
        return 'Master';
      case NleCurveType.red:
        return 'Red';
      case NleCurveType.green:
        return 'Green';
      case NleCurveType.blue:
        return 'Blue';
      case NleCurveType.luma:
        return 'Luma';
      case NleCurveType.hueVsSat:
        return 'Hue/Sat';
      case NleCurveType.hueVsHue:
        return 'Hue/Hue';
      case NleCurveType.hueVsLum:
        return 'Hue/Lum';
      case NleCurveType.lumVsSat:
        return 'Lum/Sat';
      case NleCurveType.satVsSat:
        return 'Sat/Sat';
    }
  }
}

class _CurveHeader extends StatelessWidget {
  final NleColorCurve curve;
  final VoidCallback onReset;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onIntensity;

  const _CurveHeader({
    required this.curve,
    required this.onReset,
    required this.onToggle,
    required this.onIntensity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _label(curve.type),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                value: curve.enabled,
                onChanged: onToggle,
              ),
              IconButton(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Intensity',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Slider(
                  value: curve.intensity.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  onChanged: onIntensity,
                ),
              ),
              GestureDetector(
                onLongPress: () {
                  onIntensity(1.0);
                  HapticFeedback.mediumImpact();
                },
                child: SizedBox(
                  width: 44,
                  child: Text(
                    curve.intensity.toStringAsFixed(2),
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
          ),
        ],
      ),
    );
  }

  String _label(NleCurveType type) {
    switch (type) {
      case NleCurveType.rgbMaster:
        return 'RGB Master Curve';
      case NleCurveType.red:
        return 'Red Channel Curve';
      case NleCurveType.green:
        return 'Green Channel Curve';
      case NleCurveType.blue:
        return 'Blue Channel Curve';
      case NleCurveType.luma:
        return 'Luma Curve';
      case NleCurveType.hueVsSat:
        return 'Hue vs Saturation';
      case NleCurveType.hueVsHue:
        return 'Hue vs Hue';
      case NleCurveType.hueVsLum:
        return 'Hue vs Luminance';
      case NleCurveType.lumVsSat:
        return 'Luminance vs Saturation';
      case NleCurveType.satVsSat:
        return 'Saturation vs Saturation';
    }
  }
}
