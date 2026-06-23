import 'dart:io';

import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/project_media/project_media_management_models.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// 34C-PRO: Scans a project for missing media, broken links, usage state,
/// and storage pressure.
class ProjectMediaHealthService {
  final MediaAssetRepository mediaRepository;
  final TimelineRepository timelineRepository;
  final ProjectStorageService storageService;

  const ProjectMediaHealthService({
    required this.mediaRepository,
    required this.timelineRepository,
    required this.storageService,
  });

  Future<NleProjectMediaHealthReport> scanProject(String projectId) async {
    final assets = await mediaRepository.getAssets(projectId);
    final clips = await timelineRepository.getProjectClips(projectId);
    final usedAssetIds = clips
        .map((clip) => clip.assetId)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final items = <NleProjectMediaHealthItem>[];
    var mediaBytes = 0;
    var usedMediaBytes = 0;
    var unusedMediaBytes = 0;

    for (final asset in assets) {
      final path = asset.resolvedEditPath;
      final used = usedAssetIds.contains(asset.id);
      final declaredBytes = asset.fileInfo.fileSizeBytes;
      final exists = path != null && path.trim().isNotEmpty && await File(path).exists();
      final actualBytes = exists ? await File(path!).length() : declaredBytes;

      mediaBytes += actualBytes;
      if (used) {
        usedMediaBytes += actualBytes;
      } else {
        unusedMediaBytes += actualBytes;
      }

      final status = _statusForAsset(
        hasPath: path != null && path.trim().isNotEmpty,
        exists: exists,
        declaredBytes: declaredBytes,
        actualBytes: actualBytes,
      );

      items.add(
        NleProjectMediaHealthItem(
          assetId: asset.id,
          displayName: asset.displayName,
          expectedPath: path,
          isUsedInTimeline: used,
          status: status,
          message: _messageForStatus(status, used),
          asset: asset,
        ),
      );
    }

    final paths = await storageService.getProjectFolders(projectId);
    final proxyBytes = await _directorySize(paths.proxies);
    final thumbnailBytes = await _directorySize(paths.thumbnails) +
        await _directorySize(paths.timelineThumbnails);
    final waveformBytes = await _directorySize(paths.waveforms);
    final exportBytes = await _directorySize(paths.exports);
    final tempBytes = await _directorySize(paths.temp);

    final storage = NleProjectStorageBreakdown(
      mediaBytes: mediaBytes,
      usedMediaBytes: usedMediaBytes,
      unusedMediaBytes: unusedMediaBytes,
      proxyBytes: proxyBytes,
      thumbnailBytes: thumbnailBytes,
      waveformBytes: waveformBytes,
      exportBytes: exportBytes,
      tempBytes: tempBytes,
      totalBytes: mediaBytes +
          proxyBytes +
          thumbnailBytes +
          waveformBytes +
          exportBytes +
          tempBytes,
    );

    return NleProjectMediaHealthReport(
      projectId: projectId,
      createdAt: DateTime.now(),
      items: items,
      storage: storage,
    );
  }

  NleMediaHealthStatus _statusForAsset({
    required bool hasPath,
    required bool exists,
    required int declaredBytes,
    required int actualBytes,
  }) {
    if (!hasPath) return NleMediaHealthStatus.missing;
    if (!exists) return NleMediaHealthStatus.missing;
    if (declaredBytes > 0 && actualBytes <= 0) {
      return NleMediaHealthStatus.corrupted;
    }
    if (declaredBytes > 0 && actualBytes > 0) {
      final delta = (actualBytes - declaredBytes).abs();
      if (delta > 0 && delta > declaredBytes * 0.05) {
        return NleMediaHealthStatus.warning;
      }
    }
    return NleMediaHealthStatus.healthy;
  }

  String _messageForStatus(NleMediaHealthStatus status, bool used) {
    return switch (status) {
      NleMediaHealthStatus.healthy => used
          ? 'Media is available and used on the timeline.'
          : 'Media is available but not used on the timeline.',
      NleMediaHealthStatus.warning =>
        'Media exists, but its file size changed compared with import metadata.',
      NleMediaHealthStatus.missing => used
          ? 'Media is missing and blocks final export.'
          : 'Media is missing but is not currently used on the timeline.',
      NleMediaHealthStatus.offline => 'Media is offline.',
      NleMediaHealthStatus.corrupted => used
          ? 'Media appears corrupted and blocks final export.'
          : 'Media appears corrupted.',
    };
  }

  Future<int> _directorySize(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) return 0;

    var total = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }
}
