class StoreReviewRiskLevel {
  StoreReviewRiskLevel._();

  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
}

class StoreReviewRisk {
  final String id;
  final String level;
  final String title;
  final String description;
  final String mitigation;

  const StoreReviewRisk({
    required this.id,
    required this.level,
    required this.title,
    required this.description,
    required this.mitigation,
  });
}

class StoreReviewRiskCatalog {
  StoreReviewRiskCatalog._();

  static const risks = <StoreReviewRisk>[
    StoreReviewRisk(
      id: 'media_permission',
      level: StoreReviewRiskLevel.medium,
      title: 'Media permission review',
      description:
          'The app needs access to photos/videos/audio for editing. Review teams need a clear reason.',
      mitigation:
          'Show permission explanation before requesting access and describe import/export use in store notes.',
    ),
    StoreReviewRisk(
      id: 'privacy_labels',
      level: StoreReviewRiskLevel.high,
      title: 'Incorrect privacy labels',
      description:
          'Privacy answers must match actual SDKs, analytics, crash reporting, and purchase systems.',
      mitigation:
          'Keep analytics/crash reporting disabled until final disclosures are ready.',
    ),
    StoreReviewRisk(
      id: 'dev_unlock',
      level: StoreReviewRiskLevel.high,
      title: 'Dev Pro unlock shipping',
      description:
          'Local developer Pro unlock must not be visible in production.',
      mitigation:
          'Use ProductionSafetyGuard and verify production checklist.',
    ),
    StoreReviewRisk(
      id: 'metadata_overclaim',
      level: StoreReviewRiskLevel.medium,
      title: 'Overclaiming features',
      description:
          'Store copy must not claim features that are not fully implemented.',
      mitigation:
          'Avoid claims like professional 4K on all phones or cloud marketplace until implemented.',
    ),
    StoreReviewRisk(
      id: 'copyright_screenshots',
      level: StoreReviewRiskLevel.medium,
      title: 'Copyrighted media in screenshots',
      description:
          'Screenshots and promo videos should not use copyrighted clips, logos, or music.',
      mitigation:
          'Use original/royalty-free sample media created for the app.',
    ),
    StoreReviewRisk(
      id: 'background_processing',
      level: StoreReviewRiskLevel.low,
      title: 'Long export/proxy jobs',
      description:
          'Long tasks may be interrupted by OS lifecycle rules.',
      mitigation:
          'Explain progress, handle interruptions, and use recovery tools.',
    ),
  ];
}
