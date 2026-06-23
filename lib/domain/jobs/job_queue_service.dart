import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/job_queue_repository.dart';
import 'package:nle_editor/domain/jobs/job_types.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

class JobQueueService {
  final JobQueueRepository jobRepository;
  final NativeBridgeContract nativeBridge;

  StreamSubscription<NativeEvent>? _eventSub;
  Timer? _pumpTimer;

  bool _isPumping = false;

  static const _uuid = Uuid();

  JobQueueService({
    required this.jobRepository,
    required this.nativeBridge,
  });

  void start() {
    _eventSub ??= nativeBridge.events.listen(_handleNativeEvent);

    _pumpTimer ??= Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => pumpQueue(),
    );

    pumpQueue();
  }

  void dispose() {
    _eventSub?.cancel();
    _eventSub = null;

    _pumpTimer?.cancel();
    _pumpTimer = null;
  }

  Future<String> enqueueJob({
    required String? projectId,
    required String jobType,
    required Map<String, dynamic> payload,
    int priority = 50,
  }) async {
    final jobId = _uuid.v4();
    await jobRepository.insertJob(
      BackgroundJobsCompanion.insert(
        id: jobId,
        projectId: Value(projectId),
        jobType: jobType,
        payload: Value(jsonEncode(payload)),
        priority: Value(priority),
        status: const Value(JobStatus.queued),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    pumpQueue();
    return jobId;
  }

  Future<void> cancelJob(String jobId) async {
    final job = await jobRepository.getJob(jobId);
    if (job == null) return;

    await jobRepository.cancelJob(jobId);

    if (job.status == JobStatus.running && job.projectId != null) {
      await nativeBridge.cancelJob(
        projectId: job.projectId!,
        jobId: jobId,
      );
    }
    pumpQueue();
  }

  Future<void> pumpQueue() async {
    if (_isPumping) return;
    _isPumping = true;

    try {
      final active = await jobRepository.watchActiveJobs().first;
      final runningCount = active.where((j) => j.status == JobStatus.running).length;

      if (runningCount >= 1) {
        return;
      }

      final nextJob = await jobRepository.getNextQueuedJob();
      if (nextJob == null) return;

      await jobRepository.updateJobFields(
        nextJob.id,
        BackgroundJobsCompanion(
          status: const Value(JobStatus.running),
          startedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final payloadMap = jsonDecode(nextJob.payload) as Map<String, dynamic>;

      if (nextJob.projectId != null) {
        await nativeBridge.startJob(
          projectId: nextJob.projectId!,
          jobId: nextJob.id,
          jobType: nextJob.jobType,
          payload: payloadMap,
        );
      } else {
        await jobRepository.updateJobFields(
          nextJob.id,
          BackgroundJobsCompanion(
            status: const Value(JobStatus.completed),
            progress: const Value(100),
            stage: const Value('Complete'),
            finishedAt: Value(DateTime.now()),
          ),
        );
      }
    } catch (_) {
      // Intentionally suppressed for background pump resilience
    } finally {
      _isPumping = false;
    }
  }

  void _handleNativeEvent(NativeEvent event) async {
    final jobId = event.jobId;
    if (jobId == null) return;

    switch (event.type) {
      case NativeEventTypes.jobStarted:
        await jobRepository.updateJobFields(
          jobId,
          BackgroundJobsCompanion(
            status: const Value(JobStatus.running),
            stage: Value(event.payload['stage'] as String? ?? 'Running'),
            progress: Value(event.payload['progress'] as int? ?? 0),
          ),
        );
        break;

      case NativeEventTypes.jobProgress:
        await jobRepository.updateJobFields(
          jobId,
          BackgroundJobsCompanion(
            stage: Value(event.payload['stage'] as String? ?? 'Running'),
            progress: Value(event.payload['progress'] as int? ?? 0),
          ),
        );
        break;

      case NativeEventTypes.jobCompleted:
        await jobRepository.updateJobFields(
          jobId,
          BackgroundJobsCompanion(
            status: const Value(JobStatus.completed),
            stage: const Value('Complete'),
            progress: const Value(100),
            result: Value(jsonEncode(event.payload['result'] ?? {})),
            finishedAt: Value(DateTime.now()),
          ),
        );
        pumpQueue();
        break;

      case NativeEventTypes.jobFailed:
        await jobRepository.updateJobFields(
          jobId,
          BackgroundJobsCompanion(
            status: const Value(JobStatus.failed),
            stage: const Value('Failed'),
            errorMessage: Value(event.payload['error'] as String? ?? 'Unknown error'),
            finishedAt: Value(DateTime.now()),
          ),
        );
        pumpQueue();
        break;

      case NativeEventTypes.jobCancelled:
        await jobRepository.updateJobFields(
          jobId,
          BackgroundJobsCompanion(
            status: const Value(JobStatus.cancelled),
            stage: const Value('Cancelled'),
            finishedAt: Value(DateTime.now()),
          ),
        );
        pumpQueue();
        break;
    }
  }
}
