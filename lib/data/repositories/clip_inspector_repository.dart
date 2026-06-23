import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/mappers/clip_inspector_mapper.dart';
import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';

class ClipInspectorRepository {
  final db.AppDatabase database;
  final ClipInspectorMapper mapper;

  const ClipInspectorRepository({
    required this.database,
    this.mapper = const ClipInspectorMapper(),
  });

  Stream<ClipInspectorState?> watchClip(String clipId) {
    return database.watchClip(clipId).map((clip) {
      if (clip == null) return null;
      return mapper.fromDb(clip);
    });
  }

  Future<ClipInspectorState> getClip(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      throw Exception('Clip not found: $clipId');
    }
    return mapper.fromDb(clip);
  }

  Future<void> updateTransform({
    required String clipId,
    double? positionX,
    double? positionY,
    double? scale,
    double? rotation,
    double? opacity,
  }) {
    return database.updateClipTransform(
      clipId: clipId,
      positionX: positionX,
      positionY: positionY,
      scale: scale,
      rotation: rotation,
      opacity: opacity,
    );
  }

  Future<void> updateFitAndCrop({
    required String clipId,
    ClipFitMode? fitMode,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) {
    return database.updateClipFitAndCrop(
      clipId: clipId,
      fitMode: fitMode?.dbValue,
      cropLeft: cropLeft,
      cropTop: cropTop,
      cropRight: cropRight,
      cropBottom: cropBottom,
    );
  }

  Future<void> updateSpeed({
    required String clipId,
    required double speed,
  }) {
    return database.updateClipSpeed(
      clipId: clipId,
      speed: speed,
    );
  }

  Future<void> updateAudio({
    required String clipId,
    double? volume,
    int? fadeInMicros,
    int? fadeOutMicros,
  }) {
    return database.updateClipAudio(
      clipId: clipId,
      volume: volume,
      fadeInMicros: fadeInMicros,
      fadeOutMicros: fadeOutMicros,
    );
  }

  Future<void> updateColor({
    required String clipId,
    double? brightness,
    double? contrast,
    double? saturation,
    double? exposure,
    double? temperature,
    double? tint,
    double? highlights,
    double? shadows,
  }) {
    return database.updateClipColorAdjustments(
      clipId: clipId,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      exposure: exposure,
      temperature: temperature,
      tint: tint,
      highlights: highlights,
      shadows: shadows,
    );
  }

  Future<void> updateText({
    required String clipId,
    String? textContent,
    String? textStyleJson,
    String? colorHex,
  }) {
    return database.updateTextClip(
      clipId: clipId,
      textContent: textContent,
      textStyleJson: textStyleJson,
      colorHex: colorHex,
    );
  }

  Future<void> resetVisualAdjustments(String clipId) {
    return database.resetClipVisualAdjustments(clipId);
  }
}
