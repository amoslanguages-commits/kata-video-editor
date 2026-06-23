import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/secondary_grade_repository.dart';
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';
import 'package:nle_editor/domain/native/native_eyedropper_service.dart';
import 'package:nle_editor/domain/preview/preview_monitor.dart';

class SecondaryGradeState {
  final bool loading;
  final bool eyedropperActive;
  final String? selectedLayerId;
  final NleSecondaryGradeStack stack;
  final NlePickedHslSample? lastSample;
  final String? error;

  const SecondaryGradeState({
    required this.loading,
    required this.eyedropperActive,
    required this.stack,
    this.selectedLayerId,
    this.lastSample,
    this.error,
  });

  const SecondaryGradeState.initial()
      : loading = false,
        eyedropperActive = false,
        selectedLayerId = null,
        stack = const NleSecondaryGradeStack.empty(),
        lastSample = null,
        error = null;

  NleSecondaryGradeLayer? get selectedLayer {
    if (selectedLayerId == null) return stack.layers.firstOrNull;

    return stack.layers
        .where((layer) => layer.id == selectedLayerId)
        .firstOrNull;
  }

  SecondaryGradeState copyWith({
    bool? loading,
    bool? eyedropperActive,
    String? selectedLayerId,
    NleSecondaryGradeStack? stack,
    NlePickedHslSample? lastSample,
    String? error,
    bool clearError = false,
  }) {
    return SecondaryGradeState(
      loading: loading ?? this.loading,
      eyedropperActive: eyedropperActive ?? this.eyedropperActive,
      selectedLayerId: selectedLayerId ?? this.selectedLayerId,
      stack: stack ?? this.stack,
      lastSample: lastSample ?? this.lastSample,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class SecondaryGradeController extends StateNotifier<SecondaryGradeState> {
  final String clipId;
  final SecondaryGradeRepository repository;
  final NativeEyedropperService eyedropperService;

  StreamSubscription<NlePickedHslSample>? _sampleSub;

  SecondaryGradeController({
    required this.clipId,
    required this.repository,
    required this.eyedropperService,
  }) : super(const SecondaryGradeState.initial()) {
    _sampleSub = eyedropperService.samples.listen(_handleSample);
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final stack = await repository.getStack(clipId);

      state = state.copyWith(
        loading: false,
        stack: stack,
        selectedLayerId: stack.layers.isNotEmpty ? stack.layers.first.id : null,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  void selectLayer(String id) {
    state = state.copyWith(selectedLayerId: id);
  }

  Future<void> addEmptyLayer() async {
    await repository.addEmptyLayer(clipId);
    await load();
  }

  Future<void> removeSelectedLayer() async {
    final layer = state.selectedLayer;
    if (layer == null) return;

    await repository.removeLayer(
      clipId: clipId,
      layerId: layer.id,
    );

    await load();
  }

  Future<void> updateSelectedLayer(
    NleSecondaryGradeLayer layer,
  ) async {
    state = state.copyWith(
      stack: state.stack.updateLayer(layer),
      selectedLayerId: layer.id,
      clearError: true,
    );

    await repository.updateLayer(
      clipId: clipId,
      layer: layer,
    );
  }

  Future<void> setEyedropperActive(bool active) async {
    state = state.copyWith(eyedropperActive: active);
  }

  Future<void> pickFromPreview({
    required PreviewMonitor monitor,
    required double normalizedX,
    required double normalizedY,
  }) async {
    if (!state.eyedropperActive) return;

    await eyedropperService.pickFromPreview(
      monitor: monitor,
      normalizedX: normalizedX,
      normalizedY: normalizedY,
    );
  }

  Future<void> reset() async {
    await repository.reset(clipId);
    await load();
  }

  Future<void> _handleSample(NlePickedHslSample sample) async {
    final selected = state.selectedLayer;

    if (selected == null) {
      final layer = await repository.addLayerFromSample(
        clipId: clipId,
        sample: sample,
      );

      state = state.copyWith(
        lastSample: sample,
        selectedLayerId: layer.id,
        eyedropperActive: false,
        clearError: true,
      );

      await load();

      return;
    }

    final updated = selected.copyWith(
      qualifier: NleHslQualifier.fromPickedHsl(
        hue: sample.hue,
        saturation: sample.saturation,
        luminance: sample.luminance,
      ),
    );

    await updateSelectedLayer(updated);

    state = state.copyWith(
      lastSample: sample,
      eyedropperActive: false,
      clearError: true,
    );
  }

  @override
  void dispose() {
    _sampleSub?.cancel();
    super.dispose();
  }
}
