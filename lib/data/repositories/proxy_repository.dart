import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/media_library/media_project_path_service.dart';
import 'package:nle_editor/domain/proxy/proxy_job_models.dart';
import 'package:nle_editor/domain/proxy/proxy_settings_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class ProxyRepository {
  final db.AppDatabase database;
  final MediaAssetRepository mediaRepository;
  final MediaProjectPathService pathService;

  const ProxyRepository({
    required this.database,
    required this.mediaRepository,
    this.pathService = const MediaProjectPathService(),
  });

  Future<NleProjectProxySettings> getSettings(String projectId) async {
    final raw = await database.getProjectProxySettingsJson(projectId);

    if (raw == null || raw.trim().isEmpty) {
      return const NleProjectProxySettings.defaults();
    }

    try {
      return NleProjectProxySettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const NleProjectProxySettings.defaults();
    }
  }

  Future<void> saveSettings({
    required String projectId,
    required NleProjectProxySettings settings,
  }) {
    return database.updateProjectProxySettingsJson(
      projectId: projectId,
      proxySettingsJson: jsonEncode(settings.toJson()),
    );
  }

  Future<List<NleProxyJob>> getJobs(String projectId) async {
    final rows = await database.getProxyJobsForProject(projectId);
    return rows.map(_jobFromRow).toList();
  }

  Future<List<NleProxyJob>> getRunnableJobs(String projectId) async {
    final rows = await database.getRunnableProxyJobs(projectId);
    return rows.map(_jobFromRow).toList();
  }

  Future<NleProxyJob> createJobForAsset({
    required NleMediaAsset asset,
    required NleProjectProxySettings settings,
    required NleProxyGenerationReason reason,
    NleProxyJobPriority priority = NleProxyJobPriority.normal,
  }) async {
    final sourcePath = asset.resolvedOriginalPath;

    if (sourcePath == null || sourcePath.isEmpty) {
      throw StateError('Asset has no valid source path');
    }

    final id = const Uuid().v4();

    final outputPath = await pathService.createProxyPath(
      projectId: asset.projectId,
      assetId: asset.id,
    );

    final now = DateTime.now();

    final job = NleProxyJob(
      id: id,
      projectId: asset.projectId,
      assetId: asset.id,
      sourcePath: sourcePath,
      outputPath: outputPath,
      status: NleProxyGenerationStatus.queued,
      reason: reason,
      priority: priority,
      spec: settings.videoSpec,
      progress: 0.0,
      createdAt: now,
      updatedAt: now,
      retryCount: 0,
      version: 1,
    );

    await saveJob(job);

    await database.updateMediaAssetProxyStatus(
      assetId: asset.id,
      proxyStatus: NleProxyStatus.queued.name,
    );

    return job;
  }

  Future<void> saveJob(NleProxyJob job) {
    return database.upsertProxyJob(
      db.ProxyJobsCompanion(
        id: Value(job.id),
        projectId: Value(job.projectId),
        assetId: Value(job.assetId),
        sourcePath: Value(job.sourcePath),
        outputPath: Value(job.outputPath),
        status: Value(job.status.name),
        reason: Value(job.reason.name),
        priority: Value(job.priority.name),
        specJson: Value(jsonEncode(job.spec.toJson())),
        progress: Value(job.progress),
        error: Value(job.error),
        createdAt: Value(job.createdAt),
        updatedAt: Value(DateTime.now()),
        startedAt: Value(job.startedAt),
        completedAt: Value(job.completedAt),
        retryCount: Value(job.retryCount),
        version: Value(job.version),
      ),
    );
  }

  Future<void> markGenerating(NleProxyJob job) async {
    await saveJob(
      job.copyWith(
        status: NleProxyGenerationStatus.generating,
        progress: 0.0,
        startedAt: DateTime.now(),
        error: null,
      ),
    );

    await database.updateMediaAssetProxyStatus(
      assetId: job.assetId,
      proxyStatus: NleProxyStatus.generating.name,
    );
  }

  Future<void> markReady({
    required NleProxyJob job,
    required NleProxyMetadata metadata,
  }) async {
    await saveJob(
      job.copyWith(
        status: NleProxyGenerationStatus.ready,
        progress: 1.0,
        completedAt: DateTime.now(),
        error: null,
      ),
    );

    await database.updateMediaAssetProxyReady(
      assetId: job.assetId,
      proxyPath: metadata.proxyPath,
      proxyMetadataJson: jsonEncode(metadata.toJson()),
    );
  }

  Future<void> markFailed({
    required NleProxyJob job,
    required String error,
  }) async {
    await saveJob(
      job.copyWith(
        status: NleProxyGenerationStatus.failed,
        progress: 0.0,
        error: error,
        retryCount: job.retryCount + 1,
      ),
    );

    await database.updateMediaAssetProxyStatus(
      assetId: job.assetId,
      proxyStatus: NleProxyStatus.failed.name,
      proxyError: error,
    );
  }

  Future<void> retryJob(NleProxyJob job) async {
    await saveJob(
      job.copyWith(
        status: NleProxyGenerationStatus.queued,
        progress: 0.0,
        error: null,
      ),
    );

    await database.updateMediaAssetProxyStatus(
      assetId: job.assetId,
      proxyStatus: NleProxyStatus.queued.name,
    );
  }

  Future<void> cancelJob(NleProxyJob job) async {
    await saveJob(
      job.copyWith(
        status: NleProxyGenerationStatus.cancelled,
        progress: 0.0,
      ),
    );

    await database.updateMediaAssetProxyStatus(
      assetId: job.assetId,
      proxyStatus: NleProxyStatus.none.name,
    );
  }

  Future<void> clearAssetProxy(String assetId) {
    return database.clearMediaAssetProxy(assetId: assetId);
  }

  NleProxyJob _jobFromRow(db.ProxyJob row) {
    return NleProxyJob(
      id: row.id,
      projectId: row.projectId,
      assetId: row.assetId,
      sourcePath: row.sourcePath,
      outputPath: row.outputPath,
      status: _enumByName(
        NleProxyGenerationStatus.values,
        row.status,
        NleProxyGenerationStatus.queued,
      ),
      reason: _enumByName(
        NleProxyGenerationReason.values,
        row.reason,
        NleProxyGenerationReason.manual,
      ),
      priority: _enumByName(
        NleProxyJobPriority.values,
        row.priority,
        NleProxyJobPriority.normal,
      ),
      spec: NleProxyVideoSpec.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.specJson) as Map),
      ),
      progress: row.progress,
      error: row.error,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      retryCount: row.retryCount,
      version: row.version,
    );
  }

  T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    final string = name?.toString();
    if (string == null) return fallback;

    for (final value in values) {
      if (value.name == string) return value;
    }

    return fallback;
  }
}
