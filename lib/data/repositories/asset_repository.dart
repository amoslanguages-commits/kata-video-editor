import 'package:nle_editor/data/database/app_database.dart';

class AssetRepository {
  final AppDatabase _db;

  AssetRepository(this._db);

  Stream<List<Asset>> watchProjectAssets(String projectId) =>
      _db.watchProjectAssets(projectId);

  Future<List<Asset>> getProjectAssets(String projectId) =>
      _db.getProjectAssets(projectId);

  Future<Asset?> getAsset(String assetId) => _db.getAsset(assetId);

  Future<Asset?> getAssetByOriginalPath(String projectId, String path) =>
      _db.getAssetByOriginalPath(projectId, path);

  Future<void> insertAsset(AssetsCompanion asset) => _db.insertAsset(asset);

  Future<void> updateAssetFields(String assetId, AssetsCompanion companion) =>
      _db.updateAssetFields(assetId, companion);

  Future<void> markAssetMissing(String assetId, String message) =>
      _db.markAssetMissing(assetId, message);

  Future<void> markAssetAvailable(String assetId) =>
      _db.markAssetAvailable(assetId);

  Future<int> deleteAsset(String assetId) => _db.deleteAsset(assetId);
}
