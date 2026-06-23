// lib/data/repositories/source_preview_repository.dart
//
// 29F: Fetches asset data for the Source Preview controller.

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/mappers/source_preview_asset_mapper.dart';
import 'package:nle_editor/domain/source_preview/source_preview_models.dart';

class SourcePreviewRepository {
  final db.AppDatabase database;
  final SourcePreviewAssetMapper mapper;

  const SourcePreviewRepository({
    required this.database,
    this.mapper = const SourcePreviewAssetMapper(),
  });

  Future<SourcePreviewAsset> getAsset(String assetId) async {
    final row = await database.getAsset(assetId);
    if (row == null) {
      throw StateError('Asset $assetId not found');
    }
    return mapper.fromDb(row);
  }
}
