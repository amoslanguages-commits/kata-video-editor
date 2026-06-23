import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/mappers/lut_asset_mapper.dart';
import 'package:nle_editor/domain/color_lut/color_lut_models.dart';
import 'package:nle_editor/domain/color_lut/cube_lut_header_parser.dart';

class LutRepository {
  final db.AppDatabase database;
  final CubeLutHeaderParser headerParser;
  final LutAssetMapper mapper;

  const LutRepository({
    required this.database,
    this.headerParser = const CubeLutHeaderParser(),
    this.mapper = const LutAssetMapper(),
  });

  Stream<List<NleLutAsset>> watchLuts() {
    return database.watchAllLutAssets().map(
          (rows) => rows.map(mapper.fromDb).toList(),
        );
  }

  Future<NleLutAsset> importCubeLut(String filePath) async {
    final header = await headerParser.parseFile(filePath);

    final id = const Uuid().v4();

    await database.insertLutAsset(
      id: id,
      name: header.title,
      filePath: filePath,
      sourceType: NleLutSourceType.cube.name,
      size: header.size,
      isValid: header.valid,
    );

    final row = await database.getLutAssetById(id);

    return mapper.fromDb(row);
  }

  Future<NleLutLayer> createLayerFromLut({
    required String lutAssetId,
    required double intensity,
    NleLutDomain domain = NleLutDomain.sceneLinear,
  }) async {
    final row = await database.getLutAssetById(lutAssetId);
    final lut = mapper.fromDb(row);

    return NleLutLayer(
      id: const Uuid().v4(),
      lutAssetId: lut.id,
      lutPath: lut.filePath,
      name: lut.name,
      size: lut.size,
      intensity: intensity,
      enabled: true,
      domain: domain,
      interpolation: NleLutInterpolation.trilinear,
    );
  }

  Future<NleClipLutStack> getClipLutStack({
    required String clipId,
  }) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      return NleClipLutStack.empty(clipId: clipId);
    }
    final raw = clip.lutStackJson;

    if (raw == null || raw.trim().isEmpty) {
      return NleClipLutStack.empty(clipId: clipId);
    }

    try {
      return NleClipLutStack.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return NleClipLutStack.empty(clipId: clipId);
    }
  }

  Future<void> saveClipLutStack(NleClipLutStack stack) async {
    await database.updateClipLutStackJson(
      clipId: stack.clipId,
      lutStackJson: jsonEncode(stack.toJson()),
    );
  }

  Future<void> applyLutToClip({
    required String clipId,
    required String lutAssetId,
    double intensity = 1.0,
    NleLutDomain domain = NleLutDomain.sceneLinear,
  }) async {
    final current = await getClipLutStack(clipId: clipId);

    final layer = await createLayerFromLut(
      lutAssetId: lutAssetId,
      intensity: intensity,
      domain: domain,
    );

    final next = NleClipLutStack(
      clipId: clipId,
      layers: [
        ...current.layers,
        layer,
      ],
    );

    await saveClipLutStack(next);
  }

  Future<void> updateLayerIntensity({
    required String clipId,
    required String layerId,
    required double intensity,
  }) async {
    final current = await getClipLutStack(clipId: clipId);

    final next = NleClipLutStack(
      clipId: clipId,
      layers: current.layers.map((layer) {
        if (layer.id != layerId) return layer;

        return NleLutLayer(
          id: layer.id,
          lutAssetId: layer.lutAssetId,
          lutPath: layer.lutPath,
          name: layer.name,
          size: layer.size,
          intensity: intensity.clamp(0.0, 1.0),
          enabled: layer.enabled,
          domain: layer.domain,
          interpolation: layer.interpolation,
        );
      }).toList(),
    );

    await saveClipLutStack(next);
  }

  Future<void> removeLayer({
    required String clipId,
    required String layerId,
  }) async {
    final current = await getClipLutStack(clipId: clipId);

    final next = NleClipLutStack(
      clipId: clipId,
      layers: current.layers.where((layer) => layer.id != layerId).toList(),
    );

    await saveClipLutStack(next);
  }
}
