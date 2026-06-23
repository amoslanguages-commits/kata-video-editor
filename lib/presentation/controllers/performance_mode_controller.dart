import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/performance/performance_mode.dart';
import 'package:nle_editor/domain/performance/media_memory_cache.dart';

class PerformanceModeController extends StateNotifier<PerformanceModeState> {
  final ThumbnailMemoryCache thumbnailCache;
  final WaveformMemoryCache waveformCache;

  PerformanceModeController({
    required this.thumbnailCache,
    required this.waveformCache,
  }) : super(PerformanceModeState.defaults());

  void setDeviceTier(String tier) {
    state = state.copyWith(deviceTier: tier);
  }

  void setPreviewQuality(String quality) {
    state = state.copyWith(previewQuality: quality);
  }

  void enterLowMemoryMode() {
    thumbnailCache.enterLowMemoryMode();
    waveformCache.enterLowMemoryMode();

    state = state.copyWith(
      lowMemoryMode: true,
      previewQuality: PreviewQualityLevel.quarter,
      maxTimelineClipWidgets: 60,
      maxMediaPoolItemsPerPage: 40,
      nativeGraphDebounce: const Duration(milliseconds: 300),
      autosaveDebounce: const Duration(seconds: 4),
    );
  }

  void exitLowMemoryMode() {
    state = PerformanceModeState.defaults().copyWith(
      deviceTier: state.deviceTier,
    );
  }

  void setThermalWarning(bool value) {
    state = state.copyWith(
      thermalWarning: value,
      previewQuality: value
          ? PreviewQualityLevel.quarter
          : PerformanceModeState.defaults().previewQuality,
    );
  }

  void setBatterySaver(bool value) {
    state = state.copyWith(
      batterySaver: value,
      previewQuality:
          value ? PreviewQualityLevel.half : PreviewQualityLevel.auto,
    );
  }
}
