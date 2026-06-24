import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/models/temporary_export_progress.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

class TemporaryExportService {
  final AssetRepository assetRepository;
  final TimelineRepository timelineRepository;
  final ProjectStorageService storageService;

  const TemporaryExportService({
    required this.assetRepository,
    required this.timelineRepository,
    required this.storageService,
  });

  Stream<TemporaryExportProgress> exportSimpleV1Sequence({
    required String projectId,
    required int targetWidth,
    required int targetHeight,
    required int frameRate,
    required String preset,
    required String bitrate,
    String? outputFileName,
  }) async* {
    throw StateError(
      'This export entrypoint is closed. Use NativeExportService and the canonical render graph export pipeline.',
    );
  }
}
