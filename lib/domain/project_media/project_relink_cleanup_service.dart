import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/project_media/project_media_management_models.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// 34C-PRO: Relink missing files and safely clean project-generated media.
class ProjectRelinkCleanupService {
  final MediaAssetRepository mediaRepository;
  final TimelineRepository timelineRepository;
  final ProjectStorageService storageService;

  const ProjectRelinkCleanupService({
    required this.mediaRepository,
    required this.timelineRepository,
    required this.storageService,
  });

  Future<List<NleRelinkCandidate>> findRelinkCandidates({
    required String projectId,
    required String searchRootPath,
  }) async {
    final root = Directory(searchRootPath);
    if (!await root.exists()) return const [];

    final assets = await mediaRepository.getAssets(projectId);
    final missingAssets = <NleMediaAsset>[];

    for (final asset in assets) {
      final path = asset.resolvedEditPath;
      final exists = path != null && await File(path).exists();
      if (!exists || asset.isMissing) {
        missingAssets.add(asset);
      }
    }

    if (missingAssets.isEmpty) return const [];

    final files = <File>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) files.add(entity);
    }

    final candidates = <NleRelinkCandidate>[];
    for (final asset in missingAssets) {
      NleRelinkCandidate? best;
      for (final file in files) {
        final candidate = await _scoreCandidate(asset, file);
        if (candidate == null) continue;
        if (best == null || _rank(candidate.strength) > _rank(best.strength)) {
          best = candidate;
        }
      }
      if (best != null) candidates.add(best);
    }

    return candidates;
  }

  Future<NleRelinkResult> relinkAutomatically({
    required String projectId,
    required String searchRootPath,
    bool acceptWeakMatches = false,
  }) async {
    final candidates = await findRelinkCandidates(
      projectId: projectId,
      searchRootPath: searchRootPath,
    );

    var relinked = 0;
    var skipped = 0;
    final warnings = <String>[];

    for (final candidate in candidates) {
      final canApply = candidate.strength == NleRelinkMatchStrength.exact ||
          candidate.strength == NleRelinkMatchStrength.strong ||
          (acceptWeakMatches && candidate.strength == NleRelinkMatchStrength.weak);

      if (!canApply) {
        skipped++;
        warnings.add('Skipped weak relink for ${candidate.displayName}.');
        continue;
      }

      await relinkAsset(
        assetId: candidate.assetId,
        newPath: candidate.candidatePath,
      );
      relinked++;
    }

    return NleRelinkResult(
      relinkedCount: relinked,
      skippedCount: skipped,
      candidates: candidates,
      warnings: warnings,
    );
  }

  Future<void> relinkAsset({
    required String assetId,
    required String newPath,
  }) async {
    final asset = await mediaRepository.getAsset(assetId);
    if (asset == null) return;

    final file = File(newPath);
    if (!await file.exists()) {
      throw StateError('Relink file does not exist: $newPath');
    }

    final updated = asset.copyWith(
      projectPath: newPath,
      availability: NleMediaAvailability.available,
      updatedAt: DateTime.now(),
    );

    await mediaRepository.saveAsset(updated);
    await mediaRepository.setAvailability(
      assetId: assetId,
      availability: NleMediaAvailability.available,
    );
  }

  Future<NleProjectCleanupResult> cleanupProject({
    required String projectId,
    required Set<NleProjectCleanupScope> scopes,
    bool dryRun = true,
  }) async {
    final assets = await mediaRepository.getAssets(projectId);
    final clips = await timelineRepository.getProjectClips(projectId);
    final usedAssetIds = clips
        .map((clip) => clip.assetId)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    var deletedFiles = 0;
    var deletedRows = 0;
    var freedBytes = 0;
    final warnings = <String>[];

    if (scopes.contains(NleProjectCleanupScope.unusedCopiedFiles) ||
        scopes.contains(NleProjectCleanupScope.unusedMediaRows)) {
      for (final asset in assets) {
        if (usedAssetIds.contains(asset.id)) continue;

        if (scopes.contains(NleProjectCleanupScope.unusedCopiedFiles) &&
            asset.storageMode == NleMediaStorageMode.copiedIntoProject) {
          final result = await _deleteFile(asset.projectPath, dryRun: dryRun);
          deletedFiles += result.deleted ? 1 : 0;
          freedBytes += result.bytes;
        }

        if (scopes.contains(NleProjectCleanupScope.unusedMediaRows)) {
          if (!dryRun) await mediaRepository.deleteAsset(asset.id);
          deletedRows++;
        }
      }
    }

    final paths = await storageService.getProjectFolders(projectId);

    if (scopes.contains(NleProjectCleanupScope.proxies)) {
      final result = await _deleteDirectoryFiles(paths.proxies, dryRun: dryRun);
      deletedFiles += result.deletedFiles;
      freedBytes += result.freedBytes;
    }

    if (scopes.contains(NleProjectCleanupScope.thumbnails)) {
      final a = await _deleteDirectoryFiles(paths.thumbnails, dryRun: dryRun);
      final b = await _deleteDirectoryFiles(paths.timelineThumbnails, dryRun: dryRun);
      deletedFiles += a.deletedFiles + b.deletedFiles;
      freedBytes += a.freedBytes + b.freedBytes;
    }

    if (scopes.contains(NleProjectCleanupScope.waveforms)) {
      final result = await _deleteDirectoryFiles(paths.waveforms, dryRun: dryRun);
      deletedFiles += result.deletedFiles;
      freedBytes += result.freedBytes;
    }

    if (scopes.contains(NleProjectCleanupScope.tempFiles)) {
      final result = await _deleteDirectoryFiles(paths.temp, dryRun: dryRun);
      deletedFiles += result.deletedFiles;
      freedBytes += result.freedBytes;
    }

    if (dryRun) {
      warnings.add('Dry run only. No files or rows were deleted.');
    }

    return NleProjectCleanupResult(
      deletedFiles: deletedFiles,
      deletedRows: deletedRows,
      freedBytes: freedBytes,
      warnings: warnings,
    );
  }

  Future<NleRelinkCandidate?> _scoreCandidate(NleMediaAsset asset, File file) async {
    final expectedName = asset.fileInfo.fileName.trim().isNotEmpty
        ? asset.fileInfo.fileName.trim().toLowerCase()
        : asset.displayName.trim().toLowerCase();
    final candidateName = p.basename(file.path).trim().toLowerCase();
    final size = await file.length();
    final expectedSize = asset.fileInfo.fileSizeBytes;

    if (expectedName.isEmpty) return null;

    final sameName = candidateName == expectedName;
    final sameExtension = p.extension(candidateName) == p.extension(expectedName);
    final sizeClose = expectedSize <= 0 || (size - expectedSize).abs() <= expectedSize * 0.02;

    if (sameName && sizeClose) {
      return NleRelinkCandidate(
        assetId: asset.id,
        displayName: asset.displayName,
        candidatePath: file.path,
        strength: NleRelinkMatchStrength.exact,
        reason: 'File name and size match.',
      );
    }

    if (sameName) {
      return NleRelinkCandidate(
        assetId: asset.id,
        displayName: asset.displayName,
        candidatePath: file.path,
        strength: NleRelinkMatchStrength.strong,
        reason: 'File name matches, but size differs.',
      );
    }

    if (sameExtension && candidateName.contains(p.basenameWithoutExtension(expectedName))) {
      return NleRelinkCandidate(
        assetId: asset.id,
        displayName: asset.displayName,
        candidatePath: file.path,
        strength: NleRelinkMatchStrength.weak,
        reason: 'Similar file name and extension.',
      );
    }

    return null;
  }

  int _rank(NleRelinkMatchStrength strength) {
    return switch (strength) {
      NleRelinkMatchStrength.exact => 4,
      NleRelinkMatchStrength.strong => 3,
      NleRelinkMatchStrength.weak => 2,
      NleRelinkMatchStrength.manual => 1,
      NleRelinkMatchStrength.none => 0,
    };
  }

  Future<_DeleteFileResult> _deleteFile(String? path, {required bool dryRun}) async {
    if (path == null || path.trim().isEmpty) {
      return const _DeleteFileResult(deleted: false, bytes: 0);
    }
    final file = File(path);
    if (!await file.exists()) {
      return const _DeleteFileResult(deleted: false, bytes: 0);
    }
    final bytes = await file.length();
    if (!dryRun) await file.delete();
    return _DeleteFileResult(deleted: true, bytes: bytes);
  }

  Future<_DeleteDirectoryResult> _deleteDirectoryFiles(
    String directoryPath, {
    required bool dryRun,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return const _DeleteDirectoryResult(deletedFiles: 0, freedBytes: 0);
    }

    var deletedFiles = 0;
    var freedBytes = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        freedBytes += await entity.length();
        deletedFiles++;
        if (!dryRun) await entity.delete();
      } catch (_) {}
    }

    return _DeleteDirectoryResult(
      deletedFiles: deletedFiles,
      freedBytes: freedBytes,
    );
  }
}

class _DeleteFileResult {
  final bool deleted;
  final int bytes;

  const _DeleteFileResult({required this.deleted, required this.bytes});
}

class _DeleteDirectoryResult {
  final int deletedFiles;
  final int freedBytes;

  const _DeleteDirectoryResult({
    required this.deletedFiles,
    required this.freedBytes,
  });
}
