import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/text_preset_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/text/text_style_model.dart';
import 'package:nle_editor/domain/text/text_style_presets.dart';
import 'package:nle_editor/native_bridge/native_command_service.dart';

class TextStyleCommandService {
  final TimelineRepository timelineRepository;
  final TextPresetRepository textPresetRepository;
  final NativeCommandService nativeCommandService;

  static const _uuid = Uuid();

  TextStyleCommandService({
    required this.timelineRepository,
    required this.textPresetRepository,
    required this.nativeCommandService,
  });

  Future<String> addTextClip({
    required String projectId,
    required String trackId,
    required int timelineStartMicros,
    required int durationMicros,
    String text = 'Your Text',
    NleTextStyle? style,
  }) async {
    final clipId = _uuid.v4();

    final safeStyle = style ?? NleTextStyle.defaults();

    await timelineRepository.insertClip(
      ClipsCompanion.insert(
        id: clipId,
        projectId: projectId,
        trackId: trackId,
        clipType: const Value('text'),
        timelineStartMicros: Value(timelineStartMicros),
        timelineEndMicros: Value(timelineStartMicros + durationMicros),
        sourceInMicros: const Value(0),
        sourceOutMicros: Value(durationMicros),
        textContent: Value(text),
        textStyle: Value(safeStyle.toJsonString()),
        sortOrder: const Value(1000),
      ),
    );

    await nativeCommandService.sendClipChanged(
      projectId: projectId,
      clipId: clipId,
      action: 'add_text_clip',
    );

    return clipId;
  }

  Future<void> updateTextContent({
    required String projectId,
    required String clipId,
    required String content,
  }) async {
    await timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        textContent: Value(content),
      ),
    );

    await nativeCommandService.sendClipChanged(
      projectId: projectId,
      clipId: clipId,
      action: 'update_text_content',
    );
  }

  Future<void> updateTextStyle({
    required String projectId,
    required String clipId,
    required NleTextStyle style,
  }) async {
    await timelineRepository.updateClipFields(
      clipId,
      ClipsCompanion(
        textStyle: Value(style.toJsonString()),
      ),
    );

    await nativeCommandService.sendClipChanged(
      projectId: projectId,
      clipId: clipId,
      action: 'update_text_style',
    );
  }

  Future<void> applyBuiltInPreset({
    required String projectId,
    required String clipId,
    required String presetId,
  }) async {
    final preset = BuiltInTextStylePresets.byId(presetId);

    await updateTextStyle(
      projectId: projectId,
      clipId: clipId,
      style: preset.style,
    );
  }

  Future<void> applyLocalPreset({
    required String projectId,
    required String clipId,
    required String presetId,
  }) async {
    final preset = await textPresetRepository.getLocalTextPreset(presetId);

    if (preset == null) {
      throw StateError('Text preset not found.');
    }

    await updateTextStyle(
      projectId: projectId,
      clipId: clipId,
      style: NleTextStyle.fromJsonString(preset.styleJson),
    );
  }

  Future<String> saveCurrentStyleAsPreset({
    required String name,
    required String category,
    required Clip clip,
  }) async {
    final presetId = _uuid.v4();
    final style = NleTextStyle.fromJsonString(clip.textStyle);

    await textPresetRepository.insertLocalTextPreset(
      LocalTextPresetsCompanion.insert(
        id: presetId,
        name: name,
        category: Value(category),
        styleJson: Value(style.toJsonString()),
        isBuiltIn: const Value(false),
        isPremium: const Value(false),
      ),
    );

    return presetId;
  }

  Future<void> toggleFavoritePreset({
    required String presetId,
    required bool favorite,
  }) async {
    await textPresetRepository.updateLocalTextPresetFields(
      presetId,
      LocalTextPresetsCompanion(
        isFavorite: Value(favorite),
      ),
    );
  }

  Future<void> deleteLocalPreset(String presetId) async {
    await textPresetRepository.deleteLocalTextPreset(presetId);
  }
}
