import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/error_log_repository.dart';
import 'package:nle_editor/domain/errors/app_error.dart';
import 'package:nle_editor/domain/errors/app_error_mapper.dart';
import 'package:nle_editor/domain/errors/native_error_mapper.dart';
import 'package:nle_editor/domain/services/error_reporting_service.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

void main() {
  late AppDatabase db;
  late ErrorLogRepository repository;
  late ErrorReportingService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ErrorLogRepository(db);
    service = ErrorReportingService(repository: repository);
  });

  tearDown(() async {
    await service.dispose();
    await db.close();
  });

  group('AppErrorMapper Tests', () {
    test('maps FileSystemException to storageWriteFailed', () {
      const fsException = FileSystemException('Write failed', 'path/to/file');
      final error = AppErrorMapper.fromException(fsException);

      expect(error.category, equals(AppErrorCategory.storage));
      expect(error.code, equals(AppErrorCode.storageWriteFailed));
      expect(error.severity, equals(AppErrorSeverity.error));
      expect(error.action?.actionId, equals(AppErrorActionId.freeStorage));
    });

    test('maps permission exceptions to permissionDenied', () {
      final exception = Exception('User denied access permission');
      final error = AppErrorMapper.fromException(exception);

      expect(error.category, equals(AppErrorCategory.permission));
      expect(error.code, equals(AppErrorCode.permissionDenied));
      expect(error.severity, equals(AppErrorSeverity.warning));
      expect(error.action?.actionId, equals(AppErrorActionId.openSettings));
    });

    test('maps not found / missing exceptions to originalFileMissing', () {
      final exception = Exception('File not found in folder');
      final error = AppErrorMapper.fromException(exception);

      expect(error.category, equals(AppErrorCategory.missingFile));
      expect(error.code, equals(AppErrorCode.originalFileMissing));
      expect(error.severity, equals(AppErrorSeverity.error));
      expect(error.action?.actionId, equals(AppErrorActionId.reconnectMedia));
    });
  });

  group('NativeErrorMapper Tests', () {
    test('maps missingFile NativeEvent to originalFileMissing AppError', () {
      final event = NativeEvent(
        id: 'evt_1',
        type: NativeEventTypes.missingFile,
        projectId: 'project_123',
        payload: const {'message': 'File is gone'},
        createdAt: DateTime.now(),
      );
      final error = NativeErrorMapper.fromNativeEvent(event);

      expect(error.category, equals(AppErrorCategory.missingFile));
      expect(error.code, equals(AppErrorCode.originalFileMissing));
      expect(error.projectId, equals('project_123'));
      expect(error.action?.actionId, equals(AppErrorActionId.reconnectMedia));
    });

    test('maps memoryWarning NativeEvent to memoryPressure AppError', () {
      final event = NativeEvent(
        id: 'evt_2',
        type: NativeEventTypes.memoryWarning,
        projectId: 'project_123',
        payload: const {'code': 'MEM_LOW', 'message': 'Memory is low'},
        createdAt: DateTime.now(),
      );
      final error = NativeErrorMapper.fromNativeEvent(event);

      expect(error.category, equals(AppErrorCategory.memory));
      expect(error.code, equals(AppErrorCode.memoryPressure));
      expect(error.nativeCode, equals('MEM_LOW'));
      expect(error.severity, equals(AppErrorSeverity.warning));
    });
  });

  group('ErrorReportingService Tests', () {
    test('reports and notifies listeners, inserts to db', () async {
      final error = AppError(
        category: AppErrorCategory.unknown,
        code: AppErrorCode.unknown,
        severity: AppErrorSeverity.error,
        userMessage: 'Test error message',
      );

      final events = <AppError>[];
      final subscription = service.errors.listen(events.add);

      await service.report(error);

      // Wait briefly for the broadcast stream event
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.length, equals(1));
      expect(events.first.id, equals(error.id));

      final recentLogs = await repository.getRecentErrorLogs();
      expect(recentLogs.length, equals(1));
      expect(recentLogs.first.id, equals(error.id));
      expect(recentLogs.first.userMessage, equals('Test error message'));
      expect(recentLogs.first.isResolved, isFalse);

      await subscription.cancel();
    });

    test('reporting exception maps and stores correctly', () async {
      final exception = Exception('Disk is full');
      await service.reportException(exception, projectId: 'project_full');

      final recentLogs = await repository.getRecentErrorLogs();
      expect(recentLogs.length, equals(1));
      expect(recentLogs.first.projectId, equals('project_full'));
      expect(recentLogs.first.category, equals(AppErrorCategory.storage));
      expect(recentLogs.first.code, equals(AppErrorCode.storageLow));
    });
  });
}
