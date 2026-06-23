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
    int? durationMicros,
  }) {
    final issues = <ExportQualityIssue>[];
    final highResolution = preset.height >= 2160 || preset.width >= 3840;
    final estimatedBytes = _estimateBytes(durationMicros, preset.bitrateMbps);
    final freeBytes = device.runtime.availableStorageBytes;

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

    if (estimatedBytes != null && freeBytes != null) {
      final requiredBytes = estimatedBytes + 512 * 1024 * 1024;
      if (freeBytes < requiredBytes) {
        issues.add(ExportQualityIssue(
          stop: true,
          title: 'Free space is low',
          message: 'Estimated file size is ${_formatBytes(estimatedBytes)}.',
        ));
      } else if (freeBytes < requiredBytes * 2) {
        issues.add(ExportQualityIssue(
          stop: false,
          title: 'Free space warning',
          message: 'Estimated file size is ${_formatBytes(estimatedBytes)}.',
        ));
      }
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

  int? _estimateBytes(int? durationMicros, int bitrateMbps) {
    if (durationMicros == null || durationMicros <= 0 || bitrateMbps <= 0) {
      return null;
    }
    final seconds = durationMicros / 1000000.0;
    return (seconds * bitrateMbps * 1000000 / 8 * 1.18).round();
  }

  String _formatBytes(int bytes) {
    const gb = 1024 * 1024 * 1024;
    const mb = 1024 * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    return '${(bytes / mb).ceil()} MB';
  }
}
