import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/export/export_preset_builder_models.dart';
import 'package:nle_editor/domain/export/export_preset_store_service.dart';

final exportPresetStoreServiceProvider = Provider<ExportPresetStoreService>((ref) {
  return const ExportPresetStoreService();
});

final projectExportPresetsProvider =
    FutureProvider.family<List<NleExportPresetSpec>, String>((ref, projectId) {
  return ref.watch(exportPresetStoreServiceProvider).loadAllPresets(projectId);
});

final builtInExportPresetsProvider = Provider<List<NleExportPresetSpec>>((ref) {
  return NleExportPresetCatalog.builtInPresets();
});
