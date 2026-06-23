import 'package:nle_editor/domain/motion_templates/motion_template_layer_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/overlays/overlay_motion_models.dart';
import 'package:nle_editor/domain/overlays/overlay_style_models.dart';
import 'package:nle_editor/domain/overlays/overlay_value_models.dart';
import 'package:nle_editor/domain/titles/title_clip_models.dart';
import 'package:nle_editor/domain/titles/title_motion_models.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

class BuiltinMotionTemplateFactory {
  const BuiltinMotionTemplateFactory();

  List<NleMotionTemplatePack> createBuiltInPacks() {
    return [
      _creatorEssentialsPack(),
      _socialCalloutsPack(),
      _cinematicTitlesPack(),
    ];
  }

  NleMotionTemplatePack _creatorEssentialsPack() {
    final now = DateTime.now();

    return NleMotionTemplatePack(
      id: 'builtin_creator_essentials',
      name: 'Creator Essentials',
      description: 'Fast modern titles, hooks, lower thirds, and badges.',
      creator: const NleTemplateCreatorMetadata.builtIn(),
      source: NleTemplateInstallSource.builtIn,
      categories: const [
        NleMotionTemplateCategory.titles,
        NleMotionTemplateCategory.lowerThirds,
        NleMotionTemplateCategory.social,
      ],
      templates: [
        _boldSocialHook(),
        _cleanLowerThird(),
        _creatorBadge(),
      ],
      access: NleMotionTemplateAccess.free,
      installedAt: now,
      version: 1,
    );
  }

  NleMotionTemplatePack _socialCalloutsPack() {
    final now = DateTime.now();

    return NleMotionTemplatePack(
      id: 'builtin_social_callouts',
      name: 'Social Callouts',
      description: 'Arrows, circles, boxes, and highlight motion overlays.',
      creator: const NleTemplateCreatorMetadata.builtIn(),
      source: NleTemplateInstallSource.builtIn,
      categories: const [
        NleMotionTemplateCategory.callouts,
        NleMotionTemplateCategory.arrows,
        NleMotionTemplateCategory.highlights,
      ],
      templates: [
        _arrowHighlight(),
        _circleHighlight(),
        _calloutBoxTemplate(),
      ],
      access: NleMotionTemplateAccess.free,
      installedAt: now,
      version: 1,
    );
  }

  NleMotionTemplatePack _cinematicTitlesPack() {
    final now = DateTime.now();

    return NleMotionTemplatePack(
      id: 'builtin_cinematic_titles',
      name: 'Cinematic Titles',
      description: 'Premium cinematic opening titles and elegant name cards.',
      creator: const NleTemplateCreatorMetadata.builtIn(),
      source: NleTemplateInstallSource.builtIn,
      categories: const [
        NleMotionTemplateCategory.cinematic,
        NleMotionTemplateCategory.titles,
      ],
      templates: [
        _cinematicCenterTitle(),
      ],
      access: NleMotionTemplateAccess.free,
      installedAt: now,
      version: 1,
    );
  }

  NleMotionTemplate _boldSocialHook() {
    const mainTextParam = NleTemplateParameterDefinition(
      id: 'main_text',
      label: 'Main Text',
      description: 'The big hook text.',
      type: NleTemplateParameterType.text,
      defaultValue: NleTemplateParameterValue(
        parameterId: 'main_text',
        type: NleTemplateParameterType.text,
        value: 'WAIT FOR IT',
      ),
      options: [],
      required: true,
    );

    const colorParam = NleTemplateParameterDefinition(
      id: 'accent_color',
      label: 'Accent Color',
      description: 'Main accent color.',
      type: NleTemplateParameterType.color,
      defaultValue: NleTemplateParameterValue(
        parameterId: 'accent_color',
        type: NleTemplateParameterType.color,
        value: NleRgbaColor(r: 1.0, g: 0.88, b: 0.10, a: 1.0),
      ),
      options: [],
      required: true,
    );

    final title = NleTitleClipData.defaultTitle(
      id: 'layer_hook_title',
      text: 'WAIT FOR IT',
    ).copyWith(
      style: const NleTextStyleModel.defaultTitle().copyWith(
        fontSize: 62,
        caseTransform: NleTextCaseTransform.uppercase,
        fillColor: const NleRgbaColor(r: 1.0, g: 0.88, b: 0.10, a: 1.0),
        stroke: const NleTextStrokeStyle(
          enabled: true,
          width: 6,
          color: NleRgbaColor.black(),
        ),
      ),
      motion: const NleTitleMotion.identity().copyWith(
        animationPreset: NleTitleAnimationPreset.scalePop,
      ),
      layout: const NleTitleLayout.center().copyWith(
        box: const NleRectNorm(
          x: 0.08,
          y: 0.14,
          width: 0.84,
          height: 0.20,
        ),
      ),
    );

    return NleMotionTemplate(
      id: 'bold_social_hook',
      packId: 'builtin_creator_essentials',
      name: 'Bold Social Hook',
      description: 'A punchy top-screen hook for Shorts, Reels, and TikTok.',
      categories: const [
        NleMotionTemplateCategory.social,
        NleMotionTemplateCategory.titles,
      ],
      tags: const ['hook', 'viral', 'bold'],
      durationMicros: 3500000,
      aspectMode: NleMotionTemplateAspectMode.any,
      parameters: const [
        mainTextParam,
        colorParam,
      ],
      layers: [
        NleMotionTemplateLayer(
          id: 'layer_hook_title',
          name: 'Hook Title',
          kind: NleMotionTemplateLayerKind.title,
          relativeStartMicros: 0,
          relativeEndMicros: 3500000,
          zIndex: 10,
          titleData: title,
          bindings: const [
            NleTemplateParameterBinding(
              parameterId: 'main_text',
              layerId: 'layer_hook_title',
              propertyPath: 'title.text',
            ),
            NleTemplateParameterBinding(
              parameterId: 'accent_color',
              layerId: 'layer_hook_title',
              propertyPath: 'title.style.fillColor',
            ),
          ],
        ),
      ],
      access: NleMotionTemplateAccess.free,
      marketplaceReady: true,
      version: 1,
    );
  }

  NleMotionTemplate _cleanLowerThird() {
    const nameParam = NleTemplateParameterDefinition(
      id: 'name',
      label: 'Name',
      description: 'Main lower-third name.',
      type: NleTemplateParameterType.text,
      defaultValue: NleTemplateParameterValue(
        parameterId: 'name',
        type: NleTemplateParameterType.text,
        value: 'YOUR NAME',
      ),
      options: [],
      required: true,
    );

    const roleParam = NleTemplateParameterDefinition(
      id: 'role',
      label: 'Role',
      description: 'Secondary lower-third role.',
      type: NleTemplateParameterType.text,
      defaultValue: NleTemplateParameterValue(
        parameterId: 'role',
        type: NleTemplateParameterType.text,
        value: 'CREATOR',
      ),
      options: [],
      required: false,
    );

    final background = NleOverlayClipData.callout(id: 'layer_l3_bg').copyWith(
      name: 'Lower Third Background',
      transform: const NleOverlayTransform.lowerThird(),
      shapeStyle: const NleShapeStyle.calloutBox(),
    );

    final nameTitle = NleTitleClipData.defaultLowerThird(
      id: 'layer_l3_name',
      name: 'YOUR NAME',
      role: 'CREATOR',
    );

    final accentLine = NleOverlayClipData.line(id: 'layer_l3_line').copyWith(
      transform: const NleOverlayTransform.center().copyWith(
        box: const NleRectNorm(
          x: 0.08,
          y: 0.66,
          width: 0.32,
          height: 0.04,
        ),
      ),
      lineStyle: const NleLineStyle.defaultLine().copyWith(
        width: 5,
        color: const NleRgbaColor(r: 1.0, g: 0.85, b: 0.20, a: 1.0),
      ),
    );

    return NleMotionTemplate(
      id: 'clean_lower_third',
      packId: 'builtin_creator_essentials',
      name: 'Clean Lower Third',
      description: 'A professional lower-third with background and accent line.',
      categories: const [
        NleMotionTemplateCategory.lowerThirds,
        NleMotionTemplateCategory.business,
      ],
      tags: const ['lower-third', 'name', 'professional'],
      durationMicros: 5000000,
      aspectMode: NleMotionTemplateAspectMode.any,
      parameters: const [
        nameParam,
        roleParam,
      ],
      layers: [
        NleMotionTemplateLayer(
          id: 'layer_l3_bg',
          name: 'Background',
          kind: NleMotionTemplateLayerKind.overlay,
          relativeStartMicros: 0,
          relativeEndMicros: 5000000,
          zIndex: 1,
          overlayData: background,
          bindings: const [],
        ),
        NleMotionTemplateLayer(
          id: 'layer_l3_line',
          name: 'Accent Line',
          kind: NleMotionTemplateLayerKind.overlay,
          relativeStartMicros: 120000,
          relativeEndMicros: 5000000,
          zIndex: 2,
          overlayData: accentLine,
          bindings: const [],
        ),
        NleMotionTemplateLayer(
          id: 'layer_l3_name',
          name: 'Name Text',
          kind: NleMotionTemplateLayerKind.title,
          relativeStartMicros: 180000,
          relativeEndMicros: 5000000,
          zIndex: 3,
          titleData: nameTitle,
          bindings: const [
            NleTemplateParameterBinding(
              parameterId: 'name',
              layerId: 'layer_l3_name',
              propertyPath: 'title.text',
            ),
            NleTemplateParameterBinding(
              parameterId: 'role',
              layerId: 'layer_l3_name',
              propertyPath: 'title.secondaryText',
            ),
          ],
        ),
      ],
      access: NleMotionTemplateAccess.free,
      marketplaceReady: true,
      version: 1,
    );
  }

  NleMotionTemplate _creatorBadge() {
    final sticker = NleOverlayClipData.sticker(id: 'layer_badge_sticker').copyWith(
      name: 'Creator Badge',
      transform: const NleOverlayTransform.center().copyWith(
        box: const NleRectNorm(
          x: 0.76,
          y: 0.08,
          width: 0.15,
          height: 0.15,
        ),
      ),
    );

    return NleMotionTemplate(
      id: 'creator_badge',
      packId: 'builtin_creator_essentials',
      name: 'Creator Badge',
      description: 'A simple animated badge sticker.',
      categories: const [
        NleMotionTemplateCategory.stickers,
        NleMotionTemplateCategory.social,
      ],
      tags: const ['badge', 'sticker', 'creator'],
      durationMicros: 4000000,
      aspectMode: NleMotionTemplateAspectMode.any,
      parameters: const [],
      layers: [
        NleMotionTemplateLayer(
          id: 'layer_badge_sticker',
          name: 'Sticker',
          kind: NleMotionTemplateLayerKind.overlay,
          relativeStartMicros: 0,
          relativeEndMicros: 4000000,
          zIndex: 5,
          overlayData: sticker,
          bindings: const [],
        ),
      ],
      access: NleMotionTemplateAccess.free,
      marketplaceReady: true,
      version: 1,
    );
  }

  NleMotionTemplate _arrowHighlight() {
    final arrow = NleOverlayClipData.arrow(id: 'layer_arrow').copyWith(
      name: 'Animated Arrow',
    );

    return NleMotionTemplate(
      id: 'arrow_highlight',
      packId: 'builtin_social_callouts',
      name: 'Arrow Highlight',
      description: 'Animated arrow pointing to an object.',
      categories: const [
        NleMotionTemplateCategory.arrows,
        NleMotionTemplateCategory.callouts,
      ],
      tags: const ['arrow', 'point', 'highlight'],
      durationMicros: 3000000,
      aspectMode: NleMotionTemplateAspectMode.any,
      parameters: const [],
      layers: [
        NleMotionTemplateLayer(
          id: 'layer_arrow',
          name: 'Arrow',
          kind: NleMotionTemplateLayerKind.overlay,
          relativeStartMicros: 0,
          relativeEndMicros: 3000000,
          zIndex: 6,
          overlayData: arrow,
          bindings: const [],
        ),
      ],
      access: NleMotionTemplateAccess.free,
      marketplaceReady: true,
      version: 1,
    );
  }

  NleMotionTemplate _circleHighlight() {
    final circle = NleOverlayClipData.circle(id: 'layer_circle').copyWith(
      name: 'Circle Highlight',
      transform: const NleOverlayTransform.center().copyWith(
        box: const NleRectNorm(
          x: 0.34,
          y: 0.28,
          width: 0.32,
          height: 0.32,
        ),
      ),
      shapeStyle: const NleShapeStyle.defaultRect().copyWith(
        shapeType: NleShapeType.circle,
        fillEnabled: false,
        stroke: const NleOverlayStrokeStyle(
          enabled: true,
          color: NleRgbaColor(r: 1.0, g: 0.12, b: 0.12, a: 1.0),
          width: 10,
          cap: NleLineCap.round,
          join: NleLineJoin.round,
        ),
      ),
    );

    return NleMotionTemplate(
      id: 'circle_highlight',
      packId: 'builtin_social_callouts',
      name: 'Circle Highlight',
      description: 'A bold circle highlight for objects and faces.',
      categories: const [
        NleMotionTemplateCategory.highlights,
        NleMotionTemplateCategory.callouts,
      ],
      tags: const ['circle', 'highlight', 'attention'],
      durationMicros: 3500000,
      aspectMode: NleMotionTemplateAspectMode.any,
      parameters: const [],
      layers: [
        NleMotionTemplateLayer(
          id: 'layer_circle',
          name: 'Circle',
          kind: NleMotionTemplateLayerKind.overlay,
          relativeStartMicros: 0,
          relativeEndMicros: 3500000,
          zIndex: 5,
          overlayData: circle,
          bindings: const [],
        ),
      ],
      access: NleMotionTemplateAccess.free,
      marketplaceReady: true,
      version: 1,
    );
  }

  NleMotionTemplate _calloutBoxTemplate() {
    final box = NleOverlayClipData.callout(id: 'layer_callout_box');

    final label = NleTitleClipData.defaultTitle(
      id: 'layer_callout_text',
      text: 'Important detail',
    ).copyWith(
      style: const NleTextStyleModel.defaultTitle().copyWith(
        fontSize: 34,
      ),
      layout: const NleTitleLayout.center().copyWith(
        box: const NleRectNorm(
          x: 0.12,
          y: 0.68,
          width: 0.64,
          height: 0.14,
        ),
      ),
    );

    return NleMotionTemplate(
      id: 'callout_box',
      packId: 'builtin_social_callouts',
      name: 'Callout Box',
      description: 'A clean callout label with animated background.',
      categories: const [
        NleMotionTemplateCategory.callouts,
        NleMotionTemplateCategory.highlights,
      ],
      tags: const ['callout', 'box', 'label'],
      durationMicros: 4000000,
      aspectMode: NleMotionTemplateAspectMode.any,
      parameters: const [
        NleTemplateParameterDefinition(
          id: 'callout_text',
          label: 'Callout Text',
          description: 'Text inside the callout.',
          type: NleTemplateParameterType.text,
          defaultValue: NleTemplateParameterValue(
            parameterId: 'callout_text',
            type: NleTemplateParameterType.text,
            value: 'Important detail',
          ),
          options: [],
          required: true,
        ),
      ],
      layers: [
        NleMotionTemplateLayer(
          id: 'layer_callout_box',
          name: 'Box',
          kind: NleMotionTemplateLayerKind.overlay,
          relativeStartMicros: 0,
          relativeEndMicros: 4000000,
          zIndex: 2,
          overlayData: box,
          bindings: const [],
        ),
        NleMotionTemplateLayer(
          id: 'layer_callout_text',
          name: 'Text',
          kind: NleMotionTemplateLayerKind.title,
          relativeStartMicros: 100000,
          relativeEndMicros: 4000000,
          zIndex: 3,
          titleData: label,
          bindings: const [
            NleTemplateParameterBinding(
              parameterId: 'callout_text',
              layerId: 'layer_callout_text',
              propertyPath: 'title.text',
            ),
          ],
        ),
      ],
      access: NleMotionTemplateAccess.free,
      marketplaceReady: true,
      version: 1,
    );
  }

  NleMotionTemplate _cinematicCenterTitle() {
    final title = NleTitleClipData.defaultTitle(
      id: 'layer_cinematic_title',
      text: 'A NEW STORY',
    ).copyWith(
      style: const NleTextStyleModel.defaultTitle().copyWith(
        fontSize: 58,
        letterSpacing: 5,
        caseTransform: NleTextCaseTransform.uppercase,
      ),
      motion: const NleTitleMotion.identity().copyWith(
        animationPreset: NleTitleAnimationPreset.cinematicSlowZoom,
      ),
    );

    final lineTop = NleOverlayClipData.line(id: 'layer_cinematic_top').copyWith(
      transform: const NleOverlayTransform.center().copyWith(
        box: const NleRectNorm(
          x: 0.25,
          y: 0.36,
          width: 0.50,
          height: 0.03,
        ),
      ),
      lineStyle: const NleLineStyle.defaultLine().copyWith(width: 3),
    );

    final lineBottom =
        NleOverlayClipData.line(id: 'layer_cinematic_bottom').copyWith(
      transform: const NleOverlayTransform.center().copyWith(
        box: const NleRectNorm(
          x: 0.25,
          y: 0.60,
          width: 0.50,
          height: 0.03,
        ),
      ),
      lineStyle: const NleLineStyle.defaultLine().copyWith(width: 3),
    );

    return NleMotionTemplate(
      id: 'cinematic_center_title',
      packId: 'builtin_cinematic_titles',
      name: 'Cinematic Center Title',
      description: 'Elegant cinematic title with slow motion and divider lines.',
      categories: const [
        NleMotionTemplateCategory.cinematic,
        NleMotionTemplateCategory.titles,
      ],
      tags: const ['cinematic', 'title', 'film'],
      durationMicros: 5500000,
      aspectMode: NleMotionTemplateAspectMode.any,
      parameters: const [
        NleTemplateParameterDefinition(
          id: 'title_text',
          label: 'Title Text',
          description: 'Main cinematic title.',
          type: NleTemplateParameterType.text,
          defaultValue: NleTemplateParameterValue(
            parameterId: 'title_text',
            type: NleTemplateParameterType.text,
            value: 'A NEW STORY',
          ),
          options: [],
          required: true,
        ),
      ],
      layers: [
        NleMotionTemplateLayer(
          id: 'layer_cinematic_top',
          name: 'Top Line',
          kind: NleMotionTemplateLayerKind.overlay,
          relativeStartMicros: 0,
          relativeEndMicros: 5500000,
          zIndex: 1,
          overlayData: lineTop,
          bindings: const [],
        ),
        NleMotionTemplateLayer(
          id: 'layer_cinematic_title',
          name: 'Title',
          kind: NleMotionTemplateLayerKind.title,
          relativeStartMicros: 200000,
          relativeEndMicros: 5500000,
          zIndex: 2,
          titleData: title,
          bindings: const [
            NleTemplateParameterBinding(
              parameterId: 'title_text',
              layerId: 'layer_cinematic_title',
              propertyPath: 'title.text',
            ),
          ],
        ),
        NleMotionTemplateLayer(
          id: 'layer_cinematic_bottom',
          name: 'Bottom Line',
          kind: NleMotionTemplateLayerKind.overlay,
          relativeStartMicros: 0,
          relativeEndMicros: 5500000,
          zIndex: 1,
          overlayData: lineBottom,
          bindings: const [],
        ),
      ],
      access: NleMotionTemplateAccess.free,
      marketplaceReady: true,
      version: 1,
    );
  }
}
