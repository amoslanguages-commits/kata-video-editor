import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/device_qa/device_qa_models.dart';
import 'package:nle_editor/domain/native/native_device_qa_service.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final nativeDeviceQaServiceProvider = Provider<NativeDeviceQaService>(
  (_) => const NativeDeviceQaService(),
);

final deviceQaControllerProvider =
    StateNotifierProvider<DeviceQaController, DeviceQaState>(
  (ref) => DeviceQaController(ref.read(nativeDeviceQaServiceProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────────

sealed class DeviceQaAction {
  const DeviceQaAction();
}

final class DeviceQaIdle extends DeviceQaAction {
  const DeviceQaIdle();
}

final class DeviceQaRunningFullQa extends DeviceQaAction {
  const DeviceQaRunningFullQa();
}

final class DeviceQaRunningCapabilities extends DeviceQaAction {
  const DeviceQaRunningCapabilities();
}

final class DeviceQaRunningMemoryProbe extends DeviceQaAction {
  const DeviceQaRunningMemoryProbe();
}

class DeviceQaState {
  final DeviceQaAction action;
  final DeviceQaReport? qaReport;
  final DeviceCapabilityReport? capabilityReport;
  final MemoryPressureResult? memoryResult;
  final ExportRecoverySuggestion? recoverySuggestion;
  final String? error;

  const DeviceQaState({
    this.action = const DeviceQaIdle(),
    this.qaReport,
    this.capabilityReport,
    this.memoryResult,
    this.recoverySuggestion,
    this.error,
  });

  bool get loading => action is! DeviceQaIdle;
  bool get hasReport => qaReport != null;

  DeviceQaState copyWith({
    DeviceQaAction? action,
    DeviceQaReport? qaReport,
    DeviceCapabilityReport? capabilityReport,
    MemoryPressureResult? memoryResult,
    ExportRecoverySuggestion? recoverySuggestion,
    String? error,
    bool clearError = false,
  }) {
    return DeviceQaState(
      action:              action              ?? this.action,
      qaReport:            qaReport            ?? this.qaReport,
      capabilityReport:    capabilityReport    ?? this.capabilityReport,
      memoryResult:        memoryResult        ?? this.memoryResult,
      recoverySuggestion:  recoverySuggestion  ?? this.recoverySuggestion,
      error:               clearError ? null : (error ?? this.error),
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class DeviceQaController extends StateNotifier<DeviceQaState> {
  final NativeDeviceQaService _service;

  DeviceQaController(this._service) : super(const DeviceQaState());

  Future<void> runFullQa() async {
    state = state.copyWith(action: const DeviceQaRunningFullQa(), clearError: true);
    try {
      final report = await _service.runDeviceCompatibilityQa();
      state = state.copyWith(
        action:          const DeviceQaIdle(),
        qaReport:        report,
        capabilityReport: report.capabilityReport,
      );
    } catch (e) {
      state = state.copyWith(action: const DeviceQaIdle(), error: e.toString());
    }
  }

  Future<void> collectCapabilities() async {
    state = state.copyWith(action: const DeviceQaRunningCapabilities(), clearError: true);
    try {
      final cap = await _service.collectDeviceCapabilities();
      state = state.copyWith(action: const DeviceQaIdle(), capabilityReport: cap);
    } catch (e) {
      state = state.copyWith(action: const DeviceQaIdle(), error: e.toString());
    }
  }

  Future<void> runMemoryProbe({int allocateMb = 128}) async {
    state = state.copyWith(action: const DeviceQaRunningMemoryProbe(), clearError: true);
    try {
      final result = await _service.runMemoryPressureProbe(allocateMb: allocateMb);
      state = state.copyWith(action: const DeviceQaIdle(), memoryResult: result);
    } catch (e) {
      state = state.copyWith(action: const DeviceQaIdle(), error: e.toString());
    }
  }

  void clear() => state = const DeviceQaState();
}
