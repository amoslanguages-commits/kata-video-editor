import 'package:uuid/uuid.dart';

import 'package:nle_editor/domain/titles/title_clip_models.dart';
import 'package:nle_editor/domain/titles/title_motion_models.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

class TitleTemplateFactory {
  static const _uuid = Uuid();

  const TitleTemplateFactory();

  NleTitleClipData create(NleTitleTemplateId template) {
    final id = _uuid.v4();

    switch (template) {
      case NleTitleTemplateId.basicTitle:
        return NleTitleClipData.defaultTitle(id: id);

      case NleTitleTemplateId.cinematicCenter:
        return NleTitleClipData.defaultTitle(
          id: id,
          text: 'CINEMATIC TITLE',
        ).copyWith(
          templateId: template,
          style: const NleTextStyleModel.defaultTitle().copyWith(
            fontSize: 64.0,
            letterSpacing: 3.0,
            caseTransform: NleTextCaseTransform.uppercase,
            shadow: const NleTextShadowStyle.soft(),
          ),
          motion: const NleTitleMotion.identity().copyWith(
            animationPreset: NleTitleAnimationPreset.cinematicSlowZoom,
          ),
        );

      case NleTitleTemplateId.lowerThirdClean:
        return NleTitleClipData.defaultLowerThird(id: id).copyWith(
          templateId: template,
        );

      case NleTitleTemplateId.lowerThirdBold:
        return NleTitleClipData.defaultLowerThird(
          id: id,
          name: 'BOLD NAME',
          role: 'CREATOR / DIRECTOR',
        ).copyWith(
          templateId: template,
          style: const NleTextStyleModel.defaultTitle().copyWith(
            fontSize: 52.0,
            caseTransform: NleTextCaseTransform.uppercase,
            background: const NleTextBackgroundStyle.darkPill(),
          ),
        );

      case NleTitleTemplateId.socialHook:
        return NleTitleClipData.defaultTitle(
          id: id,
          text: 'WAIT FOR IT',
        ).copyWith(
          kind: NleTextClipKind.title,
          templateId: template,
          layout: const NleTitleLayout.center().copyWith(
            box: const NleRectNorm(
              x: 0.08,
              y: 0.16,
              width: 0.84,
              height: 0.18,
            ),
          ),
          style: const NleTextStyleModel.defaultTitle().copyWith(
            fontSize: 58.0,
            caseTransform: NleTextCaseTransform.uppercase,
            stroke: const NleTextStrokeStyle(
              enabled: true,
              width: 5.0,
              color: NleRgbaColor.black(),
            ),
            shadow: const NleTextShadowStyle.soft(),
          ),
          motion: const NleTitleMotion.identity().copyWith(
            animationPreset: NleTitleAnimationPreset.scalePop,
          ),
        );

      case NleTitleTemplateId.subtitleCard:
        return NleTitleClipData.defaultTitle(
          id: id,
          text: 'This is your subtitle text',
        ).copyWith(
          kind: NleTextClipKind.caption,
          templateId: template,
          layout: const NleTitleLayout.center().copyWith(
            box: const NleRectNorm(
              x: 0.08,
              y: 0.78,
              width: 0.84,
              height: 0.14,
            ),
          ),
          style: const NleTextStyleModel.defaultTitle().copyWith(
            fontSize: 32.0,
            background: const NleTextBackgroundStyle.darkPill(),
          ),
        );

      case NleTitleTemplateId.nameTag:
        return NleTitleClipData.defaultTitle(
          id: id,
          text: '@username',
        ).copyWith(
          kind: NleTextClipKind.label,
          templateId: template,
          layout: const NleTitleLayout.lowerThird().copyWith(
            box: const NleRectNorm(
              x: 0.06,
              y: 0.08,
              width: 0.50,
              height: 0.12,
            ),
          ),
          style: const NleTextStyleModel.defaultTitle().copyWith(
            fontSize: 34.0,
            background: const NleTextBackgroundStyle.darkPill(),
          ),
        );

      case NleTitleTemplateId.breakingNews:
        return NleTitleClipData.defaultLowerThird(
          id: id,
          name: 'BREAKING NEWS',
          role: 'Add your headline here',
        ).copyWith(
          templateId: template,
          style: const NleTextStyleModel.defaultTitle().copyWith(
            fontSize: 38.0,
            fillColor: const NleRgbaColor(r: 1.0, g: 1.0, b: 1.0, a: 1.0),
            background: const NleTextBackgroundStyle(
              enabled: true,
              color: NleRgbaColor(r: 0.90, g: 0.05, b: 0.05, a: 0.92),
              radius: 8.0,
              paddingX: 20.0,
              paddingY: 10.0,
            ),
          ),
          secondaryStyle: const NleTextStyleModel.defaultTitle().copyWith(
            fontSize: 28.0,
            background: const NleTextBackgroundStyle(
              enabled: true,
              color: NleRgbaColor(r: 0.0, g: 0.0, b: 0.0, a: 0.72),
              radius: 8.0,
              paddingX: 20.0,
              paddingY: 10.0,
            ),
          ),
        );
    }
  }
}
