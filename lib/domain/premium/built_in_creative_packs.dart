import 'package:nle_editor/domain/premium/creative_pack.dart';
import 'package:nle_editor/domain/premium/premium_feature.dart';

class BuiltInCreativePacks {
  BuiltInCreativePacks._();

  static List<CreativePack> all() {
    return [
      _viralTextPack(),
      _cinematicColorPack(),
      _creatorEffectsPack(),
      _smoothTransitionsPack(),
      _exportPresetPack(),
      _socialTemplatePack(),
    ];
  }

  static CreativePack _viralTextPack() {
    const packId = 'pack_text_viral_titles';

    return CreativePack(
      id: packId,
      type: CreativePackType.text,
      title: 'Viral Titles',
      subtitle: 'Captions that look social-ready',
      description: 'Bold captions, punchy hooks, and premium title styles.',
      version: '1.0.0',
      author: 'Kata',
      proOnly: true,
      requiredFeatureId: PremiumFeatureId.premiumTextStyles,
      tags: const ['text', 'caption', 'viral', 'titles'],
      items: const [
        CreativePackItem(
          id: 'text_bold_hook',
          packId: packId,
          type: CreativePackItemType.textPreset,
          title: 'Bold Hook',
          description: 'Large bold caption with stroke and shadow.',
          proOnly: false,
          payload: {
            'fontSize': 84,
            'color': '#FFFFFFFF',
            'opacity': 1.0,
            'strokeColor': '#FF000000',
            'strokeWidth': 5.0,
            'shadowEnabled': true,
            'shadowColor': '#AA000000',
            'shadowBlur': 10.0,
            'backgroundEnabled': false,
            'alignment': 'center',
          },
          tags: ['text', 'free'],
        ),
        CreativePackItem(
          id: 'text_luxury_title',
          packId: packId,
          type: CreativePackItemType.textPreset,
          title: 'Luxury Title',
          description: 'Premium cinematic title with soft background.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumTextStyles,
          payload: {
            'fontSize': 72,
            'color': '#FFFFF1D0',
            'opacity': 1.0,
            'strokeColor': '#33000000',
            'strokeWidth': 1.0,
            'shadowEnabled': true,
            'shadowColor': '#99000000',
            'shadowBlur': 18.0,
            'backgroundEnabled': true,
            'backgroundColor': '#44130F08',
            'backgroundRadius': 24.0,
            'alignment': 'center',
          },
          tags: ['text', 'premium', 'luxury'],
        ),
        CreativePackItem(
          id: 'text_neon_caption',
          packId: packId,
          type: CreativePackItemType.textPreset,
          title: 'Neon Caption',
          description: 'Bright creator caption for energetic edits.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumTextStyles,
          payload: {
            'fontSize': 76,
            'color': '#FF00E5FF',
            'opacity': 1.0,
            'strokeColor': '#FF00111A',
            'strokeWidth': 4.0,
            'shadowEnabled': true,
            'shadowColor': '#CC00E5FF',
            'shadowBlur': 20.0,
            'backgroundEnabled': false,
            'alignment': 'center',
          },
          tags: ['text', 'premium', 'neon'],
        ),
      ],
    );
  }

  static CreativePack _cinematicColorPack() {
    const packId = 'pack_color_cinematic';

    return CreativePack(
      id: packId,
      type: CreativePackType.color,
      title: 'Cinematic Color',
      subtitle: 'Premium color moods',
      description: 'Fast cinematic color presets for travel, product, and drama edits.',
      version: '1.0.0',
      author: 'Kata',
      proOnly: true,
      requiredFeatureId: PremiumFeatureId.premiumColorPresets,
      tags: const ['color', 'cinematic', 'lut'],
      items: const [
        CreativePackItem(
          id: 'color_clean_pop',
          packId: packId,
          type: CreativePackItemType.colorPreset,
          title: 'Clean Pop',
          description: 'Bright clean social-media look.',
          proOnly: false,
          payload: {
            'brightness': 0.03,
            'contrast': 1.12,
            'saturation': 1.15,
            'temperature': 0.0,
            'tint': 0.0,
          },
          tags: ['color', 'free'],
        ),
        CreativePackItem(
          id: 'color_gold_film',
          packId: packId,
          type: CreativePackItemType.colorPreset,
          title: 'Gold Film',
          description: 'Warm premium film-style grade.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumColorPresets,
          payload: {
            'brightness': -0.02,
            'contrast': 1.22,
            'saturation': 0.92,
            'temperature': 0.18,
            'tint': 0.03,
          },
          tags: ['color', 'premium', 'film'],
        ),
        CreativePackItem(
          id: 'color_moody_blue',
          packId: packId,
          type: CreativePackItemType.colorPreset,
          title: 'Moody Blue',
          description: 'Cool dramatic grade for emotional edits.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumColorPresets,
          payload: {
            'brightness': -0.06,
            'contrast': 1.28,
            'saturation': 0.82,
            'temperature': -0.22,
            'tint': 0.02,
          },
          tags: ['color', 'premium', 'moody'],
        ),
      ],
    );
  }

  static CreativePack _creatorEffectsPack() {
    const packId = 'pack_effect_creator';

    return CreativePack(
      id: packId,
      type: CreativePackType.effects,
      title: 'Creator Effects',
      subtitle: 'Fast effects for short videos',
      description: 'Premium visual settings for punchy short-form edits.',
      version: '1.0.0',
      author: 'Kata',
      proOnly: true,
      requiredFeatureId: PremiumFeatureId.premiumEffects,
      tags: const ['effects', 'creator', 'shorts'],
      items: const [
        CreativePackItem(
          id: 'effect_soft_zoom',
          packId: packId,
          type: CreativePackItemType.effectPreset,
          title: 'Soft Zoom',
          description: 'Subtle scale and contrast boost.',
          proOnly: false,
          payload: {
            'scale': 1.08,
            'rotation': 0.0,
            'opacity': 1.0,
            'brightness': 0.02,
            'contrast': 1.08,
            'saturation': 1.05,
          },
          tags: ['effect', 'free'],
        ),
        CreativePackItem(
          id: 'effect_flash_pop',
          packId: packId,
          type: CreativePackItemType.effectPreset,
          title: 'Flash Pop',
          description: 'Punchy bright flash-style look.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumEffects,
          payload: {
            'scale': 1.0,
            'rotation': 0.0,
            'opacity': 1.0,
            'brightness': 0.12,
            'contrast': 1.35,
            'saturation': 1.30,
          },
          tags: ['effect', 'premium', 'flash'],
        ),
        CreativePackItem(
          id: 'effect_dream_blur_foundation',
          packId: packId,
          type: CreativePackItemType.effectPreset,
          title: 'Dream Look',
          description: 'Soft dreamy grade foundation.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumEffects,
          payload: {
            'scale': 1.02,
            'rotation': 0.0,
            'opacity': 0.96,
            'brightness': 0.05,
            'contrast': 0.92,
            'saturation': 0.85,
          },
          tags: ['effect', 'premium', 'dream'],
        ),
      ],
    );
  }

  static CreativePack _smoothTransitionsPack() {
    const packId = 'pack_transition_smooth';

    return CreativePack(
      id: packId,
      type: CreativePackType.transitions,
      title: 'Smooth Transitions',
      subtitle: 'Clean movement between clips',
      description: 'Dissolves, fades, pushes, and social-ready movement transitions.',
      version: '1.0.0',
      author: 'Kata',
      proOnly: true,
      requiredFeatureId: PremiumFeatureId.premiumTransitions,
      tags: const ['transition', 'smooth'],
      items: const [
        CreativePackItem(
          id: 'transition_clean_dissolve',
          packId: packId,
          type: CreativePackItemType.transitionPreset,
          title: 'Clean Dissolve',
          description: 'Simple smooth crossfade.',
          proOnly: false,
          payload: {
            'transitionType': 'dissolve',
            'durationMicros': 500000,
            'easing': 'smooth',
            'direction': 'none',
          },
          tags: ['transition', 'free'],
        ),
        CreativePackItem(
          id: 'transition_luxury_fade',
          packId: packId,
          type: CreativePackItemType.transitionPreset,
          title: 'Luxury Fade',
          description: 'Premium slow fade for cinematic edits.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumTransitions,
          payload: {
            'transitionType': 'fade_black',
            'durationMicros': 800000,
            'easing': 'ease_in_out',
            'direction': 'none',
          },
          tags: ['transition', 'premium', 'cinematic'],
        ),
        CreativePackItem(
          id: 'transition_social_push',
          packId: packId,
          type: CreativePackItemType.transitionPreset,
          title: 'Social Push',
          description: 'Fast push transition for vertical videos.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumTransitions,
          payload: {
            'transitionType': 'push_left',
            'durationMicros': 350000,
            'easing': 'ease_out',
            'direction': 'left',
          },
          tags: ['transition', 'premium', 'social'],
        ),
      ],
    );
  }

  static CreativePack _exportPresetPack() {
    const packId = 'pack_export_creator';

    return CreativePack(
      id: packId,
      type: CreativePackType.export,
      title: 'Creator Export',
      subtitle: 'Ready export settings',
      description: 'Export presets for Reels, Shorts, TikTok, and high quality archive.',
      version: '1.0.0',
      author: 'Kata',
      proOnly: false,
      tags: const ['export', 'social'],
      items: const [
        CreativePackItem(
          id: 'export_social_1080p',
          packId: packId,
          type: CreativePackItemType.exportPreset,
          title: 'Social 1080p',
          description: 'Good quality for TikTok, Shorts, and Reels.',
          proOnly: false,
          payload: {
            'width': 1080,
            'height': 1920,
            'frameRate': 30,
            'videoBitrate': 8000000,
            'audioBitrate': 192000,
            'includeAudio': true,
          },
          tags: ['export', 'free', 'vertical'],
        ),
        CreativePackItem(
          id: 'export_premium_4k',
          packId: packId,
          type: CreativePackItemType.exportPreset,
          title: 'Premium 4K',
          description: 'High quality 4K export for Pro users.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.proExport4k,
          payload: {
            'width': 2160,
            'height': 3840,
            'frameRate': 30,
            'videoBitrate': 24000000,
            'audioBitrate': 256000,
            'includeAudio': true,
          },
          tags: ['export', 'premium', '4k'],
        ),
      ],
    );
  }

  static CreativePack _socialTemplatePack() {
    const packId = 'pack_template_social';

    return CreativePack(
      id: packId,
      type: CreativePackType.template,
      title: 'Social Templates',
      subtitle: 'Ready layouts for creators',
      description: 'Reusable template payloads for intros, hooks, captions, and outros.',
      version: '1.0.0',
      author: 'Kata',
      proOnly: true,
      requiredFeatureId: PremiumFeatureId.premiumTemplates,
      tags: const ['template', 'social', 'intro'],
      items: const [
        CreativePackItem(
          id: 'template_hook_intro',
          packId: packId,
          type: CreativePackItemType.socialTemplate,
          title: 'Hook Intro',
          description: 'Fast opening layout with bold hook text.',
          proOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumTemplates,
          payload: {
            'aspectRatio': '9:16',
            'durationMicros': 2500000,
            'textSlots': [
              {
                'slotId': 'hook',
                'defaultText': 'WAIT FOR IT',
                'startMicros': 0,
                'endMicros': 2000000,
                'stylePresetId': 'text_bold_hook',
              }
            ],
            'suggestedExportPresetId': 'export_social_1080p',
          },
          tags: ['template', 'premium', 'intro'],
        ),
      ],
    );
  }
}
