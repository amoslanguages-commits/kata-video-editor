import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';

class ClipInspectorMapper {
  const ClipInspectorMapper();

  ClipInspectorState fromDb(db.Clip row) {
    return ClipInspectorState(
      clipId: row.id,
      projectId: row.projectId,
      trackId: row.trackId,
      assetId: _emptyToNull(row.assetId),
      clipType: row.clipType,
      name: row.textContent ?? 'Clip',
      timelineStartMicros: row.timelineStartMicros,
      timelineEndMicros: row.timelineEndMicros,
      sourceStartMicros: row.sourceInMicros,
      sourceEndMicros: row.sourceOutMicros,
      positionX: row.positionX,
      positionY: row.positionY,
      scale: row.scale,
      rotation: row.rotation,
      opacity: row.opacity,
      fitMode: ClipFitModeX.fromDb(row.fitMode),
      cropLeft: row.cropLeft,
      cropTop: row.cropTop,
      cropRight: row.cropRight,
      cropBottom: row.cropBottom,
      speed: row.speed,
      volume: row.volume,
      fadeInMicros: row.fadeInMicros,
      fadeOutMicros: row.fadeOutMicros,
      brightness: row.brightness,
      contrast: row.contrast,
      saturation: row.saturation,
      exposure: row.exposure,
      temperature: row.temperature,
      tint: row.tint,
      highlights: row.highlights,
      shadows: row.shadows,
      textContent: row.textContent ?? '',
      textStyleJson: _emptyToNull(row.textStyleJson),
      colorHex: _emptyToNull(row.colorHex),
      isDisabled: row.isDisabled,
    );
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    if (value.trim().isEmpty) return null;
    return value;
  }
}
