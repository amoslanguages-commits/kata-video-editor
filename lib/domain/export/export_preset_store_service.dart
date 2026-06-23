import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/domain/export/export_preset_builder_models.dart';

class ExportPresetStoreService {
  const ExportPresetStoreService();

  String _key(String projectId) => 'nle.export.custom_presets.$projectId';

  Future<List<NleExportPresetSpec>> loadCustomPresets(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(projectId));
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .map(NleExportPresetSpec.fromJson)
          .where((preset) => !preset.isBuiltIn)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<NleExportPresetSpec>> loadAllPresets(String projectId) async {
    final builtIn = NleExportPresetCatalog.builtInPresets();
    final custom = await loadCustomPresets(projectId);
    return [...builtIn, ...custom];
  }

  Future<void> saveCustomPreset({
    required String projectId,
    required NleExportPresetSpec preset,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustomPresets(projectId);
    final updatedPreset = preset.copyWith(
      isBuiltIn: false,
      updatedAt: DateTime.now(),
    );

    final next = [
      for (final item in current)
        if (item.id != updatedPreset.id) item,
      updatedPreset,
    ];

    await prefs.setString(
      _key(projectId),
      jsonEncode(next.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  Future<void> deleteCustomPreset({
    required String projectId,
    required String presetId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustomPresets(projectId);
    final next = current.where((item) => item.id != presetId).toList(growable: false);
    await prefs.setString(
      _key(projectId),
      jsonEncode(next.map((item) => item.toJson()).toList(growable: false)),
    );
  }
}
