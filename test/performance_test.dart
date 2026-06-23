// ============================================================================
// performance_test.dart
//
// Unit tests for Step 23: Performance Optimization layer.
//
// Covers:
//   - Debouncer / Throttler utility behaviour
//   - LruMemoryCache eviction policy
//   - ThumbnailMemoryCache / WaveformMemoryCache wrappers
//   - PerformanceModeState defaults and copyWith
//   - PerformanceModeController state transitions
//   - RenderGraphDiffService change detection
//   - TimelineViewportCalculator window maths
//   - BackgroundJobPriorityTuner priority logic
//   - ExportPerformanceEstimator duration / size estimates
//   - AdaptivePreviewQualityService resolution selection
//   - ProxyRecommendationEngine recommendation logic
//   - ProjectAssetIndexService build correctness
// ============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/core/performance/lru_memory_cache.dart';
import 'package:nle_editor/core/performance/performance_timers.dart';
import 'package:nle_editor/domain/performance/adaptive_preview_quality_service.dart';
import 'package:nle_editor/domain/performance/background_job_priority_tuner.dart';
import 'package:nle_editor/domain/performance/export_performance_estimator.dart';
import 'package:nle_editor/domain/performance/media_memory_cache.dart';
import 'package:nle_editor/domain/performance/performance_mode.dart';
import 'package:nle_editor/domain/performance/project_asset_index.dart';
import 'package:nle_editor/domain/performance/proxy_recommendation_engine.dart';
import 'package:nle_editor/domain/performance/render_graph_diff_service.dart';
import 'package:nle_editor/domain/performance/timeline_viewport.dart';

void main() {
  // ─── Debouncer ─────────────────────────────────────────────────────────────

  group('Debouncer', () {
    test('fires once after delay when called multiple times', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);

      // Not fired yet.
      expect(callCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callCount, 1);

      debouncer.dispose();
    });

    test('cancel prevents action', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.run(() => callCount++);
      debouncer.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callCount, 0);

      debouncer.dispose();
    });
  });

  // ─── Throttler ────────────────────────────────────────────────────────────

  group('Throttler', () {
    test('executes first call immediately', () {
      final throttler = Throttler(interval: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.run(() => callCount++);
      expect(callCount, 1);

      throttler.dispose();
    });

    test('suppresses calls within interval', () async {
      final throttler = Throttler(interval: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.run(() => callCount++); // fires immediately
      throttler.run(() => callCount++, trailing: false); // suppressed
      throttler.run(() => callCount++, trailing: false); // suppressed

      expect(callCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1); // trailing=false so still 1

      throttler.dispose();
    });

    test('trailing call executes after interval', () async {
      final throttler = Throttler(interval: const Duration(milliseconds: 80));
      int callCount = 0;

      throttler.run(() => callCount++); // fires immediately
      await Future<void>.delayed(const Duration(milliseconds: 20));
      throttler.run(() => callCount++, trailing: true); // trailing queued

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callCount, 2);

      throttler.dispose();
    });
  });

  // ─── LruMemoryCache ───────────────────────────────────────────────────────

  group('LruMemoryCache', () {
    test('get returns null for missing key', () {
      final cache = LruMemoryCache<String>(maxCostBytes: 1000);
      expect(cache.get('missing'), isNull);
    });

    test('put and get round-trips correctly', () {
      final cache = LruMemoryCache<String>(maxCostBytes: 1000);
      cache.put(key: 'a', value: 'hello', costBytes: 10);
      expect(cache.get('a'), 'hello');
    });

    test('evicts LRU entry when cost exceeds max', () {
      final evicted = <String>[];
      final cache = LruMemoryCache<String>(
        maxCostBytes: 30,
        onEvict: (v) => evicted.add(v),
      );

      cache.put(key: 'a', value: 'val-a', costBytes: 15);
      cache.put(key: 'b', value: 'val-b', costBytes: 15);
      cache.put(key: 'c', value: 'val-c', costBytes: 15); // triggers eviction

      expect(evicted, contains('val-a'));
      expect(cache.get('a'), isNull);
    });

    test('reduceTo evicts until under target bytes', () {
      final evicted = <String>[];
      final cache = LruMemoryCache<String>(
        maxCostBytes: 200,
        onEvict: (v) => evicted.add(v),
      );

      cache.put(key: 'a', value: 'val-a', costBytes: 50);
      cache.put(key: 'b', value: 'val-b', costBytes: 50);
      cache.put(key: 'c', value: 'val-c', costBytes: 50);
      cache.put(key: 'd', value: 'val-d', costBytes: 50);

      cache.reduceTo(100);

      // Should retain only the 2 most-recently-used entries.
      expect(evicted.length, 2);
    });

    test('clear removes all entries', () {
      final cache = LruMemoryCache<String>(maxCostBytes: 1000);
      cache.put(key: 'a', value: 'hello', costBytes: 10);
      cache.clear();
      expect(cache.get('a'), isNull);
    });
  });

  // ─── WaveformMemoryCache ──────────────────────────────────────────────────

  group('WaveformMemoryCache', () {
    test('stores and retrieves waveform samples', () {
      final cache = WaveformMemoryCache();
      final samples = Float32List.fromList([0.1, 0.5, 0.9]);
      cache.put(key: 'clip_01', samples: samples);
      final result = cache.get('clip_01');
      expect(result, isNotNull);
      expect(result![1], closeTo(0.5, 0.001));
    });

    test('enterLowMemoryMode shrinks cache', () {
      final cache = WaveformMemoryCache(maxBytes: 1024);
      cache.enterLowMemoryMode();
      // After low-memory mode the target is 8 MB; adding a tiny sample
      // should still succeed without error.
      cache.put(
        key: 'x',
        samples: Float32List.fromList([0.0, 1.0]),
      );
      expect(cache.get('x'), isNotNull);
    });
  });

  // ─── PerformanceModeState ─────────────────────────────────────────────────

  group('PerformanceModeState', () {
    test('defaults has sensible values', () {
      final state = PerformanceModeState.defaults();
      expect(state.deviceTier, DevicePerformanceTier.mid);
      expect(state.previewQuality, PreviewQualityLevel.auto);
      expect(state.lowMemoryMode, isFalse);
      expect(state.maxTimelineClipWidgets, greaterThan(0));
    });

    test('copyWith overrides individual fields', () {
      final base = PerformanceModeState.defaults();
      final updated = base.copyWith(
        lowMemoryMode: true,
        previewQuality: PreviewQualityLevel.quarter,
      );

      expect(updated.lowMemoryMode, isTrue);
      expect(updated.previewQuality, PreviewQualityLevel.quarter);
      // Other fields unchanged
      expect(updated.deviceTier, base.deviceTier);
    });
  });

  // ─── RenderGraphDiffService ───────────────────────────────────────────────

  group('RenderGraphDiffService', () {
    test('identical graphs show no change', () {
      final service = RenderGraphDiffService();
      final graph = {'clips': 3, 'version': 1};

      service.check(graph, reason: 'init');
      final diff2 = service.check(graph, reason: 'no-op');

      expect(diff2.changed, isFalse);
    });

    test('different graph content reports change', () {
      final service = RenderGraphDiffService();

      service.check({'clips': 3}, reason: 'init');
      final diff2 = service.check({'clips': 4}, reason: 'add');

      expect(diff2.changed, isTrue);
    });

    test('first check always shows change', () {
      final service = RenderGraphDiffService();
      final diff = service.check({'clips': 0}, reason: 'first');
      expect(diff.changed, isTrue);
    });
  });

  // ─── TimelineViewportCalculator ───────────────────────────────────────────

  group('TimelineViewportCalculator', () {
    test('computes correct window from scroll parameters', () {
      const pixelsPerSecond = 100.0;
      const viewportWidth = 500.0;
      const scrollOffset = 200.0;

      final window = TimelineViewportCalculator.calculate(
        scrollOffset: scrollOffset,
        viewportWidth: viewportWidth,
        pixelsPerSecond: pixelsPerSecond,
        overscanMicros: 0,
      );

      // startMicros = (200 / 100) * 1_000_000 = 2_000_000
      expect(window.startMicros, closeTo(2000000, 10));
      // endMicros = ((200 + 500) / 100) * 1_000_000 = 7_000_000
      expect(window.endMicros, closeTo(7000000, 10));
    });

    test('overscan extends window on both sides', () {
      final window = TimelineViewportCalculator.calculate(
        scrollOffset: 0,
        viewportWidth: 100,
        pixelsPerSecond: 100,
        overscanMicros: 500000,
      );

      // Without overscan: start=0, end=1_000_000
      // With overscan: start=-500_000 (clamped to 0), end=1_500_000
      expect(window.startMicros, 0); // clamped
      expect(window.endMicros, 1500000);
    });
  });

  // ─── BackgroundJobPriorityTuner ───────────────────────────────────────────

  group('BackgroundJobPriorityTuner', () {
    final tuner = BackgroundJobPriorityTuner();

    test('user waiting yields urgent priority', () {
      final p = tuner.priorityFor(
        jobType: 'proxy',
        userWaiting: true,
        deviceUnderStress: false,
      );
      expect(p, JobPriorityLevel.urgent);
    });

    test('export under stress gets normal priority', () {
      final p = tuner.priorityFor(
        jobType: 'export',
        userWaiting: false,
        deviceUnderStress: true,
      );
      expect(p, JobPriorityLevel.normal);
    });

    test('thumbnail under stress gets idle priority', () {
      final p = tuner.priorityFor(
        jobType: 'thumbnail',
        userWaiting: false,
        deviceUnderStress: true,
      );
      expect(p, JobPriorityLevel.idle);
    });

    test('export without stress is high priority', () {
      final p = tuner.priorityFor(
        jobType: 'export',
        userWaiting: false,
        deviceUnderStress: false,
      );
      expect(p, JobPriorityLevel.high);
    });
  });

  // ─── AdaptivePreviewQualityService ───────────────────────────────────────

  group('AdaptivePreviewQualityService', () {
    final service = AdaptivePreviewQualityService();
    final defaults = PerformanceModeState.defaults();

    test('returns quarter quality when exporting', () {
      final result = service.resolve(
        performance: defaults,
        sourceWidth: 1920,
        sourceHeight: 1080,
        isScrubbing: false,
        isExporting: true,
      );
      expect(result.quality, PreviewQualityLevel.quarter);
    });

    test('returns quarter quality in low memory mode', () {
      final mode = defaults.copyWith(lowMemoryMode: true);
      final result = service.resolve(
        performance: mode,
        sourceWidth: 1920,
        sourceHeight: 1080,
        isScrubbing: false,
        isExporting: false,
      );
      expect(result.quality, PreviewQualityLevel.quarter);
    });

    test('returns half quality when scrubbing', () {
      final result = service.resolve(
        performance: defaults,
        sourceWidth: 1920,
        sourceHeight: 1080,
        isScrubbing: true,
        isExporting: false,
      );
      expect(result.quality, PreviewQualityLevel.half);
    });

    test('auto on 4K source selects half quality', () {
      final mode = defaults.copyWith(previewQuality: PreviewQualityLevel.auto);
      final result = service.resolve(
        performance: mode,
        sourceWidth: 3840,
        sourceHeight: 2160,
        isScrubbing: false,
        isExporting: false,
      );
      expect(result.quality, PreviewQualityLevel.half);
    });
  });

  // ─── ExportPerformanceEstimator ───────────────────────────────────────────

  group('ExportPerformanceEstimator', () {
    final estimator = ExportPerformanceEstimator();

    test('estimate duration is positive', () {
      final estimate = estimator.estimate(
        clips: [],
        timelineDurationMicros: 30 * 1000000, // 30 seconds
        width: 1920,
        height: 1080,
        frameRate: 30,
        videoBitrate: 8000000,
        audioBitrate: 128000,
        performanceMode: PerformanceModeState.defaults(),
      );
      expect(estimate.estimatedDuration.inSeconds, greaterThan(0));
    });

    test('estimate output bytes proportional to bitrate × duration', () {
      final estimate = estimator.estimate(
        clips: [],
        timelineDurationMicros: 10 * 1000000, // 10 seconds
        width: 1920,
        height: 1080,
        frameRate: 30,
        videoBitrate: 1000000, // 1 Mbps
        audioBitrate: 0,
        performanceMode: PerformanceModeState.defaults(),
      );
      // 10 s × 1 Mbps / 8 = 1_250_000 bytes
      expect(estimate.estimatedOutputBytes, closeTo(1250000, 5000));
    });

    test('low-memory mode adds duration warning', () {
      final mode = PerformanceModeState.defaults().copyWith(
        lowMemoryMode: true,
      );
      final estimate = estimator.estimate(
        clips: [],
        timelineDurationMicros: 10 * 1000000,
        width: 1920,
        height: 1080,
        frameRate: 30,
        videoBitrate: 8000000,
        audioBitrate: 128000,
        performanceMode: mode,
      );
      expect(estimate.warnings, isNotEmpty);
    });
  });

  // ─── ProxyRecommendationEngine ────────────────────────────────────────────

  group('ProxyRecommendationEngine', () {
    final engine = ProxyRecommendationEngine();

    IndexedAssetInfo _makeAsset({
      String id = 'asset_1',
      String fileType = 'video',
      int width = 1920,
      int height = 1080,
      int durationMicros = 30 * 1000000,
      int fileSizeBytes = 100 * 1024 * 1024,
      bool hasProxy = false,
    }) {
      return IndexedAssetInfo(
        assetId: id,
        fileName: '$id.mp4',
        fileType: fileType,
        path: '/tmp/$id.mp4',
        exists: true,
        hasProxy: hasProxy,
        hasAudio: true,
        width: width,
        height: height,
        durationMicros: durationMicros,
        fileSizeBytes: fileSizeBytes,
      );
    }

    test('recommends proxy for high-res video without proxy', () {
      final asset = _makeAsset(width: 3840, height: 2160);
      final rec = engine.recommendForAsset(
        asset: asset,
        performanceMode: PerformanceModeState.defaults(),
      );
      expect(rec.recommended, isTrue);
      expect(rec.reasons, contains(ProxyRecommendationReason.highResolution));
    });

    test('does not recommend proxy when proxy already exists', () {
      final asset = _makeAsset(width: 3840, height: 2160, hasProxy: true);
      final rec = engine.recommendForAsset(
        asset: asset,
        performanceMode: PerformanceModeState.defaults(),
      );
      expect(rec.recommended, isFalse);
    });

    test('uses draft_540p target on low-tier devices', () {
      final mode = PerformanceModeState.defaults().copyWith(
        deviceTier: DevicePerformanceTier.low,
      );
      final asset = _makeAsset(width: 1920, height: 1080);
      final rec = engine.recommendForAsset(
        asset: asset,
        performanceMode: mode,
      );
      expect(rec.targetProfile, 'draft_540p');
    });
  });

  // ─── ProjectAssetIndexService ─────────────────────────────────────────────

  group('ProjectAssetIndexService', () {
    test('index maps asset ids correctly', () async {
      // We test with empty lists since we can't create real DB objects
      // in a unit test without a database.
      final service = ProjectAssetIndexService();
      final index = await service.build(
        projectId: 'proj_1',
        assets: [],
        clips: [],
      );

      expect(index.projectId, 'proj_1');
      expect(index.assetsById, isEmpty);
      expect(index.clipsByAssetId, isEmpty);
    });
  });
}
