import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/project_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

class ProjectService {
  final ProjectRepository _projectRepository;
  final TimelineRepository _timelineRepository;
  final ProjectStorageService _projectStorageService;

  ProjectService(
    this._projectRepository,
    this._timelineRepository,
    this._projectStorageService,
  );

  static const _uuid = Uuid();

  Future<String> createProject({
    required String name,
    required String aspectRatio,
    required int resolution,
    required int frameRate,
  }) async {
    final projectId = _uuid.v4();
    final now = DateTime.now();

    final folders =
        await _projectStorageService.createProjectFolders(projectId);

    final (width, height) = _calculateDimensions(
      aspectRatio: aspectRatio,
      resolution: resolution,
    );

    await _projectRepository.transaction(() async {
      await _projectRepository.insertProject(
        ProjectsCompanion.insert(
          id: projectId,
          name: name.trim().isEmpty ? 'Untitled Project' : name.trim(),
          aspectRatio: Value(aspectRatio),
          targetWidth: Value(width),
          targetHeight: Value(height),
          targetFrameRate: Value(frameRate),
          durationMicros: const Value(0),
          colorSpace: const Value('rec709'),
          projectFolderPath: Value(folders.root),
          createdAt: Value(now),
          modifiedAt: Value(now),
          hasWatermark: const Value(true),
          exportPreset: const Value('standard'),
        ),
      );

      await _timelineRepository.createDefaultTracks(projectId);
    });

    return projectId;
  }

  Future<void> updateModifiedAt(String projectId) {
    return _projectRepository.touchProject(projectId);
  }

  Future<void> markProjectOpened(String projectId) {
    return _projectRepository.markOpened(projectId);
  }

  Future<void> deleteProjectSafely(String projectId) async {
    await _projectRepository.deleteProjectSafely(projectId);
    await _projectStorageService.deleteProjectFolder(projectId);
  }

  (int, int) _calculateDimensions({
    required String aspectRatio,
    required int resolution,
  }) {
    switch (aspectRatio) {
      case '9:16':
        return (resolution * 9 ~/ 16, resolution);
      case '1:1':
        return (resolution, resolution);
      case '4:5':
        return (resolution * 4 ~/ 5, resolution);
      case '21:9':
        return (resolution * 21 ~/ 9, resolution);
      case '16:9':
      default:
        return (resolution * 16 ~/ 9, resolution);
    }
  }
}
