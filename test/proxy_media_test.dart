import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_recommendation_service.dart';
import 'package:nle_editor/domain/proxy/proxy_resolution_service.dart';
import 'package:nle_editor/domain/proxy/proxy_settings_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

void main() {
  group('NleProxyVideoSpec Tests', () {
    test('preset specifications resolve correct properties', () {
      final spec360 = NleProxyVideoSpec.fromPreset(NleProxyResolutionPreset.p360);
      expect(spec360.maxHeight, equals(360));
      expect(spec360.maxWidth, equals(640));
      expect(spec360.bitrate, equals(850000));
      expect(spec360.codec, equals(NleProxyCodec.h264));

      final spec720 = NleProxyVideoSpec.fromPreset(NleProxyResolutionPreset.p720);
      expect(spec720.maxHeight, equals(720));
      expect(spec720.maxWidth, equals(1280));
      expect(spec720.bitrate, equals(2500000));
    });
  });

  group('Database Schema v49 Migration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('verifies version and columns queryable after migration', () async {
      expect(db.schemaVersion, equals(49));

      // Test Project proxySettingsJson column addition
      final project = ProjectsCompanion(
        id: const Value('proj_test'),
        name: const Value('Test Project'),
        proxySettingsJson: const Value('{"enabled":false}'),
      );
      await db.insertProject(project);

      final fetchedProj = await db.getProjectById('proj_test');
      expect(fetchedProj.proxySettingsJson, equals('{"enabled":false}'));

      // Test MediaAssets columns additions
      await db.upsertMediaAsset(
        MediaAssetsCompanion.insert(
          id: 'asset_test',
          projectId: 'proj_test',
          displayName: 'Test Media',
          type: 'video',
          importSource: 'filePicker',
          storageMode: 'copiedIntoProject',
          availability: 'available',
          proxyStatus: 'none',
          usageState: 'unused',
          fileInfoJson: '{}',
          videoInfoJson: '{}',
          audioInfoJson: '{}',
          timecodeInfoJson: '{}',
          tagsJson: '[]',
          importedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          proxyMetadataJson: const Value('{"width":1920}'),
          proxyError: const Value('transcode error'),
          proxyCreatedAt: Value(DateTime.now()),
        ),
      );

      final asset = await db.getMediaAssetById('asset_test');
      expect(asset, isNotNull);
      expect(asset!.proxyStatus, equals('none'));

      // Test ProxyJobs table creation
      final now = DateTime.now();
      await db.upsertProxyJob(
        ProxyJobsCompanion.insert(
          id: 'job_test',
          projectId: 'proj_test',
          assetId: 'asset_test',
          sourcePath: 'original.mp4',
          outputPath: 'proxy.mp4',
          status: const Value('queued'),
          reason: const Value('manual'),
          priority: const Value('normal'),
          specJson: '{}',
          progress: const Value(0.5),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final jobs = await db.getProxyJobsForProject('proj_test');
      expect(jobs.length, equals(1));
      expect(jobs.first.id, equals('job_test'));
      expect(jobs.first.progress, equals(0.5));
    });
  });

  group('ProxyRecommendationService Tests', () {
    const service = ProxyRecommendationService();
    const settings = NleProjectProxySettings.defaults();

    test('should recommend for 4K video assets', () {
      final heavyAsset = NleMediaAsset(
        id: 'asset_4k',
        projectId: 'proj_123',
        displayName: '4K Clip',
        type: NleMediaAssetType.video,
        importSource: NleMediaImportSource.filePicker,
        storageMode: NleMediaStorageMode.referencedExternal,
        availability: NleMediaAvailability.available,
        proxyStatus: NleProxyStatus.none,
        usageState: NleMediaUsageState.unused,
        fileInfo: const NleMediaFileInfo(fileSizeBytes: 1024, fileName: '4k.mp4', extension: 'mp4'),
        videoInfo: const NleMediaVideoInfo(width: 3840, height: 2160, fps: 29.97, codec: 'h264', hasHdr: false, colorSpace: 'rec709'),
        audioInfo: const NleMediaAudioInfo(codec: 'aac', sampleRate: 48000, channelCount: 2, bitrate: 128000),
        timecodeInfo: const NleMediaTimecodeInfo(durationMicros: 5000000, fps: 29.97, startTimecodeMicros: 0),
        tags: [],
        importedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      expect(service.shouldGenerateProxy(asset: heavyAsset, settings: settings), isTrue);
      expect(service.reasonLabel(asset: heavyAsset, settings: settings), equals('4K media'));
    });

    test('should recommend for HDR video assets', () {
      final hdrAsset = NleMediaAsset(
        id: 'asset_hdr',
        projectId: 'proj_123',
        displayName: 'HDR Clip',
        type: NleMediaAssetType.video,
        importSource: NleMediaImportSource.filePicker,
        storageMode: NleMediaStorageMode.referencedExternal,
        availability: NleMediaAvailability.available,
        proxyStatus: NleProxyStatus.none,
        usageState: NleMediaUsageState.unused,
        fileInfo: const NleMediaFileInfo(fileSizeBytes: 1024, fileName: 'hdr.mp4', extension: 'mp4'),
        videoInfo: const NleMediaVideoInfo(width: 1920, height: 1080, fps: 29.97, codec: 'hevc', hasHdr: true, colorSpace: 'rec2020'),
        audioInfo: const NleMediaAudioInfo(codec: 'aac', sampleRate: 48000, channelCount: 2, bitrate: 128000),
        timecodeInfo: const NleMediaTimecodeInfo(durationMicros: 5000000, fps: 29.97, startTimecodeMicros: 0),
        tags: [],
        importedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      expect(service.shouldGenerateProxy(asset: hdrAsset, settings: settings), isTrue);
      expect(service.reasonLabel(asset: hdrAsset, settings: settings), equals('HDR media'));
    });

    test('should not recommend for 1080p SDR short video assets', () {
      final lightAsset = NleMediaAsset(
        id: 'asset_light',
        projectId: 'proj_123',
        displayName: 'Light Clip',
        type: NleMediaAssetType.video,
        importSource: NleMediaImportSource.filePicker,
        storageMode: NleMediaStorageMode.referencedExternal,
        availability: NleMediaAvailability.available,
        proxyStatus: NleProxyStatus.none,
        usageState: NleMediaUsageState.unused,
        fileInfo: const NleMediaFileInfo(fileSizeBytes: 1024, fileName: 'light.mp4', extension: 'mp4'),
        videoInfo: const NleMediaVideoInfo(width: 1920, height: 1080, fps: 24.0, codec: 'h264', hasHdr: false, colorSpace: 'rec709'),
        audioInfo: const NleMediaAudioInfo(codec: 'aac', sampleRate: 48000, channelCount: 2, bitrate: 128000),
        timecodeInfo: const NleMediaTimecodeInfo(durationMicros: 5000000, fps: 24.0, startTimecodeMicros: 0),
        tags: [],
        importedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      expect(service.shouldGenerateProxy(asset: lightAsset, settings: settings), isFalse);
    });
  });

  group('ProxyResolutionService Tests', () {
    const service = ProxyResolutionService();
    final settings = const NleProjectProxySettings.defaults().copyWith(enabled: true);

    final readyProxyAsset = NleMediaAsset(
      id: 'asset_ready',
      projectId: 'proj_123',
      displayName: 'Ready Asset',
      type: NleMediaAssetType.video,
      importSource: NleMediaImportSource.filePicker,
      storageMode: NleMediaStorageMode.referencedExternal,
      availability: NleMediaAvailability.available,
      originalPath: 'path/original.mp4',
      projectPath: 'project/original.mp4',
      proxyPath: 'proxy/optim.mp4',
      proxyStatus: NleProxyStatus.ready,
      usageState: NleMediaUsageState.unused,
      fileInfo: const NleMediaFileInfo(fileSizeBytes: 1024, fileName: 'original.mp4', extension: 'mp4'),
      videoInfo: const NleMediaVideoInfo(width: 3840, height: 2160, fps: 29.97, codec: 'h264', hasHdr: false, colorSpace: 'rec709'),
      audioInfo: const NleMediaAudioInfo(codec: 'aac', sampleRate: 48000, channelCount: 2, bitrate: 128000),
      timecodeInfo: const NleMediaTimecodeInfo(durationMicros: 5000000, fps: 29.97, startTimecodeMicros: 0),
      tags: [],
      importedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
    );

    test('resolveForPreview returns proxyPath if enabled and ready', () {
      final resolved = service.resolveForPreview(asset: readyProxyAsset, settings: settings);
      expect(resolved.usingProxy, isTrue);
      expect(resolved.path, equals('proxy/optim.mp4'));
    });

    test('resolveForPreview returns editPath if settings disabled', () {
      final disabledSettings = settings.copyWith(enabled: false);
      final resolved = service.resolveForPreview(asset: readyProxyAsset, settings: disabledSettings);
      expect(resolved.usingProxy, isFalse);
      expect(resolved.path, equals(readyProxyAsset.resolvedEditPath));
    });

    test('resolveForExport defaults to originalPath', () {
      final resolved = service.resolveForExport(asset: readyProxyAsset, settings: settings);
      expect(resolved.usingProxy, isFalse);
      expect(resolved.path, equals(readyProxyAsset.resolvedOriginalPath));
    });

    test('resolveForExport returns proxyPath if proxyDraft mode chosen', () {
      final draftSettings = settings.copyWith(exportMode: NleProxyExportMode.proxyDraft);
      final resolved = service.resolveForExport(asset: readyProxyAsset, settings: draftSettings);
      expect(resolved.usingProxy, isTrue);
      expect(resolved.path, equals('proxy/optim.mp4'));
    });
  });
}
