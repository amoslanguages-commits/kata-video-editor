import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/data/repositories/project_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// STEP 18 — Saves a full JSON snapshot of the project timeline every N seconds.
class ProjectAutosaveService {
  final ProjectRepository projectRepository;
  final AssetRepository assetRepository;
  final TimelineRepository timelineRepository;
  final ProjectStorageService storageService;

  ProjectAutosaveService({
    required this.projectRepository,
    required this.assetRepository,
    required this.timelineRepository,
    required this.storageService,
  });

  Future<String?> autosaveProject(String projectId) async {
    final project = await projectRepository.getProject(projectId);
    if (project == null) return null;

    final assets = await assetRepository.getProjectAssets(projectId);
    final tracks = await timelineRepository.getProjectTracks(projectId);
    final clips = await timelineRepository.getProjectClips(projectId);
    final folders = await storageService.getProjectFolders(projectId);
    final now = DateTime.now();

    final snapshot = {
      'version': 1,
      'type': 'nle_autosave',
      'projectId': projectId,
      'savedAt': now.toIso8601String(),
      'project': {
        'id': project.id,
        'name': project.name,
        'aspectRatio': project.aspectRatio,
        'targetWidth': project.targetWidth,
        'targetHeight': project.targetHeight,
        'targetFrameRate': project.targetFrameRate,
        'durationMicros': project.durationMicros,
        'colorSpace': project.colorSpace,
        'hasWatermark': project.hasWatermark,
        'exportPreset': project.exportPreset,
      },
      'assets': assets
          .map((a) => {
                'id': a.id,
                'fileName': a.fileName,
                'originalPath': a.originalPath,
                'fileType': a.fileType,
                'durationMicros': a.durationMicros,
                'width': a.width,
                'height': a.height,
                'thumbnailPath': a.thumbnailPath,
                'waveformPath': a.waveformPath,
                'proxyPath': a.proxyPath,
                'isMissing': a.isMissing,
              })
          .toList(),
      'tracks': tracks
          .map((t) => {
                'id': t.id,
                'name': t.name,
                'type': t.type,
                'index': t.index,
                'isMuted': t.isMuted,
                'isVisible': t.isVisible,
                'isLocked': t.isLocked,
              })
          .toList(),
      'clips': clips
          .map((c) => {
                'id': c.id,
                'trackId': c.trackId,
                'assetId': c.assetId,
                'clipType': c.clipType,
                'timelineStartMicros': c.timelineStartMicros,
                'timelineEndMicros': c.timelineEndMicros,
                'sourceInMicros': c.sourceInMicros,
                'sourceOutMicros': c.sourceOutMicros,
                'positionX': c.positionX,
                'positionY': c.positionY,
                'scale': c.scale,
                'rotation': c.rotation,
                'opacity': c.opacity,
                'exposure': c.exposure,
                'contrast': c.contrast,
                'saturation': c.saturation,
                'temperature': c.temperature,
                'tint': c.tint,
                'volume': c.volume,
                'audioPan': c.audioPan,
                'textContent': c.textContent,
                'textStyle': c.textStyle,
                'speed': c.speed,
                'isReversed': c.isReversed,
              })
          .toList(),
    };

    final encoded = const JsonEncoder.withIndent('  ').convert(snapshot);
    final latestPath = p.join(folders.autosaves, 'latest.autosave.json');
    final datedPath = p.join(
      folders.autosaves,
      'autosave_${now.millisecondsSinceEpoch}.json',
    );

    await File(latestPath).writeAsString(encoded);
    await File(datedPath).writeAsString(encoded);
    await projectRepository.touchProject(projectId);

    return latestPath;
  }

  Future<bool> hasRecoverySnapshot(String projectId) async {
    final folders = await storageService.getProjectFolders(projectId);
    return File(p.join(folders.autosaves, 'latest.autosave.json')).exists();
  }

  Future<Map<String, dynamic>?> readLatestSnapshot(String projectId) async {
    final folders = await storageService.getProjectFolders(projectId);
    final file = File(p.join(folders.autosaves, 'latest.autosave.json'));
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }
}

/// Timer-driven controller that kicks off autosave every 8 seconds.
class ProjectAutosaveController {
  final ProjectAutosaveService autosaveService;

  Timer? _timer;
  String? _projectId;

  ProjectAutosaveController({required this.autosaveService});

  void start(String projectId) {
    if (_projectId == projectId && _timer != null) return;
    stop();
    _projectId = projectId;
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      autosaveService.autosaveProject(projectId).ignore();
    });
  }

  Future<void> saveNow() async {
    final id = _projectId;
    if (id != null) await autosaveService.autosaveProject(id);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _projectId = null;
  }
}
