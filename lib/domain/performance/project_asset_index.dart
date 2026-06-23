import 'dart:io';

import 'package:nle_editor/data/database/app_database.dart';

class IndexedAssetInfo {
  final String assetId;
  final String fileName;
  final String fileType;
  final String path;
  final bool exists;
  final bool hasProxy;
  final bool hasAudio;
  final int? width;
  final int? height;
  final int? durationMicros;
  final int fileSizeBytes;

  const IndexedAssetInfo({
    required this.assetId,
    required this.fileName,
    required this.fileType,
    required this.path,
    required this.exists,
    required this.hasProxy,
    required this.hasAudio,
    required this.width,
    required this.height,
    required this.durationMicros,
    required this.fileSizeBytes,
  });

  bool get isLargeVideo {
    if (fileType != 'video') return false;

    final pixels = (width ?? 0) * (height ?? 0);
    final duration = durationMicros ?? 0;

    return pixels >= 1920 * 1080 || duration >= 60 * 1000000;
  }
}

class ProjectAssetIndex {
  final String projectId;
  final Map<String, IndexedAssetInfo> assetsById;
  final Map<String, List<Clip>> clipsByAssetId;
  final DateTime createdAt;

  const ProjectAssetIndex({
    required this.projectId,
    required this.assetsById,
    required this.clipsByAssetId,
    required this.createdAt,
  });

  IndexedAssetInfo? asset(String assetId) => assetsById[assetId];

  List<Clip> clipsUsingAsset(String assetId) {
    return clipsByAssetId[assetId] ?? const [];
  }
}

class ProjectAssetIndexService {
  Future<ProjectAssetIndex> build({
    required String projectId,
    required List<Asset> assets,
    required List<Clip> clips,
  }) async {
    final assetsById = <String, IndexedAssetInfo>{};

    for (final asset in assets) {
      final file = File(asset.originalPath);
      final exists = file.existsSync();

      assetsById[asset.id] = IndexedAssetInfo(
        assetId: asset.id,
        fileName: asset.fileName,
        fileType: asset.fileType,
        path: asset.originalPath,
        exists: exists,
        hasProxy: (asset.proxyPath ?? '').isNotEmpty,
        hasAudio: asset.hasAudio,
        width: asset.width,
        height: asset.height,
        durationMicros: asset.durationMicros,
        fileSizeBytes: exists ? file.lengthSync() : 0,
      );
    }

    final clipsByAssetId = <String, List<Clip>>{};

    for (final clip in clips) {
      final assetId = clip.assetId;
      if (assetId == null) continue;

      clipsByAssetId.putIfAbsent(assetId, () => []).add(clip);
    }

    return ProjectAssetIndex(
      projectId: projectId,
      assetsById: assetsById,
      clipsByAssetId: clipsByAssetId,
      createdAt: DateTime.now(),
    );
  }
}
