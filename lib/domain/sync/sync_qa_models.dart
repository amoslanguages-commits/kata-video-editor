// ============================================================================
// 29D: Dart sync QA models
// Maps the payload returned by Android's NleSyncQaReport.toPayload()
// into typed Dart objects.
// ============================================================================

class SyncQaIssue {
  final String id;
  final String message;
  final String severity;

  const SyncQaIssue({
    required this.id,
    required this.message,
    required this.severity,
  });

  bool get isFail => severity == 'fail';
  bool get isWarning => severity == 'warning';

  factory SyncQaIssue.fromJson(Map<String, dynamic> json) {
    return SyncQaIssue(
      id:       json['id'] as String? ?? '',
      message:  json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'fail',
    );
  }
}

class SyncQaVideoTiming {
  final int totalFrames;
  final int droppedFrameCount;
  final int maxDriftUs;
  final bool passed;

  const SyncQaVideoTiming({
    required this.totalFrames,
    required this.droppedFrameCount,
    required this.maxDriftUs,
    required this.passed,
  });

  factory SyncQaVideoTiming.fromJson(Map<String, dynamic> json) {
    return SyncQaVideoTiming(
      totalFrames:       (json['totalFrames'] as num?)?.toInt() ?? 0,
      droppedFrameCount: (json['droppedFrameCount'] as num?)?.toInt() ?? 0,
      maxDriftUs:        (json['maxDriftUs'] as num?)?.toInt() ?? 0,
      passed:            json['passed'] as bool? ?? true,
    );
  }
}

class SyncQaAudioTiming {
  final int totalSamples;
  final int gapCount;
  final int maxGapUs;
  final bool passed;

  const SyncQaAudioTiming({
    required this.totalSamples,
    required this.gapCount,
    required this.maxGapUs,
    required this.passed,
  });

  factory SyncQaAudioTiming.fromJson(Map<String, dynamic> json) {
    return SyncQaAudioTiming(
      totalSamples: (json['totalSamples'] as num?)?.toInt() ?? 0,
      gapCount:     (json['gapCount'] as num?)?.toInt() ?? 0,
      maxGapUs:     (json['maxGapUs'] as num?)?.toInt() ?? 0,
      passed:       json['passed'] as bool? ?? true,
    );
  }
}

class SyncQaDrift {
  final int cumulativeDriftUs;
  final int sampleCount;
  final bool passed;

  const SyncQaDrift({
    required this.cumulativeDriftUs,
    required this.sampleCount,
    required this.passed,
  });

  factory SyncQaDrift.fromJson(Map<String, dynamic> json) {
    return SyncQaDrift(
      cumulativeDriftUs: (json['cumulativeDriftUs'] as num?)?.toInt() ?? 0,
      sampleCount:       (json['sampleCount'] as num?)?.toInt() ?? 0,
      passed:            json['passed'] as bool? ?? true,
    );
  }
}

class SyncQaReport {
  final String runId;
  final String context;
  final bool passed;
  final int issueCount;
  final List<SyncQaIssue> issues;
  final SyncQaVideoTiming? videoTiming;
  final SyncQaAudioTiming? audioTiming;
  final SyncQaDrift? drift;

  const SyncQaReport({
    required this.runId,
    required this.context,
    required this.passed,
    required this.issueCount,
    required this.issues,
    this.videoTiming,
    this.audioTiming,
    this.drift,
  });

  int get failCount => issues.where((i) => i.isFail).length;
  int get warningCount => issues.where((i) => i.isWarning).length;

  factory SyncQaReport.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'] as List<dynamic>? ?? [];
    final rawVideo  = json['videoTiming'] as Map<String, dynamic>?;
    final rawAudio  = json['audioTiming'] as Map<String, dynamic>?;
    final rawDrift  = json['drift'] as Map<String, dynamic>?;

    return SyncQaReport(
      runId:      json['runId'] as String? ?? '',
      context:    json['context'] as String? ?? '',
      passed:     json['passed'] as bool? ?? false,
      issueCount: (json['issueCount'] as num?)?.toInt() ?? 0,
      issues:     rawIssues
          .cast<Map<String, dynamic>>()
          .map(SyncQaIssue.fromJson)
          .toList(),
      videoTiming: rawVideo != null ? SyncQaVideoTiming.fromJson(rawVideo) : null,
      audioTiming: rawAudio != null ? SyncQaAudioTiming.fromJson(rawAudio) : null,
      drift:       rawDrift != null ? SyncQaDrift.fromJson(rawDrift) : null,
    );
  }
}
