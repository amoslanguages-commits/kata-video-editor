import 'package:nle_editor/domain/monetization/monetization_product_ids.dart';

enum MonetizationProductType {
  subscription,
  lifetime,
}

enum BillingPeriod {
  monthly,
  yearly,
  lifetime,
}

class MonetizationProduct {
  final String id;
  final String title;
  final String description;
  final MonetizationProductType type;
  final BillingPeriod billingPeriod;
  final String priceText;
  final double priceAmount;
  final String currencyCode;
  final bool recommended;
  final int? trialDays;
  final List<String> benefits;

  const MonetizationProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.billingPeriod,
    required this.priceText,
    required this.priceAmount,
    required this.currencyCode,
    this.recommended = false,
    this.trialDays,
    this.benefits = const [],
  });

  bool get isSubscription => type == MonetizationProductType.subscription;
  bool get isLifetime => type == MonetizationProductType.lifetime;

  MonetizationProduct copyWith({
    String? id,
    String? title,
    String? description,
    MonetizationProductType? type,
    BillingPeriod? billingPeriod,
    String? priceText,
    double? priceAmount,
    String? currencyCode,
    bool? recommended,
    int? trialDays,
    List<String>? benefits,
  }) {
    return MonetizationProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      priceText: priceText ?? this.priceText,
      priceAmount: priceAmount ?? this.priceAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      recommended: recommended ?? this.recommended,
      trialDays: trialDays ?? this.trialDays,
      benefits: benefits ?? this.benefits,
    );
  }
}

class MonetizationProductCatalog {
  MonetizationProductCatalog._();

  static const mockProducts = <MonetizationProduct>[
    MonetizationProduct(
      id: MonetizationProductId.proMonthly,
      title: 'Pro Monthly',
      description: 'Unlock all Pro features monthly.',
      type: MonetizationProductType.subscription,
      billingPeriod: BillingPeriod.monthly,
      priceText: r'$4.99 / month',
      priceAmount: 4.99,
      currencyCode: 'USD',
      trialDays: 7,
      benefits: [
        'Premium text, effects, transitions, and color packs',
        'No watermark',
        '4K export support',
        'Advanced audio tools',
        'Batch proxy tools',
      ],
    ),
    MonetizationProduct(
      id: MonetizationProductId.proYearly,
      title: 'Pro Yearly',
      description: 'Best value for serious creators.',
      type: MonetizationProductType.subscription,
      billingPeriod: BillingPeriod.yearly,
      priceText: r'$29.99 / year',
      priceAmount: 29.99,
      currencyCode: 'USD',
      recommended: true,
      trialDays: 7,
      benefits: [
        'Everything in Pro Monthly',
        'Best yearly value',
        'Premium creator packs',
        'No watermark',
        '4K export support',
      ],
    ),
    MonetizationProduct(
      id: MonetizationProductId.proLifetime,
      title: 'Lifetime Pro',
      description: 'Pay once and unlock Pro forever.',
      type: MonetizationProductType.lifetime,
      billingPeriod: BillingPeriod.lifetime,
      priceText: r'$79.99 once',
      priceAmount: 79.99,
      currencyCode: 'USD',
      benefits: [
        'Lifetime Pro unlock',
        'No recurring subscription',
        'Premium packs',
        'No watermark',
        '4K export support',
      ],
    ),
  ];

  static MonetizationProduct? byId(String id) {
    for (final product in mockProducts) {
      if (product.id == id) return product;
    }

    return null;
  }
}
