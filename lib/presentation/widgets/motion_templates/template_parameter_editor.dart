import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';
import 'package:nle_editor/presentation/providers/motion_template_providers.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';

class TemplateParameterEditor extends ConsumerWidget {
  final NleMotionTemplate template;
  final VoidCallback onApplied;
  final String projectId;
  final String trackId;
  final int timelineStartMicros;

  const TemplateParameterEditor({
    super.key,
    required this.template,
    required this.onApplied,
    required this.projectId,
    required this.trackId,
    required this.timelineStartMicros,
  });

  static const List<NleRgbaColor> presetColors = [
    NleRgbaColor(r: 1.0, g: 0.18, b: 0.18, a: 1.0), // Red
    NleRgbaColor(r: 0.18, g: 0.8, b: 0.18, a: 1.0), // Green
    NleRgbaColor(r: 0.18, g: 0.36, b: 1.0, a: 1.0), // Blue
    NleRgbaColor(r: 1.0, g: 0.88, b: 0.10, a: 1.0), // Yellow/Gold
    NleRgbaColor(r: 0.8, g: 0.18, b: 1.0, a: 1.0),  // Purple
    NleRgbaColor(r: 1.0, g: 1.0, b: 1.0, a: 1.0),  // White
    NleRgbaColor(r: 0.0, g: 0.0, b: 0.0, a: 1.0),  // Black
    NleRgbaColor(r: 0.5, g: 0.5, b: 0.5, a: 1.0),  // Grey
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(motionTemplateControllerProvider);
    final controller = ref.read(motionTemplateControllerProvider.notifier);

    final edited = browserState.editedParameters[template.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  template.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textMuted),
              onPressed: onApplied,
            ),
          ],
        ),
        const Divider(color: AppTheme.borderSubtle, height: 24),
        if (template.parameters.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No editable parameters for this template.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: template.parameters.length,
              itemBuilder: (context, index) {
                final param = template.parameters[index];
                final current = edited.where((e) => e.parameterId == param.id).firstOrNull ??
                    param.defaultValue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildParameterField(context, param, current, controller),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PremiumRadius.lg),
              ),
            ),
            icon: const Icon(Icons.add_to_photos_rounded, size: 18),
            label: const Text(
              'Apply to Playhead',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            onPressed: () async {
              await controller.applyTemplate(
                projectId: projectId,
                trackId: trackId,
                timelineStartMicros: timelineStartMicros,
                templateId: template.id,
              );
              onApplied();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParameterField(
    BuildContext context,
    NleTemplateParameterDefinition param,
    NleTemplateParameterValue current,
    MotionTemplateController controller,
  ) {
    switch (param.type) {
      case NleTemplateParameterType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              param.label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: TextEditingController(text: current.value?.toString() ?? '')
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: current.value?.toString().length ?? 0),
                ),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D1320),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: param.description,
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PremiumRadius.md),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PremiumRadius.md),
                  borderSide: const BorderSide(color: AppTheme.accentPrimary),
                ),
              ),
              onChanged: (val) {
                controller.updateParameterValue(
                  template.id,
                  param.id,
                  NleTemplateParameterType.text,
                  val,
                );
              },
            ),
          ],
        );

      case NleTemplateParameterType.color:
        final selectedColor = current.value as NleRgbaColor? ?? const NleRgbaColor.white();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              param.label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetColors.map((color) {
                final isSelected = selectedColor.r == color.r &&
                    selectedColor.g == color.g &&
                    selectedColor.b == color.b &&
                    selectedColor.a == color.a;

                return GestureDetector(
                  onTap: () {
                    controller.updateParameterValue(
                      template.id,
                      param.id,
                      NleTemplateParameterType.color,
                      color,
                    );
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(color.toArgbInt()),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.accentPrimary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );

      case NleTemplateParameterType.number:
        final val = (current.value as num?)?.toDouble() ?? 0.0;
        final minVal = param.min ?? 0.0;
        final maxVal = param.max ?? 100.0;

        return InspectorSliderRow(
          label: param.label,
          value: val,
          min: minVal,
          max: maxVal,
          onChanged: (newVal) {
            controller.updateParameterValue(
              template.id,
              param.id,
              NleTemplateParameterType.number,
              newVal,
            );
          },
        );

      case NleTemplateParameterType.boolean:
        final isTrue = current.value == true;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              param.label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Switch(
              value: isTrue,
              activeColor: AppTheme.accentPrimary,
              onChanged: (newVal) {
                controller.updateParameterValue(
                  template.id,
                  param.id,
                  NleTemplateParameterType.boolean,
                  newVal,
                );
              },
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
