import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/monetization/monetization_service.dart';
import 'package:nle_editor/domain/monetization/product_model.dart';
import 'package:nle_editor/domain/monetization/pro_entitlement.dart';
import 'package:nle_editor/domain/monetization/purchase_result.dart';

class MonetizationState {
  final ProEntitlement entitlement;
  final List<MonetizationProduct> products;
  final PurchaseFlowStatus status;
  final String? message;
  final String? errorCode;
  final bool loadingProducts;

  const MonetizationState({
    required this.entitlement,
    required this.products,
    required this.status,
    this.message,
    this.errorCode,
    this.loadingProducts = false,
  });

  factory MonetizationState.initial() {
    return MonetizationState(
      entitlement: ProEntitlement.free(),
      products: const [],
      status: PurchaseFlowStatus.idle,
    );
  }

  MonetizationState copyWith({
    ProEntitlement? entitlement,
    List<MonetizationProduct>? products,
    PurchaseFlowStatus? status,
    String? message,
    String? errorCode,
    bool? loadingProducts,
  }) {
    return MonetizationState(
      entitlement: entitlement ?? this.entitlement,
      products: products ?? this.products,
      status: status ?? this.status,
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
      loadingProducts: loadingProducts ?? this.loadingProducts,
    );
  }
}

class MonetizationController extends StateNotifier<MonetizationState> {
  final MonetizationService service;

  StreamSubscription<ProEntitlement>? _entitlementSub;
  StreamSubscription<PurchaseResult>? _purchaseSub;

  MonetizationController({
    required this.service,
  }) : super(MonetizationState.initial()) {
    initialize();
  }

  Future<void> initialize() async {
    final entitlement = await service.initialize();

    state = state.copyWith(entitlement: entitlement);

    _entitlementSub = service.entitlementUpdates.listen((entitlement) {
      state = state.copyWith(entitlement: entitlement);
    });

    _purchaseSub = service.purchaseResults.listen((result) {
      state = state.copyWith(
        status: result.status,
        message: result.message,
        errorCode: result.errorCode,
        entitlement: result.entitlement ?? state.entitlement,
      );
    });

    await loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(loadingProducts: true);

    try {
      final products = await service.loadProducts();

      state = state.copyWith(
        products: products,
        loadingProducts: false,
        status: PurchaseFlowStatus.available,
      );
    } catch (e) {
      state = state.copyWith(
        loadingProducts: false,
        status: PurchaseFlowStatus.failed,
        message: e.toString(),
      );
    }
  }

  Future<void> buy(MonetizationProduct product) async {
    state = state.copyWith(
      status: PurchaseFlowStatus.pending,
      message: 'Starting purchase...',
    );

    final result = await service.buy(product);

    state = state.copyWith(
      status: result.status,
      message: result.message,
      errorCode: result.errorCode,
      entitlement: result.entitlement ?? state.entitlement,
    );
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(
      status: PurchaseFlowStatus.pending,
      message: 'Restoring purchases...',
    );

    final result = await service.restorePurchases();

    state = state.copyWith(
      status: result.status,
      message: result.message,
      errorCode: result.errorCode,
      entitlement: result.entitlement ?? state.entitlement,
    );
  }

  Future<void> startTrial() async {
    await service.startLocalTrial(days: 7);
  }

  Future<void> clearForTesting() async {
    await service.clearLocalEntitlementForTesting();
  }

  bool hasFeature(String featureId) {
    return state.entitlement.hasFeature(featureId);
  }

  @override
  void dispose() {
    _entitlementSub?.cancel();
    _purchaseSub?.cancel();
    super.dispose();
  }
}
