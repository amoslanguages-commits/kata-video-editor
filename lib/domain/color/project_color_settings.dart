// lib/domain/color/project_color_settings.dart
//
// 30A-PRO: Project-level color management settings.
//
// Stored as JSON in the Projects table (colorSettingsJson column).
// Wraps the full NleColorManagementPipeline plus project-scoped flags.

import 'package:nle_editor/domain/color/color_management_models.dart';

class ProjectColorSettings {
  final String projectId;
  final NleColorManagementPipeline pipeline;
  final bool useAutomaticInputDetection;
  final bool warnOnMixedColorSpaces;
  final bool preferWideGamutPreview;
  final bool allowHdrExport;

  const ProjectColorSettings({
    required this.projectId,
    required this.pipeline,
    this.useAutomaticInputDetection = true,
    this.warnOnMixedColorSpaces = true,
    this.preferWideGamutPreview = false,
    this.allowHdrExport = false,
  });

  factory ProjectColorSettings.defaultForProject(String projectId) {
    return ProjectColorSettings(
      projectId: projectId,
      pipeline: const NleColorManagementPipeline.defaultRec709(),
      useAutomaticInputDetection: true,
      warnOnMixedColorSpaces: true,
      preferWideGamutPreview: false,
      allowHdrExport: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'pipeline': pipeline.toJson(),
      'useAutomaticInputDetection': useAutomaticInputDetection,
      'warnOnMixedColorSpaces': warnOnMixedColorSpaces,
      'preferWideGamutPreview': preferWideGamutPreview,
      'allowHdrExport': allowHdrExport,
    };
  }

  factory ProjectColorSettings.fromJson(Map<String, dynamic> json) {
    return ProjectColorSettings(
      projectId: json['projectId']?.toString() ?? '',
      pipeline: NleColorManagementPipeline.fromJson(
        Map<String, dynamic>.from(json['pipeline'] as Map? ?? const {}),
      ),
      useAutomaticInputDetection: json['useAutomaticInputDetection'] != false,
      warnOnMixedColorSpaces: json['warnOnMixedColorSpaces'] != false,
      preferWideGamutPreview: json['preferWideGamutPreview'] == true,
      allowHdrExport: json['allowHdrExport'] == true,
    );
  }
}
