import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/core/config/app_config.dart';
import 'package:nle_editor/domain/premium/entitlement_state.dart';

class LocalEntitlementService {
  final AppConfig config;

  LocalEntitlementService({
    required this.config,
  });

  static const _planKey = 'nle_user_plan_v1';
  static const _devUnlockKey = 'nle_dev_unlock_pro_v1';

  Future<EntitlementState> load() async {
    if (config.isProduction) {
      return EntitlementState.free();
    }

    final prefs = await SharedPreferences.getInstance();

    final devUnlock = prefs.getBool(_devUnlockKey) ?? false;

    if (devUnlock && config.allowDevProUnlock) {
      return EntitlementState.proLocalDev();
    }

    final plan = prefs.getString(_planKey) ?? UserPlan.free;

    if (plan == UserPlan.pro || plan == UserPlan.lifetime) {
      return EntitlementState.proLocalDev().copyWith(plan: plan);
    }

    return EntitlementState.free();
  }

  Future<void> setLocalPlan(String plan) async {
    if (config.isProduction) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, plan);
  }

  Future<void> setDevUnlockPro(bool value) async {
    if (config.isProduction) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devUnlockKey, value);
  }
}
