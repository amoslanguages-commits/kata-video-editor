import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/keyframe_repository.dart';
import 'package:nle_editor/domain/keyframes/default_keyframe_property_factory.dart';
import 'package:nle_editor/domain/keyframes/keyframe_clipboard_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_editing_tools.dart';
import 'package:nle_editor/domain/keyframes/keyframe_interpolation_engine.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_preset_factory.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

void main() {
  group('Keyframe Value Models Tests', () {
    test('NleKeyframeColorValue serialization', () {
      const color = NleKeyframeColorValue(r: 0.1, g: 0.2, b: 0.3, a: 0.4);
      final json = color.toJson();

      expect(json['r'], equals(0.1));
      expect(json['a'], equals(0.4));

      final fromJson = NleKeyframeColorValue.fromJson(json);
      expect(fromJson.r, equals(0.1));
      expect(fromJson.a, equals(0.4));
    });

    test('NleKeyframeVec2Value serialization', () {
      const vec = NleKeyframeVec2Value(x: 10.0, y: 20.0);
      final json = vec.toJson();

      expect(json['x'], equals(10.0));
      expect(json['y'], equals(20.0));

      final fromJson = NleKeyframeVec2Value.fromJson(json);
      expect(fromJson.x, equals(10.0));
      expect(fromJson.y, equals(20.0));
    });

    test('NleKeyframeValue serialization', () {
      const numberVal = NleKeyframeValue.number(5.5);
      final numJson = numberVal.toJson();
      expect(numJson['type'], equals('number'));
      expect(numJson['value'], equals(5.5));

      final fromNumJson = NleKeyframeValue.fromJson(numJson);
      expect(fromNumJson.numberOrZero, equals(5.5));

      const booleanVal = NleKeyframeValue.boolean(true);
      final boolJson = booleanVal.toJson();
      expect(boolJson['value'], isTrue);

      final fromBoolJson = NleKeyframeValue.fromJson(boolJson);
      expect(fromBoolJson.boolOrFalse, isTrue);

      const vecVal = NleKeyframeValue.vec2(NleKeyframeVec2Value(x: 1, y: 2));
      final vecJson = vecVal.toJson();
      expect(vecJson['value']['x'], equals(1.0));

      final fromVecJson = NleKeyframeValue.fromJson(vecJson);
      expect(fromVecJson.vec2OrZero.x, equals(1.0));
    });
  });

  group('Keyframe Models Tests', () {
    test('NleBezierHandle serialization', () {
      const handle = NleBezierHandle(x: 0.25, y: 0.75);
      final json = handle.toJson();
      expect(json['x'], equals(0.25));

      final fromJson = NleBezierHandle.fromJson(json);
      expect(fromJson.x, equals(0.25));
    });

    test('NleKeyframe serialization', () {
      const keyframe = NleKeyframe(
        id: 'kf1',
        timeOffsetMicros: 1000,
        value: NleKeyframeValue.number(42.0),
        interpolation: NleKeyframeInterpolation.linear,
        inHandle: NleBezierHandle(x: 0.1, y: 0.2),
        outHandle: NleBezierHandle(x: 0.3, y: 0.4),
        selected: true,
        locked: false,
      );

      final json = keyframe.toJson();
      expect(json['id'], equals('kf1'));
      expect(json['timeOffsetMicros'], equals(1000));
      expect(json['selected'], isTrue);

      final fromJson = NleKeyframe.fromJson(json);
      expect(fromJson.id, equals('kf1'));
      expect(fromJson.timeOffsetMicros, equals(1000));
      expect(fromJson.selected, isTrue);
      expect(fromJson.value.numberOrZero, equals(42.0));
    });
  });

  group('KeyframeInterpolationEngine Tests', () {
    const engine = KeyframeInterpolationEngine();

    test('Returns default value if no keyframes', () {
      const prop = NleAnimatableProperty(
        id: 'p1',
        ownerId: 'o1',
        ownerType: NleKeyframeOwnerType.title,
        propertyPath: 'x',
        label: 'X',
        group: NleKeyframePropertyGroup.transform,
        valueType: NleKeyframeValueType.number,
        defaultValue: NleKeyframeValue.number(100.0),
        enabled: true,
        keyframes: [],
      );

      expect(engine.sampleProperty(property: prop, localTimeMicros: 500).numberOrZero, equals(100.0));
    });

    test('Returns first or last value if out of bounds', () {
      const prop = NleAnimatableProperty(
        id: 'p1',
        ownerId: 'o1',
        ownerType: NleKeyframeOwnerType.title,
        propertyPath: 'x',
        label: 'X',
        group: NleKeyframePropertyGroup.transform,
        valueType: NleKeyframeValueType.number,
        defaultValue: NleKeyframeValue.number(100.0),
        enabled: true,
        keyframes: [
          NleKeyframe(
            id: 'k1',
            timeOffsetMicros: 1000,
            value: NleKeyframeValue.number(10.0),
            interpolation: NleKeyframeInterpolation.linear,
            inHandle: NleBezierHandle.easeIn(),
            outHandle: NleBezierHandle.easeOut(),
            selected: false,
            locked: false,
          ),
          NleKeyframe(
            id: 'k2',
            timeOffsetMicros: 2000,
            value: NleKeyframeValue.number(20.0),
            interpolation: NleKeyframeInterpolation.linear,
            inHandle: NleBezierHandle.easeIn(),
            outHandle: NleBezierHandle.easeOut(),
            selected: false,
            locked: false,
          ),
        ],
      );

      expect(engine.sampleProperty(property: prop, localTimeMicros: 500).numberOrZero, equals(10.0));
      expect(engine.sampleProperty(property: prop, localTimeMicros: 2500).numberOrZero, equals(20.0));
    });

    test('Interpolates Hold, Linear, EaseInOut correctly', () {
      final prop = NleAnimatableProperty(
        id: 'p1',
        ownerId: 'o1',
        ownerType: NleKeyframeOwnerType.title,
        propertyPath: 'x',
        label: 'X',
        group: NleKeyframePropertyGroup.transform,
        valueType: NleKeyframeValueType.number,
        defaultValue: NleKeyframeValue.number(100.0),
        enabled: true,
        keyframes: [
          const NleKeyframe(
            id: 'k1',
            timeOffsetMicros: 0,
            value: NleKeyframeValue.number(10.0),
            interpolation: NleKeyframeInterpolation.linear,
            inHandle: NleBezierHandle.easeIn(),
            outHandle: NleBezierHandle.easeOut(),
            selected: false,
            locked: false,
          ),
          const NleKeyframe(
            id: 'k2',
            timeOffsetMicros: 1000,
            value: NleKeyframeValue.number(20.0),
            interpolation: NleKeyframeInterpolation.linear,
            inHandle: NleBezierHandle.easeIn(),
            outHandle: NleBezierHandle.easeOut(),
            selected: false,
            locked: false,
          ),
        ],
      );

      // Linear mid-point (0.5 progress) -> 15.0
      expect(engine.sampleProperty(property: prop, localTimeMicros: 500).numberOrZero, equals(15.0));

      // Test Hold interpolation
      final holdProp = prop.copyWith(
        keyframes: [
          prop.keyframes[0].copyWith(interpolation: NleKeyframeInterpolation.hold),
          prop.keyframes[1],
        ],
      );
      expect(engine.sampleProperty(property: holdProp, localTimeMicros: 500).numberOrZero, equals(10.0));
    });
  });

  group('KeyframeEditingTools Tests', () {
    const tools = KeyframeEditingTools();
    const initialProp = NleAnimatableProperty(
      id: 'p1',
      ownerId: 'o1',
      ownerType: NleKeyframeOwnerType.title,
      propertyPath: 'x',
      label: 'X',
      group: NleKeyframePropertyGroup.transform,
      valueType: NleKeyframeValueType.number,
      defaultValue: NleKeyframeValue.number(100.0),
      enabled: true,
      keyframes: [],
    );

    test('Add, update, move, remove keyframe', () {
      var prop = tools.addKeyframe(
        property: initialProp,
        timeOffsetMicros: 500,
        value: const NleKeyframeValue.number(50.0),
      );

      expect(prop.keyframes.length, equals(1));
      expect(prop.keyframes.first.timeOffsetMicros, equals(500));
      expect(prop.keyframes.first.value.numberOrZero, equals(50.0));

      final kfId = prop.keyframes.first.id;

      prop = tools.updateKeyframeValue(
        property: prop,
        keyframeId: kfId,
        value: const NleKeyframeValue.number(75.0),
      );
      expect(prop.keyframes.first.value.numberOrZero, equals(75.0));

      prop = tools.moveKeyframe(
        property: prop,
        keyframeId: kfId,
        timeOffsetMicros: 800,
        clipDurationMicros: 1000,
      );
      expect(prop.keyframes.first.timeOffsetMicros, equals(800));

      prop = tools.removeKeyframe(property: prop, keyframeId: kfId);
      expect(prop.keyframes, isEmpty);
    });
  });

  group('KeyframePresetFactory Tests', () {
    const factory = KeyframePresetFactory();
    const prop = NleAnimatableProperty(
      id: 'p1',
      ownerId: 'o1',
      ownerType: NleKeyframeOwnerType.title,
      propertyPath: 'opacity',
      label: 'Opacity',
      group: NleKeyframePropertyGroup.visual,
      valueType: NleKeyframeValueType.number,
      defaultValue: NleKeyframeValue.number(1.0),
      enabled: true,
      keyframes: [],
    );

    test('Builds fadeIn preset', () {
      final keyframes = factory.buildPreset(
        preset: NleKeyframePresetId.fadeIn,
        property: prop,
        durationMicros: 2000,
      );

      expect(keyframes.length, equals(2));
      expect(keyframes.first.timeOffsetMicros, equals(0));
      expect(keyframes.first.value.numberOrZero, equals(0.0));
      expect(keyframes.last.timeOffsetMicros, equals(2000));
      expect(keyframes.last.value.numberOrZero, equals(1.0));
    });
  });

  group('KeyframeClipboard Tests', () {
    final clipboard = KeyframeClipboard();

    test('Copy and paste keyframes', () {
      final kfs = [
        const NleKeyframe(
          id: 'k1',
          timeOffsetMicros: 200,
          value: NleKeyframeValue.number(10.0),
          interpolation: NleKeyframeInterpolation.linear,
          inHandle: NleBezierHandle.easeIn(),
          outHandle: NleBezierHandle.easeOut(),
          selected: true,
          locked: false,
        ),
        const NleKeyframe(
          id: 'k2',
          timeOffsetMicros: 600,
          value: NleKeyframeValue.number(20.0),
          interpolation: NleKeyframeInterpolation.linear,
          inHandle: NleBezierHandle.easeIn(),
          outHandle: NleBezierHandle.easeOut(),
          selected: true,
          locked: false,
        ),
      ];

      clipboard.copy(
        sourcePropertyPath: 'p1',
        selectedKeyframes: kfs,
        playheadMicros: 200,
      );

      expect(clipboard.payload, isNotNull);
      expect(clipboard.payload!.keyframes.length, equals(2));

      final pasted = clipboard.pasteAt(targetMicros: 1000);
      expect(pasted.length, equals(2));
      expect(pasted[0].timeOffsetMicros, equals(1000));
      expect(pasted[1].timeOffsetMicros, equals(1400));
    });
  });

  group('KeyframeRepository Integration Tests', () {
    late AppDatabase db;
    late KeyframeRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = KeyframeRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('CRUD operations and default seeding', () async {
      const clipId = 'clip_1';

      await db.insertProject(
        ProjectsCompanion.insert(
          id: 'proj_1',
          name: 'Test Project',
          aspectRatio: const Value('16:9'),
        ),
      );

      await db.insertTrack(
        TracksCompanion.insert(
          id: 'track_1',
          projectId: 'proj_1',
          name: 'Main Track',
          type: 'text',
        ),
      );

      await db.insertTitleClip(
        id: clipId,
        projectId: 'proj_1',
        trackId: 'track_1',
        name: 'My Title',
        timelineStartMicros: 1000,
        durationMicros: 4000,
        titleDataJson: '{}',
      );

      // Verify no track exists initially
      final initialRaw = await db.getClipKeyframeTrackJson(clipId);
      expect(initialRaw, isNull);

      // Fetch tracks (should seed defaults)
      final seededTrack = await repository.getTrackForClip(
        clipId: clipId,
        clipType: 'title',
        clipDurationMicros: 4000,
      );

      expect(seededTrack.properties.length, equals(5)); // Title properties (Position X/Y, Scale, Rotation, Opacity)
      expect(seededTrack.properties.first.ownerType, equals(NleKeyframeOwnerType.title));

      // Modify and save
      final updatedProperties = List<NleAnimatableProperty>.from(seededTrack.properties);
      updatedProperties[0] = seededTrack.properties[0].copyWith(
        keyframes: [
          const NleKeyframe(
            id: 'k1',
            timeOffsetMicros: 100,
            value: NleKeyframeValue.number(0.5),
            interpolation: NleKeyframeInterpolation.linear,
            inHandle: NleBezierHandle.easeIn(),
            outHandle: NleBezierHandle.easeOut(),
            selected: false,
            locked: false,
          ),
        ],
      );

      final trackToSave = seededTrack.copyWith(properties: updatedProperties);
      await repository.saveTrack(trackToSave);

      // Fetch again to verify persistence
      final loadedTrack = await repository.getTrackForClip(
        clipId: clipId,
        clipType: 'title',
        clipDurationMicros: 4000,
      );

      expect(loadedTrack.properties[0].keyframes.length, equals(1));
      expect(loadedTrack.properties[0].keyframes.first.value.numberOrZero, equals(0.5));
    });
  });
}
