import 'package:nle_editor/domain/monetization/pro_entitlement.dart';
import 'package:nle_editor/domain/premium/premium_feature.dart';

class ExportLimitDecision {
  final bool allowed;
  final bool watermarkRequired;
  final String? blockedReason;
  final String? requiredFeatureId;

  const ExportLimitDecision({
    required this.allowed,
    required this.watermarkRequired,
    this.blockedReason,
    this.requiredFeatureId,
  });
}

class ProPlanRules {
  const ProPlanRules();

  bool canUseFeature({
    required ProEntitlement entitlement,
    required String featureId,
  }) {
    return entitlement.hasFeature(featureId);
  }

  bool canUsePremiumPack({
    required ProEntitlement entitlement,
    required bool packProOnly,
    String? requiredFeatureId,
  }) {
    if (!packProOnly) return true;
    if (requiredFeatureId == null) return entitlement.isPro;
    return entitlement.hasFeature(requiredFeatureId);
  }

  ExportLimitDecision checkExport({
    required ProEntitlement entitlement,
    required int width,
    required int height,
    required bool removeWatermarkRequested,
  }) {
    final pixels = width * height;
    final is4k = pixels >= 3840 * 2160 || width >= 2160 || height >= 2160;

    if (is4k && !entitlement.hasFeature(PremiumFeatureId.proExport4k)) {
      return const ExportLimitDecision(
        allowed: false,
        watermarkRequired: true,
        blockedReason: '4K export requires Pro.',
        requiredFeatureId: PremiumFeatureId.proExport4k,
      );
    }

    if (removeWatermarkRequested &&
        !entitlement.hasFeature(PremiumFeatureId.proNoWatermark)) {
      return const ExportLimitDecision(
        allowed: false,
        watermarkRequired: true,
        blockedReason: 'Removing the watermark requires Pro.',
        requiredFeatureId: PremiumFeatureId.proNoWatermark,
      );
    }

    return ExportLimitDecision(
      allowed: true,
      watermarkRequired: !entitlement.hasFeature(PremiumFeatureId.proNoWatermark),
    );
  }

  bool canBatchProxy(ProEntitlement entitlement) {
    return entitlement.hasFeature(PremiumFeatureId.batchProxy);
  }

  bool canUseAdvancedAudio(ProEntitlement entitlement) {
    return entitlement.hasFeature(PremiumFeatureId.advancedAudio);
  }
}
