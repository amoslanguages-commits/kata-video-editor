import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/overlays/overlay_template_factory.dart';

class OverlayClipRepository {
  final db.AppDatabase database;
  final OverlayTemplateFactory templates;

  const OverlayClipRepository({
    required this.database,
    this.templates = const OverlayTemplateFactory(),
  });

  Future<NleOverlayClipData> getOverlayData(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      return NleOverlayClipData.rectangle(id: clipId);
    }
    final raw = clip.overlayDataJson;

    if (raw == null || raw.trim().isEmpty) {
      return NleOverlayClipData.rectangle(id: clipId);
    }

    try {
      return NleOverlayClipData.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return NleOverlayClipData.rectangle(id: clipId);
    }
  }

  Future<void> saveOverlayData({
    required String clipId,
    required NleOverlayClipData data,
  }) {
    return database.updateClipOverlayDataJson(
      clipId: clipId,
      overlayDataJson: jsonEncode(data.toJson()),
    );
  }

  Future<String> createOverlayClip({
    required String projectId,
    required String trackId,
    required int timelineStartMicros,
    int durationMicros = 4 * 1000 * 1000,
    NleOverlayTemplateId template = NleOverlayTemplateId.rectangle,
  }) async {
    final id = const Uuid().v4();
    final data = templates.create(template);

    final normalized = NleOverlayClipData(
      id: id,
      kind: data.kind,
      name: data.name,
      transform: data.transform,
      shapeStyle: data.shapeStyle,
      lineStyle: data.lineStyle,
      stickerStyle: data.stickerStyle,
      motion: data.motion,
      editable: data.editable,
      locked: data.locked,
      hidden: data.hidden,
      version: data.version,
    );

    await database.insertOverlayClip(
      id: id,
      projectId: projectId,
      trackId: trackId,
      name: normalized.name,
      timelineStartMicros: timelineStartMicros,
      durationMicros: durationMicros,
      overlayDataJson: jsonEncode(normalized.toJson()),
    );

    return id;
  }

  Future<void> applyTemplate({
    required String clipId,
    required NleOverlayTemplateId template,
  }) async {
    final data = templates.create(template);

    final normalized = NleOverlayClipData(
      id: clipId,
      kind: data.kind,
      name: data.name,
      transform: data.transform,
      shapeStyle: data.shapeStyle,
      lineStyle: data.lineStyle,
      stickerStyle: data.stickerStyle,
      motion: data.motion,
      editable: data.editable,
      locked: data.locked,
      hidden: data.hidden,
      version: data.version,
    );

    await saveOverlayData(
      clipId: clipId,
      data: normalized,
    );
  }
}
