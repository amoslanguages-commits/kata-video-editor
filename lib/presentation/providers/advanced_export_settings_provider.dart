import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/export/advanced_export_settings.dart';

final advancedExportSettingsProvider =
    StateProvider.family<Map<String, dynamic>, String>((ref, projectId) {
  return const AdvancedExportSettings().toSettingsMap();
});

void updateAdvancedExportSetting(
  WidgetRef ref,
  String projectId,
  String key,
  Object? value,
) {
  final current = ref.read(advancedExportSettingsProvider(projectId));
  ref.read(advancedExportSettingsProvider(projectId).notifier).state = {
    ...current,
    key: value,
  };
}
