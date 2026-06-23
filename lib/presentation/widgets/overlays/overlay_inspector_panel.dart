import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/overlays/overlay_motion_models.dart';
import 'package:nle_editor/domain/overlays/overlay_style_models.dart';
import 'package:nle_editor/domain/overlays/overlay_value_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';
import 'package:nle_editor/presentation/controllers/overlay_clip_controller.dart';
import 'package:nle_editor/presentation/providers/overlay_clip_controller_provider.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_section_card.dart';
import 'package:nle_editor/presentation/widgets/inspector/inspector_slider_row.dart';

class OverlayInspectorPanel extends ConsumerWidget {
  final String clipId;

  const OverlayInspectorPanel({
    super.key,
    required this.clipId,
  });

  static const List<NleRgbaColor> presetColors = [
    NleRgbaColor(r: 1.0, g: 0.18, b: 0.18, a: 1.0), // Red
    NleRgbaColor(r: 0.18, g: 0.8, b: 0.18, a: 1.0), // Green
    NleRgbaColor(r: 0.18, g: 0.36, b: 1.0, a: 1.0), // Blue
    NleRgbaColor(r: 1.0, g: 0.8, b: 0.0, a: 1.0),  // Yellow
    NleRgbaColor(r: 0.8, g: 0.18, b: 1.0, a: 1.0),  // Purple
    NleRgbaColor(r: 1.0, g: 1.0, b: 1.0, a: 1.0),  // White
    NleRgbaColor(r: 0.0, g: 0.0, b: 0.0, a: 1.0),  // Black
    NleRgbaColor(r: 0.5, g: 0.5, b: 0.5, a: 1.0),  // Grey
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(overlayClipControllerProvider(clipId));
    final controller = ref.read(overlayClipControllerProvider(clipId).notifier);

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final data = state.data;
    if (data == null) {
      return const Center(
        child: Text(
          'No overlay clip loaded',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, data, controller),
          const SizedBox(height: PremiumSpacing.md),
          _buildTransformSection(data, controller),
          const SizedBox(height: PremiumSpacing.md),
          if (data.shapeStyle != null) ...[
            _buildShapeStyleSection(data, controller),
            const SizedBox(height: PremiumSpacing.md),
          ],
          if (data.lineStyle != null) ...[
            _buildLineStyleSection(data, controller),
            const SizedBox(height: PremiumSpacing.md),
          ],
          if (data.stickerStyle != null) ...[
            _buildStickerStyleSection(data, controller),
            const SizedBox(height: PremiumSpacing.md),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    NleOverlayClipData data,
    OverlayClipController controller,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Type: ${data.kind.name.toUpperCase()}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            data.locked ? Icons.lock : Icons.lock_open_outlined,
            color: data.locked ? AppTheme.accentPrimary : AppTheme.textMuted,
            size: 18,
          ),
          onPressed: () => controller.setLocked(!data.locked),
        ),
        IconButton(
          icon: Icon(
            data.hidden ? Icons.visibility_off : Icons.visibility,
            color: data.hidden ? AppTheme.accentPrimary : AppTheme.textMuted,
            size: 18,
          ),
          onPressed: () => controller.setHidden(!data.hidden),
        ),
      ],
    );
  }

  Widget _buildTransformSection(
    NleOverlayClipData data,
    OverlayClipController controller,
  ) {
    final t = data.transform;

    return InspectorSectionCard(
      icon: Icons.transform_rounded,
      title: 'Layout & Transform',
      children: [
        InspectorSliderRow(
          label: 'Scale',
          value: t.scale,
          min: 0.1,
          max: 4.0,
          onChanged: (val) {
            controller.setTransform(t.copyWith(scale: val));
          },
        ),
        InspectorSliderRow(
          label: 'Rotation',
          value: t.rotationDegrees,
          min: -180.0,
          max: 180.0,
          onChanged: (val) {
            controller.setTransform(t.copyWith(rotationDegrees: val));
          },
        ),
        InspectorSliderRow(
          label: 'Opacity',
          value: t.opacity,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            controller.setTransform(t.copyWith(opacity: val));
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Respect Safe Area',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Switch(
              value: t.respectSafeArea,
              activeColor: AppTheme.accentPrimary,
              onChanged: (val) {
                controller.setTransform(t.copyWith(respectSafeArea: val));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShapeStyleSection(
    NleOverlayClipData data,
    OverlayClipController controller,
  ) {
    final style = data.shapeStyle!;

    return InspectorSectionCard(
      icon: Icons.format_paint_rounded,
      title: 'Shape Styling',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fill Shape',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Switch(
              value: style.fillEnabled,
              activeColor: AppTheme.accentPrimary,
              onChanged: (val) {
                controller.setShapeStyle(style.copyWith(fillEnabled: val));
              },
            ),
          ],
        ),
        if (style.fillEnabled) ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fill Color',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildColorPicker(
            selectedColor: style.fillColor,
            onColorSelected: (color) {
              controller.setShapeStyle(style.copyWith(fillColor: color));
            },
          ),
        ],
        const Divider(color: AppTheme.borderSubtle, height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stroke Outline',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Switch(
              value: style.stroke.enabled,
              activeColor: AppTheme.accentPrimary,
              onChanged: (val) {
                controller.setShapeStyle(
                  style.copyWith(stroke: style.stroke.copyWith(enabled: val)),
                );
              },
            ),
          ],
        ),
        if (style.stroke.enabled) ...[
          InspectorSliderRow(
            label: 'Stroke Width',
            value: style.stroke.width,
            min: 0.0,
            max: 20.0,
            onChanged: (val) {
              controller.setShapeStyle(
                style.copyWith(stroke: style.stroke.copyWith(width: val)),
              );
            },
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Stroke Color',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildColorPicker(
            selectedColor: style.stroke.color,
            onColorSelected: (color) {
              controller.setShapeStyle(
                style.copyWith(stroke: style.stroke.copyWith(color: color)),
              );
            },
          ),
        ],
        const Divider(color: AppTheme.borderSubtle, height: 16),
        InspectorSliderRow(
          label: 'Corner Radius',
          value: style.cornerRadius,
          min: 0.0,
          max: 100.0,
          onChanged: (val) {
            controller.setShapeStyle(style.copyWith(cornerRadius: val));
          },
        ),
      ],
    );
  }

  Widget _buildLineStyleSection(
    NleOverlayClipData data,
    OverlayClipController controller,
  ) {
    final style = data.lineStyle!;

    return InspectorSectionCard(
      icon: Icons.linear_scale_rounded,
      title: 'Line & Arrow Styling',
      children: [
        InspectorSliderRow(
          label: 'Thickness',
          value: style.width,
          min: 1.0,
          max: 30.0,
          onChanged: (val) {
            controller.setLineStyle(style.copyWith(width: val));
          },
        ),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Line Color',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildColorPicker(
          selectedColor: style.color,
          onColorSelected: (color) {
            controller.setLineStyle(style.copyWith(color: color));
          },
        ),
        const Divider(color: AppTheme.borderSubtle, height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dashed Line',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Switch(
              value: style.dashed,
              activeColor: AppTheme.accentPrimary,
              onChanged: (val) {
                controller.setLineStyle(style.copyWith(dashed: val));
              },
            ),
          ],
        ),
        if (style.dashed) ...[
          InspectorSliderRow(
            label: 'Dash Length',
            value: style.dashLength,
            min: 5.0,
            max: 50.0,
            onChanged: (val) {
              controller.setLineStyle(style.copyWith(dashLength: val));
            },
          ),
          InspectorSliderRow(
            label: 'Gap Length',
            value: style.gapLength,
            min: 2.0,
            max: 40.0,
            onChanged: (val) {
              controller.setLineStyle(style.copyWith(gapLength: val));
            },
          ),
        ],
        const Divider(color: AppTheme.borderSubtle, height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Arrow Start',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Switch(
              value: style.arrowStart,
              activeColor: AppTheme.accentPrimary,
              onChanged: (val) {
                controller.setLineStyle(style.copyWith(arrowStart: val));
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Arrow End',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Switch(
              value: style.arrowEnd,
              activeColor: AppTheme.accentPrimary,
              onChanged: (val) {
                controller.setLineStyle(style.copyWith(arrowEnd: val));
              },
            ),
          ],
        ),
        if (style.arrowStart || style.arrowEnd) ...[
          InspectorSliderRow(
            label: 'Arrow Head Size',
            value: style.arrowSize,
            min: 5.0,
            max: 60.0,
            onChanged: (val) {
              controller.setLineStyle(style.copyWith(arrowSize: val));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStickerStyleSection(
    NleOverlayClipData data,
    OverlayClipController controller,
  ) {
    final style = data.stickerStyle!;

    return InspectorSectionCard(
      icon: Icons.emoji_emotions_rounded,
      title: 'Sticker Settings',
      children: [
        InspectorSliderRow(
          label: 'Opacity',
          value: style.opacity,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            controller.setStickerStyle(style.copyWith(opacity: val));
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Keep Aspect Ratio',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Switch(
              value: style.preserveAspectRatio,
              activeColor: AppTheme.accentPrimary,
              onChanged: (val) {
                controller.setStickerStyle(style.copyWith(preserveAspectRatio: val));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker({
    required NleRgbaColor selectedColor,
    required ValueChanged<NleRgbaColor> onColorSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presetColors.map((color) {
        final isSelected = selectedColor.r == color.r &&
            selectedColor.g == color.g &&
            selectedColor.b == color.b &&
            selectedColor.a == color.a;

        return GestureDetector(
          onTap: () => onColorSelected(color),
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
    );
  }
}
