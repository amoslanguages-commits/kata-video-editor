// lib/data/repositories/project_color_settings_repository.dart
//
// 30A-PRO: Persistence layer for ProjectColorSettings.
//
// Reads/writes the colorSettingsJson column on the Projects table.

import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/color/project_color_settings.dart';

class ProjectColorSettingsRepository {
  final db.AppDatabase database;

  const ProjectColorSettingsRepository({required this.database});

  Future<ProjectColorSettings> getProjectColorSettings(
    String projectId,
  ) async {
    final project = await database.getProjectById(projectId);
    final jsonString = project.colorSettingsJson;

    if (jsonString == null || jsonString.trim().isEmpty) {
      return ProjectColorSettings.defaultForProject(projectId);
    }

    try {
      return ProjectColorSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(jsonString) as Map),
      );
    } catch (_) {
      return ProjectColorSettings.defaultForProject(projectId);
    }
  }

  Future<void> saveProjectColorSettings(
    ProjectColorSettings settings,
  ) async {
    await database.updateProjectColorSettingsJson(
      projectId: settings.projectId,
      colorSettingsJson: jsonEncode(settings.toJson()),
    );
  }
}
