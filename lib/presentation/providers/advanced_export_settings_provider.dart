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

void updateAdvancedExportSetting(
  WidgetRef ref,
  String projectId,
  String key,
  Object? value,
) {
  final current = ref.read(advancedExportSettingsProvider(projectId));
  final next = {
    ...current,
    key: value,
  };
  ref.read(advancedExportSettingsProvider(projectId).notifier).state = next;
  SharedPreferences.getInstance().then((prefs) {
    prefs.setString(advancedExportSettingsPrefsKey(projectId), jsonEncode(next));
  });
}
