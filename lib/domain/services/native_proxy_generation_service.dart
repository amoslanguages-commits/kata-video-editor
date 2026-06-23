import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_proxy_job.dart';

class NativeProxyGenerationService {
  final NativeBridgeContract nativeBridge;
  final AssetRepository assetRepository;
  final ProjectStorageService storageService;

  static const _uuid = Uuid();

  NativeProxyGenerationService({
    required this.nativeBridge,
    required this.assetRepository,
    required this.storageService,
  });

  Future<String> requestProxyGeneration({
    required Asset asset,
    NativeProxyProfile profile = const NativeProxyProfile(),
  }) async {
    final jobId = _uuid.v4();

    await assetRepository.updateAssetFields(
      asset.id,
      const AssetsCompanion(
        proxyStatus: Value('processing'),
        errorMessage: Value(null),
      ),
    );

    try {
      final folders = await storageService.getProjectFolders(asset.projectId);
      final outputPath = p.join(folders.proxies, '${asset.id}_proxy.mp4');

      final result = await nativeBridge.startProxyJob(
        projectId: asset.projectId,
        jobId: jobId,
        assetId: asset.id,
        inputPath: asset.originalPath,
        outputPath: outputPath,
        profile: profile.toJson(),
      );

      if (!result.accepted) {
        throw StateError(result.message ?? 'Proxy request rejected by native engine.');
      }

      return jobId;
    } catch (e) {
      await assetRepository.updateAssetFields(
        asset.id,
        AssetsCompanion(
          proxyStatus: const Value('failed'),
          errorMessage: Value(e.toString()),
        ),
      );
      rethrow;
    }
  }

  Future<void> cancelProxyGeneration({
    required String jobId,
  }) async {
    final result = await nativeBridge.cancelProxyJob(jobId: jobId);
    if (!result.accepted) {
      throw StateError(result.message ?? 'Cancel request failed.');
    }
  }
}
