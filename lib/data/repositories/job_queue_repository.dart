import 'package:nle_editor/data/database/app_database.dart';

class JobQueueRepository {
  final AppDatabase _db;

  JobQueueRepository(this._db);

  Future<void> insertJob(BackgroundJobsCompanion job) {
    return _db.insertBackgroundJob(job);
  }

  Future<BackgroundJob?> getJob(String jobId) {
    return _db.getBackgroundJob(jobId);
  }

  Stream<List<BackgroundJob>> watchProjectJobs(String projectId) {
    return _db.watchProjectJobs(projectId);
  }

  Stream<List<BackgroundJob>> watchActiveJobs() {
    return _db.watchActiveJobs();
  }

  Future<BackgroundJob?> getNextQueuedJob() {
    return _db.getNextQueuedJob();
  }

  Future<void> updateJobFields(
    String jobId,
    BackgroundJobsCompanion companion,
  ) {
    return _db.updateBackgroundJobFields(jobId, companion);
  }

  Future<void> cancelJob(String jobId) {
    return _db.cancelBackgroundJob(jobId);
  }

  Future<List<BackgroundJob>> getInterruptedJobs({String? projectId}) {
    return _db.getInterruptedBackgroundJobs(projectId: projectId);
  }

  Future<int> markInterruptedJobs({String? projectId}) {
    return _db.markInterruptedBackgroundJobs(projectId: projectId);
  }
}

