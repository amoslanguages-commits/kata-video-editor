import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/color_scope_settings_repository.dart';
import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';
import 'package:nle_editor/domain/native/native_scope_service.dart';
import 'package:nle_editor/domain/preview/preview_monitor.dart';

class ColorScopeState {
  final bool loading;
  final bool live;
  final NleScopeSettings settings;
  final NleScopeFrameData frameData;
  final String? error;

  const ColorScopeState({
    required this.loading,
    required this.live,
    required this.settings,
    required this.frameData,
    this.error,
  });

  const ColorScopeState.initial()
      : loading = false,
        live = false,
        settings = const NleScopeSettings.defaultMobile(),
        frameData = const NleScopeFrameData(
          frameTimestampMicros: 0,
          sampleWidth: 0,
          sampleHeight: 0,
          waveform: [],
          rgbParade: [],
          vectorscope: [],
          histogram: NleHistogramData(
            luma: [],
            red: [],
            green: [],
            blue: [],
          ),
          warnings: NleClippingWarnings(
            blackClipping: false,
            whiteClipping: false,
            redChannelClipping: false,
            greenChannelClipping: false,
            blueChannelClipping: false,
            overSaturated: false,
            blackClipPercent: 0.0,
            whiteClipPercent: 0.0,
            redClipPercent: 0.0,
            greenClipPercent: 0.0,
            blueClipPercent: 0.0,
            saturationWarningPercent: 0.0,
          ),
        ),
        error = null;

  ColorScopeState copyWith({
    bool? loading,
    bool? live,
    NleScopeSettings? settings,
    NleScopeFrameData? frameData,
    String? error,
    bool clearError = false,
  }) {
    return ColorScopeState(
      loading: loading ?? this.loading,
      live: live ?? this.live,
      settings: settings ?? this.settings,
      frameData: frameData ?? this.frameData,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ColorScopeController extends StateNotifier<ColorScopeState> {
  final ColorScopeSettingsRepository repository;
  final NativeScopeService nativeService;

  StreamSubscription<NleScopeFrameData>? _frameSub;

  ColorScopeController({
    required this.repository,
    required this.nativeService,
  }) : super(const ColorScopeState.initial()) {
    _frameSub = nativeService.frames.listen((frame) {
      state = state.copyWith(frameData: frame, clearError: true);
    });

    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final settings = await repository.load();

      state = state.copyWith(
        loading: false,
        settings: settings,
        clearError: true,
      );

      await nativeService.configureScopes(settings: settings);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> updateSettings(NleScopeSettings settings) async {
    state = state.copyWith(settings: settings, clearError: true);
    await repository.save(settings);
    await nativeService.configureScopes(settings: settings);
  }

  Future<void> setType(NleScopeType type) {
    return updateSettings(
      state.settings.copyWith(activeType: type),
    );
  }

  Future<void> setEnabled(bool enabled) {
    return updateSettings(
      state.settings.copyWith(enabled: enabled),
    );
  }

  Future<void> setOverlay(bool overlay) {
    return updateSettings(
      state.settings.copyWith(showOverlay: overlay),
    );
  }

  Future<void> setSkinToneLine(bool enabled) {
    return updateSettings(
      state.settings.copyWith(showSkinToneLine: enabled),
    );
  }

  Future<void> setClippingWarnings(bool enabled) {
    return updateSettings(
      state.settings.copyWith(showClippingWarnings: enabled),
    );
  }

  Future<void> startLive({
    PreviewMonitor monitor = PreviewMonitor.program,
  }) async {
    state = state.copyWith(live: true, clearError: true);
    await nativeService.startLive(monitor: monitor);
  }

  Future<void> stopLive() async {
    state = state.copyWith(live: false, clearError: true);
    await nativeService.stopLive();
  }

  Future<void> requestCurrentFrame({
    required PreviewMonitor monitor,
    required int timestampMicros,
  }) {
    return nativeService.requestFrame(
      monitor: monitor,
      timestampMicros: timestampMicros,
    );
  }

  @override
  void dispose() {
    _frameSub?.cancel();
    super.dispose();
  }
}
