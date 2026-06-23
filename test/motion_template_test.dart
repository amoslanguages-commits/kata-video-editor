import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/motion_template_repository.dart';
import 'package:nle_editor/domain/motion_templates/builtin_motion_template_factory.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_layer_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';
import 'package:nle_editor/domain/motion_templates/template_parameter_applier.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

void main() {
  group('Motion Template Value Models Tests', () {
    test('NleTemplateParameterOption serialization', () {
      const option = NleTemplateParameterOption(value: 'val1', label: 'Label 1');
      final json = option.toJson();

      expect(json['value'], equals('val1'));
      expect(json['label'], equals('Label 1'));

      final fromJson = NleTemplateParameterOption.fromJson(json);
      expect(fromJson.value, equals('val1'));
      expect(fromJson.label, equals('Label 1'));
    });

    test('NleTemplateParameterValue serialization', () {
      const val = NleTemplateParameterValue(
        parameterId: 'p1',
        type: NleTemplateParameterType.text,
        value: 'hello',
      );
      final json = val.toJson();

      expect(json['parameterId'], equals('p1'));
      expect(json['value'], equals('hello'));

      final fromJson = NleTemplateParameterValue.fromJson(json);
      expect(fromJson.parameterId, equals('p1'));
      expect(fromJson.value, equals('hello'));
    });

    test('NleTemplateParameterDefinition serialization', () {
      const def = NleTemplateParameterDefinition(
        id: 'p2',
        label: 'Param 2',
        description: 'Test',
        type: NleTemplateParameterType.number,
        defaultValue: NleTemplateParameterValue(
          parameterId: 'p2',
          type: NleTemplateParameterType.number,
          value: 45.0,
        ),
        options: [],
        min: 10,
        max: 100,
        required: true,
      );

      final json = def.toJson();
      expect(json['id'], equals('p2'));
      expect(json['min'], equals(10.0));

      final fromJson = NleTemplateParameterDefinition.fromJson(json);
      expect(fromJson.id, equals('p2'));
      expect(fromJson.min, equals(10.0));
      expect(fromJson.defaultValue.value, equals(45.0));
    });
  });

  group('BuiltinMotionTemplateFactory Tests', () {
    test('Creates built-in packs correctly', () {
      const factory = BuiltinMotionTemplateFactory();
      final packs = factory.createBuiltInPacks();

      expect(packs.length, equals(3));

      final creatorPack = packs.firstWhere((p) => p.id == 'builtin_creator_essentials');
      expect(creatorPack.templates.length, equals(3));
      expect(creatorPack.templates.any((t) => t.id == 'bold_social_hook'), isTrue);
      expect(creatorPack.templates.any((t) => t.id == 'clean_lower_third'), isTrue);

      final socialPack = packs.firstWhere((p) => p.id == 'builtin_social_callouts');
      expect(socialPack.templates.length, equals(3));

      final cinematicPack = packs.firstWhere((p) => p.id == 'builtin_cinematic_titles');
      expect(cinematicPack.templates.length, equals(1));
    });
  });

  group('TemplateParameterApplier Tests', () {
    const applier = TemplateParameterApplier();

    test('Applies title parameter values correctly', () {
      const factory = BuiltinMotionTemplateFactory();
      final hookTemplate = factory.createBuiltInPacks()
          .expand((p) => p.templates)
          .firstWhere((t) => t.id == 'bold_social_hook');

      final layer = hookTemplate.layers.first;

      final values = [
        const NleTemplateParameterValue(
          parameterId: 'main_text',
          type: NleTemplateParameterType.text,
          value: 'NEW HOOK TEXT',
        ),
        const NleTemplateParameterValue(
          parameterId: 'accent_color',
          type: NleTemplateParameterType.color,
          value: NleRgbaColor(r: 0.1, g: 0.2, b: 0.3, a: 1.0),
        ),
      ];

      final applied = applier.applyValues(layer: layer, values: values);
      expect(applied.titleData, isNotNull);
      expect(applied.titleData!.text, equals('NEW HOOK TEXT'));
      expect(applied.titleData!.style.fillColor.r, equals(0.1));
    });
  });

  group('MotionTemplateRepository Integration Tests', () {
    late AppDatabase db;
    late MotionTemplateRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = MotionTemplateRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('DB initialization, favorites, usages, and apply template expansion', () async {
      const projectId = 'proj_1';
      const trackId = 'track_1';

      await db.insertProject(
        ProjectsCompanion.insert(
          id: projectId,
          name: 'Test Project',
          aspectRatio: const Value('16:9'),
        ),
      );

      await db.insertTrack(
        TracksCompanion.insert(
          id: trackId,
          projectId: projectId,
          name: 'Main Track',
          type: 'text',
        ),
      );

      // Check initially empty
      final initialPacks = await db.getMotionTemplatePacks();
      expect(initialPacks, isEmpty);

      // Initialize built-in packs
      await repository.initializeBuiltInPacks();
      final packs = await repository.getTemplatePacks();
      expect(packs.length, equals(3));

      // Favorite toggling
      await db.setTemplateFavorite(templateId: 'bold_social_hook', favorite: true);
      final usage = await db.getTemplateUsage('bold_social_hook');
      expect(usage, isNotNull);
      expect(usage!.favorite, isTrue);

      // Apply bold social hook template
      final template = await repository.getTemplateById('bold_social_hook');
      expect(template, isNotNull);

      final result = await repository.applyTemplate(
        NleTemplateApplyRequest(
          projectId: projectId,
          trackId: trackId,
          timelineStartMicros: 2000000,
          templateId: 'bold_social_hook',
          values: template!.defaultParameterValues,
        ),
      );

      expect(result.templateId, equals('bold_social_hook'));
      expect(result.createdClipIds.length, equals(1));

      // Verify the generated clip in database
      final clip = await db.getClip(result.createdClipIds.first);
      expect(clip, isNotNull);
      expect(clip!.templateGroupId, equals(result.groupId));
      expect(clip.sourceTemplateId, equals('bold_social_hook'));
      expect(clip.timelineStartMicros, equals(2000000));
      expect(clip.timelineEndMicros, equals(2000000 + 3500000));
    });
  });
}
