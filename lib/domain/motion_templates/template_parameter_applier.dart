import 'package:nle_editor/domain/motion_templates/motion_template_layer_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/titles/title_clip_models.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

class TemplateParameterApplier {
  const TemplateParameterApplier();

  NleMotionTemplateLayer applyValues({
    required NleMotionTemplateLayer layer,
    required List<NleTemplateParameterValue> values,
  }) {
    var title = layer.titleData;
    var overlay = layer.overlayData;

    for (final binding in layer.bindings) {
      final value = values
          .where((item) => item.parameterId == binding.parameterId)
          .firstOrNull;

      if (value == null) continue;

      if (binding.propertyPath.startsWith('title.') && title != null) {
        title = _applyTitleValue(
          title: title,
          path: binding.propertyPath,
          value: value,
        );
      }

      if (binding.propertyPath.startsWith('overlay.') && overlay != null) {
        overlay = _applyOverlayValue(
          overlay: overlay,
          path: binding.propertyPath,
          value: value,
        );
      }
    }

    return NleMotionTemplateLayer(
      id: layer.id,
      name: layer.name,
      kind: layer.kind,
      relativeStartMicros: layer.relativeStartMicros,
      relativeEndMicros: layer.relativeEndMicros,
      zIndex: layer.zIndex,
      titleData: title,
      overlayData: overlay,
      bindings: layer.bindings,
    );
  }

  NleTitleClipData _applyTitleValue({
    required NleTitleClipData title,
    required String path,
    required NleTemplateParameterValue value,
  }) {
    switch (path) {
      case 'title.text':
        return title.copyWith(text: value.value?.toString() ?? title.text);

      case 'title.secondaryText':
        return title.copyWith(
          secondaryText: value.value?.toString() ?? title.secondaryText,
        );

      case 'title.style.fillColor':
        if (value.value is NleRgbaColor) {
          return title.copyWith(
            style: title.style.copyWith(
              fillColor: value.value as NleRgbaColor,
            ),
          );
        }
        return title;

      case 'title.style.fontSize':
        if (value.value is num) {
          return title.copyWith(
            style: title.style.copyWith(
              fontSize: (value.value as num).toDouble(),
            ),
          );
        }
        return title;

      case 'title.style.font.family':
        return title.copyWith(
          style: title.style.copyWith(
            font: title.style.font.copyWith(
              family: value.value?.toString(),
            ),
          ),
        );

      case 'title.style.caseTransform':
        final raw = value.value?.toString();
        final transform = NleTextCaseTransform.values
            .where((item) => item.name == raw)
            .firstOrNull;

        if (transform == null) return title;
        return title.copyWith(
          style: title.style.copyWith(caseTransform: transform),
        );

      default:
        return title;
    }
  }

  NleOverlayClipData _applyOverlayValue({
    required NleOverlayClipData overlay,
    required String path,
    required NleTemplateParameterValue value,
  }) {
    switch (path) {
      case 'overlay.name':
        return overlay.copyWith(name: value.value?.toString());

      case 'overlay.shapeStyle.fillColor':
        if (value.value is NleRgbaColor && overlay.shapeStyle != null) {
          return overlay.copyWith(
            shapeStyle: overlay.shapeStyle!.copyWith(
              fillColor: value.value as NleRgbaColor,
            ),
          );
        }
        return overlay;

      case 'overlay.shapeStyle.stroke.color':
        if (value.value is NleRgbaColor && overlay.shapeStyle != null) {
          return overlay.copyWith(
            shapeStyle: overlay.shapeStyle!.copyWith(
              stroke: overlay.shapeStyle!.stroke.copyWith(
                color: value.value as NleRgbaColor,
              ),
            ),
          );
        }
        return overlay;

      case 'overlay.lineStyle.color':
        if (value.value is NleRgbaColor && overlay.lineStyle != null) {
          return overlay.copyWith(
            lineStyle: overlay.lineStyle!.copyWith(
              color: value.value as NleRgbaColor,
            ),
          );
        }
        return overlay;

      default:
        return overlay;
    }
  }
}
