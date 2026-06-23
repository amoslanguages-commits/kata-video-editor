import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/proxy_repository.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/proxy/proxy_cleanup_service.dart';
import 'package:nle_editor/domain/proxy/proxy_generation_service.dart';
import 'package:nle_editor/domain/proxy/proxy_job_models.dart';
import 'package:nle_editor/domain/proxy/proxy_queue_runner.dart';
import 'package:nle_editor/domain/proxy/proxy_settings_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class ProxyEditorState {
  final bool loading;
  final bool running;
  final NleProjectProxySettings settings;
  final List<NleProxyJob> jobs;
  final List<NleMediaAsset> assets;
  final String? selectedAssetId;
  final String? message;
  final String? error;

  const ProxyEditorState({
    required this.loading,
    required this.running,
    required this.settings,
    required this.jobs,
    required this.assets,
    this.selectedAssetId,
    this.message,
    this.error,
  });

  const ProxyEditorState.initial()
      : loading = true,
        running = false,
        settings = const NleProjectProxySettings.defaults(),
        jobs = const [],
        assets = const [],
        selectedAssetId = null,
        message = null,
        error = null;

  ProxyEditorState copyWith({
    bool? loading,
    bool? running,
    NleProjectProxySettings? settings,
    List<NleProxyJob>? jobs,
    List<NleMediaAsset>? assets,
    String? selectedAssetId,
    String? message,
    String? error,
  }) {
    return ProxyEditorState(
      loading: loading ?? this.loading,
      running: running ?? this.running,
      settings: settings ?? this.settings,
      jobs: jobs ?? this.jobs,
      assets: assets ?? this.assets,
      selectedAssetId: selectedAssetId ?? this.selectedAssetId,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }
}

class ProxyController extends StateNotifier<ProxyEditorState> {
  final String projectId;
  final ProxyRepository proxyRepository;
  final MediaAssetRepository mediaRepository;
  final ProxyQueueRunner queueRunner;
  final ProxyGenerationService generationService;
  final ProxyCleanupService cleanupService;

  ProxyController({
    required this.projectId,
    required this.proxyRepository,
    required this.mediaRepository,
    required this.queueRunner,
    required this.generationService,
    required this.cleanupService,
  }) : super(const ProxyEditorState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final settings = await proxyRepository.getSettings(projectId);
      final jobs = await proxyRepository.getJobs(projectId);
      final assets = await mediaRepository.getAssets(projectId);

      state = state.copyWith(
        loading: false,
        settings: settings,
        jobs: jobs,
        assets: assets,
        running: queueRunner.running,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> updateSettings(NleProjectProxySettings settings) async {
    state = state.copyWith(settings: settings);
    await proxyRepository.saveSettings(projectId: projectId, settings: settings);
    await load();
  }

  Future<void> toggleProxyPreview(bool enabled) async {
    await updateSettings(state.settings.copyWith(enabled: enabled));
  }

  Future<void> updateResolutionPreset(NleProxyResolutionPreset preset) async {
    await updateSettings(state.settings.copyWith(resolutionPreset: preset));
  }

  Future<void> updateStoragePolicy(NleProxyStoragePolicy policy) async {
    await updateSettings(state.settings.copyWith(storagePolicy: policy));
  }

  Future<void> updateAutoGenerate(bool autoGenerate) async {
    await updateSettings(state.settings.copyWith(autoGenerateOnImport: autoGenerate));
  }

  Future<void> togglePauseOnPlayback(bool pause) async {
    await updateSettings(state.settings.copyWith(pauseProxyGenerationDuringPlayback: pause));
  }

  Future<void> generateProxyManual(String assetId) async {
    final asset = state.assets.firstWhere((a) => a.id == assetId);
    await generationService.queueManualProxy(asset);
    await load();
    startQueue();
  }

  Future<void> cancelJob(String jobId) async {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    await proxyRepository.cancelJob(job);
    await load();
  }

  Future<void> retryJob(String jobId) async {
    final job = state.jobs.firstWhere((j) => j.id == jobId);
    await proxyRepository.retryJob(job);
    await load();
    startQueue();
  }

  Future<void> startQueue() async {
    if (queueRunner.running) return;
    state = state.copyWith(running: true);
    await queueRunner.run(
      projectId: projectId,
      onProgress: () {
        load();
      },
    );
    state = state.copyWith(running: queueRunner.running);
  }

  void stopQueue() {
    queueRunner.requestCancel();
    state = state.copyWith(running: false);
  }

  Future<void> deleteAllProxies() async {
    stopQueue();
    state = state.copyWith(loading: true);
    final result = await cleanupService.deleteAllProxies(projectId);
    await load();
    state = state.copyWith(
      loading: false,
      message: 'Deleted ${result.deletedProxyCount} proxies, freed ${(result.freedBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
    );
  }

  Future<void> deleteUnusedProxies() async {
    stopQueue();
    state = state.copyWith(loading: true);
    final result = await cleanupService.deleteUnusedProxies(projectId);
    await load();
    state = state.copyWith(
      loading: false,
      message: 'Deleted ${result.deletedProxyCount} unused proxies, freed ${(result.freedBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
    );
  }

  void selectAsset(String? assetId) {
    state = state.copyWith(selectedAssetId: assetId);
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }
}
