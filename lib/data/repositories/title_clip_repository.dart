import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/titles/title_clip_models.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';
import 'package:nle_editor/domain/titles/title_template_factory.dart';

class TitleClipRepository {
  final db.AppDatabase database;
  final TitleTemplateFactory templates;

  const TitleClipRepository({
    required this.database,
    this.templates = const TitleTemplateFactory(),
  });

  Future<NleTitleClipData> getTitleData(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      return NleTitleClipData.defaultTitle(id: clipId);
    }
    final raw = clip.titleDataJson;

    if (raw == null || raw.trim().isEmpty) {
      return NleTitleClipData.defaultTitle(id: clipId);
    }

    try {
      return NleTitleClipData.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return NleTitleClipData.defaultTitle(id: clipId);
    }
  }

  Future<void> saveTitleData({
    required String clipId,
    required NleTitleClipData data,
  }) {
    return database.updateClipTitleDataJson(
      clipId: clipId,
      titleDataJson: jsonEncode(data.toJson()),
    );
  }

  Future<String> createTitleClip({
    required String projectId,
    required String trackId,
    required int timelineStartMicros,
    int durationMicros = 4 * 1000 * 1000,
    NleTitleTemplateId template = NleTitleTemplateId.basicTitle,
  }) async {
    final id = const Uuid().v4();
    final data = templates.create(template).copyWith();

    final normalizedData = NleTitleClipData(
      id: id,
      kind: data.kind,
      text: data.text,
      secondaryText: data.secondaryText,
      style: data.style,
      secondaryStyle: data.secondaryStyle,
      layout: data.layout,
      motion: data.motion,
      templateId: data.templateId,
      editable: data.editable,
      version: data.version,
    );

    await database.insertTitleClip(
      id: id,
      projectId: projectId,
      trackId: trackId,
      name: _clipName(template),
      timelineStartMicros: timelineStartMicros,
      durationMicros: durationMicros,
      titleDataJson: jsonEncode(normalizedData.toJson()),
    );

    return id;
  }

  Future<void> applyTemplate({
    required String clipId,
    required NleTitleTemplateId template,
  }) async {
    final next = templates.create(template);

    final normalized = NleTitleClipData(
      id: clipId,
      kind: next.kind,
      text: next.text,
      secondaryText: next.secondaryText,
      style: next.style,
      secondaryStyle: next.secondaryStyle,
      layout: next.layout,
      motion: next.motion,
      templateId: next.templateId,
      editable: next.editable,
      version: next.version,
    );

    await saveTitleData(
      clipId: clipId,
      data: normalized,
    );
  }

  String _clipName(NleTitleTemplateId template) {
    switch (template) {
      case NleTitleTemplateId.basicTitle:
        return 'Title';
      case NleTitleTemplateId.cinematicCenter:
        return 'Cinematic Title';
      case NleTitleTemplateId.lowerThirdClean:
        return 'Lower Third';
      case NleTitleTemplateId.lowerThirdBold:
        return 'Bold Lower Third';
      case NleTitleTemplateId.socialHook:
        return 'Social Hook';
      case NleTitleTemplateId.subtitleCard:
        return 'Subtitle Card';
      case NleTitleTemplateId.nameTag:
        return 'Name Tag';
      case NleTitleTemplateId.breakingNews:
        return 'Breaking News';
    }
  }
}
