import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/project_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/data/repositories/job_queue_repository.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/domain/services/app_permission_service.dart';
import 'package:nle_editor/domain/services/interrupted_job_recovery_service.dart';
import 'package:nle_editor/domain/services/missing_media_service.dart';
import 'package:nle_editor/domain/services/project_autosave_service.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/domain/services/project_session_service.dart';
import 'package:nle_editor/domain/services/resume_project_safety_check_service.dart';
import 'package:nle_editor/domain/services/recovery_snapshot_detector.dart';
import 'package:nle_editor/domain/services/error_reporting_service.dart';

// Fake implementations for testing lifecycle and recovery

class FakeAppPermissionService implements AppPermissionService {
  bool hasAccessValue = true;

  @override
  ErrorReportingService get errorReportingService => throw UnimplementedError();

  @override
  Future<AppPermissionState> check(String permissionType) async {
    return AppPermissionState(
      type: permissionType,
      status: hasAccessValue
          ? AppPermissionStatusValue.granted
          : AppPermissionStatusValue.denied,
      canRequestAgain: true,
      shouldOpenSettings: false,
      hasLimitedAccess: false,
      checkedAt: DateTime.now(),
    );
  }

  @override
  Future<AppPermissionState> request(String permissionType,
      {String? projectId, String? source, bool reportIfDenied = true}) async {
    return check(permissionType);
  }

  @override
  Future<AppPermissionState> ensure(String permissionType,
      {String? projectId, String? source}) async {
    return check(permissionType);
  }

  @override
  Future<bool> ensureHasAccess(String permissionType,
      {String? projectId, String? source}) async {
    final state = await ensure(permissionType);
    return state.hasAccess;
  }

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<bool> openPhotoManagerSettings() async => true;

  @override
  Future<void> presentLimitedMediaPicker() async {}
}

class FakeMissingMediaService implements MissingMediaService {
  int missingCount = 0;
  int totalCount = 0;

  @override
  MediaAssetRepository get assetRepository => throw UnimplementedError();

  @override
  Future<MissingMediaReport> checkProjectMedia(String projectId) async {
    return MissingMediaReport(
      totalAssets: totalCount,
      missingAssets: missingCount,
    );
  }
}

class FakeInterruptedJobRecoveryService
    implements InterruptedJobRecoveryService {
  int interruptedCount = 0;

  @override
  JobQueueRepository get jobQueueRepository => throw UnimplementedError();
  @override
  ErrorReportingService get errorReportingService => throw UnimplementedError();

  @override
  Future<int> markInterruptedJobs(
      {String? projectId, bool notify = false}) async {
    return interruptedCount;
  }
}

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
  late ProjectRepository projectRepository;
  late AssetRepository assetRepository;
  late TimelineRepository timelineRepository;
  late FakeProjectStorageService storageService;
  late ProjectAutosaveService autosaveService;
  late String tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    projectRepository = ProjectRepository(db);
    assetRepository = AssetRepository(db);
    timelineRepository = TimelineRepository(db);

    // Create a local temp directory inside project build folder
    tempDir =
        '${Directory.current.path}/build/test_lifecycle_recovery_${DateTime.now().millisecondsSinceEpoch}';
    storageService = FakeProjectStorageService(tempDir);

    autosaveService = ProjectAutosaveService(
      projectRepository: projectRepository,
      assetRepository: assetRepository,
      timelineRepository: timelineRepository,
      storageService: storageService,
    );
  });

  tearDown(() async {
    await db.close();
    final dir = Directory(tempDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  group('ResumeProjectSafetyReport Tests', () {
    test('reports warnings correctly', () {
      const reportNoWarnings = ResumeProjectSafetyReport(
        missingAssets: 0,
        interruptedJobs: 0,
        mediaPermissionAvailable: true,
      );
      expect(reportNoWarnings.hasWarnings, isFalse);

      const reportMissingAssets = ResumeProjectSafetyReport(
        missingAssets: 2,
        interruptedJobs: 0,
        mediaPermissionAvailable: true,
      );
      expect(reportMissingAssets.hasWarnings, isTrue);

      const reportInterruptedJobs = ResumeProjectSafetyReport(
        missingAssets: 0,
        interruptedJobs: 1,
        mediaPermissionAvailable: true,
      );
      expect(reportInterruptedJobs.hasWarnings, isTrue);

      const reportNoPermission = ResumeProjectSafetyReport(
        missingAssets: 0,
        interruptedJobs: 0,
        mediaPermissionAvailable: false,
      );
      expect(reportNoPermission.hasWarnings, isTrue);
    });
  });

  group('ResumeProjectSafetyCheckService Tests', () {
    test('aggregates subservice results accurately', () async {
      final fakePermission = FakeAppPermissionService();
      final fakeMissingMedia = FakeMissingMediaService();
      final fakeInterrupted = FakeInterruptedJobRecoveryService();

      final safetyCheckService = ResumeProjectSafetyCheckService(
        permissionService: fakePermission,
        missingMediaService: fakeMissingMedia,
        interruptedJobRecoveryService: fakeInterrupted,
      );

      // Scenario 1: All clean
      fakePermission.hasAccessValue = true;
      fakeMissingMedia.totalCount = 5;
      fakeMissingMedia.missingCount = 0;
      fakeInterrupted.interruptedCount = 0;

      var report = await safetyCheckService.checkProjectOnResume('project_abc');
      expect(report.hasWarnings, isFalse);
      expect(report.missingAssets, equals(0));
      expect(report.interruptedJobs, equals(0));
      expect(report.mediaPermissionAvailable, isTrue);

      // Scenario 2: Warnings present
      fakePermission.hasAccessValue = false;
      fakeMissingMedia.missingCount = 3;
      fakeInterrupted.interruptedCount = 2;

      report = await safetyCheckService.checkProjectOnResume('project_abc');
      expect(report.hasWarnings, isTrue);
      expect(report.missingAssets, equals(3));
      expect(report.interruptedJobs, equals(2));
      expect(report.mediaPermissionAvailable, isFalse);
    });
  });

  group('ProjectAutosaveService Tests', () {
    test('creates and reads snapshot files successfully', () async {
      const projectId = 'test_project_1';

      // Insert dummy project
      await db.into(db.projects).insert(ProjectsCompanion.insert(
            id: projectId,
            name: 'My Masterpiece',
            aspectRatio: const Value('16:9'),
            targetWidth: const Value(1920),
            targetHeight: const Value(1080),
            targetFrameRate: const Value(30),
            durationMicros: const Value(30000000),
            createdAt: Value(DateTime.now()),
            modifiedAt: Value(DateTime.now()),
          ));

      // Initially should have no recovery snapshot
      var hasSnapshot = await autosaveService.hasRecoverySnapshot(projectId);
      expect(hasSnapshot, isFalse);

      // Trigger autosave
      final savedPath = await autosaveService.autosaveProject(projectId);
      expect(savedPath, isNotNull);
      expect(File(savedPath!).existsSync(), isTrue);

      // Now it should have recovery snapshot
      hasSnapshot = await autosaveService.hasRecoverySnapshot(projectId);
      expect(hasSnapshot, isTrue);

      // Read snapshot back and verify fields
      final data = await autosaveService.readLatestSnapshot(projectId);
      expect(data, isNotNull);
      expect(data!['version'], equals(1));
      expect(data['type'], equals('nle_autosave'));
      expect(data['projectId'], equals(projectId));

      final projectData = data['project'] as Map<String, dynamic>;
      expect(projectData['name'], equals('My Masterpiece'));
      expect(projectData['aspectRatio'], equals('16:9'));
    });
  });

  group('RecoverySnapshotDetector Tests', () {
    test('inspectProject returns correct session metadata', () async {
      const projectId = 'test_proj';

      final detector = RecoverySnapshotDetector(
        projectStorageService: storageService,
        projectSessionService:
            ProjectSessionService(projectStorageService: storageService),
      );

      // Scenario 1: No snapshot or session
      var info = await detector.inspectProject(projectId);
      expect(info.hasAutosave, isFalse);
      expect(info.hasSession, isFalse);

      // Scenario 2: Write manual session state and check
      final sessionPaths = await storageService.getProjectFolders(projectId);
      final sessionFile = File('${sessionPaths.root}/session_state.json');
      final sessionData = {
        'projectId': projectId,
        'playheadMicros': 5000000,
        'selectedClipId': 'clip_1',
        'activeTool': 'trim',
        'lastActiveAt': DateTime.now().toIso8601String(),
      };
      sessionFile.writeAsStringSync(sessionData.toString());

      info = await detector.inspectProject(projectId);
      expect(info.hasAutosave, isFalse);
      expect(info.hasSession, isTrue);

      // Scenario 3: Trigger autosave and check
      await db.into(db.projects).insert(ProjectsCompanion.insert(
            id: projectId,
            name: 'Test Project',
            aspectRatio: const Value('9:16'),
            targetWidth: const Value(1080),
            targetHeight: const Value(1920),
            targetFrameRate: const Value(60),
            durationMicros: const Value(15000000),
            createdAt: Value(DateTime.now()),
            modifiedAt: Value(DateTime.now()),
          ));

      await autosaveService.autosaveProject(projectId);

      info = await detector.inspectProject(projectId);
      expect(info.hasAutosave, isTrue);
      expect(info.hasSession, isTrue);
      expect(info.autosaveModifiedAt, isNotNull);
    });
  });
}
