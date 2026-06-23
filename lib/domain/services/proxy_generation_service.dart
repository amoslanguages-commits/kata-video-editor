import 'dart:io';

import 'package:drift/drift.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';

/// STEP 22 — Generates a low-resolution proxy for fast editing.
class ProxyGenerationService {
  final AssetRepository assetRepository;
  final ProjectStorageService storageService;

  ProxyGenerationService({
    required this.assetRepository,
    required this.storageService,
  });

  Future<String?> generateProxy({
    required String projectId,
    required String assetId,
    int height = 720,
  }) async {
    final asset = await assetRepository.getAsset(assetId);
    if (asset == null || asset.fileType != 'video') return null;

    final original = File(asset.originalPath);
    if (!await original.exists()) {
      await assetRepository.markAssetMissing(
        asset.id,
        'Original file is missing. Proxy cannot be generated.',
      );
      return null;
    }

    final folders = await storageService.getProjectFolders(projectId);
    final outputPath =
        p.join(folders.proxies, '${asset.id}_${height}p_proxy.mp4');

    await assetRepository.updateAssetFields(
      asset.id,
      AssetsCompanion(
        proxyStatus: const Value('generating'),
        errorMessage: const Value(null),
        proxyHeight: Value(height),
      ),
    );

    final command = [
      '-y',
      '-i', _q(asset.originalPath),
      '-vf', _q('scale=-2:$height'),
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-crf', '28',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-movflags', '+faststart',
      _q(outputPath),
    ].join(' ');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final proxyFile = File(outputPath);
      final size = await proxyFile.exists() ? await proxyFile.length() : 0;

      await assetRepository.updateAssetFields(
        asset.id,
        AssetsCompanion(
          proxyPath: Value(outputPath),
          proxyStatus: const Value('ready'),
          proxyHeight: Value(height),
          proxyCodec: const Value('h264'),
          proxyFileSize: Value(size),
        ),
      );
      return outputPath;
    }

    final logs = await session.getAllLogsAsString();
    await assetRepository.updateAssetFields(
      asset.id,
      AssetsCompanion(
        proxyStatus: const Value('failed'),
        errorMessage: Value(logs),
      ),
    );
    return null;
  }

  String _q(String value) => '"${value.replaceAll('"', r'\"')}"';
}
