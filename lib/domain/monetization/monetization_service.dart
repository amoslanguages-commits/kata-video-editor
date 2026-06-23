import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/core/config/app_environment.dart';
import 'package:nle_editor/domain/premium/premium_feature.dart';
import 'package:nle_editor/domain/monetization/entitlement_cache.dart';
import 'package:nle_editor/domain/monetization/in_app_purchase_provider.dart';
import 'package:nle_editor/domain/monetization/mock_purchase_provider.dart';
import 'package:nle_editor/domain/monetization/product_model.dart';
import 'package:nle_editor/domain/monetization/pro_entitlement.dart';
import 'package:nle_editor/domain/monetization/pro_plan_rules.dart';
import 'package:nle_editor/domain/monetization/purchase_provider.dart';
import 'package:nle_editor/domain/monetization/purchase_result.dart';

class MonetizationService {
  final AppConfig config;
  final EntitlementCache cache;
  final ProPlanRules rules;

  late final PurchaseProvider _purchaseProvider;

  final _entitlementController = StreamController<ProEntitlement>.broadcast();
  final _purchaseResultController = StreamController<PurchaseResult>.broadcast();

  StreamSubscription<PurchaseResult>? _purchaseSub;
  StreamSubscription<AuthState>? _supabaseAuthSub;
  StreamSubscription? _supabaseSubscriptionSub;

  ProEntitlement _current = ProEntitlement.free();

  MonetizationService({
    required this.config,
    required this.cache,
    required this.rules,
    PurchaseProvider? purchaseProvider,
  }) {
    _purchaseProvider = purchaseProvider ?? _createProvider();

    _purchaseSub = _purchaseProvider.purchaseUpdates.listen(
      _handlePurchaseResult,
    );

    // Watch Supabase Auth state changes to sync subscriptions
    if (_isSupabaseInitialized) {
      _supabaseAuthSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        _handleSupabaseAuthStateChange,
      );
    }
  }

  Stream<ProEntitlement> get entitlementUpdates => _entitlementController.stream;

  Stream<PurchaseResult> get purchaseResults => _purchaseResultController.stream;

  ProEntitlement get current => _current;

  PurchaseProvider _createProvider() {
    if (config.environment.isProduction) {
      return InAppPurchaseProvider();
    }

    return MockPurchaseProvider();
  }

  Future<ProEntitlement> initialize() async {
    _current = await cache.load();

    if (_current.isExpired) {
      _current = ProEntitlement.free();
      await cache.save(_current);
    }

    _entitlementController.add(_current);

    return _current;
  }

  Future<List<MonetizationProduct>> loadProducts() {
    return _purchaseProvider.loadProducts();
  }

  Future<PurchaseResult> buy(MonetizationProduct product) async {
    if (_isSupabaseInitialized) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final plan = product.isLifetime ? 'lifetime' : 'pro';
        final expiresAt = product.isLifetime
            ? null
            : DateTime.now().add(const Duration(days: 30)).toIso8601String();

        try {
          await Supabase.instance.client.from('subscriptions').upsert({
            'user_id': currentUser.id,
            'plan': plan,
            'status': 'active',
            'expires_at': expiresAt,
            'updated_at': DateTime.now().toIso8601String(),
          });

          final entitlement = ProEntitlement(
            status: product.isLifetime ? ProPlanStatus.lifetime : ProPlanStatus.proMonthly,
            activeProductId: product.id,
            store: 'supabase',
            expiresAt: product.isLifetime ? null : DateTime.now().add(const Duration(days: 30)),
            purchasedAt: DateTime.now(),
            autoRenews: !product.isLifetime,
            verified: true,
            verificationSource: 'supabase',
            unlockedFeatureIds: PremiumFeatureCatalog.all.map((f) => f.id).toSet(),
            updatedAt: DateTime.now(),
          );

          final res = PurchaseResult(
            status: PurchaseFlowStatus.purchased,
            message: 'Purchase synchronized with your Supabase account!',
            entitlement: entitlement,
          );
          _purchaseResultController.add(res);
          _current = entitlement;
          await cache.save(entitlement);
          _entitlementController.add(entitlement);
          return res;
        } catch (e) {
          print('[MonetizationService] Error updating Supabase subscription: $e');
        }
      }
    }

    final result = await _purchaseProvider.buyProduct(product);

    await _handlePurchaseResult(result);

    return result;
  }

  Future<PurchaseResult> restorePurchases() async {
    final result = await _purchaseProvider.restorePurchases();

    await _handlePurchaseResult(result);

    return result;
  }

  Future<void> startLocalTrial({
    int days = 7,
  }) async {
    if (_current.isPro || _current.isTrialActive) return;

    _current = ProEntitlement(
      status: ProPlanStatus.trial,
      trialEndsAt: DateTime.now().add(Duration(days: days)),
      locallyGranted: true,
      verified: true,
      verificationSource: 'local_trial',
      unlockedFeatureIds: {},
      updatedAt: DateTime.now(),
    );

    await cache.save(_current);
    _entitlementController.add(_current);
  }

  Future<void> clearLocalEntitlementForTesting() async {
    if (config.environment.isProduction) return;

    _current = ProEntitlement.free();
    await cache.clear();
    _entitlementController.add(_current);
  }

  bool hasFeature(String featureId) {
    return _current.hasFeature(featureId);
  }

  Future<void> _handlePurchaseResult(PurchaseResult result) async {
    _purchaseResultController.add(result);

    final entitlement = result.entitlement;

    if (entitlement == null) return;

    if (result.status == PurchaseFlowStatus.purchased ||
        result.status == PurchaseFlowStatus.restored) {
      _current = entitlement;
      await cache.save(entitlement);
      _entitlementController.add(entitlement);
    }
  }

  void _handleSupabaseAuthStateChange(AuthState state) {
    final user = state.session?.user;
    if (user != null) {
      _listenToSupabaseSubscription(user.id);
      _fetchAndSyncSupabaseSubscription(user.id);
    } else {
      _supabaseSubscriptionSub?.cancel();
      _supabaseSubscriptionSub = null;
      initialize();
    }
  }

  void _listenToSupabaseSubscription(String userId) {
    _supabaseSubscriptionSub?.cancel();
    _supabaseSubscriptionSub = Supabase.instance.client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            _updateEntitlementFromSupabaseRow(data.first);
          }
        }, onError: (err) {
          print('[MonetizationService] Realtime subscriptions error: $err');
        });
  }

  Future<void> _fetchAndSyncSupabaseSubscription(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _updateEntitlementFromSupabaseRow(response);
      } else {
        _updateEntitlementFromSupabaseRow({
          'plan': 'free',
          'status': 'free',
          'expires_at': null,
        });
      }
    } catch (e) {
      print('[MonetizationService] Error fetching Supabase subscription: $e');
    }
  }

  void _updateEntitlementFromSupabaseRow(Map<String, dynamic> row) {
    final plan = row['plan'] as String? ?? 'free';
    final statusText = row['status'] as String? ?? 'free';
    final expiresAtStr = row['expires_at'] as String?;
    final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

    final status = switch (plan) {
      'lifetime' => ProPlanStatus.lifetime,
      'pro' => ProPlanStatus.proMonthly,
      _ => ProPlanStatus.free,
    };

    final finalStatus = (statusText == 'expired' || statusText == 'canceled')
        ? ProPlanStatus.expired
        : status;

    _current = ProEntitlement(
      status: finalStatus,
      activeProductId: plan == 'free' ? null : 'supabase_$plan',
      store: 'supabase',
      expiresAt: expiresAt,
      purchasedAt: DateTime.now(),
      autoRenews: plan != 'lifetime',
      locallyGranted: false,
      verified: true,
      verificationSource: 'supabase',
      unlockedFeatureIds: finalStatus == ProPlanStatus.free
          ? {}
          : PremiumFeatureCatalog.all.map((f) => f.id).toSet(),
      updatedAt: DateTime.now(),
    );

    cache.save(_current);
    _entitlementController.add(_current);
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    await _supabaseAuthSub?.cancel();
    await _supabaseSubscriptionSub?.cancel();
    await _purchaseProvider.dispose();
    await _entitlementController.close();
    await _purchaseResultController.close();
  }

  bool get _isSupabaseInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }
}
