import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/premium/entitlement_state.dart';
import 'package:nle_editor/domain/premium/local_entitlement_service.dart';

class EntitlementController extends StateNotifier<EntitlementState> {
  final LocalEntitlementService service;

  EntitlementController({
    required this.service,
  }) : super(EntitlementState.free()) {
    load();
  }

  Future<void> load() async {
    state = await service.load();
  }

  Future<void> setLocalPlan(String plan) async {
    await service.setLocalPlan(plan);
    await load();
  }

  Future<void> setDevUnlockPro(bool value) async {
    await service.setDevUnlockPro(value);
    await load();
  }

  bool hasFeature(String featureId) {
    return state.hasFeature(featureId);
  }
}
