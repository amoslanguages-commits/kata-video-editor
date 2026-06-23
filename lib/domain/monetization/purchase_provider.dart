import 'dart:async';

import 'package:nle_editor/domain/monetization/product_model.dart';
import 'package:nle_editor/domain/monetization/purchase_result.dart';

abstract class PurchaseProvider {
  Stream<PurchaseResult> get purchaseUpdates;

  Future<bool> isAvailable();

  Future<List<MonetizationProduct>> loadProducts();

  Future<PurchaseResult> buyProduct(MonetizationProduct product);

  Future<PurchaseResult> restorePurchases();

  Future<void> dispose();
}
