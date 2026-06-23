import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

class NleMediaImportRequest {
  final String projectId;
  final List<String> sourcePaths;
  final String? targetBinId;
  final NleMediaImportSource importSource;
  final NleMediaStorageMode storageMode;
  final bool generateThumbnails;
  final bool generateWaveforms;
  final bool detectDuplicates;
  final bool createProxyPlaceholder;

  const NleMediaImportRequest({
    required this.projectId,
    required this.sourcePaths,
    this.targetBinId,
    required this.importSource,
    required this.storageMode,
    required this.generateThumbnails,
    required this.generateWaveforms,
    required this.detectDuplicates,
    required this.createProxyPlaceholder,
  });
}

class NleMediaImportItemResult {
  final String sourcePath;
  final NleMediaAsset? asset;
  final bool success;
  final bool duplicate;
  final String? error;

  const NleMediaImportItemResult({
    required this.sourcePath,
    this.asset,
    required this.success,
    required this.duplicate,
    this.error,
  });
}

class NleMediaImportResult {
  final List<NleMediaImportItemResult> items;

  const NleMediaImportResult({
    required this.items,
  });

  int get importedCount => items.where((item) => item.success).length;
  int get failedCount => items.where((item) => !item.success).length;
  int get duplicateCount => items.where((item) => item.duplicate).length;
}
