import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;

class BetaCrashLogger {
  final AppDatabase database;

  const BetaCrashLogger({required this.database});

  Future<void> init() async {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logError(
        category: 'flutter_error',
        code: 'framework_exception',
        userMessage: 'An internal UI error occurred.',
        technicalMessage: '${details.exception}\n${details.stack}',
        severity: 'fail',
      );
    };

    // Catch asynchronous errors outside the Flutter framework
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      logError(
        category: 'platform_error',
        code: 'async_exception',
        userMessage: 'An unexpected application crash occurred.',
        technicalMessage: '$error\n$stack',
        severity: 'fail',
      );
      return true;
    };
  }

  Future<void> logError({
    required String category,
    required String code,
    required String userMessage,
    String? technicalMessage,
    String severity = 'warning',
    String? projectId,
  }) async {
    try {
      final logEntry = AppErrorLogsCompanion(
        id: Value(const Uuid().v4()),
        category: Value(category),
        code: Value(code),
        severity: Value(severity),
        userMessage: Value(userMessage),
        technicalMessage: Value(technicalMessage),
        projectId: Value(projectId),
        createdAt: Value(DateTime.now()),
      );

      await database.into(database.appErrorLogs).insert(logEntry);
      
      // Also print to console
      debugPrint('[BETA_CRASH_LOGGER] ($severity) $category/$code: $userMessage\nTechnical: $technicalMessage');
    } catch (e) {
      debugPrint('[BETA_CRASH_LOGGER] Failed to write log to DB: $e');
    }
  }
}
