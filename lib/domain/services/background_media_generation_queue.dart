import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nle_editor/data/repositories/asset_repository.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/services/thumbnail_service.dart';
import 'package:nle_editor/domain/services/waveform_service.dart';
import 'package:drift/drift.dart';

class GenerationTask {
  final String assetId;
  final Future<void> Function() run;

  GenerationTask({
    required this.assetId,
    required this.run,
  });
}

class BackgroundMediaGenerationQueue {
  final ThumbnailService _thumbnailService;
  final WaveformService _waveformService;
  final AssetRepository _assetRepository;

  final List<GenerationTask> _queue = [];
  bool _isProcessing = false;
  final Set<String> _cancelledAssetIds = {};

  BackgroundMediaGenerationQueue(
    this._thumbnailService,
    this._waveformService,
    this._assetRepository,
  );

  /// Queues waveform generation for an asset
  void queueWaveform({
    required String assetId,
    required String sourcePath,
    required String outputDirectory,
  }) {
    _cancelledAssetIds.remove(assetId);
    _queue.add(
      GenerationTask(
        assetId: assetId,
        run: () => _processWaveform(assetId, sourcePath, outputDirectory),
      ),
    );
    _processNext();
  }

  /// Queues thumbnail strip generation (multiple timestamps)
  void queueThumbnailStrip({
    required String assetId,
    required String sourcePath,
    required String outputDirectory,
    required int durationMicros,
  }) {
    _cancelledAssetIds.remove(assetId);
    _queue.add(
      GenerationTask(
        assetId: assetId,
        run: () => _processThumbnailStrip(assetId, sourcePath, outputDirectory, durationMicros),
      ),
    );
    _processNext();
  }

  /// Cancels any pending or active tasks for the asset ID
  void cancelForAsset(String assetId) {
    _cancelledAssetIds.add(assetId);
    _queue.removeWhere((task) => task.assetId == assetId);
  }

  /// Cancels all tasks
  void cancelAll() {
    _queue.clear();
    _isProcessing = false;
  }

  Future<void> _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    final task = _queue.removeAt(0);

    if (!_cancelledAssetIds.contains(task.assetId)) {
      try {
        await task.run();
      } catch (e) {
        debugPrint('Generation task failed: $e');
      }
    }

    _isProcessing = false;
    _processNext();
  }

  Future<void> _processWaveform(
    String assetId,
    String sourcePath,
    String outputDirectory,
  ) async {
    await _assetRepository.updateAssetFields(
      assetId,
      const AssetsCompanion(waveformStatus: Value('generating')),
    );

    final path = await _waveformService.generateWaveform(
      sourcePath: sourcePath,
      outputDirectory: outputDirectory,
      assetId: assetId,
    );

    if (_cancelledAssetIds.contains(assetId)) return;

    await _assetRepository.updateAssetFields(
      assetId,
      AssetsCompanion(
        waveformPath: Value(path),
        waveformStatus: Value(path == null ? 'failed' : 'ready'),
      ),
    );
  }

  Future<void> _processThumbnailStrip(
    String assetId,
    String sourcePath,
    String outputDirectory,
    int durationMicros,
  ) async {
    await _assetRepository.updateAssetFields(
      assetId,
      const AssetsCompanion(thumbnailStatus: Value('generating')),
    );

    // Calculate timestamps (ms) for the thumbnail strip
    // Generate one thumbnail every 2 seconds, minimum 3, maximum 10
    final durationMs = durationMicros ~/ 1000;
    final intervalMs = 2000;
    final timestamps = <int>[];

    if (durationMs <= intervalMs) {
      timestamps.addAll([0, durationMs ~/ 2, durationMs]);
    } else {
      int time = 0;
      while (time < durationMs && timestamps.length < 10) {
        timestamps.add(time);
        time += intervalMs;
      }
      if (timestamps.last != durationMs && timestamps.length < 10) {
        timestamps.add(durationMs);
      }
    }

    String? primaryPath;
    bool success = true;

    for (final timeMs in timestamps) {
      if (_cancelledAssetIds.contains(assetId)) return;

      final path = await _thumbnailService.generateThumbnail(
        sourcePath: sourcePath,
        outputDirectory: outputDirectory,
        assetId: assetId,
        fileType: 'video',
        timeMs: timeMs,
      );

      if (path == null) {
        success = false;
      } else if (timeMs == 0) {
        primaryPath = path;
      }
    }

    if (_cancelledAssetIds.contains(assetId)) return;

    await _assetRepository.updateAssetFields(
      assetId,
      AssetsCompanion(
        thumbnailPath: Value(primaryPath),
        thumbnailStatus: Value(success ? 'ready' : 'failed'),
      ),
    );
  }
}
