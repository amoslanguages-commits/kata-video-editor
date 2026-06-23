import 'package:nle_editor/domain/premium/premium_feature.dart';

class UserPlan {
  UserPlan._();

  static const String free = 'free';
  static const String pro = 'pro';
  static const String lifetime = 'lifetime';
}

class EntitlementState {
  final String plan;
  final bool isTrialActive;
  final DateTime? trialEndsAt;
  final Set<String> unlockedFeatureIds;

  const EntitlementState({
    required this.plan,
    this.isTrialActive = false,
    this.trialEndsAt,
    this.unlockedFeatureIds = const {},
  });

  factory EntitlementState.free() {
    return const EntitlementState(
      plan: UserPlan.free,
    );
  }

  factory EntitlementState.proLocalDev() {
    return const EntitlementState(
      plan: UserPlan.pro,
      unlockedFeatureIds: {
        PremiumFeatureId.proExport1080p,
        PremiumFeatureId.proExport4k,
        PremiumFeatureId.proNoWatermark,
        PremiumFeatureId.premiumTransitions,
        PremiumFeatureId.premiumEffects,
        PremiumFeatureId.premiumTextStyles,
        PremiumFeatureId.premiumColorPresets,
        PremiumFeatureId.premiumTemplates,
        PremiumFeatureId.batchProxy,
        PremiumFeatureId.advancedAudio,
        PremiumFeatureId.brandKit,
      },
    );
  }

  bool get isPro => plan == UserPlan.pro || plan == UserPlan.lifetime;

  bool hasFeature(String featureId) {
    final feature = PremiumFeatureCatalog.byId(featureId);

    if (feature == null) return false;

    if (!feature.proOnly) return true;

    if (isPro) return true;

    return unlockedFeatureIds.contains(featureId);
  }

  EntitlementState copyWith({
    String? plan,
    bool? isTrialActive,
    DateTime? trialEndsAt,
    Set<String>? unlockedFeatureIds,
  }) {
    return EntitlementState(
      plan: plan ?? this.plan,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      unlockedFeatureIds: unlockedFeatureIds ?? this.unlockedFeatureIds,
    );
  }
}
