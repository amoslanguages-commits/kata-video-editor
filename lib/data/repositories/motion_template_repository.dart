import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/motion_templates/builtin_motion_template_factory.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';
import 'package:nle_editor/domain/motion_templates/template_parameter_applier.dart';

class MotionTemplateRepository {
  final db.AppDatabase database;
  final BuiltinMotionTemplateFactory builtinFactory;
  final TemplateParameterApplier parameterApplier;

  const MotionTemplateRepository({
    required this.database,
    this.builtinFactory = const BuiltinMotionTemplateFactory(),
    this.parameterApplier = const TemplateParameterApplier(),
  });

  Future<void> initializeBuiltInPacks() async {
    final existing = await database.getMotionTemplatePacks();
    if (existing.isEmpty) {
      final packs = builtinFactory.createBuiltInPacks();
      for (final pack in packs) {
        await database.upsertMotionTemplatePack(
          db.MotionTemplatePacksCompanion.insert(
            id: pack.id,
            name: pack.name,
            description: pack.description,
            source: pack.source.name,
            access: pack.access.name,
            packJson: jsonEncode(pack.toJson()),
            installedAt: pack.installedAt,
            updatedAt: pack.installedAt,
            version: Value(pack.version),
          ),
        );
      }
    }
  }

  Future<List<NleMotionTemplatePack>> getTemplatePacks() async {
    await initializeBuiltInPacks();
    final rows = await database.getMotionTemplatePacks();
    final list = <NleMotionTemplatePack>[];
    for (final row in rows) {
      try {
        list.add(NleMotionTemplatePack.fromJson(
          Map<String, dynamic>.from(jsonDecode(row.packJson) as Map),
        ));
      } catch (_) {}
    }
    return list;
  }

  Future<NleMotionTemplate?> getTemplateById(String templateId) async {
    final packs = await getTemplatePacks();
    for (final pack in packs) {
      for (final t in pack.templates) {
        if (t.id == templateId) {
          return t;
        }
      }
    }
    return null;
  }

  Future<NleTemplateApplyResult> applyTemplate(NleTemplateApplyRequest request) async {
    final template = await getTemplateById(request.templateId);
    if (template == null) {
      throw StateError('Template not found: ${request.templateId}');
    }

    final groupId = const Uuid().v4();
    final createdClipIds = <String>[];

    for (final layer in template.layers) {
      final resolved = parameterApplier.applyValues(
        layer: layer,
        values: request.values,
      );

      final clipId = const Uuid().v4();

      if (resolved.kind == NleMotionTemplateLayerKind.title && resolved.titleData != null) {
        await database.insertTitleClip(
          id: clipId,
          projectId: request.projectId,
          trackId: request.trackId,
          name: resolved.name,
          timelineStartMicros: request.timelineStartMicros + resolved.relativeStartMicros,
          durationMicros: resolved.durationMicros,
          titleDataJson: jsonEncode(resolved.titleData!.toJson()),
        );
      } else if ((resolved.kind == NleMotionTemplateLayerKind.overlay ||
                  resolved.kind == NleMotionTemplateLayerKind.sticker) &&
                 resolved.overlayData != null) {
        await database.insertOverlayClip(
          id: clipId,
          projectId: request.projectId,
          trackId: request.trackId,
          name: resolved.name,
          timelineStartMicros: request.timelineStartMicros + resolved.relativeStartMicros,
          durationMicros: resolved.durationMicros,
          overlayDataJson: jsonEncode(resolved.overlayData!.toJson()),
        );
      } else {
        continue;
      }

      await (database.update(database.clips)..where((tbl) => tbl.id.equals(clipId))).write(
        db.ClipsCompanion(
          templateGroupId: Value(groupId),
          sourceTemplateId: Value(template.id),
        ),
      );

      createdClipIds.add(clipId);
    }

    await database.markTemplateUsed(request.templateId);

    return NleTemplateApplyResult(
      templateId: template.id,
      groupId: groupId,
      createdClipIds: createdClipIds,
    );
  }
}
