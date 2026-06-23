class MonetizationProductId {
  MonetizationProductId._();

  // Use these exact IDs in Google Play Console / App Store Connect later.
  static const String proMonthly = 'nle_editor_pro_monthly';
  static const String proYearly = 'nle_editor_pro_yearly';
  static const String proLifetime = 'nle_editor_pro_lifetime';

  static const Set<String> all = {
    proMonthly,
    proYearly,
    proLifetime,
  };
}

class MonetizationStoreId {
  MonetizationStoreId._();

  static const String mock = 'mock';
  static const String googlePlay = 'google_play';
  static const String appStore = 'app_store';
  static const String unknown = 'unknown';
}
