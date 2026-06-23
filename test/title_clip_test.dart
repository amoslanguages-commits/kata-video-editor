import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/mappers/multitrack_db_mapper.dart';
import 'package:nle_editor/data/repositories/title_clip_repository.dart';
import 'package:nle_editor/domain/titles/title_clip_models.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';
import 'package:nle_editor/domain/titles/title_template_factory.dart';

void main() {
  group('Title Clip Models Tests', () {
    test('NleRgbaColor json serialization and copyWith', () {
      const color = NleRgbaColor(r: 0.5, g: 0.6, b: 0.7, a: 0.8);
      final json = color.toJson();

      expect(json['r'], equals(0.5));
      expect(json['g'], equals(0.6));
      expect(json['b'], equals(0.7));
      expect(json['a'], equals(0.8));

      final fromJson = NleRgbaColor.fromJson(json);
      expect(fromJson.r, equals(0.5));
      expect(fromJson.g, equals(0.6));
      expect(fromJson.b, equals(0.7));
      expect(fromJson.a, equals(0.8));

      final updated = color.copyWith(r: 0.9);
      expect(updated.r, equals(0.9));
      expect(updated.g, equals(0.6));

      expect(color.toArgbInt(), isA<int>());
    });

    test('NleRectNorm json serialization', () {
      const rect = NleRectNorm(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final json = rect.toJson();

      expect(json['x'], equals(0.1));
      expect(json['y'], equals(0.2));
      expect(json['width'], equals(0.3));
      expect(json['height'], equals(0.4));

      final fromJson = NleRectNorm.fromJson(json);
      expect(fromJson.x, equals(0.1));
      expect(fromJson.width, equals(0.3));
    });

    test('NleTitleClipData json serialization and template creation', () {
      final templates = const TitleTemplateFactory();
      final data = templates.create(NleTitleTemplateId.cinematicCenter);

      expect(data.templateId, equals(NleTitleTemplateId.cinematicCenter));
      expect(data.text, equals('CINEMATIC TITLE'));

      final json = data.toJson();
      final fromJson = NleTitleClipData.fromJson(json);

      expect(fromJson.id, equals(data.id));
      expect(fromJson.text, equals('CINEMATIC TITLE'));
      expect(fromJson.style.fontSize, equals(64.0));
      expect(fromJson.style.letterSpacing, equals(3.0));
    });
  });

  group('Title Clip DB Repository & Mapper Tests', () {
    late AppDatabase db;
    late TitleClipRepository repository;
    const mapper = MultitrackDbMapper();

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = TitleClipRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Create, retrieve, save, and apply templates', () async {
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
          name: 'Text Track',
          type: 'text',
        ),
      );

      // Create title clip
      final clipId = await repository.createTitleClip(
        projectId: projectId,
        trackId: trackId,
        timelineStartMicros: 1000000,
        durationMicros: 3000000,
        template: NleTitleTemplateId.breakingNews,
      );

      // Retrieve clip data
      final data = await repository.getTitleData(clipId);
      expect(data.templateId, equals(NleTitleTemplateId.breakingNews));
      expect(data.text, equals('BREAKING NEWS'));

      // Check if mapped clip has correct fields
      final rawClip = await db.getClip(clipId);
      expect(rawClip, isNotNull);
      expect(rawClip!.isTitleClip, isTrue);

      final multitrackClip = mapper.clipFromDb(rawClip);
      expect(multitrackClip.textContent, equals('BREAKING NEWS'));
      expect(multitrackClip.textStyleJson, isNotNull);

      // Parse mapped flat textStyleJson
      final flatStyle = jsonDecode(multitrackClip.textStyleJson!) as Map<String, dynamic>;
      expect(flatStyle['fontSize'], equals(38.0));
      expect(flatStyle['strokeWidth'], equals(0.0));
      expect(flatStyle['backgroundEnabled'], isTrue);

      // Update text
      final updatedData = data.copyWith(text: 'UPDATED BREAKING NEWS');
      await repository.saveTitleData(clipId: clipId, data: updatedData);

      final reloadedData = await repository.getTitleData(clipId);
      expect(reloadedData.text, equals('UPDATED BREAKING NEWS'));

      // Apply template
      await repository.applyTemplate(clipId: clipId, template: NleTitleTemplateId.socialHook);
      final templateAppliedData = await repository.getTitleData(clipId);
      expect(templateAppliedData.templateId, equals(NleTitleTemplateId.socialHook));
      expect(templateAppliedData.text, equals('WAIT FOR IT'));
    });
  });
}
