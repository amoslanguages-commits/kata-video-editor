import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:nle_editor/domain/lifecycle/project_session_state.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// Reads and writes the `session_state.json` file for a project.
/// This file is placed in the project's root storage folder alongside
/// thumbnails, autosaves, etc.
class ProjectSessionService {
  final ProjectStorageService projectStorageService;

  ProjectSessionService({
    required this.projectStorageService,
  });

  Future<File> _sessionFile(String projectId) async {
    final folders = await projectStorageService.getProjectFolders(projectId);
    return File(p.join(folders.root, 'session_state.json'));
  }

  Future<void> saveSession(ProjectSessionState session) async {
    final file = await _sessionFile(session.projectId);

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(session.toJson()),
    );
  }

  Future<ProjectSessionState?> readSession(String projectId) async {
    final file = await _sessionFile(projectId);

    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      return ProjectSessionState.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasSession(String projectId) async {
    final file = await _sessionFile(projectId);
    return file.exists();
  }

  Future<void> clearSession(String projectId) async {
    final file = await _sessionFile(projectId);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
