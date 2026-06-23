import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/monetization/entitlement_cache.dart';
import 'package:nle_editor/domain/monetization/monetization_service.dart';
import 'package:nle_editor/domain/monetization/pro_plan_rules.dart';
import 'package:nle_editor/presentation/controllers/monetization_controller.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';

final entitlementCacheProvider = Provider<EntitlementCache>((ref) {
  return EntitlementCache();
});

final proPlanRulesProvider = Provider<ProPlanRules>((ref) {
  return const ProPlanRules();
});

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  final service = MonetizationService(
    config: ref.watch(appConfigProvider),
    cache: ref.watch(entitlementCacheProvider),
    rules: ref.watch(proPlanRulesProvider),
  );

  ref.onDispose(service.dispose);

  return service;
});

final monetizationProvider =
    StateNotifierProvider<MonetizationController, MonetizationState>((ref) {
  return MonetizationController(
    service: ref.watch(monetizationServiceProvider),
  );
});
