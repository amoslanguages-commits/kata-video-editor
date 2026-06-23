import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/clip_interactions_repository.dart';
import 'package:nle_editor/domain/timeline/clip_interaction_models.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/clip_interactions_providers.dart';
import 'package:nle_editor/presentation/providers/timeline_snap_providers.dart';

import 'package:nle_editor/native_bridge/fake_native_bridge.dart';

void main() {
  late AppDatabase db;
  late ClipInteractionsRepository repository;
  late FakeNativeBridge nativeBridge;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = ClipInteractionsRepository(database: db);
    nativeBridge = FakeNativeBridge();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clipInteractionsRepositoryProvider.overrideWithValue(repository),
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

  group('Clip Interactions Tests', () {
    const projectId = 'test_project';
    const videoTrackId = 'video_track';
    const audioTrackId = 'audio_track';
    const clipId = 'test_clip';
    const assetId = 'test_asset';

    setUp(() async {
      // Setup Project
      await db.insertProject(
        ProjectsCompanion.insert(
          id: projectId,
          name: 'Test Project',
          aspectRatio: const Value('16:9'),
        ),
      );

      // Setup Video and Audio Tracks
      await db.insertTrack(
        TracksCompanion.insert(
          id: videoTrackId,
          projectId: projectId,
          name: 'Video Track',
          type: 'video',
          index: const Value(1),
        ),
      );

      await db.insertTrack(
        TracksCompanion.insert(
          id: audioTrackId,
          projectId: projectId,
          name: 'Audio Track',
          type: 'audio',
          index: const Value(2),
        ),
      );

      // Setup asset metadata for duration checking (e.g. 10 seconds duration)
      await db.insertAsset(
        AssetsCompanion.insert(
          id: assetId,
          projectId: projectId,
          originalPath: 'path/to/media.mp4',
          fileName: 'media.mp4',
          fileType: 'video',
          durationMicros: const Value(10000000), // 10s
        ),
      );

      // Insert test Video Clip (starts at 1s, ends at 4s, sources 0s to 3s)
      await db.insertClip(
        ClipsCompanion.insert(
          id: clipId,
          projectId: projectId,
          trackId: videoTrackId,
          assetId: const Value(assetId),
          clipType: const Value('video'),
          timelineStartMicros: const Value(1000000),
          timelineEndMicros: const Value(4000000),
          sourceInMicros: const Value(0),
          sourceOutMicros: const Value(3000000),
          speed: const Value(1.0),
          modifiedAt: Value(DateTime.now()),
        ),
      );
    });

    test('getClip retrieves clip details correctly', () async {
      final clip = await repository.getClip(clipId);
      expect(clip.id, equals(clipId));
      expect(clip.timelineStartMicros, equals(1000000));
      expect(clip.timelineEndMicros, equals(4000000));
    });

    test('moveClipBy shifts clip timing horizontally', () async {
      // Shift forward by 1.5 seconds (1500000 micros)
      await repository.moveClipBy(clipId: clipId, deltaMicros: 1500000);
      var clip = await repository.getClip(clipId);
      expect(clip.timelineStartMicros, equals(2500000));
      expect(clip.timelineEndMicros, equals(5500000));

      // Shift backward beyond 0; should clamp to 0
      await repository.moveClipBy(clipId: clipId, deltaMicros: -5000000);
      clip = await repository.getClip(clipId);
      expect(clip.timelineStartMicros, equals(0));
      expect(clip.timelineEndMicros, equals(3000000));
    });

    test('moveClipTo moves clip to target track and shifts time', () async {
      // Move to a new start at 2s (still on video track)
      await repository.moveClipTo(
        clipId: clipId,
        targetTrackId: videoTrackId,
        newStartMicros: 2000000,
      );
      var clip = await repository.getClip(clipId);
      expect(clip.trackId, equals(videoTrackId));
      expect(clip.timelineStartMicros, equals(2000000));
      expect(clip.timelineEndMicros, equals(5000000));
    });

    test('moveClipTo rejects type-incompatible tracks', () async {
      // Try to move video clip to audio track
      expect(
        () => repository.moveClipTo(
          clipId: clipId,
          targetTrackId: audioTrackId,
          newStartMicros: 2000000,
        ),
        throwsA(isA<ClipInteractionException>()),
      );
    });

    test('trimLeftBy shifts start point and clamps on outer boundary',
        () async {
      // Trim left side inwards by 0.5s (pushes start and source forward)
      await repository.trimLeftBy(clipId: clipId, deltaMicros: 500000);
      var clip = await repository.getClip(clipId);
      expect(clip.timelineStartMicros, equals(1500000));
      expect(clip.timelineEndMicros, equals(4000000));
      expect(clip.sourceInMicros, equals(500000));

      // Try trimming left past minimum clip duration limits (should clamp to maxStart)
      await repository.trimLeftBy(clipId: clipId, deltaMicros: 5000000);
      clip = await repository.getClip(clipId);
      expect(clip.timelineStartMicros, equals(3900000));
      expect(clip.timelineEndMicros, equals(4000000));
      expect(clip.sourceInMicros, equals(2900000));
    });

    test('trimRightBy shifts end point and clamps on outer boundary', () async {
      // Trim right side outwards by 1s (pushes end and source out)
      await repository.trimRightBy(clipId: clipId, deltaMicros: 1000000);
      var clip = await repository.getClip(clipId);
      expect(clip.timelineStartMicros, equals(1000000));
      expect(clip.timelineEndMicros, equals(5000000));
      expect(clip.sourceOutMicros, equals(4000000));

      // Try trimming right beyond asset duration (clamps to sourceMax duration of 10s)
      await repository.trimRightBy(clipId: clipId, deltaMicros: 15000000);
      clip = await repository.getClip(clipId);
      expect(clip.timelineEndMicros,
          equals(11000000)); // timelineStart (1s) + 10s asset duration
      expect(clip.sourceOutMicros, equals(10000000)); // 10s max source
    });

    test('splitClipAt splits a clip into two distinct clips', () async {
      // Split at playhead = 2.5s (2500000 micros)
      final newClipId = await repository.splitClipAt(
        clipId: clipId,
        splitMicros: 2500000,
      );

      final leftClip = await repository.getClip(clipId);
      final rightClip = await repository.getClip(newClipId);

      // Left clip timing validation
      expect(leftClip.timelineStartMicros, equals(1000000));
      expect(leftClip.timelineEndMicros, equals(2500000));
      expect(leftClip.sourceInMicros, equals(0));
      expect(leftClip.sourceOutMicros, equals(1500000));

      // Right clip timing validation
      expect(rightClip.timelineStartMicros, equals(2500000));
      expect(rightClip.timelineEndMicros, equals(4000000));
      expect(rightClip.sourceInMicros, equals(1500000));
      expect(rightClip.sourceOutMicros, equals(3000000));
    });

    test('deleteClip removes clip from database', () async {
      await repository.deleteClip(clipId);
      expect(
        () => repository.getClip(clipId),
        throwsA(isA<ClipInteractionException>()),
      );
    });

    test('duplicateClip duplicates clip downstream', () async {
      final newClipId = await repository.duplicateClip(clipId);
      final orig = await repository.getClip(clipId);
      final dupe = await repository.getClip(newClipId);

      expect(dupe.id, isNot(equals(orig.id)));
      expect(dupe.timelineStartMicros,
          equals(orig.timelineEndMicros + 500000)); // offset by 0.5s
      expect(dupe.sourceInMicros, equals(orig.sourceInMicros));
      expect(dupe.sourceOutMicros, equals(orig.sourceOutMicros));
    });

    test('locked tracks block all modifications', () async {
      // Lock the track
      await db.setTrackLocked(trackId: videoTrackId, locked: true);

      // 1. Move clip should fail
      expect(
        () => repository.moveClipBy(clipId: clipId, deltaMicros: 1000000),
        throwsA(isA<ClipInteractionException>()),
      );

      // 2. Trim left should fail
      expect(
        () => repository.trimLeftBy(clipId: clipId, deltaMicros: 100000),
        throwsA(isA<ClipInteractionException>()),
      );

      // 3. Trim right should fail
      expect(
        () => repository.trimRightBy(clipId: clipId, deltaMicros: 100000),
        throwsA(isA<ClipInteractionException>()),
      );

      // 4. Split should fail
      expect(
        () => repository.splitClipAt(clipId: clipId, splitMicros: 2500000),
        throwsA(isA<ClipInteractionException>()),
      );

      // 5. Delete should fail
      expect(
        () => repository.deleteClip(clipId),
        throwsA(isA<ClipInteractionException>()),
      );

      // 6. Duplicate should fail
      expect(
        () => repository.duplicateClip(clipId),
        throwsA(isA<ClipInteractionException>()),
      );
    });

    test('ClipInteractionsController performs and invalidates correctly',
        () async {
      final controller =
          container.read(clipInteractionsControllerProvider(projectId));

      // Test controller movement triggers
      final result =
          await controller.moveClipBy(clipId: clipId, deltaMicros: 500000);
      expect(result.action, equals('move'));

      final clip = await repository.getClip(clipId);
      expect(clip.timelineStartMicros, equals(1500000));
    });

    test('ClipInteractionsController deleteClip in magnetic mode closes gaps',
        () async {
      final controller =
          container.read(clipInteractionsControllerProvider(projectId));

      // Enable snap/magnetic settings
      container.read(timelineSnapSettingsProvider.notifier).setEnabled(true);

      // Insert another clip that starts at 5s, ends at 8s
      const secondClipId = 'second_clip';
      await db.insertClip(
        ClipsCompanion.insert(
          id: secondClipId,
          projectId: projectId,
          trackId: videoTrackId,
          assetId: const Value(assetId),
          clipType: const Value('video'),
          timelineStartMicros: const Value(5000000),
          timelineEndMicros: const Value(8000000),
          sourceInMicros: const Value(0),
          sourceOutMicros: const Value(3000000),
          speed: const Value(1.0),
          modifiedAt: Value(DateTime.now()),
        ),
      );

      // Verify second clip start initially is 5s
      var second = await repository.getClip(secondClipId);
      expect(second.timelineStartMicros, equals(5000000));

      // Delete the first clip (clipId = starts at 1s, ends at 4s, duration = 3s)
      await controller.deleteClip(clipId: clipId);

      // Verify the first clip is deleted
      expect(
        () => repository.getClip(clipId),
        throwsA(isA<ClipInteractionException>()),
      );

      // Verify the second clip was shifted left by the first clip's duration (3s)
      // New timelineStart = 5s - 3s = 2s
      // New timelineEnd = 8s - 3s = 5s
      second = await repository.getClip(secondClipId);
      expect(second.timelineStartMicros, equals(2000000));
      expect(second.timelineEndMicros, equals(5000000));
    });

    test(
        'ClipInteractionsController deleteClip in non-magnetic mode does not close gaps',
        () async {
      final controller =
          container.read(clipInteractionsControllerProvider(projectId));

      // Disable snap/magnetic settings
      container.read(timelineSnapSettingsProvider.notifier).setEnabled(false);

      // Insert another clip that starts at 5s, ends at 8s
      const secondClipId = 'second_clip_non_mag';
      await db.insertClip(
        ClipsCompanion.insert(
          id: secondClipId,
          projectId: projectId,
          trackId: videoTrackId,
          assetId: const Value(assetId),
          clipType: const Value('video'),
          timelineStartMicros: const Value(5000000),
          timelineEndMicros: const Value(8000000),
          sourceInMicros: const Value(0),
          sourceOutMicros: const Value(3000000),
          speed: const Value(1.0),
          modifiedAt: Value(DateTime.now()),
        ),
      );

      // Delete the first clip (clipId = starts at 1s, ends at 4s, duration = 3s)
      await controller.deleteClip(clipId: clipId);

      // Verify the first clip is deleted
      expect(
        () => repository.getClip(clipId),
        throwsA(isA<ClipInteractionException>()),
      );

      // Verify the second clip was NOT shifted
      final second = await repository.getClip(secondClipId);
      expect(second.timelineStartMicros, equals(5000000));
    });
  });
}
