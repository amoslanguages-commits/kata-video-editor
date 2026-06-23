import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:nle_editor/domain/monetization/monetization_product_ids.dart';
import 'package:nle_editor/domain/monetization/product_model.dart';
import 'package:nle_editor/domain/monetization/pro_entitlement.dart';
import 'package:nle_editor/domain/monetization/purchase_provider.dart';
import 'package:nle_editor/domain/monetization/purchase_result.dart';

class InAppPurchaseProvider implements PurchaseProvider {
  final InAppPurchase _iap;

  final _controller = StreamController<PurchaseResult>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _sub;

  final Map<String, ProductDetails> _productDetailsById = {};

  InAppPurchaseProvider({
    InAppPurchase? iap,
  }) : _iap = iap ?? InAppPurchase.instance {
    _sub = _iap.purchaseStream.listen(
      _onPurchasesUpdated,
      onError: (Object error) {
        _controller.add(
          PurchaseResult.failed(
            message: 'Purchase stream error.',
            errorCode: 'purchase_stream_error',
            raw: error,
          ),
        );
      },
    );
  }

  @override
  Stream<PurchaseResult> get purchaseUpdates => _controller.stream;

  @override
  Future<bool> isAvailable() {
    return _iap.isAvailable();
  }

  @override
  Future<List<MonetizationProduct>> loadProducts() async {
    final available = await isAvailable();

    if (!available) {
      return const [];
    }

    final response = await _iap.queryProductDetails(
      MonetizationProductId.all,
    );

    _productDetailsById
      ..clear()
      ..addEntries(
        response.productDetails.map(
          (details) => MapEntry(details.id, details),
        ),
      );

    final products = <MonetizationProduct>[];

    for (final details in response.productDetails) {
      final fallback = MonetizationProductCatalog.byId(details.id);

      if (fallback == null) continue;

      products.add(
        fallback.copyWith(
          title: details.title,
          description: details.description,
          priceText: details.price,
          currencyCode: details.currencyCode,
          priceAmount: details.rawPrice,
        ),
      );
    }

    products.sort((a, b) {
      final order = [
        MonetizationProductId.proMonthly,
        MonetizationProductId.proYearly,
        MonetizationProductId.proLifetime,
      ];

      return order.indexOf(a.id).compareTo(order.indexOf(b.id));
    });

    return products;
  }

  @override
  Future<PurchaseResult> buyProduct(MonetizationProduct product) async {
    final details = _productDetailsById[product.id];

    if (details == null) {
      return PurchaseResult.failed(
        productId: product.id,
        message: 'Product is not available in the store.',
        errorCode: 'product_not_loaded',
      );
    }

    final purchaseParam = PurchaseParam(productDetails: details);

    final ok = await _iap.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!ok) {
      return PurchaseResult.failed(
        productId: product.id,
        message: 'Could not start purchase.',
        errorCode: 'purchase_start_failed',
      );
    }

    return const PurchaseResult(
      status: PurchaseFlowStatus.pending,
      message: 'Purchase started.',
    );
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    await _iap.restorePurchases();

    return const PurchaseResult(
      status: PurchaseFlowStatus.pending,
      message: 'Restore started. Waiting for store response.',
    );
  }

  Future<void> _onPurchasesUpdated(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _controller.add(
            PurchaseResult(
              status: PurchaseFlowStatus.pending,
              productId: purchase.productID,
              message: 'Purchase pending.',
              raw: purchase,
            ),
          );
          break;

        case PurchaseStatus.error:
          _controller.add(
            PurchaseResult.failed(
              productId: purchase.productID,
              message: purchase.error?.message ?? 'Purchase failed.',
              errorCode: purchase.error?.code,
              raw: purchase,
            ),
          );
          break;

        case PurchaseStatus.canceled:
          _controller.add(
            PurchaseResult.cancelled(
              productId: purchase.productID,
            ),
          );
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final valid = await _verifyPurchasePlaceholder(purchase);

          if (!valid) {
            _controller.add(
              PurchaseResult.failed(
                productId: purchase.productID,
                message: 'Purchase could not be verified.',
                errorCode: 'purchase_verification_failed',
                raw: purchase,
              ),
            );
            break;
          }

          final entitlement = _entitlementFromPurchase(purchase);

          _controller.add(
            purchase.status == PurchaseStatus.restored
                ? PurchaseResult.restored(
                    entitlement: entitlement,
                    raw: purchase,
                  )
                : PurchaseResult.purchased(
                    productId: purchase.productID,
                    entitlement: entitlement,
                    raw: purchase,
                  ),
          );

          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchasePlaceholder(PurchaseDetails purchase) async {
    // Production rule:
    // Do NOT permanently grant Pro from local receipt parsing alone.
    // Send purchase.verificationData to your backend and verify with:
    // - App Store Server API / StoreKit signed transaction
    // - Google Play Developer API
    //
    // V1 placeholder returns true so you can test the flow.
    return purchase.productID.isNotEmpty;
  }

  ProEntitlement _entitlementFromPurchase(PurchaseDetails purchase) {
    final store = Platform.isIOS
        ? MonetizationStoreId.appStore
        : Platform.isAndroid
            ? MonetizationStoreId.googlePlay
            : MonetizationStoreId.unknown;

    return ProEntitlement.mockPro(
      productId: purchase.productID,
      store: store,
    ).copyWith(
      locallyGranted: false,
      verified: true,
      verificationSource: 'iap_placeholder_verification',
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
