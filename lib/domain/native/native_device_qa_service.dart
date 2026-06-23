import 'package:flutter/services.dart';

import 'package:nle_editor/domain/device_qa/device_qa_models.dart';

/// Dart bridge for 29E Android Device Compatibility QA routes.
///
/// Calls the native MethodChannel and decodes results into typed models.
class NativeDeviceQaService {
  static const _channel = MethodChannel('nle_editor/native_methods');

  const NativeDeviceQaService();

  // ── Commands ──────────────────────────────────────────────────────────────

  /// Runs the full 29E device compatibility QA check.
  Future<DeviceQaReport> runDeviceCompatibilityQa() async {
    return _callAndParse(
      method:  'qa_run_device_compatibility',
      decoder: DeviceQaReport.fromJson,
      args:    const {},
    );
  }

  /// Collects device capabilities without running full QA checks.
  Future<DeviceCapabilityReport> collectDeviceCapabilities() async {
    return _callAndParse(
      method:  'qa_collect_device_capabilities',
      decoder: DeviceCapabilityReport.fromJson,
      args:    const {},
    );
  }

  /// Runs a memory pressure probe, allocating [allocateMb] MB.
  Future<MemoryPressureResult> runMemoryPressureProbe({
    int allocateMb = 128,
  }) async {
    return _callAndParse(
      method:  'qa_run_memory_pressure_probe',
      decoder: MemoryPressureResult.fromJson,
      args:    {'allocateMb': allocateMb},
    );
  }

  /// Returns export retry suggestions based on a failure message.
  Future<ExportRecoverySuggestion> getExportRecoverySuggestion({
    required String failureMessage,
  }) async {
    return _callAndParse(
      method:  'qa_export_recovery_suggestion',
      decoder: ExportRecoverySuggestion.fromJson,
      args:    {'failureMessage': failureMessage},
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<T> _callAndParse<T>({
    required String method,
    required T Function(Map<String, dynamic>) decoder,
    required Map<String, dynamic> args,
  }) async {
    try {
      final raw      = await _channel.invokeMethod<dynamic>(method, args);
      final outerMap = _toStringDynamic(raw);

      if (outerMap['success'] == true) {
        final resultMap = _toStringDynamic(outerMap['result']);
        return decoder(resultMap);
      }

      throw StateError(
        _toStringDynamic(outerMap['error'])['message']?.toString() ??
            'Native device QA call failed: $method',
      );
    } on PlatformException catch (e) {
      throw StateError('PlatformException during $method: ${e.message}');
    }
  }

  Map<String, dynamic> _toStringDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }
}
