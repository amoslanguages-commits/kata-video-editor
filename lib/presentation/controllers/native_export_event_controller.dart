import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

/// Listens to native export events and synchronises the [ExportJobs] Drift
/// table with progress, output paths, and error states.
///
/// Lifecycle is managed by [nativeExportEventControllerProvider].
class NativeExportEventController {
  final NativeBridgeContract nativeBridge;
  final Ref ref;

  StreamSubscription<NativeEvent>? _subscription;

  NativeExportEventController({
    required this.nativeBridge,
    required this.ref,
  });

  void start() {
    _subscription ??= nativeBridge.events.listen(_handleEvent);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _handleEvent(NativeEvent event) async {
    switch (event.type) {
      case NativeEventTypes.exportStarted:
        await _handleStarted(event);
        break;
      case NativeEventTypes.exportProgress:
        await _handleProgress(event);
        break;
      case NativeEventTypes.exportPaused:
        await _handlePaused(event);
        break;
      case NativeEventTypes.exportResumed:
        await _handleResumed(event);
        break;
      case NativeEventTypes.exportCompleted:
        await _handleCompleted(event);
        break;
      case NativeEventTypes.exportFailed:
        await _handleFailed(event);
        break;
      case NativeEventTypes.exportCancelled:
        await _handleCancelled(event);
        break;
    }
  }

  Future<void> _handleStarted(NativeEvent event) async {
    final jobId = event.jobId;
    if (jobId == null) return;

    try {
      await ref.read(exportRepositoryProvider).updateExportJob(
            jobId,
            const ExportJobsCompanion(
              status: Value('running'),
              stage: Value('Preparing'),
              progress: Value(0),
            ),
          );
    } catch (e) {
      debugPrint('[NativeExportEventController] exportStarted error: $e');
    }
  }

  Future<void> _handleProgress(NativeEvent event) async {
    final jobId = event.jobId;
    if (jobId == null) return;

    final progress = (event.payload['progress'] as num?)?.toInt() ?? 0;
    final stage = event.payload['stage']?.toString() ?? 'Rendering';

    try {
      await ref.read(exportRepositoryProvider).updateExportJob(
            jobId,
            ExportJobsCompanion(
              status: const Value('running'),
              stage: Value(stage),
              progress: Value(progress.clamp(0, 99).toInt()),
            ),
          );
    } catch (e) {
      debugPrint('[NativeExportEventController] exportProgress error: $e');
    }
  }

  Future<void> _handlePaused(NativeEvent event) async {
    final jobId = event.jobId;
    if (jobId == null) return;

    try {
      await ref.read(exportRepositoryProvider).updateExportJob(
            jobId,
            const ExportJobsCompanion(
              status: Value('paused'),
              stage: Value('Paused'),
            ),
          );
    } catch (e) {
      debugPrint('[NativeExportEventController] exportPaused error: $e');
    }
  }

  Future<void> _handleResumed(NativeEvent event) async {
    final jobId = event.jobId;
    if (jobId == null) return;

    try {
      await ref.read(exportRepositoryProvider).updateExportJob(
            jobId,
            const ExportJobsCompanion(
              status: Value('running'),
              stage: Value('Resuming'),
            ),
          );
    } catch (e) {
      debugPrint('[NativeExportEventController] exportResumed error: $e');
    }
  }

  Future<void> _handleCompleted(NativeEvent event) async {
    final jobId = event.jobId;
    if (jobId == null) return;

    final result = _asMap(event.payload['result']);
    final outputPath = result['outputPath']?.toString() ??
        event.payload['outputPath']?.toString();

    try {
      if (outputPath == null || outputPath.trim().isEmpty) {
        await _markCompletionInvalid(jobId, 'Native export completed without an output path.');
        return;
      }

      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        await _markCompletionInvalid(jobId, 'Native export output file does not exist: $outputPath');
        return;
      }
      final fileSize = await outputFile.length();
      if (fileSize <= 0) {
        await _markCompletionInvalid(jobId, 'Native export output file is empty: $outputPath');
        return;
      }

      await ref.read(exportRepositoryProvider).updateExportJob(
            jobId,
            ExportJobsCompanion(
              status: const Value('completed'),
              stage: const Value('Complete'),
              progress: const Value(100),
              outputPath: Value(outputPath),
              completedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      debugPrint('[NativeExportEventController] exportCompleted error: $e');
      await _markCompletionInvalid(jobId, 'Export completion verification failed: $e');
    }
  }

  Future<void> _markCompletionInvalid(String jobId, String message) async {
    await ref.read(exportRepositoryProvider).updateExportJob(
          jobId,
          ExportJobsCompanion(
            status: const Value('failed'),
            stage: const Value('Failed'),
            errorMessage: Value(message),
            completedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _handleFailed(NativeEvent event) async {
    final jobId = event.jobId;
    if (jobId == null) return;

    final error = event.payload['errorMessage']?.toString() ?? 'Export failed';

    try {
      await ref.read(exportRepositoryProvider).updateExportJob(
            jobId,
            ExportJobsCompanion(
              status: const Value('failed'),
              stage: const Value('Failed'),
              errorMessage: Value(error),
              completedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      debugPrint('[NativeExportEventController] exportFailed error: $e');
    }
  }

  Future<void> _handleCancelled(NativeEvent event) async {
    final jobId = event.jobId;
    if (jobId == null) return;

    try {
      await ref.read(exportRepositoryProvider).updateExportJob(
            jobId,
            ExportJobsCompanion(
              status: const Value('cancelled'),
              stage: const Value('Cancelled'),
              completedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      debugPrint('[NativeExportEventController] exportCancelled error: $e');
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }
}
