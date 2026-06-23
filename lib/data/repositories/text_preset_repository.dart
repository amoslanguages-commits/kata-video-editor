import 'package:nle_editor/data/database/app_database.dart';

class TextPresetRepository {
  final AppDatabase _db;

  TextPresetRepository(this._db);

  Stream<List<LocalTextPreset>> watchLocalTextPresets() {
    return _db.watchLocalTextPresets();
  }

  Future<List<LocalTextPreset>> getLocalTextPresets() {
    return _db.getLocalTextPresets();
  }

  Future<LocalTextPreset?> getLocalTextPreset(String presetId) {
    return _db.getLocalTextPreset(presetId);
  }

  Future<void> insertLocalTextPreset(LocalTextPresetsCompanion preset) {
    return _db.insertLocalTextPreset(preset);
  }

  Future<void> updateLocalTextPresetFields(
    String presetId,
    LocalTextPresetsCompanion companion,
  ) {
    return _db.updateLocalTextPresetFields(presetId, companion);
  }

  Future<int> deleteLocalTextPreset(String presetId) {
    return _db.deleteLocalTextPreset(presetId);
  }
}
