import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/clip_inspector_repository.dart';
import 'package:nle_editor/domain/timeline/clip_inspector_models.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_refresh_bridge.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/clip_inspector_providers.dart';
import 'package:nle_editor/presentation/providers/clip_interactions_providers.dart';

void main() {
  late AppDatabase db;
  late ClipInspectorRepository repository;
  late ProviderContainer container;
  late List<String> refreshCalls;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = ClipInspectorRepository(database: db);
    refreshCalls = [];

    final mockRefreshBridge = TimelineEditRefreshBridge(
      invalidateTimeline: (projectId) {
        refreshCalls.add(projectId);
      },
    );

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clipInspectorRepositoryProvider.overrideWithValue(repository),
        timelineEditRefreshBridgeProvider.overrideWithValue(mockRefreshBridge),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Clip Inspector Tests', () {
    const projectId = 'test_project';
    const trackId = 'test_track';
    const clipId = 'test_clip';

    setUp(() async {
      // Setup minimal DB structure
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
          name: 'Video Track',
          type: 'video',
        ),
      );

      await db.insertClip(
        ClipsCompanion.insert(
          id: clipId,
          projectId: projectId,
          trackId: trackId,
          clipType: const Value('video'),
          timelineStartMicros: const Value(0),
          timelineEndMicros: const Value(5000000), // 5 seconds
        ),
      );
    });

    test('getClip retrieves and maps ClipInspectorState correctly', () async {
      final state = await repository.getClip(clipId);
      expect(state.clipId, equals(clipId));
      expect(state.clipType, equals('video'));
      expect(state.timelineStartMicros, equals(0));
      expect(state.timelineEndMicros, equals(5000000));
      expect(state.isVisual, isTrue);
      expect(state.isAudio, isTrue);
      expect(state.isText, isFalse);
      expect(state.readableDuration, equals('5.00s'));
      expect(state.fitMode, equals(ClipFitMode.fit));
    });

    test('updateTransform updates position, scale, rotation, opacity',
        () async {
      await repository.updateTransform(
        clipId: clipId,
        positionX: 0.5,
        positionY: -0.2,
        scale: 1.5,
        rotation: 45,
        opacity: 0.8,
      );

      final state = await repository.getClip(clipId);
      expect(state.positionX, equals(0.5));
      expect(state.positionY, equals(-0.2));
      expect(state.scale, equals(1.5));
      expect(state.rotation, equals(45));
      expect(state.opacity, equals(0.8));
    });

    test('updateFitAndCrop updates fitMode and crop parameters', () async {
      await repository.updateFitAndCrop(
        clipId: clipId,
        fitMode: ClipFitMode.fill,
        cropLeft: 0.1,
        cropTop: 0.15,
        cropRight: 0.2,
        cropBottom: 0.25,
      );

      final state = await repository.getClip(clipId);
      expect(state.fitMode, equals(ClipFitMode.fill));
      expect(state.cropLeft, equals(0.1));
      expect(state.cropTop, equals(0.15));
      expect(state.cropRight, equals(0.2));
      expect(state.cropBottom, equals(0.25));
    });

    test('updateSpeed clamps and updates speed', () async {
      // Over maximum speed (clamp to 8.0)
      await repository.updateSpeed(clipId: clipId, speed: 10.0);
      var state = await repository.getClip(clipId);
      expect(state.speed, equals(8.0));

      // Under minimum speed (clamp to 0.1)
      await repository.updateSpeed(clipId: clipId, speed: 0.05);
      state = await repository.getClip(clipId);
      expect(state.speed, equals(0.1));
    });

    test('updateAudio clamps and updates volume, fade', () async {
      await repository.updateAudio(
        clipId: clipId,
        volume: 1.5,
        fadeInMicros: 1000000,
        fadeOutMicros: 2000000,
      );

      final state = await repository.getClip(clipId);
      expect(state.volume, equals(1.5));
      expect(state.fadeInMicros, equals(1000000));
      expect(state.fadeOutMicros, equals(2000000));
    });

    test('updateColor updates brightness, contrast, saturation', () async {
      await repository.updateColor(
        clipId: clipId,
        brightness: 0.3,
        contrast: 1.2,
        saturation: 1.4,
      );

      final state = await repository.getClip(clipId);
      expect(state.brightness, equals(0.3));
      expect(state.contrast, equals(1.2));
      expect(state.saturation, equals(1.4));
    });

    test('updateText updates content, style, color', () async {
      await repository.updateText(
        clipId: clipId,
        textContent: 'Hello',
        textStyleJson: '{"size": 20}',
        colorHex: '#FF5E5E',
      );

      final state = await repository.getClip(clipId);
      expect(state.textContent, equals('Hello'));
      expect(state.textStyleJson, equals('{"size": 20}'));
      expect(state.colorHex, equals('#FF5E5E'));
    });

    test('resetVisualAdjustments restores defaults', () async {
      await repository.updateTransform(
          clipId: clipId, scale: 2.0, opacity: 0.5);
      await repository.updateColor(clipId: clipId, brightness: 0.5);
      await repository.updateFitAndCrop(
          clipId: clipId, fitMode: ClipFitMode.stretch);

      await repository.resetVisualAdjustments(clipId);

      final state = await repository.getClip(clipId);
      expect(state.scale, equals(1.0));
      expect(state.opacity, equals(1.0));
      expect(state.brightness, equals(0.0));
      expect(state.fitMode, equals(ClipFitMode.fit));
    });

    test('ClipInspectorController debounces refresh calls', () async {
      final controller =
          container.read(clipInspectorControllerProvider(projectId));

      // Execute multiple rapid updates
      await controller.updateTransform(clipId: clipId, scale: 1.1);
      await controller.updateTransform(clipId: clipId, scale: 1.2);
      await controller.updateTransform(clipId: clipId, scale: 1.3);

      expect(refreshCalls, isEmpty); // Debounced

      // Wait for debounce period (120ms + extra margin)
      await Future.delayed(const Duration(milliseconds: 200));

      expect(refreshCalls, equals([projectId]));
    });
  });
}
