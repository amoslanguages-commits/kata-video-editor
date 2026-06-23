import 'package:flutter/services.dart';

import 'package:nle_editor/domain/sync/sync_qa_models.dart';

/// Dart bridge for 29D Android sync QA routes.
///
/// Calls the same [MethodChannel] as [AndroidNativeBridge] but returns
/// the raw `result` payload from the router so sync telemetry can be
/// decoded into typed [SyncQaReport] objects.
class NativeSyncQaService {
  static const _methodChannel = MethodChannel('nle_editor/native_methods');

  const NativeSyncQaService();

  // ── Commands ──────────────────────────────────────────────────────────────

  /// Triggers the export sync QA report built from telemetry collected
  /// during the most recent export.
  Future<SyncQaReport> runExportSync() async {
    return _callAndParse('qa_run_export_sync', const {});
  }

  /// Triggers the preview sync QA report built from telemetry collected
  /// during the most recent preview playback session.
  Future<SyncQaReport> runPreviewSync() async {
    return _callAndParse('qa_run_preview_sync', const {});
  }

  /// Clears all accumulated sync telemetry on the native side.
  /// Call before starting a new export or preview if you want a clean slate.
  Future<void> clearSyncTelemetry() async {
    try {
      await _methodChannel.invokeMethod<dynamic>(
        'qa_clear_sync_telemetry',
        const {},
      );
    } on PlatformException catch (e) {
      // Non-fatal — log and continue.
      // ignore: avoid_print
      print('[NativeSyncQaService] clearSyncTelemetry error: ${e.message}');
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<SyncQaReport> _callAndParse(
    String method,
    Map<String, dynamic> args,
  ) async {
    try {
      final raw = await _methodChannel.invokeMethod<dynamic>(method, args);
      final outerMap = _toStringDynamic(raw);

      // The router wraps every response as:
      // { "success": true, "method": "...", "result": { ... } }
      if (outerMap['success'] == true) {
        final resultMap = _toStringDynamic(outerMap['result']);
        return SyncQaReport.fromJson(resultMap);
      }

      // On failure, return a synthetic "failed" report so the UI can show
      // the error without crashing.
      final errorMap = _toStringDynamic(outerMap['error']);
      return _errorReport(
        method: method,
        message: errorMap['message']?.toString() ?? 'Native sync QA failed.',
      );
    } on PlatformException catch (e) {
      return _errorReport(
        method: method,
        message: e.message ?? 'PlatformException during sync QA.',
      );
    } catch (e) {
      return _errorReport(method: method, message: e.toString());
    }
  }

  Map<String, dynamic> _toStringDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }

  SyncQaReport _errorReport({
    required String method,
    required String message,
  }) {
    return SyncQaReport(
      runId: '',
      context: method,
      passed: false,
      issueCount: 1,
      issues: [
        SyncQaIssue(
          id: 'native.error',
          message: message,
          severity: 'fail',
        ),
      ],
    );
  }
}
