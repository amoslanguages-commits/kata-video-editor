import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/performance/performance_mode.dart';

class ExportPerformanceEstimate {
  final Duration estimatedDuration;
  final int estimatedOutputBytes;
  final String confidence;
  final List<String> warnings;

  const ExportPerformanceEstimate({
    required this.estimatedDuration,
    required this.estimatedOutputBytes,
    required this.confidence,
    required this.warnings,
  });
}

class ExportPerformanceEstimator {
  ExportPerformanceEstimate estimate({
    required List<Clip> clips,
    required int timelineDurationMicros,
    required int width,
    required int height,
    required int frameRate,
    required int videoBitrate,
    required int audioBitrate,
    required PerformanceModeState performanceMode,
  }) {
    final durationSeconds = timelineDurationMicros / 1000000.0;
    final pixels = width * height;
    final totalBitrate = videoBitrate + audioBitrate;

    final estimatedOutputBytes =
        ((durationSeconds * totalBitrate) / 8.0).round();

    double realtimeMultiplier;

    if (pixels >= 3840 * 2160) {
      realtimeMultiplier = 3.5;
    } else if (pixels >= 1920 * 1080) {
      realtimeMultiplier = 2.0;
    } else {
      realtimeMultiplier = 1.2;
    }

    if (frameRate > 30) {
      realtimeMultiplier *= 1.4;
    }

    if (clips.length > 50) {
      realtimeMultiplier *= 1.25;
    }

    if (performanceMode.lowMemoryMode ||
        performanceMode.deviceTier == DevicePerformanceTier.low) {
      realtimeMultiplier *= 1.6;
    }

    final estimatedSeconds =
        (durationSeconds * realtimeMultiplier).clamp(5.0, 36000.0);

    final warnings = <String>[];

    if (pixels >= 3840 * 2160) {
      warnings.add('4K export may be slow on mid-range devices.');
    }

    if (clips.length > 80) {
      warnings.add('Large timeline may take longer to render.');
    }

    if (performanceMode.lowMemoryMode) {
      warnings.add('Low-memory mode is active. Export may run slower.');
    }

    return ExportPerformanceEstimate(
      estimatedDuration: Duration(seconds: estimatedSeconds.round()),
      estimatedOutputBytes: estimatedOutputBytes,
      confidence: performanceMode.deviceTier == DevicePerformanceTier.low
          ? 'low'
          : 'medium',
      warnings: warnings,
    );
  }
}
