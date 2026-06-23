import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProjectStoragePaths {
  final String root;
  final String thumbnails;
  final String timelineThumbnails;
  final String waveforms;
  final String proxies;
  final String exports;
  final String autosaves;
  final String temp;

  const ProjectStoragePaths({
    required this.root,
    required this.thumbnails,
    required this.timelineThumbnails,
    required this.waveforms,
    required this.proxies,
    required this.exports,
    required this.autosaves,
    required this.temp,
  });
}

class ProjectStorageService {
  Future<ProjectStoragePaths> createProjectFolders(String projectId) async {
    final appDir = await getApplicationSupportDirectory();

    final root = p.join(appDir.path, 'projects', projectId);
    final thumbnails = p.join(root, 'thumbnails');
    final timelineThumbnails = p.join(root, 'timeline_thumbnails');
    final waveforms = p.join(root, 'waveforms');
    final proxies = p.join(root, 'proxies');
    final exports = p.join(root, 'exports');
    final autosaves = p.join(root, 'autosaves');
    final temp = p.join(root, 'temp');

    for (final dir in [
      root,
      thumbnails,
      timelineThumbnails,
      waveforms,
      proxies,
      exports,
      autosaves,
      temp,
    ]) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    return ProjectStoragePaths(
      root: root,
      thumbnails: thumbnails,
      timelineThumbnails: timelineThumbnails,
      waveforms: waveforms,
      proxies: proxies,
      exports: exports,
      autosaves: autosaves,
      temp: temp,
    );
  }

  Future<ProjectStoragePaths> getProjectFolders(String projectId) async {
    return createProjectFolders(projectId);
  }

  Future<void> deleteProjectFolder(String projectId) async {
    final appDir = await getApplicationSupportDirectory();
    final root = p.join(appDir.path, 'projects', projectId);
    final directory = Directory(root);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s\.\-\(\)]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
