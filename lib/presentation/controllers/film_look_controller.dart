import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/film_look_repository.dart';
import 'package:nle_editor/domain/film_look/film_look_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class FilmLookState {
  final bool loading;
  final NleFilmLookSettings settings;
  final String? error;

  const FilmLookState({
    required this.loading,
    required this.settings,
    this.error,
  });

  const FilmLookState.initial()
      : loading = false,
        settings = const NleFilmLookSettings.identity(),
        error = null;

  FilmLookState copyWith({
    bool? loading,
    NleFilmLookSettings? settings,
    String? error,
    bool clearError = false,
  }) {
    return FilmLookState(
      loading: loading ?? this.loading,
      settings: settings ?? this.settings,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class FilmLookController extends StateNotifier<FilmLookState> {
  final String clipId;
  final FilmLookRepository repository;

  FilmLookController({
    required this.clipId,
    required this.repository,
  }) : super(const FilmLookState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final settings = await repository.getClipFilmLook(clipId);
      state = state.copyWith(loading: false, settings: settings, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> update(NleFilmLookSettings settings) async {
    state = state.copyWith(settings: settings, clearError: true);
    await repository.saveClipFilmLook(clipId: clipId, settings: settings);
  }

  Future<void> applyPreset(NleFilmStockPreset preset) async {
    await repository.applyClipPreset(clipId: clipId, preset: preset);
    await load();
  }

  Future<void> reset() async {
    await repository.resetClipFilmLook(clipId);
    await load();
  }

  void setEnabled(bool enabled) {
    _apply(state.settings.copyWith(enabled: enabled));
  }

  void setIntensity(double value) {
    _apply(state.settings.copyWith(intensity: value));
  }

  void setGrain(NleFilmGrainSettings grain) {
    _apply(state.settings.copyWith(grain: grain));
  }

  void setHalation(NleHalationSettings halation) {
    _apply(state.settings.copyWith(halation: halation));
  }

  void setBloom(NleBloomSettings bloom) {
    _apply(state.settings.copyWith(bloom: bloom));
  }

  void setPrint(NlePrintSettings print) {
    _apply(state.settings.copyWith(print: print));
  }

  void setVignette(NleVignetteSettings vignette) {
    _apply(state.settings.copyWith(vignette: vignette));
  }

  void setGateWeave(NleGateWeaveSettings gateWeave) {
    _apply(state.settings.copyWith(gateWeave: gateWeave));
  }

  void setChromaticSoftness(double value) {
    _apply(state.settings.copyWith(chromaticSoftness: value));
  }

  void _apply(NleFilmLookSettings settings) {
    state = state.copyWith(settings: settings, clearError: true);
    repository.saveClipFilmLook(clipId: clipId, settings: settings);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline / Project scope
// ─────────────────────────────────────────────────────────────────────────────

class TimelineFilmLookController extends StateNotifier<FilmLookState> {
  final String projectId;
  final FilmLookRepository repository;

  TimelineFilmLookController({
    required this.projectId,
    required this.repository,
  }) : super(const FilmLookState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final settings = await repository.getTimelineFilmLook(projectId);
      state = state.copyWith(loading: false, settings: settings, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> update(NleFilmLookSettings settings) async {
    state = state.copyWith(settings: settings, clearError: true);
    await repository.saveTimelineFilmLook(projectId: projectId, settings: settings);
  }

  void setEnabled(bool enabled) {
    _apply(state.settings.copyWith(enabled: enabled));
  }

  void setIntensity(double value) {
    _apply(state.settings.copyWith(intensity: value));
  }

  void setGrain(NleFilmGrainSettings grain) {
    _apply(state.settings.copyWith(grain: grain));
  }

  void setHalation(NleHalationSettings halation) {
    _apply(state.settings.copyWith(halation: halation));
  }

  void setBloom(NleBloomSettings bloom) {
    _apply(state.settings.copyWith(bloom: bloom));
  }

  void setPrint(NlePrintSettings print) {
    _apply(state.settings.copyWith(print: print));
  }

  void setVignette(NleVignetteSettings vignette) {
    _apply(state.settings.copyWith(vignette: vignette));
  }

  void setGateWeave(NleGateWeaveSettings gateWeave) {
    _apply(state.settings.copyWith(gateWeave: gateWeave));
  }

  void setChromaticSoftness(double value) {
    _apply(state.settings.copyWith(chromaticSoftness: value));
  }

  void _apply(NleFilmLookSettings settings) {
    state = state.copyWith(settings: settings, clearError: true);
    repository.saveTimelineFilmLook(projectId: projectId, settings: settings);
  }
}
