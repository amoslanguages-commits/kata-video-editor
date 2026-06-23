import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/creative_pack_repository.dart';
import 'package:nle_editor/domain/premium/creative_pack.dart';
import 'package:nle_editor/domain/premium/creative_preset_apply_service.dart';
import 'package:nle_editor/domain/premium/entitlement_state.dart';
import 'package:nle_editor/domain/premium/local_entitlement_service.dart';
import 'package:nle_editor/domain/premium/user_creative_preset.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/app_config_provider.dart';
import 'package:nle_editor/presentation/providers/monetization_providers.dart';
import 'package:nle_editor/domain/monetization/pro_entitlement.dart';

final localEntitlementServiceProvider =
    Provider<LocalEntitlementService>((ref) {
  return LocalEntitlementService(
    config: ref.watch(appConfigProvider),
  );
});

final entitlementProvider = Provider<EntitlementState>((ref) {
  final newEntitlement = ref.watch(monetizationProvider).entitlement;
  return EntitlementState(
    plan: newEntitlement.status == ProPlanStatus.lifetime
        ? UserPlan.lifetime
        : newEntitlement.isPro
            ? UserPlan.pro
            : UserPlan.free,
    isTrialActive: newEntitlement.isTrialActive,
    trialEndsAt: newEntitlement.trialEndsAt,
    unlockedFeatureIds: newEntitlement.unlockedFeatureIds,
  );
});

final creativePackRepositoryProvider = Provider<CreativePackRepository>((ref) {
  return CreativePackRepository(
    db: ref.watch(databaseProvider),
  );
});

final creativePacksProvider = FutureProvider<List<CreativePack>>((ref) {
  return ref.watch(creativePackRepositoryProvider).getBuiltInPacks();
});

final creativePacksByTypeProvider =
    FutureProvider.family<List<CreativePack>, String>((ref, type) {
  return ref.watch(creativePackRepositoryProvider).getPacksByType(type);
});

final userCreativePresetsProvider =
    StreamProvider.family<List<UserCreativePreset>, String>((ref, type) {
  return ref.watch(creativePackRepositoryProvider).watchUserPresets(type);
});

final creativePresetApplyServiceProvider =
    Provider<CreativePresetApplyService>((ref) {
  return CreativePresetApplyService(
    timelineRepository: ref.watch(timelineRepositoryProvider),
    transitionRepository: ref.watch(transitionRepositoryProvider),
  );
});
