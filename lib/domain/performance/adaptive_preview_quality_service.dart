import 'package:nle_editor/domain/performance/performance_mode.dart';

class AdaptivePreviewQualityResult {
  final String quality;
  final String reason;
  final int targetHeight;

  const AdaptivePreviewQualityResult({
    required this.quality,
    required this.reason,
    required this.targetHeight,
  });
}

class AdaptivePreviewQualityService {
  AdaptivePreviewQualityResult resolve({
    required PerformanceModeState performance,
    required int sourceWidth,
    required int sourceHeight,
    required bool isScrubbing,
    required bool isExporting,
  }) {
    if (isExporting) {
      return const AdaptivePreviewQualityResult(
        quality: PreviewQualityLevel.quarter,
        reason: 'Export is running',
        targetHeight: 360,
      );
    }

    if (performance.lowMemoryMode || performance.thermalWarning) {
      return const AdaptivePreviewQualityResult(
        quality: PreviewQualityLevel.quarter,
        reason: 'Device is under stress',
        targetHeight: 360,
      );
    }

    if (isScrubbing) {
      return const AdaptivePreviewQualityResult(
        quality: PreviewQualityLevel.half,
        reason: 'Timeline scrubbing',
        targetHeight: 540,
      );
    }

    switch (performance.previewQuality) {
      case PreviewQualityLevel.full:
        return AdaptivePreviewQualityResult(
          quality: PreviewQualityLevel.full,
          reason: 'Manual full quality',
          targetHeight: sourceHeight,
        );

      case PreviewQualityLevel.half:
        return const AdaptivePreviewQualityResult(
          quality: PreviewQualityLevel.half,
          reason: 'Manual half quality',
          targetHeight: 540,
        );

      case PreviewQualityLevel.quarter:
        return const AdaptivePreviewQualityResult(
          quality: PreviewQualityLevel.quarter,
          reason: 'Manual quarter quality',
          targetHeight: 360,
        );

      default:
        if (sourceHeight >= 2160) {
          return const AdaptivePreviewQualityResult(
            quality: PreviewQualityLevel.half,
            reason: 'Auto quality for 4K source',
            targetHeight: 720,
          );
        }

        return const AdaptivePreviewQualityResult(
          quality: PreviewQualityLevel.full,
          reason: 'Auto quality',
          targetHeight: 1080,
        );
    }
  }
}
