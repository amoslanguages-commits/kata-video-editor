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
      final presets = decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .map(NleExportPresetSpec.fromJson)
          .where((preset) => !preset.isBuiltIn)
          .toList(growable: false);
      return _sorted(presets);
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
    final existing = current.where((item) => item.id == preset.id).firstOrNull;
    final updatedPreset = preset.copyWith(
      isBuiltIn: false,
      sortOrder: preset.sortOrder == 0
          ? existing?.sortOrder ?? _nextSortOrder(current)
          : preset.sortOrder,
      updatedAt: DateTime.now(),
    );

    final next = [
      for (final item in current)
        if (item.id != updatedPreset.id) item,
      updatedPreset,
    ];

    await _saveCustomPresets(prefs, projectId, _sorted(next));
  }

  Future<void> setFavorite({
    required String projectId,
    required String presetId,
    required bool isFavorite,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustomPresets(projectId);
    final next = [
      for (final item in current)
        item.id == presetId
            ? item.copyWith(isFavorite: isFavorite, updatedAt: DateTime.now())
            : item,
    ];
    await _saveCustomPresets(prefs, projectId, _sorted(next));
  }

  Future<void> moveCustomPreset({
    required String projectId,
    required String presetId,
    required int direction,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustomPresets(projectId);
    final index = current.indexWhere((item) => item.id == presetId);
    if (index < 0) return;
    final target = (index + direction).clamp(0, current.length - 1).toInt();
    if (target == index) return;

    final reordered = [...current];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);

    final next = <NleExportPresetSpec>[
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(sortOrder: (i + 1) * 10, updatedAt: DateTime.now()),
    ];
    await _saveCustomPresets(prefs, projectId, next);
  }

  Future<void> deleteCustomPreset({
    required String projectId,
    required String presetId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCustomPresets(projectId);
    final next = current.where((item) => item.id != presetId).toList(growable: false);
    await _saveCustomPresets(prefs, projectId, _sorted(next));
  }

  List<NleExportPresetSpec> _sorted(List<NleExportPresetSpec> presets) {
    final next = [...presets];
    next.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return next;
  }

  int _nextSortOrder(List<NleExportPresetSpec> presets) {
    if (presets.isEmpty) return 10;
    final maxOrder = presets
        .map((item) => item.sortOrder)
        .fold<int>(0, (previous, value) => value > previous ? value : previous);
    return maxOrder + 10;
  }

  Future<void> _saveCustomPresets(
    SharedPreferences prefs,
    String projectId,
    List<NleExportPresetSpec> presets,
  ) async {
    await prefs.setString(
      _key(projectId),
      jsonEncode(presets.map((item) => item.toJson()).toList(growable: false)),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
