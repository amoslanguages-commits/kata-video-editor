import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/mappers/multitrack_db_mapper.dart';
import 'package:nle_editor/data/repositories/overlay_clip_repository.dart';
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/overlays/overlay_motion_models.dart';
import 'package:nle_editor/domain/overlays/overlay_style_models.dart';
import 'package:nle_editor/domain/overlays/overlay_value_models.dart';
import 'package:nle_editor/domain/overlays/overlay_template_factory.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/titles/title_value_models.dart';

void main() {
  group('Overlay Clip Value Models Tests', () {
    test('NleOverlayShadowStyle json serialization and copyWith', () {
      const shadow = NleOverlayShadowStyle(
        enabled: true,
        color: NleRgbaColor(r: 0.1, g: 0.2, b: 0.3, a: 0.4),
        blur: 10.0,
        offsetX: 5.0,
        offsetY: 6.0,
      );

      final json = shadow.toJson();
      expect(json['enabled'], isTrue);
      expect(json['blur'], equals(10.0));
      expect(json['offsetX'], equals(5.0));

      final fromJson = NleOverlayShadowStyle.fromJson(json);
      expect(fromJson.enabled, isTrue);
      expect(fromJson.color.r, equals(0.1));
      expect(fromJson.blur, equals(10.0));

      final copied = shadow.copyWith(blur: 15.0);
      expect(copied.blur, equals(15.0));
      expect(copied.offsetX, equals(5.0));
    });

    test('NleOverlayStrokeStyle json serialization and copyWith', () {
      const stroke = NleOverlayStrokeStyle(
        enabled: true,
        color: NleRgbaColor(r: 0.5, g: 0.5, b: 0.5, a: 1.0),
        width: 4.0,
        cap: NleLineCap.square,
        join: NleLineJoin.bevel,
      );

      final json = stroke.toJson();
      expect(json['enabled'], isTrue);
      expect(json['width'], equals(4.0));
      expect(json['cap'], equals('square'));

      final fromJson = NleOverlayStrokeStyle.fromJson(json);
      expect(fromJson.width, equals(4.0));
      expect(fromJson.cap, equals(NleLineCap.square));

      final copied = stroke.copyWith(width: 8.0);
      expect(copied.width, equals(8.0));
    });

    test('NleOverlayTransform json serialization and copyWith', () {
      const box = NleRectNorm(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const transform = NleOverlayTransform(
        box: box,
        anchor: NleOverlayAnchor.bottomRight,
        rotationDegrees: 45.0,
        scale: 1.5,
        opacity: 0.9,
        respectSafeArea: false,
      );

      final json = transform.toJson();
      expect(json['rotationDegrees'], equals(45.0));
      expect(json['scale'], equals(1.5));
      expect(json['respectSafeArea'], isFalse);

      final fromJson = NleOverlayTransform.fromJson(json);
      expect(fromJson.scale, equals(1.5));
      expect(fromJson.anchor, equals(NleOverlayAnchor.bottomRight));
      expect(fromJson.respectSafeArea, isFalse);

      final copied = transform.copyWith(scale: 2.0);
      expect(copied.scale, equals(2.0));
    });
  });

  group('Overlay Clip Style Models Tests', () {
    test('NleShapeStyle json serialization and copyWith', () {
      const style = NleShapeStyle(
        shapeType: NleShapeType.ellipse,
        fillEnabled: true,
        fillColor: NleRgbaColor(r: 0.2, g: 0.3, b: 0.4, a: 0.5),
        stroke: NleOverlayStrokeStyle.none(),
        shadow: NleOverlayShadowStyle.none(),
        cornerRadius: 15.0,
        blendMode: NleOverlayBlendMode.multiply,
      );

      final json = style.toJson();
      expect(json['shapeType'], equals('ellipse'));
      expect(json['cornerRadius'], equals(15.0));
      expect(json['blendMode'], equals('multiply'));

      final fromJson = NleShapeStyle.fromJson(json);
      expect(fromJson.shapeType, equals(NleShapeType.ellipse));
      expect(fromJson.cornerRadius, equals(15.0));

      final copied = style.copyWith(cornerRadius: 20.0);
      expect(copied.cornerRadius, equals(20.0));
    });

    test('NleLineStyle json serialization and copyWith', () {
      const style = NleLineStyle(
        color: NleRgbaColor.white(),
        width: 5.0,
        cap: NleLineCap.round,
        dashed: true,
        dashLength: 10.0,
        gapLength: 5.0,
        arrowStart: true,
        arrowEnd: false,
        arrowSize: 15.0,
        shadow: NleOverlayShadowStyle.none(),
      );

      final json = style.toJson();
      expect(json['dashed'], isTrue);
      expect(json['arrowStart'], isTrue);

      final fromJson = NleLineStyle.fromJson(json);
      expect(fromJson.dashed, isTrue);
      expect(fromJson.width, equals(5.0));

      final copied = style.copyWith(arrowEnd: true);
      expect(copied.arrowEnd, isTrue);
    });

    test('NleStickerStyle json serialization and copyWith', () {
      const style = NleStickerStyle(
        assetId: 'stick_1',
        localPath: 'assets/stick.png',
        opacity: 0.8,
        blendMode: NleOverlayBlendMode.screen,
        shadow: NleOverlayShadowStyle.none(),
        preserveAspectRatio: true,
      );

      final json = style.toJson();
      expect(json['assetId'], equals('stick_1'));
      expect(json['preserveAspectRatio'], isTrue);

      final fromJson = NleStickerStyle.fromJson(json);
      expect(fromJson.assetId, equals('stick_1'));
      expect(fromJson.blendMode, equals(NleOverlayBlendMode.screen));

      final copied = style.copyWith(opacity: 1.0);
      expect(copied.opacity, equals(1.0));
    });
  });

  group('Overlay Clip Motion Models Tests', () {
    test('NleOverlayKeyframe and NleOverlayMotion serialization', () {
      const keyframe = NleOverlayKeyframe(
        id: 'kf_1',
        timeOffsetMicros: 1000,
        property: NleOverlayMotionProperty.scale,
        value: 1.5,
        easing: NleOverlayEasing.easeIn,
      );

      final jsonKf = keyframe.toJson();
      expect(jsonKf['id'], equals('kf_1'));
      expect(jsonKf['property'], equals('scale'));

      final fromJsonKf = NleOverlayKeyframe.fromJson(jsonKf);
      expect(fromJsonKf.id, equals('kf_1'));
      expect(fromJsonKf.property, equals(NleOverlayMotionProperty.scale));

      const motion = NleOverlayMotion(
        preset: NleOverlayAnimationPreset.pulse,
        keyframes: [keyframe],
      );

      final jsonMotion = motion.toJson();
      expect(jsonMotion['preset'], equals('pulse'));
      expect((jsonMotion['keyframes'] as List).length, equals(1));

      final fromJsonMotion = NleOverlayMotion.fromJson(jsonMotion);
      expect(fromJsonMotion.preset, equals(NleOverlayAnimationPreset.pulse));
      expect(fromJsonMotion.keyframes.first.id, equals('kf_1'));
    });
  });

  group('OverlayTemplateFactory Tests', () {
    test('Creates templates correctly', () {
      const factory = OverlayTemplateFactory();

      final rect = factory.create(NleOverlayTemplateId.rectangle);
      expect(rect.kind, equals(NleOverlayClipKind.shape));
      expect(rect.shapeStyle!.shapeType, equals(NleShapeType.roundedRectangle));

      final circle = factory.create(NleOverlayTemplateId.circle);
      expect(circle.kind, equals(NleOverlayClipKind.shape));
      expect(circle.shapeStyle!.shapeType, equals(NleShapeType.circle));

      final line = factory.create(NleOverlayTemplateId.line);
      expect(line.kind, equals(NleOverlayClipKind.line));
      expect(line.lineStyle, isNotNull);

      final arrow = factory.create(NleOverlayTemplateId.arrow);
      expect(arrow.kind, equals(NleOverlayClipKind.arrow));
      expect(arrow.motion.preset, equals(NleOverlayAnimationPreset.drawLine));

      final callout = factory.create(NleOverlayTemplateId.calloutBox);
      expect(callout.kind, equals(NleOverlayClipKind.callout));

      final sticker = factory.create(NleOverlayTemplateId.sticker);
      expect(sticker.kind, equals(NleOverlayClipKind.sticker));
    });
  });

  group('Overlay Clip DB Repository & Mapper Tests', () {
    late AppDatabase db;
    late OverlayClipRepository repository;
    const mapper = MultitrackDbMapper();

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = OverlayClipRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Create, retrieve, save, and apply templates to overlay clips', () async {
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
          name: 'Overlay Track',
          type: 'overlay',
        ),
      );

      // Create overlay clip
      final clipId = await repository.createOverlayClip(
        projectId: projectId,
        trackId: trackId,
        timelineStartMicros: 1000000,
        durationMicros: 3000000,
        template: NleOverlayTemplateId.rectangle,
      );

      // Retrieve clip data
      final data = await repository.getOverlayData(clipId);
      expect(data.kind, equals(NleOverlayClipKind.shape));
      expect(data.name, equals('Rounded Rectangle'));

      // Check if mapped clip has correct fields
      final rawClip = await db.getClip(clipId);
      expect(rawClip, isNotNull);
      expect(rawClip!.isOverlayClip, isTrue);

      final multitrackClip = mapper.clipFromDb(rawClip);
      expect(multitrackClip.textContent, equals('Rounded Rectangle'));
      expect(multitrackClip.type, equals(MultitrackClipType.image));

      // Update transform
      final updatedTransform = data.transform.copyWith(scale: 2.5);
      final updatedData = data.copyWith(transform: updatedTransform);
      await repository.saveOverlayData(clipId: clipId, data: updatedData);

      final reloadedData = await repository.getOverlayData(clipId);
      expect(reloadedData.transform.scale, equals(2.5));

      // Apply template
      await repository.applyTemplate(clipId: clipId, template: NleOverlayTemplateId.circle);
      final templateAppliedData = await repository.getOverlayData(clipId);
      expect(templateAppliedData.shapeStyle!.shapeType, equals(NleShapeType.circle));
      expect(templateAppliedData.name, equals('Circle'));
    });
  });
}
