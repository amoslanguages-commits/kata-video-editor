import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/export_repository.dart';
import 'package:nle_editor/domain/export/advanced_export_settings.dart';
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

  Future<String> startExport({
    required String projectId,
    required Map<String, dynamic> settings,
  }) async {
    final jobId = _uuid.v4();
    final persistedAdvancedSettings = await _loadAdvancedSettings(projectId);
    final mergedSettings = {
      ...persistedAdvancedSettings,
      ...settings,
    };
    final advanced = AdvancedExportSettings.fromMap(mergedSettings);

    final permissionResult =
        await nativeBridge.checkExportPermissions(settings: mergedSettings);
    if (!permissionResult.accepted) {
      throw StateError(permissionResult.message ?? 'Export permissions are not ready.');
    }

    final renderGraphJson = await renderGraphService.buildProjectGraph(projectId);

    if (advanced.enableMultiTrackQa) {
      final qaResult = await nativeBridge.validateExportGraph(
        projectId: projectId,
        renderGraphJson: renderGraphJson,
        settings: mergedSettings,
      );
      if (!qaResult.accepted) {
        throw StateError(qaResult.message ?? 'Export validation failed.');
      }
    }

    final project = await database.getProjectById(projectId);
    final folders = await storageService.getProjectFolders(projectId);
    final outputDirectory = await _resolveOutputDirectory(
      fallbackExportsPath: folders.exports,
      advanced: advanced,
    );

    final requestedName = mergedSettings['outputFileName']?.toString().trim();
    final outputFileName = requestedName == null || requestedName.isEmpty
        ? const ExportFilenameBuilder().build(
            pattern: mergedSettings['filenamePattern']?.toString() ??
                ExportFilenamePatterns.defaultPattern,
            projectName: project.name,
            presetName: mergedSettings['presetName']?.toString() ??
                mergedSettings['preset']?.toString() ??
                'export',
            platform: mergedSettings['platform']?.toString() ?? 'video',
            resolution:
                '${mergedSettings['width'] ?? project.targetWidth}x${mergedSettings['resolution'] ?? project.targetHeight}',
            extension: mergedSettings['format']?.toString() ?? 'mp4',
            version: (DateTime.now().millisecondsSinceEpoch % 99) + 1,
          )
        : requestedName;

    final outputPath = await const ExportFilenameVersioner().uniquePath(
      directoryPath: outputDirectory,
      fileName: outputFileName,
    );
    final finalOutputFileName = p.basename(outputPath);

    final aspectRatio = project.aspectRatio;
    final finalSettings = {
      ...mergedSettings,
      'aspectRatio': aspectRatio,
      'resolution': mergedSettings['resolution'] ?? project.targetHeight,
      'frameRate': mergedSettings['frameRate'] ?? project.targetFrameRate,
      'outputFileName': finalOutputFileName,
      'outputPath': outputPath,
      'destinationMode': advanced.destinationMode,
    };
    final profile = NativeExportProfile.fromSettings(finalSettings);

    await exportRepository.insertExportJob(
      ExportJobsCompanion.insert(
        id: jobId,
        projectId: projectId,
        status: const Value('running'),
        progress: const Value(0),
        stage: const Value('Preparing'),
        settings: jsonEncode(finalSettings),
      ),
    );

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

    if (advanced.showCompletionNotification) {
      await nativeBridge.scheduleExportNotification(
        jobId: jobId,
        title: 'Export started',
        body: finalOutputFileName,
      );
    }

    return jobId;
  }

  Future<Map<String, dynamic>> _loadAdvancedSettings(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('nle.export.advanced_settings.$projectId');
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

  Future<String> _resolveOutputDirectory({
    required String fallbackExportsPath,
    required AdvancedExportSettings advanced,
  }) async {
    if (advanced.destinationMode == ExportDestinationModes.customFolder &&
        advanced.customDirectoryPath != null &&
        advanced.customDirectoryPath!.trim().isNotEmpty) {
      final directory = Directory(advanced.customDirectoryPath!.trim());
      await directory.create(recursive: true);
      return directory.path;
    }
    return fallbackExportsPath;
  }

  Future<void> pauseExport({required String jobId}) async {
    final result = await nativeBridge.pauseExportJob(jobId: jobId);
    if (!result.accepted) {
      throw StateError(result.message ?? 'Pause request failed.');
    }
    await exportRepository.updateExportJob(
      jobId,
      const ExportJobsCompanion(status: Value('paused'), stage: Value('Paused')),
    );
  }

  Future<void> resumeExport({required String jobId}) async {
    final result = await nativeBridge.resumeExportJob(jobId: jobId);
    if (!result.accepted) {
      throw StateError(result.message ?? 'Resume request failed.');
    }
    await exportRepository.updateExportJob(
      jobId,
      const ExportJobsCompanion(status: Value('running'), stage: Value('Resuming')),
    );
  }

  Future<void> cancelExport({required String jobId}) async {
    final result = await nativeBridge.cancelExportJob(jobId: jobId);
    if (!result.accepted) {
      throw StateError(result.message ?? 'Cancel request failed.');
    }
  }

  Future<void> openExportFile({required String outputPath}) async {
    final result = await nativeBridge.openExportFile(outputPath: outputPath);
    if (!result.accepted) {
      throw StateError(result.message ?? 'Open file request failed.');
    }
  }

  Future<void> openExportFolder({required String outputPath}) async {
    final result = await nativeBridge.openExportFolder(outputPath: outputPath);
    if (!result.accepted) {
      throw StateError(result.message ?? 'Open folder request failed.');
    }
  }

  Future<void> recoverExportJobs({required String projectId}) async {
    await nativeBridge.recoverExportJobs(projectId: projectId);
  }
}
