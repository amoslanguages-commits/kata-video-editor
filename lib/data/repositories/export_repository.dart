import 'package:nle_editor/data/database/app_database.dart';

class ExportRepository {
  final AppDatabase _db;

  ExportRepository(this._db);

  Stream<List<ExportJob>> watchProjectExports(String projectId) {
    return _db.watchProjectExports(projectId);
  }

  Future<void> insertExportJob(ExportJobsCompanion job) {
    return _db.insertExportJob(job);
  }

  Future<void> updateExportJob(String jobId, ExportJobsCompanion companion) {
    return _db.updateExportJob(jobId, companion);
  }
}
