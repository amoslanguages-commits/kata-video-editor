import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

class MediaProjectPathService {
  const MediaProjectPathService();

  Future<Directory> projectRoot(String projectId) async {
    final docs = await getApplicationDocumentsDirectory();

    final root = Directory(
      p.join(
        docs.path,
        'projects',
        projectId,
      ),
    );

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    return root;
  }

  Future<Directory> mediaDir(String projectId, NleMediaAssetType type) async {
    final root = await projectRoot(projectId);

    final folderName = switch (type) {
      NleMediaAssetType.video => 'media/video',
      NleMediaAssetType.audio => 'media/audio',
      NleMediaAssetType.image => 'media/images',
      NleMediaAssetType.unknown => 'media/other',
    };

    final dir = Directory(p.join(root.path, folderName));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  Future<Directory> thumbnailDir(String projectId) async {
    final root = await projectRoot(projectId);

    final dir = Directory(p.join(root.path, 'cache', 'thumbnails'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  Future<Directory> proxyDir(String projectId) async {
    final root = await projectRoot(projectId);

    final dir = Directory(p.join(root.path, 'proxies'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  Future<String> createImportedMediaPath({
    required String projectId,
    required NleMediaAssetType type,
    required String assetId,
    required String originalPath,
  }) async {
    final dir = await mediaDir(projectId, type);

    final ext = p.extension(originalPath);
    final safeExt = ext.isEmpty ? '.media' : ext;

    return p.join(dir.path, 'asset_$assetId$safeExt');
  }

  Future<String> createThumbnailPath({
    required String projectId,
    required String assetId,
  }) async {
    final dir = await thumbnailDir(projectId);
    return p.join(dir.path, 'thumb_$assetId.jpg');
  }

  Future<String> createProxyPath({
    required String projectId,
    required String assetId,
  }) async {
    final dir = await proxyDir(projectId);
    return p.join(dir.path, 'proxy_$assetId.mp4');
  }
}
