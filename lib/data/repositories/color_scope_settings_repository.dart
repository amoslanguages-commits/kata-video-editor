import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';

class ColorScopeSettingsRepository {
  static const _key = 'nle.colorScopes.settings.v1';

  const ColorScopeSettingsRepository();

  Future<NleScopeSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.trim().isEmpty) {
      return const NleScopeSettings.defaultMobile();
    }

    try {
      return NleScopeSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const NleScopeSettings.defaultMobile();
    }
  }

  Future<void> save(NleScopeSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
