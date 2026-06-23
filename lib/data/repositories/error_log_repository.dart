import 'package:nle_editor/data/database/app_database.dart';

class ErrorLogRepository {
  final AppDatabase _db;

  ErrorLogRepository(this._db);

  Future<void> insertErrorLog(AppErrorLogsCompanion log) {
    return _db.insertAppErrorLog(log);
  }

  Stream<List<AppErrorLog>> watchRecentErrorLogs({
    int limit = 100,
  }) {
    return _db.watchRecentErrorLogs(limit: limit);
  }

  Stream<List<AppErrorLog>> watchUnresolvedErrorLogs({
    String? projectId,
  }) {
    return _db.watchUnresolvedErrorLogs(projectId: projectId);
  }

  Future<List<AppErrorLog>> getRecentErrorLogs({
    int limit = 100,
  }) {
    return _db.getRecentErrorLogs(limit: limit);
  }

  Future<void> markResolved(String errorId) {
    return _db.markAppErrorResolved(errorId);
  }

  Future<int> clearResolved() {
    return _db.clearResolvedAppErrors();
  }

  Future<int> clearAll() {
    return _db.clearAllAppErrorLogs();
  }
}
