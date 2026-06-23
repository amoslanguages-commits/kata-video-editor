import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/domain/export/advanced_export_settings.dart';

final advancedExportSettingsProvider =
    StateProvider.family<Map<String, dynamic>, String>((ref, projectId) {
  return const AdvancedExportSettings().toSettingsMap();
});

String advancedExportSettingsPrefsKey(String projectId) {
  return 'nle.export.advanced_settings.$projectId';
}

Future<Map<String, dynamic>> loadAdvancedExportSettings(String projectId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(advancedExportSettingsPrefsKey(projectId));
  if (raw == null || raw.trim().isEmpty) {
    return const AdvancedExportSettings().toSettingsMap();
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}

  return const AdvancedExportSettings().toSettingsMap();
}

void updateAdvancedExportSetting(
  WidgetRef ref,
  String projectId,
  String key,
  Object? value,
) {
  final current = ref.read(advancedExportSettingsProvider(projectId));
  final next = <String, dynamic>{
    ...current,
    key: value,
  };
  ref.read(advancedExportSettingsProvider(projectId).notifier).state = next;
  SharedPreferences.getInstance().then((prefs) {
    prefs.setString(advancedExportSettingsPrefsKey(projectId), jsonEncode(next));
  });
}
