import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/domain/monetization/pro_entitlement.dart';

class EntitlementCache {
  static const _key = 'pro_entitlement_cache_v1';

  Future<ProEntitlement> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      return ProEntitlement.free();
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;

      return ProEntitlement(
        status: _statusFromString(json['status']?.toString()),
        activeProductId: json['activeProductId']?.toString(),
        store: json['store']?.toString(),
        expiresAt: _date(json['expiresAt']),
        purchasedAt: _date(json['purchasedAt']),
        trialEndsAt: _date(json['trialEndsAt']),
        autoRenews: json['autoRenews'] == true,
        locallyGranted: json['locallyGranted'] == true,
        verified: json['verified'] == true,
        verificationSource: json['verificationSource']?.toString(),
        unlockedFeatureIds: (json['unlockedFeatureIds'] as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            const {},
        updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
      );
    } catch (_) {
      return ProEntitlement.free();
    }
  }

  Future<void> save(ProEntitlement entitlement) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode(
        {
          'status': entitlement.status.name,
          'activeProductId': entitlement.activeProductId,
          'store': entitlement.store,
          'expiresAt': entitlement.expiresAt?.toIso8601String(),
          'purchasedAt': entitlement.purchasedAt?.toIso8601String(),
          'trialEndsAt': entitlement.trialEndsAt?.toIso8601String(),
          'autoRenews': entitlement.autoRenews,
          'locallyGranted': entitlement.locallyGranted,
          'verified': entitlement.verified,
          'verificationSource': entitlement.verificationSource,
          'unlockedFeatureIds': entitlement.unlockedFeatureIds.toList(),
          'updatedAt': entitlement.updatedAt.toIso8601String(),
        },
      ),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  ProPlanStatus _statusFromString(String? value) {
    for (final status in ProPlanStatus.values) {
      if (status.name == value) return status;
    }

    return ProPlanStatus.unknown;
  }
}
