import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/native/native_sync_qa_service.dart';
import 'package:nle_editor/domain/sync/sync_qa_models.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final nativeSyncQaServiceProvider = Provider<NativeSyncQaService>(
  (_) => const NativeSyncQaService(),
);

final syncQaControllerProvider =
    StateNotifierProvider<SyncQaController, SyncQaState>(
  (ref) => SyncQaController(ref.read(nativeSyncQaServiceProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────────

class SyncQaState {
  final bool loading;
  final SyncQaReport? exportReport;
  final SyncQaReport? previewReport;
  final String? error;

  const SyncQaState({
    this.loading = false,
    this.exportReport,
    this.previewReport,
    this.error,
  });

  SyncQaState copyWith({
    bool? loading,
    SyncQaReport? exportReport,
    SyncQaReport? previewReport,
    String? error,
    bool clearError = false,
  }) {
    return SyncQaState(
      loading:       loading       ?? this.loading,
      exportReport:  exportReport  ?? this.exportReport,
      previewReport: previewReport ?? this.previewReport,
      error:         clearError ? null : (error ?? this.error),
    );
  }

  bool get hasAnyReport => exportReport != null || previewReport != null;

  bool get allPassed {
    final ep = exportReport;
    final pp = previewReport;
    if (ep == null && pp == null) return false;
    return (ep?.passed ?? true) && (pp?.passed ?? true);
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class SyncQaController extends StateNotifier<SyncQaState> {
  final NativeSyncQaService _service;

  SyncQaController(this._service) : super(const SyncQaState());

  Future<void> runExportQa() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final report = await _service.runExportSync();
      state = state.copyWith(loading: false, exportReport: report);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> runPreviewQa() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final report = await _service.runPreviewSync();
      state = state.copyWith(loading: false, previewReport: report);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> clearTelemetry() async {
    await _service.clearSyncTelemetry();
    state = const SyncQaState();
  }
}
