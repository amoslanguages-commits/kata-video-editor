import 'package:nle_editor/domain/device/device_capability_profile.dart';
import 'package:nle_editor/domain/export/export_preset_builder_models.dart';

class ExportQualityIssue {
  final bool stop;
  final String title;
  final String message;

  const ExportQualityIssue({
    required this.stop,
    required this.title,
    required this.message,
  });
}

class ExportQualityReport {
  final List<ExportQualityIssue> issues;

  const ExportQualityReport(this.issues);

  bool get hasIssues => issues.isNotEmpty;
  bool get shouldStop => issues.any((issue) => issue.stop);
}

class ExportQualityAdvisor {
  const ExportQualityAdvisor();

  ExportQualityReport check({
    required NleExportPresetSpec preset,
    required DeviceCapabilityProfile device,
  }) {
    final issues = <ExportQualityIssue>[];
    final highResolution = preset.height >= 2160 || preset.width >= 3840;

    if (preset.height > device.limits.maxExportHeight) {
      issues.add(ExportQualityIssue(
        stop: true,
        title: 'Resolution too high',
        message: '${preset.resolutionLabel} is above the safe device limit.',
      ));
    }

    if (preset.frameRate > device.limits.maxExportFrameRate) {
      issues.add(ExportQualityIssue(
        stop: true,
        title: 'Frame rate too high',
        message: '${preset.frameRateLabel} is above the safe device limit.',
      ));
    }

    if (highResolution && !device.limits.allow4kExport) {
      issues.add(const ExportQualityIssue(
        stop: true,
        title: 'High resolution not supported',
        message: 'Use a lower resolution preset on this device.',
      ));
    }

    if (highResolution && device.limits.proxyRequiredFor4k) {
      issues.add(const ExportQualityIssue(
        stop: false,
        title: 'High resolution may be slow',
        message: 'Generating proxies first can improve export stability.',
      ));
    }

    if (preset.height >= 2160 && preset.bitrateMbps < 35) {
      issues.add(const ExportQualityIssue(
        stop: false,
        title: 'Bitrate may be low',
        message: 'Higher bitrate is recommended for 4K exports.',
      ));
    }

    if (preset.height >= 1080 && preset.bitrateMbps < 8) {
      issues.add(const ExportQualityIssue(
        stop: false,
        title: 'Bitrate may be low',
        message: 'Higher bitrate is recommended for 1080p exports.',
      ));
    }

    if (device.runtime.lowPowerMode || device.runtime.memoryPressure) {
      issues.add(const ExportQualityIssue(
        stop: false,
        title: 'Device pressure detected',
        message: 'Close other apps or keep the device charging for long exports.',
      ));
    }

    return ExportQualityReport(issues);
  }
}
