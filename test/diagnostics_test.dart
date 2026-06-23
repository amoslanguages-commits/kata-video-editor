import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/data/repositories/transition_repository.dart';
import 'package:nle_editor/domain/diagnostics/timeline_issue.dart';
import 'package:nle_editor/domain/services/render_graph_validation_service.dart';
import 'package:nle_editor/domain/services/project_repair_service.dart';
import 'package:nle_editor/domain/services/debug_log_service.dart';
import 'package:nle_editor/data/repositories/error_log_repository.dart';
import 'package:nle_editor/domain/errors/app_error.dart';
import 'package:nle_editor/domain/services/export_readiness_checker.dart';
import 'package:nle_editor/domain/services/app_permission_service.dart';
import 'package:nle_editor/domain/services/error_reporting_service.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/domain/storage/project_storage_report.dart';

void main() {
  late AppDatabase db;
  late MediaAssetRepository assetRepo;
  late TimelineRepository timelineRepo;
  late TransitionRepository transitionRepo;
  late RenderGraphValidationService validator;
  late ProjectRepairService repairService;
  late DebugLogService debugLogService;
  late ExportReadinessChecker readinessChecker;
  late MockAppPermissionService mockPermissionService;

  const projectId = 'proj_test_diag';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    assetRepo = MediaAssetRepository(database: db);
    timelineRepo = TimelineRepository(db);
    transitionRepo = TransitionRepository(db);

    validator = RenderGraphValidationService(
      timelineRepository: timelineRepo,
      assetRepository: assetRepo,
    );

    repairService = ProjectRepairService(
      timelineRepository: timelineRepo,
      assetRepository: assetRepo,
      transitionRepository: transitionRepo,
    );

    debugLogService = DebugLogService(
      repository: ErrorLogRepository(db),
    );

    final errorReportingService = ErrorReportingService(
      repository: ErrorLogRepository(db),
    );

    mockPermissionService = MockAppPermissionService(
      errorReportingService: errorReportingService,
    );

    readinessChecker = ExportReadinessChecker(
      validationService: validator,
      permissionService: mockPermissionService,
      assetRepository: assetRepo,
    );

    // Insert a project row first (required by FK).
    await db.insertProject(
      ProjectsCompanion.insert(
        id: projectId,
        name: 'Diag Test Project',
      ),
    );

    // Create default tracks.
    await timelineRepo.createDefaultTracks(projectId);
  });

  tearDown(() async {
    await db.close();
  });

  // ── TimelineIssue model tests ─────────────────────────────────────────────

  group('TimelineIssue model', () {
    test('severity helpers are correct', () {
      final critical = TimelineIssue(
        severity: TimelineIssueSeverity.critical,
        category: TimelineIssueCategory.media,
        title: 'test',
        description: 'desc',
      );
      expect(critical.isCritical, isTrue);
      expect(critical.isError, isFalse);

      final warning = TimelineIssue(
        severity: TimelineIssueSeverity.warning,
        category: TimelineIssueCategory.timeline,
        title: 'warn',
        description: 'desc',
      );
      expect(warning.isWarning, isTrue);
      expect(warning.isInfo, isFalse);
    });

    test('isActionable is true only when action is set', () {
      final noAction = TimelineIssue(
        severity: TimelineIssueSeverity.info,
        category: TimelineIssueCategory.timeline,
        title: 'no action',
        description: 'desc',
      );
      expect(noAction.isActionable, isFalse);

      final withAction = TimelineIssue(
        severity: TimelineIssueSeverity.error,
        category: TimelineIssueCategory.media,
        title: 'with action',
        description: 'desc',
        action: const TimelineIssueAction(
          label: 'Fix',
          actionId: TimelineIssueActionId.removeClip,
        ),
      );
      expect(withAction.isActionable, isTrue);
    });
  });

  // ── TimelineValidationReport tests ───────────────────────────────────────

  group('TimelineValidationReport', () {
    test('counts are correct', () {
      final issues = [
        TimelineIssue(
          severity: TimelineIssueSeverity.critical,
          category: TimelineIssueCategory.media,
          title: 'c1',
          description: '',
        ),
        TimelineIssue(
          severity: TimelineIssueSeverity.error,
          category: TimelineIssueCategory.timeline,
          title: 'e1',
          description: '',
        ),
        TimelineIssue(
          severity: TimelineIssueSeverity.warning,
          category: TimelineIssueCategory.audio,
          title: 'w1',
          description: '',
        ),
      ];

      final report = TimelineValidationReport(
        projectId: projectId,
        issues: issues,
        generatedAt: DateTime.now(),
      );

      expect(report.criticalCount, 1);
      expect(report.errorCount, 1);
      expect(report.warningCount, 1);
      expect(report.hasBlockingIssues, isTrue);
    });

    test('empty report has correct state', () {
      final report = TimelineValidationReport(
        projectId: projectId,
        issues: const [],
        generatedAt: DateTime.now(),
      );

      expect(report.isEmpty, isTrue);
      expect(report.hasBlockingIssues, isFalse);
      expect(report.summaryText, 'No issues found');
    });
  });

  // ── RenderGraphValidationService tests ───────────────────────────────────

  group('RenderGraphValidationService', () {
    test('empty timeline returns an info issue', () async {
      final report = await validator.validateProject(projectId);
      final infos = report.issues
          .where((i) => i.severity == TimelineIssueSeverity.info)
          .toList();
      expect(infos, isNotEmpty);
    });

    test('missing asset generates a critical issue', () async {
      // Insert an asset marked as missing.
      await _insertFakeMediaAsset(
        repo: assetRepo,
        id: 'asset_missing_1',
        projectId: projectId,
        fileName: 'video.mp4',
        path: '/nonexistent/video.mp4',
        isMissing: true,
      );

      final report = await validator.validateProject(projectId);
      final critical = report.issues
          .where((i) => i.severity == TimelineIssueSeverity.critical)
          .toList();

      expect(critical, isNotEmpty);
      expect(critical.first.category, TimelineIssueCategory.media);
    });

    test('clip with inverted bounds generates an error', () async {
      final tracks = await timelineRepo.getProjectTracks(projectId);
      final videoTrack = tracks.firstWhere((t) => t.type == 'video');

      await _insertFakeMediaAsset(
        repo: assetRepo,
        id: 'asset_v1',
        projectId: projectId,
        fileName: 'clip.mp4',
        path: '/fake/clip.mp4',
      );

      await timelineRepo.insertClip(
        ClipsCompanion.insert(
          id: 'clip_bad',
          projectId: projectId,
          trackId: videoTrack.id,
          clipType: const Value('video'),
          assetId: const Value('asset_v1'),
          timelineStartMicros: const Value(0),
          timelineEndMicros: const Value(5000000),
          // inverted source range
          sourceInMicros: const Value(10000000),
          sourceOutMicros: const Value(1000000),
        ),
      );

      final report = await validator.validateProject(projectId);
      final errors = report.issues
          .where((i) => i.severity == TimelineIssueSeverity.error)
          .toList();

      expect(errors.any((e) => e.clipId == 'clip_bad'), isTrue);
    });

    test('overlapping clips on same video track generates a warning', () async {
      final tracks = await timelineRepo.getProjectTracks(projectId);
      final videoTrack = tracks.firstWhere((t) => t.type == 'video');

      await _insertFakeMediaAsset(
        repo: assetRepo,
        id: 'asset_v2',
        projectId: projectId,
        fileName: 'clip2.mp4',
        path: '/fake/clip2.mp4',
      );

      await timelineRepo.insertClip(
        ClipsCompanion.insert(
          id: 'clip_a',
          projectId: projectId,
          trackId: videoTrack.id,
          clipType: const Value('video'),
          assetId: const Value('asset_v2'),
          timelineStartMicros: const Value(0),
          timelineEndMicros: const Value(5000000),
          sourceInMicros: const Value(0),
          sourceOutMicros: const Value(5000000),
        ),
      );

      await timelineRepo.insertClip(
        ClipsCompanion.insert(
          id: 'clip_b',
          projectId: projectId,
          trackId: videoTrack.id,
          clipType: const Value('video'),
          assetId: const Value('asset_v2'),
          // overlaps clip_a
          timelineStartMicros: const Value(3000000),
          timelineEndMicros: const Value(8000000),
          sourceInMicros: const Value(0),
          sourceOutMicros: const Value(5000000),
        ),
      );

      final report = await validator.validateProject(projectId);
      final warnings = report.issues
          .where((i) => i.severity == TimelineIssueSeverity.warning)
          .toList();

      expect(warnings.any((w) => w.category == TimelineIssueCategory.timeline),
          isTrue);
    });
  });

  // ── ProjectRepairService tests ────────────────────────────────────────────

  group('ProjectRepairService', () {
    test('repairClipTiming swaps inverted in/out', () async {
      final tracks = await timelineRepo.getProjectTracks(projectId);
      final videoTrack = tracks.firstWhere((t) => t.type == 'video');

      await _insertFakeMediaAsset(
        repo: assetRepo,
        id: 'asset_repair',
        projectId: projectId,
        fileName: 'r.mp4',
        path: '/fake/r.mp4',
      );

      await timelineRepo.insertClip(
        ClipsCompanion.insert(
          id: 'clip_repair',
          projectId: projectId,
          trackId: videoTrack.id,
          clipType: const Value('video'),
          assetId: const Value('asset_repair'),
          timelineStartMicros: const Value(0),
          timelineEndMicros: const Value(5000000),
          sourceInMicros: const Value(8000000),
          sourceOutMicros: const Value(2000000),
        ),
      );

      final fixed = await repairService.repairClipTiming('clip_repair');
      expect(fixed, 1);

      final clip = await timelineRepo.getClip('clip_repair');
      expect(clip, isNotNull);
      expect(clip!.sourceInMicros, lessThan(clip.sourceOutMicros));
    });

    test('removeClip deletes the clip', () async {
      final tracks = await timelineRepo.getProjectTracks(projectId);
      final videoTrack = tracks.firstWhere((t) => t.type == 'video');

      await _insertFakeMediaAsset(
        repo: assetRepo,
        id: 'asset_del',
        projectId: projectId,
        fileName: 'd.mp4',
        path: '/fake/d.mp4',
      );

      await timelineRepo.insertClip(
        ClipsCompanion.insert(
          id: 'clip_del',
          projectId: projectId,
          trackId: videoTrack.id,
          clipType: const Value('video'),
          assetId: const Value('asset_del'),
          timelineStartMicros: const Value(0),
          timelineEndMicros: const Value(2000000),
          sourceInMicros: const Value(0),
          sourceOutMicros: const Value(2000000),
        ),
      );

      await repairService.removeClip('clip_del');
      final gone = await timelineRepo.getClip('clip_del');
      expect(gone, isNull);
    });

    test('autoRepair returns a result with correct state for clean project',
        () async {
      final result = await repairService.autoRepair(projectId);
      expect(result.totalFixed, 0);
      expect(result.hadIssues, isFalse);
    });
  });

  // ── DebugLogService tests ──────────────────────────────────────────────────

  group('DebugLogService', () {
    test('search filters by user message', () {
      final logs = [
        _makeFakeLog('Export failed due to codec error'),
        _makeFakeLog('Permission denied'),
        _makeFakeLog('Missing file detected'),
      ];

      final results = debugLogService.search(logs, 'export');
      expect(results.length, 1);
      expect(results.first.userMessage, contains('Export'));
    });

    test('filterBySeverity returns only matching logs', () {
      final logs = [
        _makeFakeLog('err1', severity: AppErrorSeverity.error),
        _makeFakeLog('warn1', severity: AppErrorSeverity.warning),
        _makeFakeLog('crit1', severity: AppErrorSeverity.critical),
      ];

      final errors =
          debugLogService.filterBySeverity(logs, AppErrorSeverity.error);
      expect(errors.length, 1);
      expect(errors.first.userMessage, 'err1');
    });

    test('clearResolvedLogs does not throw on empty DB', () async {
      final count = await debugLogService.clearResolvedLogs();
      expect(count, 0);
    });
  });

  // ── ExportReadinessChecker tests ──────────────────────────────────────────

  group('ExportReadinessChecker', () {
    test('ready when project is clean, has permission, and storage is sufficient', () async {
      mockPermissionService.hasGalleryAccess = true;
      final report = await readinessChecker.checkReadiness(
        projectId: projectId,
        projectDurationMicros: 30 * 1000000,
        storageReport: ProjectStorageReport.empty(projectId),
      );

      expect(report.ready, isTrue);
      expect(report.blockingIssues, isEmpty);
    });

    test('blocking issue when gallery permission is missing', () async {
      mockPermissionService.hasGalleryAccess = false;
      final report = await readinessChecker.checkReadiness(
        projectId: projectId,
        projectDurationMicros: 30 * 1000000,
        storageReport: ProjectStorageReport.empty(projectId),
      );

      expect(report.ready, isFalse);
      expect(
        report.blockingIssues.any((i) => i.category == TimelineIssueCategory.permission),
        isTrue,
      );
    });

    test('warning when temp files are too large', () async {
      mockPermissionService.hasGalleryAccess = true;
      final report = await readinessChecker.checkReadiness(
        projectId: projectId,
        projectDurationMicros: 30 * 1000000,
        storageReport: ProjectStorageReport.empty(projectId).copyWith(
          tempBytes: 600 * 1024 * 1024,
          totalBytes: 600 * 1024 * 1024,
        ),
      );

      expect(report.ready, isTrue);
      expect(
        report.warnings.any((w) => w.action?.actionId == TimelineIssueActionId.clearCache),
        isTrue,
      );
    });
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────────

AppErrorLog _makeFakeLog(
  String message, {
  String severity = AppErrorSeverity.info,
}) {
  return AppErrorLog(
    id: 'log_${message.hashCode}',
    category: AppErrorCategory.unknown,
    code: AppErrorCode.unknown,
    severity: severity,
    userMessage: message,
    technicalMessage: null,
    recoverySuggestion: null,
    projectId: null,
    source: null,
    nativeCode: null,
    actionLabel: null,
    actionPayload: '{}',
    contextJson: '{}',
    isResolved: false,
    createdAt: DateTime.now(),
  );
}

class MockAppPermissionService extends AppPermissionService {
  bool hasGalleryAccess = true;

  MockAppPermissionService({required super.errorReportingService});

  @override
  Future<AppPermissionState> check(String type) async {
    if (type == AppPermissionType.gallerySave) {
      return AppPermissionState(
        type: type,
        status: hasGalleryAccess ? AppPermissionStatusValue.granted : AppPermissionStatusValue.denied,
        canRequestAgain: !hasGalleryAccess,
        shouldOpenSettings: !hasGalleryAccess,
        hasLimitedAccess: false,
        checkedAt: DateTime.now(),
      );
    }
    return AppPermissionState.unknown(type);
  }
}

Future<void> _insertFakeMediaAsset({
  required MediaAssetRepository repo,
  required String id,
  required String projectId,
  required String fileName,
  required String path,
  bool isMissing = false,
}) async {
  final asset = NleMediaAsset(
    id: id,
    projectId: projectId,
    displayName: fileName,
    type: NleMediaAssetType.video,
    importSource: NleMediaImportSource.filePicker,
    storageMode: NleMediaStorageMode.copiedIntoProject,
    availability: isMissing ? NleMediaAvailability.missing : NleMediaAvailability.available,
    originalPath: path,
    projectPath: path,
    proxyStatus: NleProxyStatus.none,
    usageState: NleMediaUsageState.unused,
    fileInfo: NleMediaFileInfo(
      fileName: fileName,
      extension: 'mp4',
      fileSizeBytes: 1024,
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
      durationMicros: 10000000,
      startTimecodeMicros: 0,
    ),
    tags: const [],
    importedAt: DateTime.now(),
    updatedAt: DateTime.now(),
    version: 1,
  );
  await repo.saveAsset(asset);
}
