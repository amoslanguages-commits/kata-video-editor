import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/domain/services/waveform_service.dart';
import 'package:nle_editor/domain/services/thumbnail_service.dart';
import 'package:nle_editor/domain/services/background_media_generation_queue.dart';

// Fake implementations to mock external platform dependencies in tests
class FakeThumbnailService extends ThumbnailService {
  @override
  Future<String?> generateThumbnail({
    required String sourcePath,
    required String outputDirectory,
    required String assetId,
    required String fileType,
    int timeMs = 0,
  }) async {
    return p.join(outputDirectory, timeMs == 0 ? '$assetId.jpg' : '${assetId}_$timeMs.jpg');
  }
}

class FakeWaveformService extends WaveformService {
  @override
  Future<String?> generateWaveform({
    required String sourcePath,
    required String outputDirectory,
    required String assetId,
    int samples = 160,
  }) async {
    final outputPath = p.join(outputDirectory, '$assetId.waveform.json');
    final dummyData = List.generate(samples, (i) => i / samples);
    final file = File(outputPath);
    await file.writeAsString(jsonEncode(dummyData));
    return outputPath;
  }
}

void main() {
  late AppDatabase db;
  late AssetRepository assetRepository;
  late FakeThumbnailService thumbnailService;
  late FakeWaveformService waveformService;
  late BackgroundMediaGenerationQueue queue;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    assetRepository = AssetRepository(db);
    thumbnailService = FakeThumbnailService();
    waveformService = FakeWaveformService();
    queue = BackgroundMediaGenerationQueue(
      thumbnailService,
      waveformService,
      assetRepository,
    );
    tempDir = await Directory.systemTemp.createTemp('nle_timeline_media_engine_test');
  });

  tearDown(() async {
    queue.cancelAll();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WaveformService tests', () {
    test('readWaveform returns empty list if file does not exist', () async {
      final service = WaveformService();
      final data = await service.readWaveform(p.join(tempDir.path, 'non_existent.json'));
      expect(data, isEmpty);
    });

    test('readWaveform parses valid json doubles list', () async {
      final service = WaveformService();
      final path = p.join(tempDir.path, 'waveform.json');
      final dummyData = [0.1, 0.25, 0.9, 0.0];
      await File(path).writeAsString(jsonEncode(dummyData));

      final data = await service.readWaveform(path);
      expect(data, equals(dummyData));
    });
  });

  group('BackgroundMediaGenerationQueue tests', () {
    const projectId = 'proj_1';
    const assetId = 'asset_1';

    setUp(() async {
      // Setup minimal project and asset in database
      await db.insertProject(
        ProjectsCompanion.insert(
          id: projectId,
          name: 'Test Project',
        ),
      );

      await db.insertAsset(
        AssetsCompanion.insert(
          id: assetId,
          projectId: projectId,
          originalPath: 'fake_video.mp4',
          fileName: 'fake_video.mp4',
          fileType: 'video',
          thumbnailStatus: const Value('pending'),
          waveformStatus: const Value('pending'),
        ),
      );
    });

    test('queueWaveform executes successfully and updates DB', () async {
      queue.queueWaveform(
        assetId: assetId,
        sourcePath: 'fake_video.mp4',
        outputDirectory: tempDir.path,
      );

      // Wait a short time for async tasks to execute
      await Future.delayed(const Duration(milliseconds: 50));

      final asset = await assetRepository.getAsset(assetId);
      expect(asset, isNotNull);
      expect(asset!.waveformStatus, equals('ready'));
      expect(asset.waveformPath, isNotNull);
      expect(File(asset.waveformPath!).existsSync(), isTrue);
    });

    test('queueThumbnailStrip executes successfully and updates DB', () async {
      queue.queueThumbnailStrip(
        assetId: assetId,
        sourcePath: 'fake_video.mp4',
        outputDirectory: tempDir.path,
        durationMicros: 5000000, // 5 seconds
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final asset = await assetRepository.getAsset(assetId);
      expect(asset, isNotNull);
      expect(asset!.thumbnailStatus, equals('ready'));
      expect(asset.thumbnailPath, isNotNull);
    });
  });
}
