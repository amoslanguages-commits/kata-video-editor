import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/core/config/app_environment.dart';
import 'package:nle_editor/domain/monetization/monetization_product_ids.dart';
import 'package:nle_editor/domain/monetization/product_model.dart';
import 'package:nle_editor/domain/monetization/pro_entitlement.dart';
import 'package:nle_editor/domain/monetization/pro_plan_rules.dart';
import 'package:nle_editor/domain/monetization/entitlement_cache.dart';
import 'package:nle_editor/domain/monetization/purchase_result.dart';
import 'package:nle_editor/domain/monetization/monetization_service.dart';
import 'package:nle_editor/domain/monetization/mock_purchase_provider.dart';
import 'package:nle_editor/domain/premium/premium_feature.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProPlanRules Tests', () {
    const rules = ProPlanRules();

    test('canUseFeature restrictions', () {
      final free = ProEntitlement.free();
      final pro = ProEntitlement.mockPro(
        productId: MonetizationProductId.proMonthly,
        store: MonetizationStoreId.mock,
      );

      // 1080p export is free
      expect(rules.canUseFeature(entitlement: free, featureId: PremiumFeatureId.proExport1080p), isTrue);
      expect(rules.canUseFeature(entitlement: pro, featureId: PremiumFeatureId.proExport1080p), isTrue);

      // 4K export and watermark require pro
      expect(rules.canUseFeature(entitlement: free, featureId: PremiumFeatureId.proExport4k), isFalse);
      expect(rules.canUseFeature(entitlement: pro, featureId: PremiumFeatureId.proExport4k), isTrue);
      expect(rules.canUseFeature(entitlement: free, featureId: PremiumFeatureId.proNoWatermark), isFalse);
      expect(rules.canUseFeature(entitlement: pro, featureId: PremiumFeatureId.proNoWatermark), isTrue);
    });

    test('canUsePremiumPack check', () {
      final free = ProEntitlement.free();
      final pro = ProEntitlement.mockPro(
        productId: MonetizationProductId.proMonthly,
        store: MonetizationStoreId.mock,
      );

      // Non-pro pack
      expect(rules.canUsePremiumPack(entitlement: free, packProOnly: false), isTrue);

      // Pro pack
      expect(rules.canUsePremiumPack(entitlement: free, packProOnly: true), isFalse);
      expect(rules.canUsePremiumPack(entitlement: pro, packProOnly: true), isTrue);

      // Specific feature pack
      expect(
        rules.canUsePremiumPack(
          entitlement: free,
          packProOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumTransitions,
        ),
        isFalse,
      );
      expect(
        rules.canUsePremiumPack(
          entitlement: pro,
          packProOnly: true,
          requiredFeatureId: PremiumFeatureId.premiumTransitions,
        ),
        isTrue,
      );
    });

    test('checkExport logic for 4K and watermarks', () {
      final free = ProEntitlement.free();
      final pro = ProEntitlement.mockPro(
        productId: MonetizationProductId.proMonthly,
        store: MonetizationStoreId.mock,
      );

      // Free 1080p export with watermark
      final freeNormal = rules.checkExport(
        entitlement: free,
        width: 1920,
        height: 1080,
        removeWatermarkRequested: false,
      );
      expect(freeNormal.allowed, isTrue);
      expect(freeNormal.watermarkRequired, isTrue);

      // Free 1080p export requesting to remove watermark -> restricted
      final freeNoWatermark = rules.checkExport(
        entitlement: free,
        width: 1920,
        height: 1080,
        removeWatermarkRequested: true,
      );
      expect(freeNoWatermark.allowed, isFalse);
      expect(freeNoWatermark.requiredFeatureId, equals(PremiumFeatureId.proNoWatermark));

      // Free 4K export -> restricted
      final free4k = rules.checkExport(
        entitlement: free,
        width: 3840,
        height: 2160,
        removeWatermarkRequested: false,
      );
      expect(free4k.allowed, isFalse);
      expect(free4k.requiredFeatureId, equals(PremiumFeatureId.proExport4k));

      // Pro 4K export without watermark -> allowed
      final pro4k = rules.checkExport(
        entitlement: pro,
        width: 3840,
        height: 2160,
        removeWatermarkRequested: true,
      );
      expect(pro4k.allowed, isTrue);
      expect(pro4k.watermarkRequired, isFalse);
    });
  });

  group('EntitlementCache Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads free entitlement by default when cache is empty', () async {
      final cache = EntitlementCache();
      final entitlement = await cache.load();
      expect(entitlement.status, equals(ProPlanStatus.free));
      expect(entitlement.isPro, isFalse);
    });

    test('Saves and loads entitlement successfully', () async {
      final cache = EntitlementCache();
      final now = DateTime.now();
      final entitlement = ProEntitlement(
        status: ProPlanStatus.proYearly,
        activeProductId: MonetizationProductId.proYearly,
        store: MonetizationStoreId.mock,
        purchasedAt: now,
        expiresAt: now.add(const Duration(days: 365)),
        autoRenews: true,
        locallyGranted: true,
        verified: true,
        verificationSource: 'test',
        unlockedFeatureIds: {'feat_1', 'feat_2'},
        updatedAt: now,
      );

      await cache.save(entitlement);

      final loaded = await cache.load();
      expect(loaded.status, equals(ProPlanStatus.proYearly));
      expect(loaded.activeProductId, equals(MonetizationProductId.proYearly));
      expect(loaded.store, equals(MonetizationStoreId.mock));
      expect(loaded.autoRenews, isTrue);
      expect(loaded.locallyGranted, isTrue);
      expect(loaded.verified, isTrue);
      expect(loaded.verificationSource, equals('test'));
      expect(loaded.unlockedFeatureIds, containsAll(['feat_1', 'feat_2']));
    });
  });

  group('MonetizationService and MockPurchaseProvider Tests', () {
    late AppConfig config;
    late EntitlementCache cache;
    late ProPlanRules rules;
    late MonetizationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      config = AppConfig.forEnvironment(AppEnvironment.dev);
      cache = EntitlementCache();
      rules = const ProPlanRules();
      service = MonetizationService(
        config: config,
        cache: cache,
        rules: rules,
        purchaseProvider: MockPurchaseProvider(),
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    test('initializes and detects trial/pro status', () async {
      final initial = await service.initialize();
      expect(initial.status, equals(ProPlanStatus.free));

      // Start trial
      await service.startLocalTrial(days: 5);
      expect(service.current.status, equals(ProPlanStatus.trial));
      expect(service.current.isTrialActive, isTrue);
      expect(service.current.isPro, isTrue);

      // Re-initialize to load from cache
      final service2 = MonetizationService(
        config: config,
        cache: cache,
        rules: rules,
        purchaseProvider: MockPurchaseProvider(),
      );
      final initial2 = await service2.initialize();
      expect(initial2.status, equals(ProPlanStatus.trial));
      expect(initial2.isPro, isTrue);
      await service2.dispose();
    });

    test('buy product updates cache and entitlement state', () async {
      await service.initialize();
      expect(service.current.isPro, isFalse);

      final product = MonetizationProductCatalog.byId(MonetizationProductId.proLifetime)!;
      final resultsFuture = service.purchaseResults.firstWhere((r) => r.status == PurchaseFlowStatus.purchased);

      await service.buy(product);

      final completedResult = await resultsFuture;
      expect(completedResult.status, equals(PurchaseFlowStatus.purchased));
      expect(completedResult.productId, equals(MonetizationProductId.proLifetime));

      expect(service.current.status, equals(ProPlanStatus.lifetime));
      expect(service.current.isPro, isTrue);

      final cached = await cache.load();
      expect(cached.status, equals(ProPlanStatus.lifetime));
    });

    test('restore purchases restores pro status', () async {
      await service.initialize();
      expect(service.current.isPro, isFalse);

      final resultsFuture = service.purchaseResults.firstWhere((r) => r.status == PurchaseFlowStatus.restored);

      await service.restorePurchases();

      final restoredResult = await resultsFuture;
      expect(restoredResult.status, equals(PurchaseFlowStatus.restored));
      expect(service.current.status, equals(ProPlanStatus.proYearly));
      expect(service.current.isPro, isTrue);
    });
  });
}
