import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart';

class ExportRepository {
  final AppDatabase _db;

  ExportRepository(this._db);

  Stream<List<ExportJob>> watchProjectExports(String projectId) {
    return _db.watchProjectExports(projectId);
  }

  Future<List<ExportJob>> getProjectExports(String projectId) {
    return (_db.select(_db.exportJobs)
          ..where((tbl) => tbl.projectId.equals(projectId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  Future<ExportJob?> getExportJob(String jobId) {
    return (_db.select(_db.exportJobs)..where((tbl) => tbl.id.equals(jobId)))
        .getSingleOrNull();
  }

  Future<List<ExportJob>> getActiveProjectExports(String projectId) {
    return (_db.select(_db.exportJobs)
          ..where((tbl) =>
              tbl.projectId.equals(projectId) &
              tbl.status.isIn(const ['pending', 'running', 'paused']))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<List<ExportJob>> getStaleActiveExports({
    required String projectId,
    required DateTime olderThan,
  }) {
    return (_db.select(_db.exportJobs)
          ..where((tbl) =>
              tbl.projectId.equals(projectId) &
              tbl.status.isIn(const ['pending', 'running', 'paused']) &
              tbl.createdAt.isSmallerThanValue(olderThan))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<void> insertExportJob(ExportJobsCompanion job) {
    return _db.insertExportJob(job);
  }

  Future<void> updateExportJob(String jobId, ExportJobsCompanion companion) {
    return _db.updateExportJob(jobId, companion);
  }

  Future<int> deleteExportJob(String jobId) {
    return (_db.delete(_db.exportJobs)..where((tbl) => tbl.id.equals(jobId))).go();
  }

  Future<int> deleteProjectExportsByStatus({
    required String projectId,
    required List<String> statuses,
  }) {
    if (statuses.isEmpty) return Future.value(0);
    return (_db.delete(_db.exportJobs)
          ..where((tbl) => tbl.projectId.equals(projectId) & tbl.status.isIn(statuses)))
        .go();
  }

  Future<int> deleteCompletedExports(String projectId) {
    return deleteProjectExportsByStatus(
      projectId: projectId,
      statuses: const ['completed', 'done', 'success'],
    );
  }

  Future<int> deleteFailedExports(String projectId) {
    return deleteProjectExportsByStatus(
      projectId: projectId,
      statuses: const ['failed', 'error', 'cancelled', 'canceled'],
    );
  }
}
