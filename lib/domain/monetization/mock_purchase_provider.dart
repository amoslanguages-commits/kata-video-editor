import 'dart:async';

import 'package:nle_editor/domain/monetization/monetization_product_ids.dart';
import 'package:nle_editor/domain/monetization/product_model.dart';
import 'package:nle_editor/domain/monetization/pro_entitlement.dart';
import 'package:nle_editor/domain/monetization/purchase_provider.dart';
import 'package:nle_editor/domain/monetization/purchase_result.dart';

class MockPurchaseProvider implements PurchaseProvider {
  final _controller = StreamController<PurchaseResult>.broadcast();

  @override
  Stream<PurchaseResult> get purchaseUpdates => _controller.stream;

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<List<MonetizationProduct>> loadProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return MonetizationProductCatalog.mockProducts;
  }

  @override
  Future<PurchaseResult> buyProduct(MonetizationProduct product) async {
    _controller.add(
      const PurchaseResult(
        status: PurchaseFlowStatus.pending,
        message: 'Mock purchase pending...',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 800));

    final entitlement = ProEntitlement.mockPro(
      productId: product.id,
      store: MonetizationStoreId.mock,
    );

    final result = PurchaseResult.purchased(
      productId: product.id,
      entitlement: entitlement,
      message: 'Mock purchase completed.',
    );

    _controller.add(result);

    return result;
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final entitlement = ProEntitlement.mockPro(
      productId: MonetizationProductId.proYearly,
      store: MonetizationStoreId.mock,
    );

    final result = PurchaseResult.restored(
      entitlement: entitlement,
      message: 'Mock purchases restored.',
    );

    _controller.add(result);

    return result;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
