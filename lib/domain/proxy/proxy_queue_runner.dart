import 'dart:async';

import 'package:nle_editor/data/repositories/proxy_repository.dart';
import 'package:nle_editor/platform/proxy/native_proxy_generator_service.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class ProxyQueueRunner {
  final ProxyRepository repository;
  final NativeProxyGeneratorService nativeGenerator;

  bool _running = false;
  bool _cancelRequested = false;

  ProxyQueueRunner({
    required this.repository,
    this.nativeGenerator = const NativeProxyGeneratorService(),
  });

  bool get running => _running;

  Future<void> run({
    required String projectId,
    void Function()? onProgress,
  }) async {
    if (_running) return;

    _running = true;
    _cancelRequested = false;

    try {
      while (!_cancelRequested) {
        final jobs = await repository.getRunnableJobs(projectId);
        if (jobs.isEmpty) break;

        final job = jobs.first;

        try {
          await repository.markGenerating(job);

          final result = await nativeGenerator.generate(
            jobId: job.id,
            sourcePath: job.sourcePath,
            outputPath: job.outputPath,
            spec: job.spec,
          );

          await repository.markReady(
            job: job,
            metadata: result.toMetadata(),
          );

          onProgress?.call();
        } catch (error) {
          if (_cancelRequested) {
            await repository.cancelJob(job);
          } else {
            await repository.markFailed(
              job: job,
              error: error.toString(),
            );
          }

          onProgress?.call();
        }

        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    } finally {
      _running = false;
    }
  }

  void requestCancel() {
    _cancelRequested = true;
  }
}
