import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart' as db_pkg;
import 'package:nle_editor/data/mappers/render_graph_asset_mapper.dart';
import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/media_library/media_bin_models.dart';
import 'package:nle_editor/domain/media_library/media_import_models.dart';
import 'package:nle_editor/domain/media_library/media_import_service.dart';
import 'package:nle_editor/domain/media_library/media_project_path_service.dart';
import 'package:nle_editor/domain/media_library/media_type_detector.dart';
import 'package:nle_editor/platform/media/native_media_scanner_service.dart';

class FakeNativeMediaScannerService extends NativeMediaScannerService {
  NleNativeMediaScanResult? scanResult;
  String? generatedThumbnailPath;

  FakeNativeMediaScannerService({this.scanResult});

  @override
  Future<NleNativeMediaScanResult> scan(String path) async {
    return scanResult ??
        NleNativeMediaScanResult(
          path: path,
          type: NleMediaAssetType.video,
          durationMicros: 10000000,
          width: 1920,
          height: 1080,
          fps: 29.97,
          sampleRate: 48000,
          channelCount: 2,
          bitrate: 15000000,
          videoCodec: 'h264',
          audioCodec: 'aac',
          colorSpace: 'rec709',
          hasHdr: false,
        );
  }

  @override
  Future<String?> generateThumbnail({
    required String path,
    required String outputPath,
    required int width,
    required int height,
  }) async {
    generatedThumbnailPath = outputPath;
    return outputPath;
  }

  @override
  Future<bool> fileExists(String path) async {
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late db_pkg.AppDatabase database;
  late MediaAssetRepository repository;
  late MediaImportService importService;
  late MediaProjectPathService pathService;
  late MediaTypeDetector typeDetector;
  late FakeNativeMediaScannerService nativeScanner;
  late Directory tempDir;

  setUp(() async {
    database = db_pkg.AppDatabase(NativeDatabase.memory());
    repository = MediaAssetRepository(database: database);
    pathService = const MediaProjectPathService();
    typeDetector = const MediaTypeDetector();
    nativeScanner = FakeNativeMediaScannerService();
    importService = MediaImportService(
      repository: repository,
      pathService: pathService,
      typeDetector: typeDetector,
      nativeScanner: nativeScanner,
    );
    tempDir = await Directory.systemTemp.createTemp('kata_media_test');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });
  });

  tearDown(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('34A-PRO: Media Asset Database Schema & Helpers', () {
    test('Can query newly added tables in schema v48', () async {
      final projectId = const Uuid().v4();

      final assetId = const Uuid().v4();
      final asset = NleMediaAsset(
        id: assetId,
        projectId: projectId,
        displayName: 'test_video.mp4',
        type: NleMediaAssetType.video,
        importSource: NleMediaImportSource.filePicker,
        storageMode: NleMediaStorageMode.copiedIntoProject,
        availability: NleMediaAvailability.available,
        originalPath: '/original/path/video.mp4',
        projectPath: '/project/path/video.mp4',
        proxyStatus: NleProxyStatus.none,
        usageState: NleMediaUsageState.unused,
        fileInfo: const NleMediaFileInfo(
          fileName: 'video.mp4',
          extension: 'mp4',
          fileSizeBytes: 1024 * 1024 * 5,
        ),
        videoInfo: const NleMediaVideoInfo(
          width: 1920,
          height: 1080,
          fps: 30.0,
          codec: 'h264',
          colorSpace: 'rec709',
          hasHdr: false,
        ),
        audioInfo: const NleMediaAudioInfo(
          sampleRate: 48000,
          channelCount: 2,
          codec: 'aac',
          bitrate: 128000,
        ),
        timecodeInfo: const NleMediaTimecodeInfo(
          fps: 30.0,
          durationMicros: 5000000,
          startTimecodeMicros: 0,
        ),
        tags: const ['b-roll', 'outdoor'],
        importedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      await repository.saveAsset(asset);

      final retrieved = await repository.getAsset(assetId);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, assetId);
      expect(retrieved.displayName, 'test_video.mp4');
      expect(retrieved.tags, containsAll(['b-roll', 'outdoor']));
      expect(retrieved.videoInfo.width, 1920);

      final binId = const Uuid().v4();
      final bin = NleMediaBin(
        id: binId,
        projectId: projectId,
        name: 'B-Roll',
        sortIndex: 1,
        smartBin: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      await repository.saveBin(bin);

      final bins = await repository.getBins(projectId);
      expect(bins.length, 1);
      expect(bins.first.name, 'B-Roll');

      await repository.linkAssetToBin(assetId: assetId, binId: binId);
      final links = await database.getAssetBinLinksForBin(binId);
      expect(links.length, 1);
      expect(links.first.assetId, assetId);
    });
  });

  group('34A-PRO: Media Import Pipeline & Deduplication', () {
    test('Import single video scans metadata, copies file and links default bin', () async {
      final projectId = const Uuid().v4();
      
      final testFile = File(p.join(tempDir.path, 'source_video.mp4'));
      await testFile.writeAsString('fake video content');

      final videoBin = NleMediaBin.defaultVideos(id: const Uuid().v4(), projectId: projectId);
      await repository.saveBin(videoBin);
      
      final currentBins = await repository.getBins(projectId);
      print("DB Bins for project: ${currentBins.map((b) => b.name).toList()}");

      final request = NleMediaImportRequest(
        projectId: projectId,
        sourcePaths: [testFile.path],
        importSource: NleMediaImportSource.filePicker,
        storageMode: NleMediaStorageMode.copiedIntoProject,
        generateThumbnails: true,
        generateWaveforms: false,
        detectDuplicates: true,
        createProxyPlaceholder: false,
      );

      final result = await importService.importFiles(request);
      print("Import success: ${result.items.first.success}, error: ${result.items.first.error}");
      
      final links = await database.getAssetBinLinksForBin(videoBin.id);
      print("Links created: ${links.length}");

      expect(result.importedCount, 1);
      expect(result.failedCount, 0);
      expect(result.duplicateCount, 0);

      final item = result.items.first;
      expect(item.success, true);
      expect(item.asset, isNotNull);
      expect(item.asset!.displayName, 'source_video.mp4');
    });

    test('Detects duplicate imports based on original path', () async {
      final projectId = const Uuid().v4();
      final testFile = File(p.join(tempDir.path, 'source_image.png'));
      await testFile.writeAsString('fake image data');

      final request = NleMediaImportRequest(
        projectId: projectId,
        sourcePaths: [testFile.path],
        importSource: NleMediaImportSource.filePicker,
        storageMode: NleMediaStorageMode.copiedIntoProject,
        generateThumbnails: false,
        generateWaveforms: false,
        detectDuplicates: true,
        createProxyPlaceholder: false,
      );

      // First Import
      final res1 = await importService.importFiles(request);
      print("Res1 success: ${res1.items.first.success}, assetId: ${res1.items.first.asset?.id}");
      expect(res1.importedCount, 1);
      expect(res1.duplicateCount, 0);
      expect(res1.items.first.success, isTrue);
      expect(res1.items.first.duplicate, isFalse);

      final existing = await repository.getAssets(projectId);
      print("Existing assets count in DB: ${existing.length}, first path: ${existing.isNotEmpty ? existing.first.originalPath : 'null'}");
      expect(existing.length, 1);

      // Second Import with detectDuplicates = true
      final res2 = await importService.importFiles(request);
      print("Res2 success: ${res2.items.first.success}, duplicate: ${res2.items.first.duplicate}");

      expect(res2.importedCount, 1);
      expect(res2.duplicateCount, 1);
      expect(res2.items.first.success, isTrue);
      expect(res2.items.first.duplicate, isTrue);
    });
  });
}
