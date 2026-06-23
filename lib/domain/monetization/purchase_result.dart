import 'package:nle_editor/domain/monetization/pro_entitlement.dart';

enum PurchaseFlowStatus {
  idle,
  loading,
  available,
  unavailable,
  pending,
  purchased,
  restored,
  cancelled,
  failed,
}

class PurchaseResult {
  final PurchaseFlowStatus status;
  final String? productId;
  final String? message;
  final String? errorCode;
  final Object? raw;
  final ProEntitlement? entitlement;

  const PurchaseResult({
    required this.status,
    this.productId,
    this.message,
    this.errorCode,
    this.raw,
    this.entitlement,
  });

  factory PurchaseResult.loading() {
    return const PurchaseResult(status: PurchaseFlowStatus.loading);
  }

  factory PurchaseResult.purchased({
    required String productId,
    required ProEntitlement entitlement,
    String? message,
    Object? raw,
  }) {
    return PurchaseResult(
      status: PurchaseFlowStatus.purchased,
      productId: productId,
      entitlement: entitlement,
      message: message ?? 'Purchase completed.',
      raw: raw,
    );
  }

  factory PurchaseResult.restored({
    required ProEntitlement entitlement,
    String? message,
    Object? raw,
  }) {
    return PurchaseResult(
      status: PurchaseFlowStatus.restored,
      entitlement: entitlement,
      message: message ?? 'Purchases restored.',
      raw: raw,
    );
  }

  factory PurchaseResult.failed({
    required String message,
    String? errorCode,
    String? productId,
    Object? raw,
  }) {
    return PurchaseResult(
      status: PurchaseFlowStatus.failed,
      productId: productId,
      message: message,
      errorCode: errorCode,
      raw: raw,
    );
  }

  factory PurchaseResult.cancelled({
    String? productId,
  }) {
    return PurchaseResult(
      status: PurchaseFlowStatus.cancelled,
      productId: productId,
      message: 'Purchase cancelled.',
    );
  }
}
