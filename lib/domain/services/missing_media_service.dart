import 'dart:io';

import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

class MissingMediaReport {
  final int totalAssets;
  final int missingAssets;

  const MissingMediaReport({
    required this.totalAssets,
    required this.missingAssets,
  });

  bool get hasMissing => missingAssets > 0;
}

/// Checks each asset's file on disk and marks missing/available in DB.
class MissingMediaService {
  final MediaAssetRepository assetRepository;

  MissingMediaService({required this.assetRepository});

  Future<MissingMediaReport> checkProjectMedia(String projectId) async {
    final assets = await assetRepository.getAssets(projectId);
    var missing = 0;

    for (final asset in assets) {
      final path = asset.projectPath ?? asset.originalPath;
      final exists = path != null && await File(path).exists();

      if (!exists) {
        missing++;
        await assetRepository.setAvailability(
          assetId: asset.id,
          availability: NleMediaAvailability.missing,
        );
      } else if (asset.isMissing) {
        await assetRepository.setAvailability(
          assetId: asset.id,
          availability: NleMediaAvailability.available,
        );
      }
    }

    return MissingMediaReport(
      totalAssets: assets.length,
      missingAssets: missing,
    );
  }
}

