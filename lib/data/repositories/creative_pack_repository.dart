import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/premium/built_in_creative_packs.dart';
import 'package:nle_editor/domain/premium/creative_pack.dart';
import 'package:nle_editor/domain/premium/user_creative_preset.dart';

class CreativePackRepository {
  final AppDatabase db;

  CreativePackRepository({
    required this.db,
  });

  Future<List<CreativePack>> getBuiltInPacks() async {
    return BuiltInCreativePacks.all();
  }

  Future<List<CreativePack>> getPacksByType(String type) async {
    final all = await getBuiltInPacks();
    return all.where((pack) => pack.type == type).toList();
  }

  Future<CreativePackItem?> findItem(String itemId) async {
    final packs = await getBuiltInPacks();

    for (final pack in packs) {
      for (final item in pack.items) {
        if (item.id == itemId) return item;
      }
    }

    return null;
  }

  Stream<List<UserCreativePreset>> watchUserPresets(String type) {
    return db.watchUserCreativePresets(type).map(
          (rows) => rows
              .map(
                (row) => UserCreativePreset(
                  id: row.id,
                  name: row.name,
                  type: row.type,
                  sourceItemId: row.sourceItemId ?? '',
                  payload: _asMap(jsonDecode(row.payloadJson)),
                  createdAt: row.createdAt,
                  updatedAt: row.updatedAt,
                ),
              )
              .toList(),
        );
  }

  Future<void> saveUserPreset(UserCreativePreset preset) {
    return db.insertUserCreativePreset(
      UserCreativePresetsCompanion.insert(
        id: preset.id,
        name: preset.name,
        type: preset.type,
        sourceItemId: Value(preset.sourceItemId),
        payloadJson: preset.payloadJson,
        createdAt: preset.createdAt,
        updatedAt: preset.updatedAt,
      ),
    );
  }

  Future<void> deleteUserPreset(String id) {
    return db.deleteUserCreativePreset(id);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }

    return {};
  }
}
