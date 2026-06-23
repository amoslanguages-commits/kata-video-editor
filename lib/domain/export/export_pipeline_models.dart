import 'package:nle_editor/data/database/app_database.dart';

/// Lightweight UI/domain model for the professional export queue panel.
///
/// This intentionally wraps the existing Drift ExportJob table instead of
/// introducing a new table, so it can be added safely before the next schema
/// migration.
class NleExportQueueSummary {
  final int totalJobs;
  final int runningJobs;
  final int completedJobs;
  final int failedJobs;
  final int cancelledJobs;
  final int pausedJobs;
  final ExportJob? latestJob;

  const NleExportQueueSummary({
    required this.totalJobs,
    required this.runningJobs,
    required this.completedJobs,
    required this.failedJobs,
    required this.cancelledJobs,
    required this.pausedJobs,
    required this.latestJob,
  });

  factory NleExportQueueSummary.fromJobs(List<ExportJob> jobs) {
    var running = 0;
    var completed = 0;
    var failed = 0;
    var cancelled = 0;
    var paused = 0;

    for (final job in jobs) {
      final status = job.status.toLowerCase();
      if (status == 'running' || status == 'pending' || status == 'queued') {
        running++;
      } else if (status == 'completed' || status == 'done' || status == 'success') {
        completed++;
      } else if (status == 'failed' || status == 'error') {
        failed++;
      } else if (status == 'cancelled' || status == 'canceled') {
        cancelled++;
      } else if (status == 'paused') {
        paused++;
      }
    }

    final sorted = [...jobs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return NleExportQueueSummary(
      totalJobs: jobs.length,
      runningJobs: running,
      completedJobs: completed,
      failedJobs: failed,
      cancelledJobs: cancelled,
      pausedJobs: paused,
      latestJob: sorted.isEmpty ? null : sorted.first,
    );
  }

  bool get hasActiveJobs => runningJobs > 0 || pausedJobs > 0;
}

class NleExportJobViewModel {
  final ExportJob job;
  final Map<String, dynamic> settings;

  const NleExportJobViewModel({
    required this.job,
    required this.settings,
  });

  String get presetName {
    final friendly = settings['presetName']?.toString().trim();
    if (friendly != null && friendly.isNotEmpty) return friendly;
    final raw = settings['preset']?.toString().trim();
    if (raw == null || raw.isEmpty) return 'Custom';
    return raw
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get resolutionLabel {
    final width = settings['width'];
    final resolution = settings['resolution'];
    if (width != null && resolution != null) return '${width}x$resolution';
    if (resolution == null) return 'Project resolution';
    return '${resolution}p';
  }

  String get bitrateLabel {
    final bitrate = settings['bitrate'];
    if (bitrate == null) return 'Auto bitrate';
    return bitrate.toString();
  }

  bool get isActive {
    final status = job.status.toLowerCase();
    return status == 'running' || status == 'pending' || status == 'queued';
  }

  bool get isPaused => job.status.toLowerCase() == 'paused';

  bool get isFailed {
    final status = job.status.toLowerCase();
    return status == 'failed' || status == 'error';
  }

  bool get isCompleted {
    final status = job.status.toLowerCase();
    return status == 'completed' || status == 'done' || status == 'success';
  }
}
