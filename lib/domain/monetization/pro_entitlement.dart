import 'package:nle_editor/domain/premium/premium_feature.dart';
import 'package:nle_editor/domain/monetization/monetization_product_ids.dart';

enum ProPlanStatus {
  free,
  trial,
  proMonthly,
  proYearly,
  lifetime,
  expired,
  unknown,
}

class ProEntitlement {
  final ProPlanStatus status;
  final String? activeProductId;
  final String? store;
  final DateTime? expiresAt;
  final DateTime? purchasedAt;
  final DateTime? trialEndsAt;
  final bool autoRenews;
  final bool locallyGranted;
  final bool verified;
  final String? verificationSource;
  final Set<String> unlockedFeatureIds;
  final DateTime updatedAt;

  const ProEntitlement({
    required this.status,
    this.activeProductId,
    this.store,
    this.expiresAt,
    this.purchasedAt,
    this.trialEndsAt,
    this.autoRenews = false,
    this.locallyGranted = false,
    this.verified = false,
    this.verificationSource,
    this.unlockedFeatureIds = const {},
    required this.updatedAt,
  });

  factory ProEntitlement.free() {
    return ProEntitlement(
      status: ProPlanStatus.free,
      updatedAt: DateTime.now(),
    );
  }

  factory ProEntitlement.mockPro({
    required String productId,
    required String store,
  }) {
    final now = DateTime.now();

    final status = switch (productId) {
      MonetizationProductId.proMonthly => ProPlanStatus.proMonthly,
      MonetizationProductId.proYearly => ProPlanStatus.proYearly,
      MonetizationProductId.proLifetime => ProPlanStatus.lifetime,
      _ => ProPlanStatus.unknown,
    };

    final expiresAt = switch (productId) {
      MonetizationProductId.proMonthly => now.add(const Duration(days: 30)),
      MonetizationProductId.proYearly => now.add(const Duration(days: 365)),
      MonetizationProductId.proLifetime => null,
      _ => null,
    };

    return ProEntitlement(
      status: status,
      activeProductId: productId,
      store: store,
      purchasedAt: now,
      expiresAt: expiresAt,
      autoRenews: productId != MonetizationProductId.proLifetime,
      locallyGranted: true,
      verified: true,
      verificationSource: 'mock_provider',
      unlockedFeatureIds: PremiumFeatureCatalog.all.map((f) => f.id).toSet(),
      updatedAt: now,
    );
  }

  bool get isPro {
    if (status == ProPlanStatus.lifetime) return true;

    if (status == ProPlanStatus.trial) {
      final end = trialEndsAt;
      return end != null && end.isAfter(DateTime.now());
    }

    if (status == ProPlanStatus.proMonthly || status == ProPlanStatus.proYearly) {
      final expiry = expiresAt;
      if (expiry == null) return true;
      return expiry.isAfter(DateTime.now());
    }

    return false;
  }

  bool get isFree => !isPro;

  bool get isTrialActive {
    final end = trialEndsAt;
    return status == ProPlanStatus.trial &&
        end != null &&
        end.isAfter(DateTime.now());
  }

  bool get isExpired {
    final expiry = expiresAt;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  bool hasFeature(String featureId) {
    final feature = PremiumFeatureCatalog.byId(featureId);

    if (feature == null) return false;
    if (!feature.proOnly) return true;
    if (isPro) return true;

    return unlockedFeatureIds.contains(featureId);
  }

  ProEntitlement copyWith({
    ProPlanStatus? status,
    String? activeProductId,
    String? store,
    DateTime? expiresAt,
    DateTime? purchasedAt,
    DateTime? trialEndsAt,
    bool? autoRenews,
    bool? locallyGranted,
    bool? verified,
    String? verificationSource,
    Set<String>? unlockedFeatureIds,
    DateTime? updatedAt,
  }) {
    return ProEntitlement(
      status: status ?? this.status,
      activeProductId: activeProductId ?? this.activeProductId,
      store: store ?? this.store,
      expiresAt: expiresAt ?? this.expiresAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      autoRenews: autoRenews ?? this.autoRenews,
      locallyGranted: locallyGranted ?? this.locallyGranted,
      verified: verified ?? this.verified,
      verificationSource: verificationSource ?? this.verificationSource,
      unlockedFeatureIds: unlockedFeatureIds ?? this.unlockedFeatureIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
