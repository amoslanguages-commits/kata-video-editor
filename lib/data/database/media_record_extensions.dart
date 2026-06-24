import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart';

extension MediaRecordDatabaseExtensions on AppDatabase {
  Future<void> saveUnavailableMediaRecord(
    MissingMediaRecordsCompanion companion,
  ) {
    return into(missingMediaRecords).insertOnConflictUpdate(companion);
  }

  Future<void> updateCanonicalMediaPath({
    required String assetId,
    required String originalPath,
    required String availability,
  }) async {
    await (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(
        originalPath: Value(originalPath),
        availability: Value(availability),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (update(missingMediaRecords)..where((tbl) => tbl.assetId.equals(assetId))).write(
      const MissingMediaRecordsCompanion(resolved: Value(true)),
    );
  }
}
