import 'package:drift/drift.dart';
import 'package:nle_editor/data/database/app_database.dart';

class ProjectRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  Stream<List<Project>> watchAllProjects() => _db.watchAllProjects();
  Future<List<Project>> getAllProjects() => _db.getAllProjects();
  Future<Project?> getProject(String projectId) => _db.getProject(projectId);

  Future<void> insertProject(ProjectsCompanion project) =>
      _db.insertProject(project);

  Future<void> updateProjectFields(
          String projectId, ProjectsCompanion companion) =>
      _db.updateProjectFields(projectId, companion);

  Future<void> touchProject(String projectId) =>
      _db.touchProject(projectId);

  Future<void> updateProjectDuration(String projectId, int durationMicros) =>
      _db.updateProjectDuration(projectId, durationMicros);

  Future<void> markOpened(String projectId) {
    return (_db.update(_db.projects)
          ..where((p) => p.id.equals(projectId)))
        .write(
      ProjectsCompanion(
        lastOpenedAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteProjectSafely(String projectId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.exportJobs)
            ..where((e) => e.projectId.equals(projectId)))
          .go();
      await (_db.delete(_db.undoStack)
            ..where((u) => u.projectId.equals(projectId)))
          .go();
      await (_db.delete(_db.projects)
            ..where((p) => p.id.equals(projectId)))
          .go();
    });
  }

  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  Future<void> updateRecoveryStatus({
    required String projectId,
    required String recoveryStatus,
  }) {
    return _db.updateProjectRecoveryStatus(
      projectId: projectId,
      recoveryStatus: recoveryStatus,
    );
  }
}

