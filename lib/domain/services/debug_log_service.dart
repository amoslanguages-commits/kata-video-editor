import 'dart:async';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/error_log_repository.dart';

/// Provides access to the persistent error log database so that the debug
/// logs viewer UI can display, filter, and clear them.
class DebugLogService {
  final ErrorLogRepository repository;

  DebugLogService({required this.repository});

  /// Watch all recent error logs (up to [limit]).
  Stream<List<AppErrorLog>> watchRecentLogs({int limit = 200}) {
    return repository.watchRecentErrorLogs(limit: limit);
  }

  /// Watch only unresolved logs for a specific project.
  Stream<List<AppErrorLog>> watchUnresolvedLogs({String? projectId}) {
    return repository.watchUnresolvedErrorLogs(projectId: projectId);
  }

  /// Fetch a one-shot snapshot of recent logs.
  Future<List<AppErrorLog>> getRecentLogs({int limit = 200}) {
    return repository.getRecentErrorLogs(limit: limit);
  }

  /// Mark an individual log entry as resolved.
  Future<void> markResolved(String errorId) {
    return repository.markResolved(errorId);
  }

  /// Clear all resolved log entries.
  Future<int> clearResolvedLogs() {
    return repository.clearResolved();
  }

  /// Clear all log entries (danger action — only in dev/debug mode).
  Future<int> clearAllLogs() {
    return repository.clearAll();
  }

  // ── Filtering helpers ─────────────────────────────────────────────────────

  List<AppErrorLog> filterBySeverity(
    List<AppErrorLog> logs,
    String severity,
  ) {
    return logs.where((l) => l.severity == severity).toList();
  }

  List<AppErrorLog> filterByCategory(
    List<AppErrorLog> logs,
    String category,
  ) {
    return logs.where((l) => l.category == category).toList();
  }

  List<AppErrorLog> filterByProject(
    List<AppErrorLog> logs,
    String projectId,
  ) {
    return logs.where((l) => l.projectId == projectId).toList();
  }

  List<AppErrorLog> search(
    List<AppErrorLog> logs,
    String query,
  ) {
    if (query.trim().isEmpty) return logs;
    final q = query.toLowerCase();
    return logs
        .where((l) =>
            l.userMessage.toLowerCase().contains(q) ||
            (l.technicalMessage?.toLowerCase().contains(q) ?? false) ||
            l.code.toLowerCase().contains(q) ||
            l.category.toLowerCase().contains(q))
        .toList();
  }
}
