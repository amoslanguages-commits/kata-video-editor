import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/export_repository.dart';
import 'package:nle_editor/domain/services/native_export_service.dart';

class ExportRecoveryReport {
  final String projectId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int staleJobsMarkedFailed;
  final int partialFilesDeleted;
  final List<String> recoveredJobIds;
  final List<String> deletedPartialPaths;
  final List<String> failedCleanupPaths;

  const ExportRecoveryReport({
    required this.projectId,
    required this.startedAt,
    required this.completedAt,
    required this.staleJobsMarkedFailed,
    required this.partialFilesDeleted,
    required this.recoveredJobIds,
    required this.deletedPartialPaths,
    required this.failedCleanupPaths,
  });

  bool get success => failedCleanupPaths.isEmpty;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'staleJobsMarkedFailed': staleJobsMarkedFailed,
        'partialFilesDeleted': partialFilesDeleted,
        'recoveredJobIds': recoveredJobIds,
        'deletedPartialPaths': deletedPartialPaths,
        'failedCleanupPaths': failedCleanupPaths,
        'success': success,
      };
}

class ExportRetryPlan {
  final String sourceJobId;
  final String projectId;
  final Map<String, dynamic> settings;
  final bool canRetry;
  final String? reason;

  const ExportRetryPlan({
    required this.sourceJobId,
    required this.projectId,
    required this.settings,
    required this.canRetry,
    this.reason,
  });
}

class ExportRecoveryService {
  final ExportRepository exportRepository;
  final NativeExportService nativeExportService;

  const ExportRecoveryService({
    required this.exportRepository,
    required this.nativeExportService,
  });

  Future<ExportRecoveryReport> recoverProjectExports({
    required String projectId,
    Duration staleAfter = const Duration(hours: 6),
    bool deletePartialOutputs = true,
  }) async {
    final startedAt = DateTime.now();
    final staleCutoff = startedAt.subtract(staleAfter);
    final staleJobs = await exportRepository.getStaleActiveExports(
      projectId: projectId,
      olderThan: staleCutoff,
    );
    final recoveredJobIds = <String>[];
    final deletedPartialPaths = <String>[];
    final failedCleanupPaths = <String>[];

    for (final job in staleJobs) {
      if (deletePartialOutputs && job.outputPath != null) {
        final deleted = await _deletePartialOutput(job.outputPath!, failedCleanupPaths);
        if (deleted) deletedPartialPaths.add(job.outputPath!);
      }
      await exportRepository.updateExportJob(
        job.id,
        ExportJobsCompanion(
          status: const Value('failed'),
          stage: const Value('Recovered stale export'),
          errorMessage: Value('Export was recovered as failed after being stuck in ${job.status}.'),
          completedAt: Value(DateTime.now()),
        ),
      );
      recoveredJobIds.add(job.id);
    }

    final completedAt = DateTime.now();
    return ExportRecoveryReport(
      projectId: projectId,
      startedAt: startedAt,
      completedAt: completedAt,
      staleJobsMarkedFailed: staleJobs.length,
      partialFilesDeleted: deletedPartialPaths.length,
      recoveredJobIds: recoveredJobIds,
      deletedPartialPaths: deletedPartialPaths,
      failedCleanupPaths: failedCleanupPaths,
    );
  }

  Future<ExportRetryPlan> buildRetryPlan(String jobId) async {
    final job = await exportRepository.getExportJob(jobId);
    if (job == null) {
      return ExportRetryPlan(
        sourceJobId: jobId,
        projectId: '',
        settings: const {},
        canRetry: false,
        reason: 'Export job was not found.',
      );
    }
    final terminalStatuses = {'failed', 'cancelled', 'canceled'};
    if (!terminalStatuses.contains(job.status)) {
      return ExportRetryPlan(
        sourceJobId: job.id,
        projectId: job.projectId,
        settings: const {},
        canRetry: false,
        reason: 'Only failed or cancelled exports can be retried safely.',
      );
    }
    final settings = _decodeSettings(job.settings);
    if (settings.isEmpty) {
      return ExportRetryPlan(
        sourceJobId: job.id,
        projectId: job.projectId,
        settings: const {},
        canRetry: false,
        reason: 'Export job has no usable settings to retry.',
      );
    }
    settings.remove('preflight');
    settings.remove('outputPath');
    settings.remove('outputFileName');
    return ExportRetryPlan(
      sourceJobId: job.id,
      projectId: job.projectId,
      settings: settings,
      canRetry: true,
    );
  }

  Future<String> retryExport(String jobId) async {
    final plan = await buildRetryPlan(jobId);
    if (!plan.canRetry) {
      throw StateError(plan.reason ?? 'Export cannot be retried.');
    }
    final source = await exportRepository.getExportJob(jobId);
    if (source?.outputPath != null) {
      await _deletePartialOutput(source!.outputPath!, <String>[]);
    }
    return nativeExportService.startExport(
      projectId: plan.projectId,
      settings: plan.settings,
    );
  }

  Future<bool> cleanupPartialOutputForJob(String jobId) async {
    final job = await exportRepository.getExportJob(jobId);
    if (job?.outputPath == null) return false;
    final failed = <String>[];
    return _deletePartialOutput(job!.outputPath!, failed);
  }

  Future<bool> _deletePartialOutput(String outputPath, List<String> failedCleanupPaths) async {
    try {
      final file = File(outputPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      failedCleanupPaths.add(outputPath);
      return false;
    }
  }

  Map<String, dynamic> _decodeSettings(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
      if (decoded is Map) return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {}
    return const {};
  }
}
