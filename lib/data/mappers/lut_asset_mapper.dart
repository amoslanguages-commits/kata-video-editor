import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/color_lut/color_lut_models.dart';

class LutAssetMapper {
  const LutAssetMapper();

  NleLutAsset fromDb(db.LutAsset row) {
    return NleLutAsset(
      id: row.id,
      name: row.name,
      filePath: row.filePath,
      sourceType: _sourceType(row.sourceType),
      size: row.size,
      isValid: row.isValid,
      previewThumbnailPath: row.previewThumbnailPath,
      importedAt: row.importedAt,
    );
  }

  NleLutSourceType _sourceType(String value) {
    switch (value) {
      case 'builtIn':
        return NleLutSourceType.builtIn;
      case 'generated':
        return NleLutSourceType.generated;
      case 'cube':
      default:
        return NleLutSourceType.cube;
    }
  }
}
