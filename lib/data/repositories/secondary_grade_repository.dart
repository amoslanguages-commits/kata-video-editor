import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';

class SecondaryGradeRepository {
  final db.AppDatabase database;

  const SecondaryGradeRepository({
    required this.database,
  });

  Future<NleSecondaryGradeStack> getStack(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      return const NleSecondaryGradeStack.empty();
    }
    final raw = clip.secondaryGradeStackJson;

    if (raw == null || raw.trim().isEmpty) {
      return const NleSecondaryGradeStack.empty();
    }

    try {
      return NleSecondaryGradeStack.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const NleSecondaryGradeStack.empty();
    }
  }

  Future<void> saveStack({
    required String clipId,
    required NleSecondaryGradeStack stack,
  }) async {
    await database.updateClipSecondaryGradeStackJson(
      clipId: clipId,
      secondaryGradeStackJson: jsonEncode(stack.toJson()),
    );
  }

  Future<NleSecondaryGradeLayer> addLayerFromSample({
    required String clipId,
    required NlePickedHslSample sample,
  }) async {
    final stack = await getStack(clipId);

    final layer = NleSecondaryGradeLayer(
      id: const Uuid().v4(),
      name: 'Qualifier ${stack.layers.length + 1}',
      enabled: true,
      qualifier: NleHslQualifier.fromPickedHsl(
        hue: sample.hue,
        saturation: sample.saturation,
        luminance: sample.luminance,
      ),
      correction: const NleSecondaryCorrection.identity(),
    );

    final next = stack.copyWith(
      layers: [
        ...stack.layers,
        layer,
      ],
    );

    await saveStack(
      clipId: clipId,
      stack: next,
    );

    return layer;
  }

  Future<void> addEmptyLayer(String clipId) async {
    final stack = await getStack(clipId);

    final layer = NleSecondaryGradeLayer(
      id: const Uuid().v4(),
      name: 'Secondary ${stack.layers.length + 1}',
      enabled: true,
      qualifier: const NleHslQualifier.identity().copyWith(enabled: true),
      correction: const NleSecondaryCorrection.identity(),
    );

    await saveStack(
      clipId: clipId,
      stack: stack.copyWith(layers: [...stack.layers, layer]),
    );
  }

  Future<void> updateLayer({
    required String clipId,
    required NleSecondaryGradeLayer layer,
  }) async {
    final stack = await getStack(clipId);

    await saveStack(
      clipId: clipId,
      stack: stack.updateLayer(layer),
    );
  }

  Future<void> removeLayer({
    required String clipId,
    required String layerId,
  }) async {
    final stack = await getStack(clipId);

    await saveStack(
      clipId: clipId,
      stack: stack.removeLayer(layerId),
    );
  }

  Future<void> reset(String clipId) {
    return saveStack(
      clipId: clipId,
      stack: const NleSecondaryGradeStack.empty(),
    );
  }
}
