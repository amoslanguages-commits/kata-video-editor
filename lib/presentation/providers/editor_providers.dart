import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/data/repositories/export_repository.dart';
import 'package:nle_editor/data/repositories/project_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/models/timeline_preview_item.dart';
import 'package:nle_editor/domain/media_library/media_import_service.dart';
import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/domain/media_library/media_project_path_service.dart';
import 'package:nle_editor/domain/media_library/media_type_detector.dart';
import 'package:nle_editor/platform/media/native_media_scanner_service.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_bin_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/media_library/media_library_filter_models.dart';
import 'package:nle_editor/domain/services/media_metadata_service.dart';
import 'package:nle_editor/domain/services/project_service.dart';
import 'package:nle_editor/domain/services/project_storage_service.dart';
import 'package:nle_editor/domain/services/thumbnail_service.dart';
import 'package:nle_editor/domain/services/timeline_command_service.dart';
import 'package:nle_editor/domain/services/waveform_service.dart';
import 'package:nle_editor/domain/services/project_autosave_service.dart';
import 'package:nle_editor/domain/services/missing_media_service.dart';
import 'package:nle_editor/domain/services/proxy_generation_service.dart';
import 'package:nle_editor/domain/services/native_proxy_generation_service.dart';
import 'package:nle_editor/domain/services/timeline_media_cache_manager.dart';
import 'package:nle_editor/domain/services/background_media_generation_queue.dart';
import 'package:nle_editor/domain/keyframes/keyframe_interpolator.dart';
import 'package:nle_editor/presentation/controllers/native_proxy_event_controller.dart';

import 'package:nle_editor/domain/proxy/proxy_queue_runner.dart';
import 'package:nle_editor/domain/proxy/proxy_generation_service.dart' as new_proxy;
import 'package:nle_editor/domain/proxy/proxy_cleanup_service.dart';
import 'package:nle_editor/presentation/controllers/proxy_controller.dart';
import 'package:nle_editor/data/repositories/proxy_repository.dart';
import 'package:nle_editor/platform/proxy/native_proxy_generator_service.dart';
import 'package:nle_editor/domain/services/native_export_service.dart';
import 'package:nle_editor/presentation/controllers/native_export_event_controller.dart';
import 'package:nle_editor/domain/services/temporary_export_service.dart';
import 'package:nle_editor/presentation/providers/monetization_providers.dart';
import 'package:nle_editor/presentation/providers/source_preview_providers.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_render_graph_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_qa_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_export_gate_providers.dart';
import 'package:nle_editor/domain/monetization/monetization_service.dart';
import 'package:nle_editor/domain/services/cache_storage_service.dart';
import 'package:nle_editor/domain/storage/project_storage_report.dart';
import 'package:nle_editor/domain/device/device_capability_profile.dart';
import 'package:nle_editor/domain/services/device_capability_profiler_service.dart';
import 'package:nle_editor/domain/services/device_profile_store_service.dart';
import 'package:nle_editor/domain/services/performance_recommendation_service.dart';
import 'package:nle_editor/domain/services/app_settings_service.dart';
import 'package:nle_editor/domain/settings/app_settings.dart';
import 'package:nle_editor/domain/settings/app_settings_notifier.dart';
import 'package:nle_editor/domain/render_graph/render_graph_service.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/native_bridge/fake_native_bridge.dart';
import 'package:nle_editor/native_bridge/android_native_bridge.dart';
import 'package:nle_editor/native_bridge/ios_native_bridge.dart';
import 'package:nle_editor/native_bridge/native_command_service.dart';
import 'package:nle_editor/data/repositories/job_queue_repository.dart';
import 'package:nle_editor/domain/jobs/job_queue_service.dart';
import 'package:nle_editor/data/repositories/transition_repository.dart';
import 'package:nle_editor/domain/services/transition_command_service.dart';
import 'package:nle_editor/data/repositories/keyframe_repository.dart';
import 'package:nle_editor/domain/services/keyframe_command_service.dart';
import 'package:nle_editor/data/repositories/text_preset_repository.dart';
import 'package:nle_editor/domain/services/text_style_command_service.dart';
import 'package:nle_editor/data/repositories/error_log_repository.dart';
import 'package:nle_editor/domain/errors/app_error.dart';
import 'package:nle_editor/domain/services/error_reporting_service.dart';
import 'package:nle_editor/domain/permissions/app_permission.dart';
import 'package:nle_editor/domain/permissions/app_permission_notifier.dart';
import 'package:nle_editor/domain/services/app_permission_service.dart';
import 'package:nle_editor/native_bridge/fake_nle_engine.dart';
import 'package:nle_editor/native_bridge/nle_engine.dart';
import 'package:nle_editor/native_bridge/nle_engine_events.dart';
import 'package:nle_editor/domain/lifecycle/app_lifecycle_controller.dart';
import 'package:nle_editor/domain/lifecycle/project_session_state.dart';
import 'package:nle_editor/domain/recovery/recovery_snapshot_info.dart';
import 'package:nle_editor/domain/services/interrupted_job_recovery_service.dart';
import 'package:nle_editor/domain/services/project_session_service.dart';
import 'package:nle_editor/domain/services/recovery_snapshot_detector.dart';
import 'package:nle_editor/domain/services/resume_project_safety_check_service.dart';
import 'package:nle_editor/domain/services/engine_health_service.dart';
import 'package:nle_editor/domain/services/render_graph_validation_service.dart';
import 'package:nle_editor/domain/services/export_readiness_checker.dart';
import 'package:nle_editor/domain/services/project_repair_service.dart';
import 'package:nle_editor/domain/services/debug_log_service.dart';
import 'package:nle_editor/domain/diagnostics/timeline_issue.dart';

export 'package:nle_editor/domain/lifecycle/project_session_state.dart'
    show ProjectSessionState;
export 'package:nle_editor/domain/services/resume_project_safety_check_service.dart'
    show ResumeProjectSafetyReport;
export 'package:nle_editor/presentation/providers/performance_providers.dart';

// ─── DB ───────────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override databaseProvider in main.dart');
});

// ─── Repositories ─────────────────────────────────────────────────────────────

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(databaseProvider));
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(databaseProvider));
});

final mediaAssetRepositoryProvider = Provider<MediaAssetRepository>((ref) {
  return MediaAssetRepository(database: ref.watch(databaseProvider));
});

final mediaProjectPathServiceProvider = Provider<MediaProjectPathService>((ref) {
  return const MediaProjectPathService();
});

final mediaTypeDetectorProvider = Provider<MediaTypeDetector>((ref) {
  return const MediaTypeDetector();
});

final nativeMediaScannerServiceProvider = Provider<NativeMediaScannerService>((ref) {
  return const NativeMediaScannerService();
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.watch(databaseProvider));
});

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return ExportRepository(ref.watch(databaseProvider));
});

final jobQueueRepositoryProvider = Provider<JobQueueRepository>((ref) {
  return JobQueueRepository(ref.watch(databaseProvider));
});

final transitionRepositoryProvider = Provider<TransitionRepository>((ref) {
  return TransitionRepository(ref.watch(databaseProvider));
});

final proxyRepositoryProvider = Provider<ProxyRepository>((ref) {
  return ProxyRepository(
    database: ref.watch(databaseProvider),
    mediaRepository: ref.watch(mediaAssetRepositoryProvider),
    pathService: ref.watch(mediaProjectPathServiceProvider),
  );
});

final nativeProxyGeneratorServiceProvider = Provider<NativeProxyGeneratorService>((ref) {
  return const NativeProxyGeneratorService();
});

final proxyQueueRunnerProvider = Provider<ProxyQueueRunner>((ref) {
  return ProxyQueueRunner(
    repository: ref.watch(proxyRepositoryProvider),
    nativeGenerator: ref.watch(nativeProxyGeneratorServiceProvider),
  );
});

final proxyGenerationServiceProvider = Provider<new_proxy.ProxyGenerationService>((ref) {
  return new_proxy.ProxyGenerationService(
    mediaRepository: ref.watch(mediaAssetRepositoryProvider),
    proxyRepository: ref.watch(proxyRepositoryProvider),
  );
});

final proxyCleanupServiceProvider = Provider<ProxyCleanupService>((ref) {
  return ProxyCleanupService(
    mediaRepository: ref.watch(mediaAssetRepositoryProvider),
    proxyRepository: ref.watch(proxyRepositoryProvider),
  );
});

final proxyControllerProvider = StateNotifierProvider.family<ProxyController, ProxyEditorState, String>((ref, projectId) {
  return ProxyController(
    projectId: projectId,
    proxyRepository: ref.watch(proxyRepositoryProvider),
    mediaRepository: ref.watch(mediaAssetRepositoryProvider),
    queueRunner: ref.watch(proxyQueueRunnerProvider),
    generationService: ref.watch(proxyGenerationServiceProvider),
    cleanupService: ref.watch(proxyCleanupServiceProvider),
  );
});

final nativeBridgeProvider = Provider<NativeBridgeContract>((ref) {
  // Use the real Android MethodChannel/EventChannel bridge on Android,
  // or the real iOS MethodChannel/EventChannel bridge on iOS.
  // Fall back to the fake in-process bridge on all other platforms (web,
  // Windows, macOS, Linux) so existing tests and desktop development are
  // unaffected.
  final NativeBridgeContract bridge;

  if (defaultTargetPlatform == TargetPlatform.android) {
    bridge = AndroidNativeBridge();
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    bridge = IosNativeBridge();
  } else {
    bridge = FakeNativeBridge();
  }

  bridge.initialize();

  ref.onDispose(() {
    bridge.dispose();
  });

  return bridge;
});

final renderGraphServiceProvider = Provider<RenderGraphService>((ref) {
  return RenderGraphService(
    multitrackService: ref.watch(multitrackRenderGraphServiceProvider),
  );
});

final nativeCommandServiceProvider = Provider<NativeCommandService>((ref) {
  return NativeCommandService(
    renderGraphService: ref.watch(multitrackRenderGraphServiceProvider),
    nativeBridge: ref.watch(nativeBridgeProvider),
  );
});

final jobQueueServiceProvider = Provider<JobQueueService>((ref) {
  final service = JobQueueService(
    jobRepository: ref.watch(jobQueueRepositoryProvider),
    nativeBridge: ref.watch(nativeBridgeProvider),
  );
  service.start();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final transitionCommandServiceProvider =
    Provider<TransitionCommandService>((ref) {
  return TransitionCommandService(
    transitionRepository: ref.watch(transitionRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    nativeCommandService: ref.watch(nativeCommandServiceProvider),
  );
});

final projectTransitionsProvider =
    StreamProvider.family<List<ClipTransition>, String>((ref, projectId) {
  return ref
      .watch(transitionRepositoryProvider)
      .watchProjectTransitions(projectId);
});

final keyframeRepositoryProvider = Provider<KeyframeRepository>((ref) {
  return KeyframeRepository(ref.watch(databaseProvider));
});

final keyframeCommandServiceProvider = Provider<KeyframeCommandService>((ref) {
  return KeyframeCommandService(
    keyframeRepository: ref.watch(keyframeRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    nativeCommandService: ref.watch(nativeCommandServiceProvider),
  );
});

final clipKeyframesProvider =
    StreamProvider.family<List<Keyframe>, String>((ref, clipId) {
  return ref.watch(keyframeRepositoryProvider).watchClipKeyframes(clipId);
});

final textPresetRepositoryProvider = Provider<TextPresetRepository>((ref) {
  return TextPresetRepository(ref.watch(databaseProvider));
});

final textStyleCommandServiceProvider =
    Provider<TextStyleCommandService>((ref) {
  return TextStyleCommandService(
    timelineRepository: ref.watch(timelineRepositoryProvider),
    textPresetRepository: ref.watch(textPresetRepositoryProvider),
    nativeCommandService: ref.watch(nativeCommandServiceProvider),
  );
});

final localTextPresetsProvider = StreamProvider<List<LocalTextPreset>>((ref) {
  return ref.watch(textPresetRepositoryProvider).watchLocalTextPresets();
});

final errorLogRepositoryProvider = Provider<ErrorLogRepository>((ref) {
  return ErrorLogRepository(ref.watch(databaseProvider));
});

final errorReportingServiceProvider = Provider<ErrorReportingService>((ref) {
  final service = ErrorReportingService(
    repository: ref.watch(errorLogRepositoryProvider),
  );

  ref.onDispose(service.dispose);

  return service;
});

final appErrorEventsProvider = StreamProvider<AppError>((ref) {
  return ref.watch(errorReportingServiceProvider).errors;
});

final recentErrorLogsProvider = StreamProvider<List<AppErrorLog>>((ref) {
  return ref.watch(errorLogRepositoryProvider).watchRecentErrorLogs();
});

final unresolvedProjectErrorsProvider =
    StreamProvider.family<List<AppErrorLog>, String?>((ref, projectId) {
  return ref.watch(errorLogRepositoryProvider).watchUnresolvedErrorLogs(
        projectId: projectId,
      );
});

final appPermissionServiceProvider = Provider<AppPermissionService>((ref) {
  return AppPermissionService(
    errorReportingService: ref.watch(errorReportingServiceProvider),
  );
});

final appPermissionNotifierProvider = StateNotifierProvider<
    AppPermissionNotifier, Map<String, AsyncValue<AppPermissionState>>>(
  (ref) {
    return AppPermissionNotifier(
      service: ref.watch(appPermissionServiceProvider),
    );
  },
);

final appPermissionStateProvider =
    FutureProvider.family<AppPermissionState, String>((ref, type) {
  return ref.watch(appPermissionServiceProvider).check(type);
});

// ─── Services ─────────────────────────────────────────────────────────────────

final projectStorageServiceProvider = Provider<ProjectStorageService>((ref) {
  return ProjectStorageService();
});

final cacheStorageServiceProvider = Provider<CacheStorageService>((ref) {
  return CacheStorageService(
    projectStorageService: ref.watch(projectStorageServiceProvider),
    assetRepository: ref.watch(assetRepositoryProvider),
  );
});

final projectStorageReportProvider =
    FutureProvider.family<ProjectStorageReport, String>((ref, projectId) {
  return ref
      .watch(cacheStorageServiceProvider)
      .calculateProjectStorage(projectId);
});

final deviceCapabilityProfilerServiceProvider =
    Provider<DeviceCapabilityProfilerService>((ref) {
  return DeviceCapabilityProfilerService();
});

final deviceProfileStoreServiceProvider =
    Provider<DeviceProfileStoreService>((ref) {
  return DeviceProfileStoreService();
});

final performanceRecommendationServiceProvider =
    Provider<PerformanceRecommendationService>((ref) {
  return const PerformanceRecommendationService();
});

final nativeProxyGenerationServiceProvider =
    Provider<NativeProxyGenerationService>((ref) {
  return NativeProxyGenerationService(
    nativeBridge: ref.watch(nativeBridgeProvider),
    assetRepository: ref.watch(assetRepositoryProvider),
    storageService: ref.watch(projectStorageServiceProvider),
  );
});

final nativeProxyEventControllerProvider =
    Provider<NativeProxyEventController>((ref) {
  final controller = NativeProxyEventController(
    nativeBridge: ref.watch(nativeBridgeProvider),
    ref: ref,
  );
  controller.start();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final nativeExportServiceProvider = Provider<NativeExportService>((ref) {
  return NativeExportService(
    nativeBridge: ref.watch(nativeBridgeProvider),
    exportRepository: ref.watch(exportRepositoryProvider),
    renderGraphService: ref.watch(renderGraphServiceProvider),
    storageService: ref.watch(projectStorageServiceProvider),
    database: ref.watch(databaseProvider),
  );
});

final nativeExportEventControllerProvider =
    Provider<NativeExportEventController>((ref) {
  final controller = NativeExportEventController(
    nativeBridge: ref.watch(nativeBridgeProvider),
    ref: ref,
  );
  controller.start();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final deviceCapabilityProfileProvider =
    FutureProvider<DeviceCapabilityProfile>((ref) async {
  final profiler = ref.watch(deviceCapabilityProfilerServiceProvider);
  final store = ref.watch(deviceProfileStoreServiceProvider);
  final nativeBridge = ref.watch(nativeBridgeProvider);

  final profile = await profiler.detectProfile(nativeBridge: nativeBridge);

  await store.saveProfile(profile);

  return profile;
});

final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  return AppSettingsService();
});

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return AppSettingsNotifier(
    service: ref.watch(appSettingsServiceProvider),
  );
});

final mediaMetadataServiceProvider = Provider<MediaMetadataService>((ref) {
  return MediaMetadataService();
});

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService();
});

final waveformServiceProvider = Provider<WaveformService>((ref) {
  return WaveformService();
});

final assetWaveformProvider =
    FutureProvider.family<List<double>, String>((ref, waveformPath) async {
  return ref.watch(waveformServiceProvider).readWaveform(waveformPath);
});

final projectStoragePathsProvider =
    FutureProvider.family<ProjectStoragePaths, String>((ref, projectId) {
  return ref.watch(projectStorageServiceProvider).getProjectFolders(projectId);
});

final timelineMediaCacheManagerProvider =
    Provider<TimelineMediaCacheManager>((ref) {
  return const TimelineMediaCacheManager();
});

final backgroundMediaGenerationQueueProvider =
    Provider<BackgroundMediaGenerationQueue>((ref) {
  final queue = BackgroundMediaGenerationQueue(
    ref.watch(thumbnailServiceProvider),
    ref.watch(waveformServiceProvider),
    ref.watch(assetRepositoryProvider),
  );
  ref.onDispose(() {
    queue.cancelAll();
  });
  return queue;
});

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(
    ref.watch(projectRepositoryProvider),
    ref.watch(timelineRepositoryProvider),
    ref.watch(projectStorageServiceProvider),
  );
});

final mediaImportServiceProvider = Provider<MediaImportService>((ref) {
  return MediaImportService(
    repository: ref.watch(mediaAssetRepositoryProvider),
    pathService: ref.watch(mediaProjectPathServiceProvider),
    typeDetector: ref.watch(mediaTypeDetectorProvider),
    nativeScanner: ref.watch(nativeMediaScannerServiceProvider),
  );
});

final timelineCommandServiceProvider = Provider<TimelineCommandService>((ref) {
  return TimelineCommandService(
    ref.watch(timelineRepositoryProvider),
    ref.watch(assetRepositoryProvider),
    ref.watch(projectRepositoryProvider),
  );
});

final projectAutosaveServiceProvider = Provider<ProjectAutosaveService>((ref) {
  return ProjectAutosaveService(
    projectRepository: ref.watch(projectRepositoryProvider),
    assetRepository: ref.watch(assetRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    storageService: ref.watch(projectStorageServiceProvider),
  );
});

final projectAutosaveControllerProvider =
    Provider<ProjectAutosaveController>((ref) {
  final controller = ProjectAutosaveController(
    autosaveService: ref.watch(projectAutosaveServiceProvider),
  );
  ref.onDispose(() {
    controller.stop();
  });
  return controller;
});

final missingMediaServiceProvider = Provider<MissingMediaService>((ref) {
  return MissingMediaService(
    assetRepository: ref.watch(mediaAssetRepositoryProvider),
  );
});

final legacyProxyGenerationServiceProvider = Provider<ProxyGenerationService>((ref) {
  return ProxyGenerationService(
    assetRepository: ref.watch(assetRepositoryProvider),
    storageService: ref.watch(projectStorageServiceProvider),
  );
});

final temporaryExportServiceProvider = Provider<TemporaryExportService>((ref) {
  return TemporaryExportService(
    assetRepository: ref.watch(assetRepositoryProvider),
    timelineRepository: ref.watch(timelineRepositoryProvider),
    storageService: ref.watch(projectStorageServiceProvider),
  );
});

// ─── NLE Engine ───────────────────────────────────────────────────────────────

final nleEngineProvider = Provider<NleEngine>((ref) {
  final engine = FakeNleEngine();
  engine.initialize();

  ref.onDispose(() {
    engine.dispose();
  });

  return engine;
});

// ─── Project providers ────────────────────────────────────────────────────────

final projectListProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAllProjects();
});

final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

final selectedProjectProvider = FutureProvider<Project?>((ref) {
  final projectId = ref.watch(selectedProjectIdProvider);
  if (projectId == null) return Future.value(null);
  return ref.watch(projectRepositoryProvider).getProject(projectId);
});

final projectAssetsProvider =
    StreamProvider.family<List<Asset>, String>((ref, projectId) {
  return ref.watch(assetRepositoryProvider).watchProjectAssets(projectId);
});

final assetByIdProvider = FutureProvider.family<Asset?, String>((ref, assetId) {
  return ref.watch(assetRepositoryProvider).getAsset(assetId);
});

final projectMediaAssetsProvider =
    FutureProvider.family<List<NleMediaAsset>, String>((ref, projectId) {
  return ref.watch(mediaAssetRepositoryProvider).getAssets(projectId);
});

final mediaAssetByIdProvider = FutureProvider.family<NleMediaAsset?, String>((ref, assetId) {
  return ref.watch(mediaAssetRepositoryProvider).getAsset(assetId);
});

final projectMediaBinsProvider =
    FutureProvider.family<List<NleMediaBin>, String>((ref, projectId) {
  return ref.watch(mediaAssetRepositoryProvider).getBins(projectId);
});

final projectTracksProvider =
    StreamProvider.family<List<Track>, String>((ref, projectId) {
  return ref.watch(timelineRepositoryProvider).watchProjectTracks(projectId);
});

final trackClipsProvider =
    StreamProvider.family<List<Clip>, String>((ref, trackId) {
  return ref.watch(timelineRepositoryProvider).watchTrackClips(trackId);
});

final projectClipsProvider =
    StreamProvider.family<List<Clip>, String>((ref, projectId) {
  return ref.watch(timelineRepositoryProvider).watchProjectClips(projectId);
});

final selectedClipProvider = FutureProvider<Clip?>((ref) {
  final clipId = ref.watch(editorStateProvider.select((s) => s.selectedClipId));
  if (clipId == null) return Future.value(null);
  return ref.watch(timelineRepositoryProvider).getClip(clipId);
});

final selectedClipAssetProvider = FutureProvider<Asset?>((ref) async {
  final clip = await ref.watch(selectedClipProvider.future);
  if (clip == null || clip.assetId == null) return null;
  return ref.watch(assetRepositoryProvider).getAsset(clip.assetId!);
});

// ─── Preview provider ────────────────────────────────────────────────────────

// ─── Preview provider ────────────────────────────────────────────────────────

Clip _interpolateClipProperties(
    Clip clip, List<Keyframe> keyframes, int currentTimeMicros) {
  final posX = KeyframeInterpolator.evaluate(
    keyframes: keyframes,
    parameterId: 'transform.positionX',
    targetTimeMicros: currentTimeMicros,
    defaultValue: clip.positionX,
  );
  final posY = KeyframeInterpolator.evaluate(
    keyframes: keyframes,
    parameterId: 'transform.positionY',
    targetTimeMicros: currentTimeMicros,
    defaultValue: clip.positionY,
  );
  final scale = KeyframeInterpolator.evaluate(
    keyframes: keyframes,
    parameterId: 'transform.scale',
    targetTimeMicros: currentTimeMicros,
    defaultValue: clip.scale,
  );
  final rotation = KeyframeInterpolator.evaluate(
    keyframes: keyframes,
    parameterId: 'transform.rotation',
    targetTimeMicros: currentTimeMicros,
    defaultValue: clip.rotation,
  );
  final opacity = KeyframeInterpolator.evaluate(
    keyframes: keyframes,
    parameterId: 'transform.opacity',
    targetTimeMicros: currentTimeMicros,
    defaultValue: clip.opacity,
  );
  final volume = KeyframeInterpolator.evaluate(
    keyframes: keyframes,
    parameterId: 'audio.volume',
    targetTimeMicros: currentTimeMicros,
    defaultValue: clip.volume,
  );

  return clip.copyWith(
    positionX: posX,
    positionY: posY,
    scale: scale,
    rotation: rotation,
    opacity: opacity,
    volume: volume,
  );
}

final timelinePreviewProvider = Provider<TimelinePreviewItem>((ref) {
  final projectId = ref.watch(selectedProjectIdProvider);
  if (projectId == null) {
    return const TimelinePreviewItem(
      primaryVisualClip: null,
      primaryVisualAsset: null,
      activeTextClips: [],
    );
  }

  final clipsAsync = ref.watch(projectClipsProvider(projectId));
  final editorState = ref.watch(editorStateProvider);
  final currentTime = editorState.currentTimeMicros;

  final clips = clipsAsync.value ?? [];

  final activeClips = clips.where((c) {
    return !c.isDisabled &&
        c.timelineStartMicros <= currentTime &&
        currentTime < c.timelineEndMicros;
  }).toList();

  final textClips = activeClips.where((c) => c.clipType == 'text').toList();
  final visualClips = activeClips
      .where((c) => c.clipType == 'video' || c.clipType == 'image')
      .toList();

  Clip? primaryVisual;
  if (visualClips.isNotEmpty) {
    // Overlays should sit on top of regular videos
    visualClips.sort((a, b) {
      final aIsOverlay = a.trackId.contains('overlay');
      final bIsOverlay = b.trackId.contains('overlay');
      if (aIsOverlay && !bIsOverlay) return -1;
      if (!aIsOverlay && bIsOverlay) return 1;
      return 0;
    });
    primaryVisual = visualClips.first;
  }

  Asset? primaryAsset;
  Clip? interpolatedVisual;
  if (primaryVisual != null) {
    final kfs = ref.watch(clipKeyframesProvider(primaryVisual.id)).value ?? [];
    interpolatedVisual =
        _interpolateClipProperties(primaryVisual, kfs, currentTime);

    if (primaryVisual.assetId != null) {
      final assetsAsync = ref.watch(projectAssetsProvider(projectId));
      final assets = assetsAsync.value ?? [];
      final matches = assets.where((a) => a.id == primaryVisual!.assetId);
      primaryAsset = matches.isNotEmpty ? matches.first : null;
    }
  }

  final interpolatedTexts = <Clip>[];
  for (final textClip in textClips) {
    final kfs = ref.watch(clipKeyframesProvider(textClip.id)).value ?? [];
    interpolatedTexts
        .add(_interpolateClipProperties(textClip, kfs, currentTime));
  }

  return TimelinePreviewItem(
    primaryVisualClip: interpolatedVisual,
    primaryVisualAsset: primaryAsset,
    activeTextClips: interpolatedTexts,
  );
});

// ─── Editor state ─────────────────────────────────────────────────────────────

enum WorkspaceLayout {
  classic,
  desktop,
  colorDesktop,
  audioDesktop,
  vfxDesktop,
  multicamDesktop,
}

const Object _noChange = Object();

class EditorState {
  final bool isPlaying;
  final int currentTimeMicros;
  final double timelineZoom;
  final String? selectedClipId;
  final String? selectedTrackId;
  final bool isScrubbing;
  final String activeTool;
  final bool showSafeArea;
  final bool snapEnabled;
  final WorkspaceLayout workspaceLayout;
  final bool linkedSelectionEnabled;
  final bool magneticTimelineEnabled;

  const EditorState({
    this.isPlaying = false,
    this.currentTimeMicros = 0,
    this.timelineZoom = 1.0,
    this.selectedClipId,
    this.selectedTrackId,
    this.isScrubbing = false,
    this.activeTool = 'media',
    this.showSafeArea = true,
    this.snapEnabled = true,
    this.workspaceLayout = WorkspaceLayout.classic,
    this.linkedSelectionEnabled = true,
    this.magneticTimelineEnabled = true,
  });

  EditorState copyWith({
    bool? isPlaying,
    int? currentTimeMicros,
    double? timelineZoom,
    Object? selectedClipId = _noChange,
    Object? selectedTrackId = _noChange,
    bool? isScrubbing,
    String? activeTool,
    bool? showSafeArea,
    bool? snapEnabled,
    WorkspaceLayout? workspaceLayout,
    bool? linkedSelectionEnabled,
    bool? magneticTimelineEnabled,
  }) {
    return EditorState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTimeMicros: currentTimeMicros ?? this.currentTimeMicros,
      timelineZoom: timelineZoom ?? this.timelineZoom,
      selectedClipId: selectedClipId == _noChange
          ? this.selectedClipId
          : selectedClipId as String?,
      selectedTrackId: selectedTrackId == _noChange
          ? this.selectedTrackId
          : selectedTrackId as String?,
      isScrubbing: isScrubbing ?? this.isScrubbing,
      activeTool: activeTool ?? this.activeTool,
      showSafeArea: showSafeArea ?? this.showSafeArea,
      snapEnabled: snapEnabled ?? this.snapEnabled,
      workspaceLayout: workspaceLayout ?? this.workspaceLayout,
      linkedSelectionEnabled: linkedSelectionEnabled ?? this.linkedSelectionEnabled,
      magneticTimelineEnabled: magneticTimelineEnabled ?? this.magneticTimelineEnabled,
    );
  }
}

final editorStateProvider =
    StateNotifierProvider<EditorStateNotifier, EditorState>((ref) {
  ref.watch(nativeProxyEventControllerProvider);
  ref.watch(nativeExportEventControllerProvider);

  return EditorStateNotifier(
    ref: ref,
    engine: ref.watch(nleEngineProvider),
    nativeBridge: ref.watch(nativeBridgeProvider),
    autosaveController: ref.watch(projectAutosaveControllerProvider),
    missingMediaService: ref.watch(missingMediaServiceProvider),
  );
});

class EditorStateNotifier extends StateNotifier<EditorState> {
  final Ref ref;
  final NleEngine engine;
  final NativeBridgeContract nativeBridge;
  final ProjectAutosaveController autosaveController;
  final MissingMediaService missingMediaService;
  StreamSubscription<NlePlaybackPosition>? _playbackSub;
  StreamSubscription<NativeEvent>? _nativeEventSub;
  String? _projectId;

  EditorStateNotifier({
    required this.ref,
    required this.engine,
    required this.nativeBridge,
    required this.autosaveController,
    required this.missingMediaService,
  }) : super(const EditorState()) {
    _playbackSub = engine.playbackStream.listen((event) {
      final wasPlaying = state.isPlaying;
      state = state.copyWith(
        isPlaying: event.isPlaying,
        currentTimeMicros: event.timelineMicros,
      );
      if (wasPlaying != event.isPlaying) {
        _handlePlaybackStateChange(event.isPlaying);
      }
    });

    // Also listen to native-clock playhead events so the Dart UI reflects
    // the 60fps Android clock ticks from NlePlaybackClock.
    _nativeEventSub = nativeBridge.events.listen((event) {
      final type = event.type;
      final wasPlaying = state.isPlaying;
      if (type == NativeEventTypes.playheadChanged) {
        final micros = (event.payload['playheadMicros'] as num?)?.toInt();
        final playing = event.payload['isPlaying'] as bool?;
        if (micros != null) {
          state = state.copyWith(
            currentTimeMicros: micros,
            isPlaying: playing ?? state.isPlaying,
          );
        }
      } else if (type == NativeEventTypes.playbackStarted) {
        state = state.copyWith(isPlaying: true);
      } else if (type == NativeEventTypes.playbackPaused ||
          type == NativeEventTypes.playbackEnded) {
        state = state.copyWith(isPlaying: false);
      }
      if (wasPlaying != state.isPlaying) {
        _handlePlaybackStateChange(state.isPlaying);
      }
    });
  }

  void _handlePlaybackStateChange(bool isPlaying) {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      final controller = ref.read(proxyControllerProvider(projectId).notifier);
      final settings = ref.read(proxyControllerProvider(projectId)).settings;

      if (settings.pauseProxyGenerationDuringPlayback) {
        if (isPlaying) {
          controller.stopQueue();
        } else {
          controller.startQueue();
        }
      }
    } catch (_) {}
  }

  Future<void> loadProject(String projectId) async {
    _projectId = projectId;
    await engine.loadProject(projectId);
    autosaveController.start(projectId);
    missingMediaService.checkProjectMedia(projectId).ignore();
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await engine.pause();
    } else {
      await engine.play();
    }
  }

  Future<void> pause() => engine.pause();
  Future<void> play() => engine.play();

  void toggleMagneticTimeline() {
    state = state.copyWith(magneticTimelineEnabled: !state.magneticTimelineEnabled);
  }

  Future<void> seekToTime(int micros) async {
    final safeMicros = micros.clamp(0, 1 << 62);
    state = state.copyWith(currentTimeMicros: safeMicros);
    await engine.seekTo(safeMicros);
  }

  Future<void> seekTo(int micros) async {
    final safeMicros = micros.clamp(0, 1 << 62);
    state = state.copyWith(currentTimeMicros: safeMicros);
    await engine.seekTo(safeMicros);
  }

  Future<void> seekForward(int micros) =>
      seekTo(state.currentTimeMicros + micros);

  Future<void> seekBackward(int micros) =>
      seekTo(state.currentTimeMicros - micros);

  void setZoom(double zoom) {
    state = state.copyWith(timelineZoom: zoom.clamp(0.2, 12.0));
  }

  void selectClip(String? clipId, String? trackId) {
    state = state.copyWith(selectedClipId: clipId, selectedTrackId: trackId);
  }

  void deselectClip() {
    state = state.copyWith(selectedClipId: null, selectedTrackId: null);
  }

  void toggleLinkedSelection() {
    state = state.copyWith(linkedSelectionEnabled: !state.linkedSelectionEnabled);
  }

  void setScrubbing(bool scrubbing) {
    state = state.copyWith(isScrubbing: scrubbing);
  }

  void setTool(String tool) {
    state = state.copyWith(activeTool: tool);
  }

  void toggleSafeArea() {
    state = state.copyWith(showSafeArea: !state.showSafeArea);
  }

  void toggleSnap() {
    state = state.copyWith(snapEnabled: !state.snapEnabled);
  }

  void toggleWorkspaceLayout() {
    state = state.copyWith(
      workspaceLayout: state.workspaceLayout == WorkspaceLayout.classic
          ? WorkspaceLayout.desktop
          : WorkspaceLayout.classic,
    );
  }

  void setWorkspaceLayout(WorkspaceLayout layout) {
    state = state.copyWith(workspaceLayout: layout);
  }

  /// Called by [PlayheadThrottleController] with already-throttled native
  /// playhead positions, so the 60 fps native clock doesn't rebuild the whole
  /// UI tree on every tick.
  void setNativePlayhead(int playheadMicros) {
    if (state.isPlaying) {
      state = state.copyWith(currentTimeMicros: playheadMicros);
    }
  }

  /// Restores editor state from a previously-saved [ProjectSessionState].
  /// Called by the recovery prompt flow when the user chooses to restore.
  Future<void> restoreSession(ProjectSessionState session) async {
    state = state.copyWith(
      currentTimeMicros: session.currentTimeMicros,
      selectedClipId: session.selectedClipId,
      selectedTrackId: session.selectedTrackId,
      activeTool: session.activeTool,
      timelineZoom: session.timelineZoom,
      showSafeArea: session.showSafeArea,
      snapEnabled: session.snapEnabled,
      isPlaying: false,
    );
    await seekTo(session.currentTimeMicros);
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    _nativeEventSub?.cancel();
    autosaveController.stop();
    super.dispose();
  }
}

// ─── Export state ─────────────────────────────────────────────────────────────

class ExportState {
  final bool isExporting;
  final int progress;
  final String stage;
  final String? error;
  final String? outputPath;
  final String? jobId;

  const ExportState({
    this.isExporting = false,
    this.progress = 0,
    this.stage = '',
    this.error,
    this.outputPath,
    this.jobId,
  });

  ExportState copyWith({
    bool? isExporting,
    int? progress,
    String? stage,
    Object? error = _noChange,
    Object? outputPath = _noChange,
    Object? jobId = _noChange,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      progress: progress ?? this.progress,
      stage: stage ?? this.stage,
      error: error == _noChange ? this.error : error as String?,
      outputPath:
          outputPath == _noChange ? this.outputPath : outputPath as String?,
      jobId: jobId == _noChange ? this.jobId : jobId as String?,
    );
  }
}

final exportStateProvider =
    StateNotifierProvider<ExportStateNotifier, ExportState>((ref) {
  return ExportStateNotifier(
    ref: ref,
    exportRepository: ref.watch(exportRepositoryProvider),
    temporaryExportService: ref.watch(temporaryExportServiceProvider),
    projectRepository: ref.watch(projectRepositoryProvider),
    monetizationService: ref.watch(monetizationServiceProvider),
  );
});

class ExportStateNotifier extends StateNotifier<ExportState> {
  final Ref ref;
  final ExportRepository exportRepository;
  final TemporaryExportService temporaryExportService;
  final ProjectRepository projectRepository;
  final MonetizationService monetizationService;

  ExportStateNotifier({
    required this.ref,
    required this.exportRepository,
    required this.temporaryExportService,
    required this.projectRepository,
    required this.monetizationService,
  }) : super(const ExportState());

  static const _uuid = Uuid();

  Future<void> startExport({
    required String projectId,
    required Map<String, dynamic> settings,
  }) async {
    if (state.isExporting) return;

    // Pause preview loops and save state before starting export
    await ref.read(editorStateProvider.notifier).pause();
    await ref.read(sourcePreviewControllerProvider(projectId).notifier).pause();
    await ref
        .read(editorAutosaveControllerProvider(projectId).notifier)
        .saveNow();

    try {
      final report =
          await ref.read(projectMultitrackQaReportProvider(projectId).future);
      ref.read(multitrackExportGateProvider).assertCanExport(report);
    } catch (e) {
      state = ExportState(
        isExporting: false,
        error: e.toString(),
        stage: 'Failed',
      );
      return;
    }

    final project = await projectRepository.getProject(projectId);
    final preset = settings['preset'] as String? ?? '1080p';
    final resolutionHeight = settings['resolution'] as int? ?? 1080;
    final bitrate = settings['bitrate'] as String? ?? '8M';

    int targetWidth = resolutionHeight * 16 ~/ 9;
    if (project != null) {
      if (project.aspectRatio == '9:16') {
        targetWidth = resolutionHeight * 9 ~/ 16;
      } else if (project.aspectRatio == '1:1') {
        targetWidth = resolutionHeight;
      } else if (project.aspectRatio == '4:5') {
        targetWidth = resolutionHeight * 4 ~/ 5;
      } else if (project.aspectRatio == '21:9') {
        targetWidth = resolutionHeight * 21 ~/ 9;
      }
    }
    targetWidth = (targetWidth ~/ 2) * 2; // Make even for encoders

    // Monetization check
    final removeWatermarkRequested = project != null && !project.hasWatermark;
    final decision = monetizationService.rules.checkExport(
      entitlement: monetizationService.current,
      width: targetWidth,
      height: resolutionHeight,
      removeWatermarkRequested: removeWatermarkRequested,
    );

    if (!decision.allowed) {
      state = ExportState(
        isExporting: false,
        error:
            decision.blockedReason ?? 'Export restricted by monetization plan.',
        stage: 'Failed',
      );
      return;
    }

    final jobId = _uuid.v4();
    state = ExportState(
      isExporting: true,
      progress: 0,
      stage: 'Preparing',
      jobId: jobId,
    );

    await exportRepository.insertExportJob(
      ExportJobsCompanion.insert(
        id: jobId,
        projectId: projectId,
        status: const Value('running'),
        progress: const Value(0),
        stage: const Value('Preparing'),
        settings: jsonEncode(settings),
      ),
    );

    try {
      await for (final progress
          in temporaryExportService.exportSimpleV1Sequence(
        projectId: projectId,
        targetWidth: targetWidth,
        targetHeight: resolutionHeight,
        frameRate: project?.targetFrameRate ?? 30,
        preset: preset,
        bitrate: bitrate,
      )) {
        state = state.copyWith(
          progress: progress.progress,
          stage: progress.stage,
          outputPath: progress.outputPath,
        );

        await exportRepository.updateExportJob(
          jobId,
          ExportJobsCompanion(
            progress: Value(progress.progress),
            stage: Value(progress.stage),
            outputPath: Value(progress.outputPath),
            status: Value(progress.progress >= 100 ? 'completed' : 'running'),
            completedAt: progress.progress >= 100
                ? Value(DateTime.now())
                : const Value.absent(),
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
        stage: 'Failed',
      );

      await exportRepository.updateExportJob(
        jobId,
        ExportJobsCompanion(
          status: const Value('failed'),
          errorMessage: Value(e.toString()),
          stage: const Value('Failed'),
        ),
      );

      return;
    }

    state = state.copyWith(
      isExporting: false,
      progress: 100,
      stage: 'Complete',
    );
  }

  Future<void> cancelExport() async {
    final jobId = state.jobId;
    state = state.copyWith(
      isExporting: false,
      progress: 0,
      stage: 'Cancelled',
    );

    if (jobId != null) {
      await exportRepository.updateExportJob(
        jobId,
        const ExportJobsCompanion(
          status: Value('cancelled'),
          stage: Value('Cancelled'),
        ),
      );
    }
  }
}

// ─── Lifecycle / Recovery ────────────────────────────────────────────────────

final projectSessionServiceProvider = Provider<ProjectSessionService>((ref) {
  return ProjectSessionService(
    projectStorageService: ref.watch(projectStorageServiceProvider),
  );
});

final recoverySnapshotDetectorProvider =
    Provider<RecoverySnapshotDetector>((ref) {
  return RecoverySnapshotDetector(
    projectStorageService: ref.watch(projectStorageServiceProvider),
    projectSessionService: ref.watch(projectSessionServiceProvider),
  );
});

final recoverySnapshotInfoProvider =
    FutureProvider.family<RecoverySnapshotInfo, String>((ref, projectId) {
  return ref.watch(recoverySnapshotDetectorProvider).inspectProject(projectId);
});

final interruptedJobRecoveryServiceProvider =
    Provider<InterruptedJobRecoveryService>((ref) {
  return InterruptedJobRecoveryService(
    jobQueueRepository: ref.watch(jobQueueRepositoryProvider),
    errorReportingService: ref.watch(errorReportingServiceProvider),
  );
});

final resumeProjectSafetyCheckServiceProvider =
    Provider<ResumeProjectSafetyCheckService>((ref) {
  return ResumeProjectSafetyCheckService(
    missingMediaService: ref.watch(missingMediaServiceProvider),
    permissionService: ref.watch(appPermissionServiceProvider),
    interruptedJobRecoveryService:
        ref.watch(interruptedJobRecoveryServiceProvider),
  );
});

final appLifecycleControllerProvider = Provider<AppLifecycleController>((ref) {
  final controller = AppLifecycleController(
    projectSessionService: ref.watch(projectSessionServiceProvider),
    autosaveController: ref.watch(projectAutosaveControllerProvider),
    nativeCommandService: ref.watch(nativeCommandServiceProvider),
    resumeSafetyCheckService:
        ref.watch(resumeProjectSafetyCheckServiceProvider),
    errorReportingService: ref.watch(errorReportingServiceProvider),
  );

  controller.start();
  ref.onDispose(controller.dispose);

  return controller;
});

// ─── Step 22: Diagnostics / QA / Health ──────────────────────────────────────

final engineHealthServiceProvider = Provider<EngineHealthService>((ref) {
  return EngineHealthService(
    bridge: ref.watch(nativeBridgeProvider),
  );
});

final renderGraphValidationServiceProvider =
    Provider<RenderGraphValidationService>((ref) {
  return RenderGraphValidationService(
    timelineRepository: ref.watch(timelineRepositoryProvider),
    assetRepository: ref.watch(mediaAssetRepositoryProvider),
  );
});

final exportReadinessCheckerProvider = Provider<ExportReadinessChecker>((ref) {
  return ExportReadinessChecker(
    validationService: ref.watch(renderGraphValidationServiceProvider),
    permissionService: ref.watch(appPermissionServiceProvider),
    assetRepository: ref.watch(mediaAssetRepositoryProvider),
  );
});

final projectRepairServiceProvider = Provider<ProjectRepairService>((ref) {
  return ProjectRepairService(
    timelineRepository: ref.watch(timelineRepositoryProvider),
    assetRepository: ref.watch(mediaAssetRepositoryProvider),
    transitionRepository: ref.watch(transitionRepositoryProvider),
  );
});

final debugLogServiceProvider = Provider<DebugLogService>((ref) {
  return DebugLogService(
    repository: ref.watch(errorLogRepositoryProvider),
  );
});

/// Live stream of timeline validation issues for the given project.
final timelineValidationReportProvider =
    FutureProvider.family<TimelineValidationReport, String>((ref, projectId) {
  return ref
      .watch(renderGraphValidationServiceProvider)
      .validateProject(projectId);
});

/// One-shot engine health check result.
final engineHealthReportProvider =
    FutureProvider<EngineHealthReport>((ref) async {
  return ref.watch(engineHealthServiceProvider).checkHealth();
});

final autoDuckingProvider = StateProvider<bool>((ref) => false);
