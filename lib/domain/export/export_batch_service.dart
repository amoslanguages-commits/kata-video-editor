import 'package:nle_editor/domain/export/export_preset_builder_models.dart';
import 'package:nle_editor/domain/services/native_export_service.dart';

class ExportBatchService {
  final NativeExportService nativeExportService;

  const ExportBatchService({required this.nativeExportService});

  Future<List<String>> startBatch({
    required String projectId,
    required List<NleExportPresetSpec> presets,
    Map<String, dynamic> sharedSettings = const {},
  }) async {
    final jobIds = <String>[];
    for (final preset in presets) {
      final jobId = await nativeExportService.startExport(
        projectId: projectId,
        settings: {
          ...sharedSettings,
          ...preset.exportSettings,
          'presetName': preset.name,
          'batchExport': true,
          'batchPresetId': preset.id,
        },
      );
      jobIds.add(jobId);
    }
    return jobIds;
  }
}
