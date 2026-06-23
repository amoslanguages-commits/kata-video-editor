import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/export_repository.dart';
import 'package:nle_editor/domain/export/export_filename_builder.dart';
import 'package:nle_editor/domain/export/export_filename_versioner.dart';
import 'package:nle_editor/domain/render_graph/render_graph_service.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_export_job.dart';

/// Triggers a native export job and writes a pending record to the
/// [ExportJobs] Drift table.
///
/// Progress updates and final result are handled asynchronously by
/// [NativeExportEventController], which listens to native events and
/// updates the DB row accordingly.
class NativeExportService {
  final NativeBridgeContract nativeBridge;
  final ExportRepository exportRepository;
  final RenderGraphService renderGraphService;
  final ProjectStorageService storageService;
  final AppDatabase database;

  static const _uuid = Uuid();

  NativeExportService({
    required this.nativeBridge,
    required this.exportRepository,
    required this.renderGraphService,
    required this.storageService,
    required this.database,
  });

  /// Starts a native export for [projectId] using [settings].
  ///
  /// Returns the [jobId] that was submitted to the native engine.
  ///
  /// [settings] accepts:
  ///   - `resolution`  : int (output height, e.g. 1080)
  ///   - `frameRate`   : int (e.g. 30)
  ///   - `bitrate`     : String (e.g. "8M")
  ///   - `aspectRatio` : String (e.g. "16:9")
  Future<String> startExport({
    required String projectId,
    required Map<String, dynamic> settings,
  }) async {
    final jobId = _uuid.v4();

    // Build the render graph JSON string
    final renderGraphJson = await renderGraphService.buildProjectGraph(projectId);

    // Fetch project configuration directly from DB
    final project = await database.getProjectById(projectId);

    // Resolve output path
    final folders = await storageService.getProjectFolders(projectId);
    final requestedName = settings['outputFileName']?.toString().trim();
    final outputFileName = requestedName == null || requestedName.isEmpty
        ? const ExportFilenameBuilder().build(
            pattern: settings['filenamePattern']?.toString() ??
                ExportFilenamePatterns.defaultPattern,
            projectName: project.name,
            presetName: settings['presetName']?.toString() ??
                settings['preset']?.toString() ??
                'export',
            platform: settings['platform']?.toString() ?? 'video',
            resolution: '${settings['width'] ?? project.targetWidth}x${settings['resolution'] ?? project.targetHeight}',
            extension: settings['format']?.toString() ?? 'mp4',
            version: (DateTime.now().millisecondsSinceEpoch % 99) + 1,
          )
        : requestedName;
    final outputPath = await const ExportFilenameVersioner().uniquePath(
      directoryPath: folders.exports,
      fileName: outputFileName,
    );
    final finalOutputFileName = p.basename(outputPath);

    // Build export profile using DB project config
    final aspectRatio = project.aspectRatio;
    final profile = NativeExportProfile.fromSettings({
      ...settings,
      'aspectRatio': aspectRatio,
      'resolution': settings['resolution'] ?? project.targetHeight,
      'frameRate': settings['frameRate'] ?? project.targetFrameRate,
      'outputFileName': finalOutputFileName,
    });

    // Insert pending export record
    await exportRepository.insertExportJob(
      ExportJobsCompanion.insert(
        id: jobId,
        projectId: projectId,
        status: const Value('running'),
        progress: const Value(0),
        stage: const Value('Preparing'),
        settings: jsonEncode({
          ...settings,
          'outputFileName': finalOutputFileName,
        }),
      ),
    );

    // Submit to native engine
    final result = await nativeBridge.startExportJob(
      projectId: projectId,
      jobId: jobId,
      renderGraphJson: renderGraphJson,
      outputPath: outputPath,
      profile: profile.toMap(),
    );

    if (!result.accepted) {
      await exportRepository.updateExportJob(
        jobId,
        ExportJobsCompanion(
          status: const Value('failed'),
          stage: const Value('Failed'),
          errorMessage: Value(result.message ?? 'Export rejected by native engine.'),
        ),
      );
      throw StateError(result.message ?? 'Export request rejected by native engine.');
    }

    return jobId;
  }

  /// Cancels an in-progress native export.
  Future<void> cancelExport({required String jobId}) async {
    final result = await nativeBridge.cancelExportJob(jobId: jobId);
    if (!result.accepted) {
      throw StateError(result.message ?? 'Cancel request failed.');
    }
  }
}
