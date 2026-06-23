import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/error_log_repository.dart';
import 'package:nle_editor/domain/errors/app_error.dart';
import 'package:nle_editor/domain/errors/app_error_mapper.dart';
import 'package:nle_editor/domain/errors/native_error_mapper.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

class ErrorReportingService {
  final ErrorLogRepository repository;

  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();

  ErrorReportingService({
    required this.repository,
  });

  Stream<AppError> get errors => _errorController.stream;

  Future<AppError> report(
    AppError error, {
    bool notify = true,
  }) async {
    await repository.insertErrorLog(
      AppErrorLogsCompanion.insert(
        id: error.id,
        category: error.category,
        code: error.code,
        severity: Value(error.severity),
        userMessage: error.userMessage,
        technicalMessage: Value(error.technicalMessage),
        recoverySuggestion: Value(error.recoverySuggestion),
        projectId: Value(error.projectId),
        source: Value(error.source),
        nativeCode: Value(error.nativeCode),
        actionLabel: Value(error.action?.label),
        actionPayload: Value(
          error.action == null ? '{}' : jsonEncode(error.action!.toJson()),
        ),
        contextJson: Value(jsonEncode(error.context)),
      ),
    );

    if (notify) {
      _errorController.add(error);
    }

    return error;
  }

  Future<AppError> reportException(
    Object exception, {
    StackTrace? stackTrace,
    String? projectId,
    String? source,
    Map<String, dynamic>? context,
    bool notify = true,
  }) {
    final error = AppErrorMapper.fromException(
      exception,
      stackTrace: stackTrace,
      projectId: projectId,
      source: source,
      context: context,
    );

    return report(error, notify: notify);
  }

  Future<AppError> reportNativeEvent(
    NativeEvent event, {
    bool notify = true,
  }) {
    final error = NativeErrorMapper.fromNativeEvent(event);
    return report(error, notify: notify);
  }

  Future<void> markResolved(String errorId) {
    return repository.markResolved(errorId);
  }

  Future<void> dispose() async {
    await _errorController.close();
  }
}
