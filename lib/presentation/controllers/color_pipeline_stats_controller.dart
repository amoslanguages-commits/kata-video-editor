import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/color/gpu_color_pipeline_models.dart';
import 'package:nle_editor/domain/preview/preview_monitor.dart';
import 'package:nle_editor/native_bridge/native_preview_events.dart';
import 'package:nle_editor/native_bridge/native_true_preview_service.dart';
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';

class ColorPipelineStatsState {
  final Map<PreviewMonitor, ColorPipelineStats> statsByMonitor;

  const ColorPipelineStatsState({
    required this.statsByMonitor,
  });

  const ColorPipelineStatsState.empty()
      : statsByMonitor = const {};

  ColorPipelineStats? statsFor(PreviewMonitor monitor) {
    return statsByMonitor[monitor];
  }

  ColorPipelineStatsState withStats({
    required PreviewMonitor monitor,
    required ColorPipelineStats stats,
  }) {
    final next = Map<PreviewMonitor, ColorPipelineStats>.from(statsByMonitor);
    next[monitor] = stats;

    return ColorPipelineStatsState(statsByMonitor: next);
  }
}

class ColorPipelineStatsController
    extends StateNotifier<ColorPipelineStatsState> {
  final NativeTruePreviewService previewService;
  StreamSubscription<NativePreviewEvent>? _subscription;

  ColorPipelineStatsController({
    required this.previewService,
  }) : super(const ColorPipelineStatsState.empty()) {
    _subscription = previewService.events.listen(_handleEvent);
  }

  void _handleEvent(NativePreviewEvent event) {
    if (event is ColorPipelineStatsEvent) {
      state = state.withStats(
        monitor: event.monitor,
        stats: event.stats,
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final colorPipelineStatsControllerProvider =
    StateNotifierProvider<ColorPipelineStatsController, ColorPipelineStatsState>((ref) {
  final service = ref.watch(nativeTruePreviewServiceProvider);
  return ColorPipelineStatsController(previewService: service);
});
