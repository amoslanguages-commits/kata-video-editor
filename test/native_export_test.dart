import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/export_repository.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/native_bridge/fake_native_bridge.dart';
import 'package:nle_editor/native_bridge/native_export_job.dart';
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
  late ExportRepository exportRepository;
  late FakeProjectStorageService storageService;
  late FakeNativeBridge nativeBridge;
  late ProviderContainer container;
  late String tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    exportRepository = ExportRepository(db);
    tempDir =
        '${Directory.current.path}/build/test_native_export_${DateTime.now().millisecondsSinceEpoch}';
    storageService = FakeProjectStorageService(tempDir);
    nativeBridge = FakeNativeBridge();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        exportRepositoryProvider.overrideWithValue(exportRepository),
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

  group('NativeExportProfile Tests', () {
    test('serializes to JSON correctly', () {
      const profile = NativeExportProfile(
        width: 1280,
        height: 720,
        frameRate: 25,
        bitrateBps: 4000000,
        gopInterval: 25,
        codec: 'video/avc',
        containerFormat: 'video/mp4',
      );

      final map = profile.toMap();
      expect(map['width'], equals(1280));
      expect(map['height'], equals(720));
      expect(map['frameRate'], equals(25));
      expect(map['bitrateBps'], equals(4000000));
      expect(map['gopInterval'], equals(25));
      expect(map['codec'], equals('video/avc'));
      expect(map['containerFormat'], equals('video/mp4'));
    });

    test('parses fromSettings correctly', () {
      final profile = NativeExportProfile.fromSettings({
        'resolution': 720,
        'aspectRatio': '16:9',
        'frameRate': 24,
        'bitrate': '4M',
      });

      expect(profile.width, equals(1280));
      expect(profile.height, equals(720));
      expect(profile.frameRate, equals(24));
      expect(profile.bitrateBps, equals(4000000));
    });
  });

  group('Native Export Integration Tests', () {
    test(
        'flow of starting export job and receiving completed events updates DB',
        () async {
      const projectId = 'proj_export_123';
      final project = ProjectsCompanion(
        id: const Value(projectId),
        name: const Value('Test Export Project'),
        aspectRatio: const Value('16:9'),
        targetWidth: const Value(1920),
        targetHeight: const Value(1080),
        targetFrameRate: const Value(30),
      );
      await db.insertProject(project);

      // Start the event controller
      container.read(nativeExportEventControllerProvider);

      final exportService = container.read(nativeExportServiceProvider);
      final jobId = await exportService.startExport(
        projectId: projectId,
        settings: {
          'resolution': 1080,
          'frameRate': 30,
          'bitrate': '8M',
        },
      );

      expect(jobId, isNotEmpty);

      // Verify DB row exists and status is running
      var job = await (db.select(db.exportJobs)
            ..where((t) => t.id.equals(jobId)))
          .getSingleOrNull();
      expect(job, isNotNull);
      expect(job!.status, equals('running'));
      expect(job.progress, equals(0));

      // Wait for fake export simulation stages to execute and complete
      // FakeNativeBridge has 6 stages taking 300+ ms each, total ~2 seconds.
      await Future<void>.delayed(const Duration(milliseconds: 3000));

      // Verify job is now completed in the DB
      job = await (db.select(db.exportJobs)..where((t) => t.id.equals(jobId)))
          .getSingleOrNull();
      expect(job, isNotNull);
      expect(job!.status, equals('completed'));
      expect(job.progress, equals(100));
      expect(job.stage, equals('Complete'));
      expect(job.outputPath, isNotNull);
      expect(job.outputPath, contains('export_'));
      expect(job.completedAt, isNotNull);
    });

    test('flow of starting export job and cancelling it updates DB', () async {
      const projectId = 'proj_export_456';
      final project = ProjectsCompanion(
        id: const Value(projectId),
        name: const Value('Test Cancel Project'),
        aspectRatio: const Value('16:9'),
        targetWidth: const Value(1920),
        targetHeight: const Value(1080),
        targetFrameRate: const Value(30),
      );
      await db.insertProject(project);

      container.read(nativeExportEventControllerProvider);

      final exportService = container.read(nativeExportServiceProvider);
      final jobId = await exportService.startExport(
        projectId: projectId,
        settings: {
          'resolution': 1080,
          'frameRate': 30,
          'bitrate': '8M',
        },
      );

      var job = await (db.select(db.exportJobs)
            ..where((t) => t.id.equals(jobId)))
          .getSingleOrNull();
      expect(job!.status, equals('running'));

      // Cancel the export immediately
      await exportService.cancelExport(jobId: jobId);

      // Wait briefly for event loops to tick
      await Future<void>.delayed(const Duration(milliseconds: 100));

      job = await (db.select(db.exportJobs)..where((t) => t.id.equals(jobId)))
          .getSingleOrNull();
      expect(job!.status, equals('cancelled'));
      expect(job.stage, equals('Cancelled'));
    });
  });
}
