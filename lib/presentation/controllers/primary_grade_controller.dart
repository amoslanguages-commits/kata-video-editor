import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/primary_grade_repository.dart';
import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';

class PrimaryGradeState {
  final bool loading;
  final NlePrimaryGrade grade;
  final String? error;

  const PrimaryGradeState({
    required this.loading,
    required this.grade,
    this.error,
  });

  const PrimaryGradeState.initial()
      : loading = false,
        grade = const NlePrimaryGrade.identity(),
        error = null;

  PrimaryGradeState copyWith({
    bool? loading,
    NlePrimaryGrade? grade,
    String? error,
    bool clearError = false,
  }) {
    return PrimaryGradeState(
      loading: loading ?? this.loading,
      grade: grade ?? this.grade,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PrimaryGradeController extends StateNotifier<PrimaryGradeState> {
  final String clipId;
  final PrimaryGradeRepository repository;

  PrimaryGradeController({
    required this.clipId,
    required this.repository,
  }) : super(const PrimaryGradeState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final grade = await repository.getPrimaryGrade(clipId);
      state = state.copyWith(
        loading: false,
        grade: grade,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> save(NlePrimaryGrade grade) async {
    state = state.copyWith(grade: grade, clearError: true);
    await repository.savePrimaryGrade(
      clipId: clipId,
      grade: grade,
    );
  }

  Future<void> reset() async {
    const identity = NlePrimaryGrade.identity();
    state = state.copyWith(grade: identity, clearError: true);
    await repository.savePrimaryGrade(
      clipId: clipId,
      grade: identity,
    );
  }

  Future<void> setEnabled(bool enabled) {
    return save(state.grade.copyWith(enabled: enabled));
  }

  Future<void> setMode(NlePrimaryGradeMode mode) {
    return save(state.grade.copyWith(mode: mode));
  }

  Future<void> setIntensity(double value) {
    return save(
      state.grade.copyWith(
        intensity: value.clamp(0.0, 1.0),
      ),
    );
  }

  Future<void> setContrast(double value) {
    return save(
      state.grade.copyWith(
        contrast: value.clamp(0.0, 3.0),
      ),
    );
  }

  Future<void> setPivot(double value) {
    return save(
      state.grade.copyWith(
        pivot: value.clamp(0.01, 1.0),
      ),
    );
  }

  Future<void> setSaturation(double value) {
    return save(
      state.grade.copyWith(
        saturation: value.clamp(0.0, 3.0),
      ),
    );
  }

  Future<void> setLift(NlePrimaryWheelControl wheel) {
    return save(state.grade.copyWith(lift: wheel));
  }

  Future<void> setGamma(NlePrimaryWheelControl wheel) {
    return save(state.grade.copyWith(gamma: wheel));
  }

  Future<void> setGain(NlePrimaryWheelControl wheel) {
    return save(state.grade.copyWith(gain: wheel));
  }

  Future<void> setOffset(NlePrimaryWheelControl wheel) {
    return save(state.grade.copyWith(offset: wheel));
  }
}
