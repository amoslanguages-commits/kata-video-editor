import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/color_curve_repository.dart';
import 'package:nle_editor/domain/color_curves/color_curve_models.dart';

class ColorCurveState {
  final bool loading;
  final NleColorCurveStack stack;
  final NleCurveType selectedType;
  final String? error;

  const ColorCurveState({
    required this.loading,
    required this.stack,
    required this.selectedType,
    this.error,
  });

  const ColorCurveState.initial()
      : loading = false,
        stack = const NleColorCurveStack(
          enabled: true,
          evaluationSpace: NleCurveEvaluationSpace.sceneLinear,
          curves: [],
        ),
        selectedType = NleCurveType.rgbMaster,
        error = null;

  ColorCurveState copyWith({
    bool? loading,
    NleColorCurveStack? stack,
    NleCurveType? selectedType,
    String? error,
    bool clearError = false,
  }) {
    return ColorCurveState(
      loading: loading ?? this.loading,
      stack: stack ?? this.stack,
      selectedType: selectedType ?? this.selectedType,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ColorCurveController extends StateNotifier<ColorCurveState> {
  final String clipId;
  final ColorCurveRepository repository;

  ColorCurveController({
    required this.clipId,
    required this.repository,
  }) : super(const ColorCurveState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final stack = await repository.getCurveStack(clipId);

      state = state.copyWith(
        loading: false,
        stack: stack,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  void selectType(NleCurveType type) {
    state = state.copyWith(selectedType: type);
  }

  Future<void> saveStack(NleColorCurveStack stack) async {
    state = state.copyWith(stack: stack, clearError: true);

    await repository.saveCurveStack(
      clipId: clipId,
      stack: stack,
    );
  }

  Future<void> setEnabled(bool enabled) {
    return saveStack(
      state.stack.copyWith(enabled: enabled),
    );
  }

  Future<void> setEvaluationSpace(NleCurveEvaluationSpace space) {
    return saveStack(
      state.stack.copyWith(evaluationSpace: space),
    );
  }

  Future<void> updateCurve(NleColorCurve curve) {
    return saveStack(
      state.stack.updateCurve(curve),
    );
  }

  Future<void> resetSelectedCurve() {
    final identity = NleColorCurve.identity(state.selectedType);
    return updateCurve(identity);
  }

  Future<void> resetAll() {
    return saveStack(NleColorCurveStack.identity());
  }
}
