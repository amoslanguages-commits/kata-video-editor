// ============================================================================
// performance_providers.dart
//
// Riverpod provider wiring for Step 23: Performance Optimization.
//
// Exposes:
//   - thumbnailMemoryCacheProvider
//   - waveformMemoryCacheProvider
//   - performanceModeControllerProvider
//   - projectAssetIndexServiceProvider
//   - projectAssetIndexProvider (family)
//   - proxyRecommendationEngineProvider
//   - adaptivePreviewQualityServiceProvider
//   - renderGraphDiffServiceProvider
//   - nativeGraphUpdateSchedulerProvider
//   - playheadThrottleControllerProvider
//   - autosaveThrottleServiceProvider
//   - backgroundJobPriorityTunerProvider
//   - exportPerformanceEstimatorProvider
//   - timelineViewportProvider
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/performance/media_memory_cache.dart';
import 'package:nle_editor/domain/performance/performance_mode.dart';
import 'package:nle_editor/domain/performance/project_asset_index.dart';
import 'package:nle_editor/domain/performance/proxy_recommendation_engine.dart';
import 'package:nle_editor/domain/performance/adaptive_preview_quality_service.dart';
import 'package:nle_editor/domain/performance/render_graph_diff_service.dart';
import 'package:nle_editor/domain/performance/background_job_priority_tuner.dart';
import 'package:nle_editor/domain/performance/export_performance_estimator.dart';
import 'package:nle_editor/domain/performance/timeline_viewport.dart';
import 'package:nle_editor/domain/services/autosave_throttle_service.dart';
import 'package:nle_editor/presentation/controllers/performance_mode_controller.dart';
import 'package:nle_editor/presentation/controllers/playhead_throttle_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

// ─── Memory Caches ───────────────────────────────────────────────────────────

/// Singleton LRU thumbnail image cache.
final thumbnailMemoryCacheProvider = Provider<ThumbnailMemoryCache>((ref) {
  final cache = ThumbnailMemoryCache();
  ref.onDispose(cache.clear);
  return cache;
});

/// Singleton LRU waveform sample cache.
final waveformMemoryCacheProvider = Provider<WaveformMemoryCache>((ref) {
  final cache = WaveformMemoryCache();
  ref.onDispose(cache.clear);
  return cache;
});

// ─── Performance Mode ────────────────────────────────────────────────────────

/// Global performance mode state — device tier, preview quality, low-memory
/// mode, thermal / battery flags, and the dynamic debounce/throttle durations.
final performanceModeControllerProvider =
    StateNotifierProvider<PerformanceModeController, PerformanceModeState>(
  (ref) {
    return PerformanceModeController(
      thumbnailCache: ref.watch(thumbnailMemoryCacheProvider),
      waveformCache: ref.watch(waveformMemoryCacheProvider),
    );
  },
);

// ─── Asset Indexing ──────────────────────────────────────────────────────────

final projectAssetIndexServiceProvider =
    Provider<ProjectAssetIndexService>((ref) {
  return ProjectAssetIndexService();
});

/// Builds and caches a full [ProjectAssetIndex] for [projectId].
/// Re-fetches whenever the asset or clip streams emit.
final projectAssetIndexProvider =
    FutureProvider.family<ProjectAssetIndex, String>((ref, projectId) async {
  final assetsAsync = ref.watch(projectAssetsProvider(projectId));
  final clipsAsync = ref.watch(projectClipsProvider(projectId));
  final service = ref.watch(projectAssetIndexServiceProvider);

  final assets = assetsAsync.value ?? [];
  final clips = clipsAsync.value ?? [];

  return service.build(
    projectId: projectId,
    assets: assets,
    clips: clips,
  );
});

// ─── Proxy Recommendations ───────────────────────────────────────────────────

final proxyRecommendationEngineProvider =
    Provider<ProxyRecommendationEngine>((ref) {
  return ProxyRecommendationEngine();
});

// ─── Adaptive Preview Quality ────────────────────────────────────────────────

final adaptivePreviewQualityServiceProvider =
    Provider<AdaptivePreviewQualityService>((ref) {
  return AdaptivePreviewQualityService();
});

// ─── Render-Graph Diffing ────────────────────────────────────────────────────

final renderGraphDiffServiceProvider =
    Provider<RenderGraphDiffService>((ref) {
  return RenderGraphDiffService();
});


// ─── Playhead Throttle ───────────────────────────────────────────────────────

/// Limits playhead-changed callbacks to at most once per [playheadThrottle]
/// interval, preventing UI overload during high-FPS native clock ticks.
final playheadThrottleControllerProvider =
    Provider<PlayheadThrottleController>((ref) {
  final mode = ref.watch(performanceModeControllerProvider);

  final controller = PlayheadThrottleController(
    ref: ref,
    interval: mode.playheadThrottle,
  );

  ref.onDispose(controller.dispose);
  return controller;
});

// ─── Autosave Throttle ───────────────────────────────────────────────────────

/// Debounces autosave calls so rapid edits don't trigger repeated saves.
final autosaveThrottleServiceProvider =
    Provider<AutosaveThrottleService>((ref) {
  final mode = ref.watch(performanceModeControllerProvider);

  final service = AutosaveThrottleService(
    autosaveService: ref.watch(projectAutosaveServiceProvider),
    delay: mode.autosaveDebounce,
  );

  ref.onDispose(service.dispose);
  return service;
});

// ─── Background Job Priority ──────────────────────────────────────────────────

final backgroundJobPriorityTunerProvider =
    Provider<BackgroundJobPriorityTuner>((ref) {
  return BackgroundJobPriorityTuner();
});

// ─── Export Performance Estimator ────────────────────────────────────────────

final exportPerformanceEstimatorProvider =
    Provider<ExportPerformanceEstimator>((ref) {
  return ExportPerformanceEstimator();
});

// ─── Timeline Viewport (Virtualization) ──────────────────────────────────────

/// A thin notifier that tracks the current scroll offset and zoom level so
/// [VirtualizedTimelineStrip] can compute which clips fall inside the viewport.
class TimelineViewportNotifier
    extends StateNotifier<TimelineViewportWindow?> {
  TimelineViewportNotifier() : super(null);

  void update({
    required double scrollOffset,
    required double viewportWidth,
    required double pixelsPerSecond,
  }) {
    state = TimelineViewportCalculator.calculate(
      scrollOffset: scrollOffset,
      viewportWidth: viewportWidth,
      pixelsPerSecond: pixelsPerSecond,
    );
  }

  void clear() {
    state = null;
  }
}

/// Exposed viewport window — null until first [TimelineViewportNotifier.update]
/// call from the scroll listener in [VirtualizedTimelineStrip].
final timelineViewportProvider =
    StateNotifierProvider<TimelineViewportNotifier, TimelineViewportWindow?>(
  (ref) => TimelineViewportNotifier(),
);
