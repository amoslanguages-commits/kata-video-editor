import 'package:nle_editor/domain/device/device_capability_profile.dart';
import 'package:nle_editor/domain/export/advanced_export_settings.dart';
import 'package:nle_editor/domain/export/export_preset_builder_models.dart';

class ExportCapabilityIssue {
  final String title;
  final String message;
  final bool blocksExport;

  const ExportCapabilityIssue({
    required this.title,
    required this.message,
    this.blocksExport = false,
  });
}

class ExportCapabilityReport {
  final List<ExportCapabilityIssue> issues;

  const ExportCapabilityReport(this.issues);

  bool get hasIssues => issues.isNotEmpty;
  bool get blocksExport => issues.any((issue) => issue.blocksExport);
}

class ExportCapabilityMatcher {
  const ExportCapabilityMatcher();

  ExportCapabilityReport check({
    required NleExportPresetSpec preset,
    required AdvancedExportSettings advanced,
    required DeviceCapabilityProfile device,
  }) {
    final issues = <ExportCapabilityIssue>[];

    if (preset.height > device.limits.maxExportHeight) {
      issues.add(
        ExportCapabilityIssue(
          title: 'Resolution too high',
          message:
              'This device supports up to ${device.limits.maxExportHeight}p export safely.',
          blocksExport: true,
        ),
      );
    }

    if (preset.frameRate > device.limits.maxExportFrameRate) {
      issues.add(
        ExportCapabilityIssue(
          title: 'Frame rate too high',
          message:
              'This device supports up to ${device.limits.maxExportFrameRate}fps export safely.',
          blocksExport: true,
        ),
      );
    }

    if (advanced.videoCodec == ExportVideoCodecs.h265 &&
        !device.codecSupport.hevcEncode) {
      issues.add(
        const ExportCapabilityIssue(
          title: 'HEVC unavailable',
          message: 'This device does not report HEVC export support. Use H.264 instead.',
          blocksExport: true,
        ),
      );
    }

    if (advanced.hdrExport && !device.codecSupport.hdrExport) {
      issues.add(
        const ExportCapabilityIssue(
          title: 'HDR export unavailable',
          message: 'This device does not report safe HDR export support.',
          blocksExport: true,
        ),
      );
    }

    if (advanced.videoCodec == ExportVideoCodecs.proRes) {
      issues.add(
        const ExportCapabilityIssue(
          title: 'ProRes native hook required',
          message: 'ProRes is exposed in the profile but needs platform encoder support.',
        ),
      );
    }

    if (preset.height >= 2160 && device.limits.proxyRequiredFor4k) {
      issues.add(
        const ExportCapabilityIssue(
          title: '4K proxy recommended',
          message: 'This device should build proxies before 4K export.',
        ),
      );
    }

    return ExportCapabilityReport(issues);
  }
}
