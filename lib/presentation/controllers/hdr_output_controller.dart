// lib/presentation/controllers/hdr_output_controller.dart
//
// 30J-PRO: Controller to coordinate HDR output settings, platform
// capability scanning, validation feedback, and active preview configurations.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/data/repositories/hdr_output_repository.dart';
import 'package:nle_editor/domain/color_output/hdr_output_models.dart';
import 'package:nle_editor/domain/native/native_hdr_output_service.dart';

class HdrOutputState {
  final bool loading;
  final NleHdrOutputSettings settings;
  final NleHdrDeviceCapability capability;
  final NleHdrExportValidation? validation;
  final String? error;

  const HdrOutputState({
    required this.loading,
    required this.settings,
    required this.capability,
    this.validation,
    this.error,
  });

  factory HdrOutputState.initial() {
    return HdrOutputState(
      loading: false,
      settings: NleHdrOutputSettings.defaultSettings(),
      capability: NleHdrDeviceCapability.unknown(),
    );
  }

  HdrOutputState copyWith({
    bool? loading,
    NleHdrOutputSettings? settings,
    NleHdrDeviceCapability? capability,
    NleHdrExportValidation? validation,
    String? error,
    bool clearError = false,
  }) {
    return HdrOutputState(
      loading: loading ?? this.loading,
      settings: settings ?? this.settings,
      capability: capability ?? this.capability,
      validation: validation ?? this.validation,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class HdrOutputController extends StateNotifier<HdrOutputState> {
  final String projectId;
  final HdrOutputRepository repository;
  final NativeHdrOutputService nativeService;

  HdrOutputController({
    required this.projectId,
    required this.repository,
    required this.nativeService,
  }) : super(HdrOutputState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final settings = await repository.getSettings(projectId);
      state = state.copyWith(settings: settings);

      // Eagerly scan capabilities and validate/configure the preview.
      await scanCapability();
      await _validateAndConfigure();

      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> scanCapability() async {
    try {
      final capability = await nativeService.scanCapability();
      state = state.copyWith(capability: capability);
    } catch (e) {
      state = state.copyWith(error: 'Device scan failed: ${e.toString()}');
    }
  }

  Future<void> updateColorMode(NleOutputColorMode mode) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final updated = await repository.setOutputMode(projectId, mode);
      state = state.copyWith(settings: updated);
      await _validateAndConfigure();
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateSettings(NleHdrOutputSettings newSettings) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await repository.saveSettings(projectId, newSettings);
      state = state.copyWith(settings: newSettings);
      await _validateAndConfigure();
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _validateAndConfigure() async {
    try {
      // Validate export safety.
      final validation = await nativeService.validateExport(
        projectId: projectId,
        settings: state.settings,
      );

      // Apply configurations to active preview pipeline.
      await nativeService.configurePreview(
        projectId: projectId,
        settings: state.settings,
      );

      state = state.copyWith(validation: validation);
    } catch (e) {
      state = state.copyWith(
        error: 'Pipeline validation/configuration failed: ${e.toString()}',
      );
    }
  }
}
