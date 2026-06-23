import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/track_controls_repository.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/track_controls_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_track_header.dart';

import 'package:nle_editor/native_bridge/fake_native_bridge.dart';

void main() {
  late AppDatabase db;
  late TrackControlsRepository repository;
  late FakeNativeBridge nativeBridge;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TrackControlsRepository(database: db);
    nativeBridge = FakeNativeBridge();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trackControlsRepositoryProvider.overrideWithValue(repository),
        nativeBridgeProvider.overrideWithValue(nativeBridge),
      ],
    );

    await nativeBridge.initialize();
  });

  tearDown(() async {
    container.dispose();
    await nativeBridge.dispose();
    await db.close();
  });

  group('Track Controls Tests', () {
    const projectId = 'test_project';
    const trackId = 'test_track_1';

    setUp(() async {
      // Insert a dummy project and track first
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
          name: 'Original Name',
          type: 'video',
          index: const Value(1),
          height: const Value(64),
        ),
      );
    });

    test('getTrack retrieves the track correctly', () async {
      final track = await repository.getTrack(trackId);
      expect(track.id, equals(trackId));
      expect(track.name, equals('Original Name'));
      expect(track.type, equals('video'));
    });

    test('toggleMute updates state', () async {
      final before = await repository.getTrack(trackId);
      expect(before.isMuted, isFalse);

      await repository.toggleMute(trackId);

      final after = await repository.getTrack(trackId);
      expect(after.isMuted, isTrue);

      await repository.toggleMute(trackId);
      final after2 = await repository.getTrack(trackId);
      expect(after2.isMuted, isFalse);
    });

    test('toggleSolo updates state', () async {
      final before = await repository.getTrack(trackId);
      expect(before.isSolo, isFalse);

      await repository.toggleSolo(trackId);

      final after = await repository.getTrack(trackId);
      expect(after.isSolo, isTrue);
    });

    test('toggleLock updates state', () async {
      final before = await repository.getTrack(trackId);
      expect(before.isLocked, isFalse);

      await repository.toggleLock(trackId);

      final after = await repository.getTrack(trackId);
      expect(after.isLocked, isTrue);
    });

    test('toggleHide updates state', () async {
      final before = await repository.getTrack(trackId);
      expect(before.isHidden, isFalse);

      await repository.toggleHide(trackId);

      final after = await repository.getTrack(trackId);
      expect(after.isHidden, isTrue);
    });

    test('renameTrack validates and updates name', () async {
      await repository.renameTrack(trackId: trackId, name: 'New Track Name');
      var track = await repository.getTrack(trackId);
      expect(track.name, equals('New Track Name'));

      expect(
        () => repository.renameTrack(trackId: trackId, name: '   '),
        throwsArgumentError,
      );
    });

    test('resizeTrackBy modifies height within boundaries', () async {
      // Height defaults to 64
      await repository.resizeTrackBy(trackId: trackId, delta: 10);
      var track = await repository.getTrack(trackId);
      expect(track.height, equals(74));

      // Test clamp max (120)
      await repository.resizeTrackBy(trackId: trackId, delta: 100);
      track = await repository.getTrack(trackId);
      expect(track.height, equals(120));

      // Test clamp min (36)
      await repository.resizeTrackBy(trackId: trackId, delta: -200);
      track = await repository.getTrack(trackId);
      expect(track.height, equals(36));
    });

    test('resetTrackHeight sets default height based on type', () async {
      // 1. Video track type (defaults to 64)
      await repository.setTrackHeight(trackId: trackId, height: 100);
      await repository.resetTrackHeight(trackId);
      var track = await repository.getTrack(trackId);
      expect(track.height, equals(64));

      // 2. Audio track type (defaults to 54)
      const audioTrackId = 'audio_track';
      await db.insertTrack(
        TracksCompanion.insert(
          id: audioTrackId,
          projectId: projectId,
          name: 'Audio Track',
          type: 'audio',
          index: const Value(2),
          height: const Value(80),
        ),
      );
      await repository.resetTrackHeight(audioTrackId);
      track = await repository.getTrack(audioTrackId);
      expect(track.height, equals(54));
    });

    test('TrackControlsController performAction dispatches correctly',
        () async {
      final controller =
          container.read(trackControlsControllerProvider(projectId));

      // Mute
      await controller.performAction(
          trackId: trackId, action: TrackControlAction.mute);
      var track = await repository.getTrack(trackId);
      expect(track.isMuted, isTrue);

      // Solo
      await controller.performAction(
          trackId: trackId, action: TrackControlAction.solo);
      track = await repository.getTrack(trackId);
      expect(track.isSolo, isTrue);

      // Lock
      await controller.performAction(
          trackId: trackId, action: TrackControlAction.lock);
      track = await repository.getTrack(trackId);
      expect(track.isLocked, isTrue);

      // Hide
      await controller.performAction(
          trackId: trackId, action: TrackControlAction.hide);
      track = await repository.getTrack(trackId);
      expect(track.isHidden, isTrue);

      // Height Increase (taller by 12)
      await repository.setTrackHeight(trackId: trackId, height: 60);
      await controller.performAction(
          trackId: trackId, action: TrackControlAction.heightUp);
      track = await repository.getTrack(trackId);
      expect(track.height, equals(72));

      // Height Decrease (shorter by 12)
      await controller.performAction(
          trackId: trackId, action: TrackControlAction.heightDown);
      track = await repository.getTrack(trackId);
      expect(track.height, equals(60));

      // Height Reset
      await controller.performAction(
          trackId: trackId, action: TrackControlAction.resetHeight);
      track = await repository.getTrack(trackId);
      expect(track.height, equals(64));

      // Rename from controller
      await controller.renameTrack(
          trackId: trackId, name: 'Renamed from Controller');
      track = await repository.getTrack(trackId);
      expect(track.name, equals('Renamed from Controller'));
    });
  });
}
