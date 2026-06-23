class PremiumFeatureId {
  PremiumFeatureId._();

  static const String proExport1080p = 'pro_export_1080p';
  static const String proExport4k = 'pro_export_4k';
  static const String proNoWatermark = 'pro_no_watermark';

  static const String premiumTransitions = 'premium_transitions';
  static const String premiumEffects = 'premium_effects';
  static const String premiumTextStyles = 'premium_text_styles';
  static const String premiumColorPresets = 'premium_color_presets';
  static const String premiumTemplates = 'premium_templates';

  static const String batchProxy = 'batch_proxy';
  static const String advancedAudio = 'advanced_audio';
  static const String brandKit = 'brand_kit';
}

class PremiumFeature {
  final String id;
  final String title;
  final String description;
  final bool proOnly;

  const PremiumFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.proOnly,
  });
}

class PremiumFeatureCatalog {
  PremiumFeatureCatalog._();

  static const all = <PremiumFeature>[
    PremiumFeature(
      id: PremiumFeatureId.proExport1080p,
      title: '1080p Export',
      description: 'Export high-quality Full HD videos.',
      proOnly: false,
    ),
    PremiumFeature(
      id: PremiumFeatureId.proExport4k,
      title: '4K Export',
      description: 'Export ultra-high-resolution videos.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.proNoWatermark,
      title: 'No Watermark',
      description: 'Export videos without a watermark.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.premiumTransitions,
      title: 'Premium Transitions',
      description: 'Use cinematic transitions and motion packs.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.premiumEffects,
      title: 'Premium Effects',
      description: 'Use advanced creator effects.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.premiumTextStyles,
      title: 'Premium Text Styles',
      description: 'Use high-end title and caption packs.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.premiumColorPresets,
      title: 'Premium Color Presets',
      description: 'Apply cinematic color styles.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.premiumTemplates,
      title: 'Premium Templates',
      description: 'Use ready-made social media templates.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.batchProxy,
      title: 'Batch Proxy',
      description: 'Generate proxies for many videos at once.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.advancedAudio,
      title: 'Advanced Audio',
      description: 'Use advanced audio tools and mix controls.',
      proOnly: true,
    ),
    PremiumFeature(
      id: PremiumFeatureId.brandKit,
      title: 'Brand Kit',
      description: 'Save custom colors, fonts, and creator styles.',
      proOnly: true,
    ),
  ];

  static PremiumFeature? byId(String id) {
    for (final feature in all) {
      if (feature.id == id) return feature;
    }
    return null;
  }
}
