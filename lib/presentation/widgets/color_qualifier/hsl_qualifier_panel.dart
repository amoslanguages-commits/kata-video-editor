import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';
import 'package:nle_editor/presentation/providers/secondary_grade_controller_provider.dart';
import 'package:nle_editor/presentation/widgets/color_qualifier/qualifier_range_slider.dart';
import 'package:nle_editor/presentation/widgets/color_qualifier/secondary_correction_panel.dart';

class HslQualifierPanel extends ConsumerWidget {
  final String? selectedClipId;

  const HslQualifierPanel({
    super.key,
    required this.selectedClipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipId = selectedClipId;

    if (clipId == null) {
      return const Center(
        child: Text(
          'Select a clip to use qualifiers.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final state = ref.watch(secondaryGradeControllerProvider(clipId));
    final controller = ref.read(
      secondaryGradeControllerProvider(clipId).notifier,
    );

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final layer = state.selectedLayer;

    return ListView(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'HSL Qualifier',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: controller.addEmptyLayer,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add secondary',
            ),
            IconButton(
              onPressed: controller.reset,
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'Reset secondaries',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LayerChips(
          layers: state.stack.layers,
          selectedId: state.selectedLayerId,
          onSelected: controller.selectLayer,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            controller.setEyedropperActive(!state.eyedropperActive);
          },
          icon: Icon(
            state.eyedropperActive
                ? Icons.colorize_rounded
                : Icons.colorize_outlined,
          ),
          label: Text(
            state.eyedropperActive
                ? 'Tap preview to pick color'
                : 'Eyedropper',
          ),
        ),
        const SizedBox(height: 12),
        if (layer == null)
          const _NoLayerState()
        else
          _QualifierEditor(
            layer: layer,
            onUpdate: controller.updateSelectedLayer,
            onDelete: controller.removeSelectedLayer,
          ),
      ],
    );
  }
}

class _LayerChips extends StatelessWidget {
  final List<NleSecondaryGradeLayer> layers;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _LayerChips({
    required this.layers,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (layers.isEmpty) {
      return const Text(
        'No secondary layer yet. Use eyedropper or +.',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: layers.map((layer) {
        return ChoiceChip(
          selected: layer.id == selectedId,
          label: Text(layer.name),
          onSelected: (_) => onSelected(layer.id),
        );
      }).toList(),
    );
  }
}

class _NoLayerState extends StatelessWidget {
  const _NoLayerState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: const Text(
        'Create a secondary correction layer, then pick a color from the preview.',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QualifierEditor extends StatelessWidget {
  final NleSecondaryGradeLayer layer;
  final ValueChanged<NleSecondaryGradeLayer> onUpdate;
  final VoidCallback onDelete;

  const _QualifierEditor({
    required this.layer,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final q = layer.qualifier;

    return Column(
      children: [
        Container(
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
                      layer.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Switch(
                    value: layer.enabled,
                    onChanged: (value) {
                      onUpdate(layer.copyWith(enabled: value));
                    },
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SegmentedButton<NleQualifierViewMode>(
                segments: const [
                  ButtonSegment(
                    value: NleQualifierViewMode.normal,
                    label: Text('Normal'),
                  ),
                  ButtonSegment(
                    value: NleQualifierViewMode.matte,
                    label: Text('Matte'),
                  ),
                  ButtonSegment(
                    value: NleQualifierViewMode.overlay,
                    label: Text('Overlay'),
                  ),
                ],
                selected: {q.viewMode},
                onSelectionChanged: (set) {
                  onUpdate(
                    layer.copyWith(
                      qualifier: q.copyWith(viewMode: set.first),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              QualifierRangeSlider(
                label: 'Hue',
                value: q.hue,
                onChanged: (value) {
                  onUpdate(
                    layer.copyWith(
                      qualifier: q.copyWith(hue: value),
                    ),
                  );
                },
              ),
              QualifierRangeSlider(
                label: 'Sat',
                value: q.saturation,
                onChanged: (value) {
                  onUpdate(
                    layer.copyWith(
                      qualifier: q.copyWith(saturation: value),
                    ),
                  );
                },
              ),
              QualifierRangeSlider(
                label: 'Lum',
                value: q.luminance,
                onChanged: (value) {
                  onUpdate(
                    layer.copyWith(
                      qualifier: q.copyWith(luminance: value),
                    ),
                  );
                },
              ),
              _SliderRow(
                label: 'Clean B',
                value: q.cleanBlack,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  onUpdate(
                    layer.copyWith(
                      qualifier: q.copyWith(cleanBlack: value),
                    ),
                  );
                },
              ),
              _SliderRow(
                label: 'Clean W',
                value: q.cleanWhite,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  onUpdate(
                    layer.copyWith(
                      qualifier: q.copyWith(cleanWhite: value),
                    ),
                  );
                },
              ),
              _SliderRow(
                label: 'Blur',
                value: q.blur,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  onUpdate(
                    layer.copyWith(
                      qualifier: q.copyWith(blur: value),
                    ),
                  );
                },
              ),
              SwitchListTile(
                value: q.invert,
                onChanged: (value) {
                  onUpdate(
                    layer.copyWith(
                      qualifier: q.copyWith(invert: value),
                    ),
                  );
                },
                title: const Text(
                  'Invert matte',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(PremiumSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1320),
            borderRadius: BorderRadius.circular(PremiumRadius.lg),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: SecondaryCorrectionPanel(
            correction: layer.correction,
            onChanged: (correction) {
              onUpdate(layer.copyWith(correction: correction));
            },
          ),
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
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
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
        SizedBox(
          width: 42,
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
      ],
    );
  }
}
