import 'package:nle_editor/data/repositories/job_queue_repository.dart';
import 'package:nle_editor/domain/errors/app_error_mapper.dart';
import 'package:nle_editor/domain/services/error_reporting_service.dart';

/// On app resume or startup, any background jobs that were still in 'running',
/// 'waiting', or 'paused' state are dead — the native process was killed.
/// This service marks them as 'failed' with a clear explanation and optionally
/// logs an error so the user sees a snackbar / error badge.
class InterruptedJobRecoveryService {
  final JobQueueRepository jobQueueRepository;
  final ErrorReportingService errorReportingService;

  InterruptedJobRecoveryService({
    required this.jobQueueRepository,
    required this.errorReportingService,
  });

  Future<int> markInterruptedJobs({
    String? projectId,
    bool notify = false,
  }) async {
    final interrupted = await jobQueueRepository.getInterruptedJobs(
      projectId: projectId,
    );

    if (interrupted.isEmpty) return 0;

    final count = await jobQueueRepository.markInterruptedJobs(
      projectId: projectId,
    );

    if (notify && count > 0) {
      await errorReportingService.report(
        AppErrorMapper.exportFailed(
          projectId: projectId,
          source: 'interrupted_job_recovery',
          technicalMessage:
              '$count background job(s) were interrupted while the app was inactive.',
          context: {
            'interruptedJobs': interrupted
                .map(
                  (job) => {
                    'id': job.id,
                    'type': job.jobType,
                    'status': job.status,
                    'stage': job.stage,
                  },
                )
                .toList(),
          },
        ),
        notify: false,
      );
    }

    return count;
  }
}
