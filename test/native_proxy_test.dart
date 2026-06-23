import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNotNull;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/native_bridge/fake_native_bridge.dart';
import 'package:nle_editor/native_bridge/native_proxy_job.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

class FakeProjectStorageService extends ProjectStorageService {
  final String tempDir;
  FakeProjectStorageService(this.tempDir);

  @override
  Future<ProjectStoragePaths> getProjectFolders(String projectId) async {
    final root = '$tempDir/projects/$projectId';
    final paths = ProjectStoragePaths(
      root: root,
      thumbnails: '$root/thumbnails',
      timelineThumbnails: '$root/timeline_thumbnails',
      waveforms: '$root/waveforms',
      proxies: '$root/proxies',
      exports: '$root/exports',
      autosaves: '$root/autosaves',
      temp: '$root/temp',
    );

    for (final dir in [
      paths.root,
      paths.thumbnails,
      paths.timelineThumbnails,
      paths.waveforms,
      paths.proxies,
      paths.exports,
      paths.autosaves,
      paths.temp,
    ]) {
      final directory = Directory(dir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
    }

    return paths;
  }

  @override
  Future<ProjectStoragePaths> createProjectFolders(String projectId) async {
    return getProjectFolders(projectId);
  }
}

void main() {
  late AppDatabase db;
  late AssetRepository assetRepository;
  late FakeProjectStorageService storageService;
  late FakeNativeBridge nativeBridge;
  late ProviderContainer container;
  late String tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    assetRepository = AssetRepository(db);
    tempDir =
        '${Directory.current.path}/build/test_native_proxy_${DateTime.now().millisecondsSinceEpoch}';
    storageService = FakeProjectStorageService(tempDir);
    nativeBridge = FakeNativeBridge();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        assetRepositoryProvider.overrideWithValue(assetRepository),
        projectStorageServiceProvider.overrideWithValue(storageService),
        nativeBridgeProvider.overrideWithValue(nativeBridge),
      ],
    );

    await nativeBridge.initialize();
  });

  tearDown(() async {
    container.dispose();
    await nativeBridge.dispose();
    await db.close();
    final dir = Directory(tempDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  group('NativeProxyProfile Tests', () {
    test('serializes to JSON correctly', () {
      const profile = NativeProxyProfile(
        targetHeight: 360,
        frameRate: 24,
        videoBitrate: 800000,
        iFrameIntervalSeconds: 1,
        codec: 'video/hevc',
      );

      final json = profile.toJson();
      expect(json['targetHeight'], equals(360));
      expect(json['frameRate'], equals(24));
      expect(json['videoBitrate'], equals(800000));
      expect(json['iFrameIntervalSeconds'], equals(1));
      expect(json['codec'], equals('video/hevc'));
    });
  });

  group('Native Proxy Generation Integration Tests', () {
    test('flow of starting proxy job and receiving completed events updates DB',
        () async {
      final project = ProjectsCompanion(
        id: const Value('proj_123'),
        name: const Value('Test Project'),
      );
      await db.insertProject(project);

      final asset = AssetsCompanion(
        id: const Value('asset_456'),
        projectId: const Value('proj_123'),
        originalPath: const Value('path/to/original.mp4'),
        fileType: const Value('video'),
        fileName: const Value('original.mp4'),
      );
      await db.insertAsset(asset);

      // Start the event controller
      container.read(nativeProxyEventControllerProvider);

      var currentAsset = await assetRepository.getAsset('asset_456');
      expect(currentAsset?.proxyStatus, equals('not_needed'));

      final proxyGenService =
          container.read(nativeProxyGenerationServiceProvider);
      final dbAsset = (await assetRepository.getAsset('asset_456'))!;
      final jobId = await proxyGenService.requestProxyGeneration(
        asset: dbAsset,
        profile: NativeProxyProfile.lowQuality(),
      );

      expect(jobId, isNotEmpty);

      currentAsset = await assetRepository.getAsset('asset_456');
      expect(currentAsset?.proxyStatus, equals('processing'));

      // Wait for fake job simulation to complete
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      currentAsset = await assetRepository.getAsset('asset_456');
      expect(currentAsset?.proxyStatus, equals('ready'));
      expect(currentAsset?.proxyPath, isNotNull);
      expect(currentAsset?.proxyWidth, equals(640));
      expect(currentAsset?.proxyHeight, equals(360));
      expect(currentAsset?.proxyCodec, equals('video/avc'));
      expect(currentAsset?.proxyFileSize, equals(1024 * 1024 * 5));
    });

    test('flow of starting proxy job and cancelling it updates DB', () async {
      final project = ProjectsCompanion(
        id: const Value('proj_123'),
        name: const Value('Test Project'),
      );
      await db.insertProject(project);

      final asset = AssetsCompanion(
        id: const Value('asset_789'),
        projectId: const Value('proj_123'),
        originalPath: const Value('path/to/original.mp4'),
        fileType: const Value('video'),
        fileName: const Value('original.mp4'),
      );
      await db.insertAsset(asset);

      container.read(nativeProxyEventControllerProvider);

      final proxyGenService =
          container.read(nativeProxyGenerationServiceProvider);
      final dbAsset = (await assetRepository.getAsset('asset_789'))!;
      final jobId = await proxyGenService.requestProxyGeneration(
        asset: dbAsset,
        profile: NativeProxyProfile.lowQuality(),
      );

      var currentAsset = await assetRepository.getAsset('asset_789');
      expect(currentAsset?.proxyStatus, equals('processing'));

      await proxyGenService.cancelProxyGeneration(jobId: jobId);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      currentAsset = await assetRepository.getAsset('asset_789');
      expect(currentAsset?.proxyStatus, equals('cancelled'));
      expect(currentAsset?.errorMessage, equals('Cancelled by user'));
    });
  });
}
