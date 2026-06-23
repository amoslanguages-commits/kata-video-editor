import 'package:uuid/uuid.dart';

// ─── Severity ──────────────────────────────────────────────────────────────────

class TimelineIssueSeverity {
  TimelineIssueSeverity._();

  static const String info = 'info';
  static const String warning = 'warning';
  static const String error = 'error';
  static const String critical = 'critical';
}

// ─── Category ──────────────────────────────────────────────────────────────────

class TimelineIssueCategory {
  TimelineIssueCategory._();

  static const String project = 'project';
  static const String media = 'media';
  static const String timeline = 'timeline';
  static const String renderGraph = 'render_graph';
  static const String transition = 'transition';
  static const String text = 'text';
  static const String audio = 'audio';
  static const String export = 'export';
  static const String storage = 'storage';
  static const String permission = 'permission';
  static const String nativeEngine = 'native_engine';
}

// ─── Action IDs ────────────────────────────────────────────────────────────────

class TimelineIssueActionId {
  TimelineIssueActionId._();

  static const String reconnectMedia = 'reconnect_media';
  static const String removeClip = 'remove_clip';
  static const String repairTiming = 'repair_timing';
  static const String generateProxy = 'generate_proxy';
  static const String openSettings = 'open_settings';
  static const String clearCache = 'clear_cache';
  static const String freeStorage = 'free_storage';
  static const String grantPermission = 'grant_permission';
  static const String reinitEngine = 'reinit_engine';
  static const String repairTransition = 'repair_transition';
  static const String repairKeyframes = 'repair_keyframes';
  static const String repairClipBounds = 'repair_clip_bounds';
  static const String dismiss = 'dismiss';
}

// ─── Action ────────────────────────────────────────────────────────────────────

class TimelineIssueAction {
  final String label;
  final String actionId;
  final Map<String, dynamic> payload;

  const TimelineIssueAction({
    required this.label,
    required this.actionId,
    this.payload = const {},
  });
}

// ─── Issue ─────────────────────────────────────────────────────────────────────

class TimelineIssue {
  final String id;
  final String severity;
  final String category;
  final String title;
  final String description;
  final TimelineIssueAction? action;
  final String? clipId;
  final String? trackId;
  final String? assetId;
  final DateTime detectedAt;

  TimelineIssue({
    String? id,
    required this.severity,
    required this.category,
    required this.title,
    required this.description,
    this.action,
    this.clipId,
    this.trackId,
    this.assetId,
    DateTime? detectedAt,
  })  : id = id ?? const Uuid().v4(),
        detectedAt = detectedAt ?? DateTime.now();

  bool get isCritical => severity == TimelineIssueSeverity.critical;
  bool get isError => severity == TimelineIssueSeverity.error;
  bool get isWarning => severity == TimelineIssueSeverity.warning;
  bool get isInfo => severity == TimelineIssueSeverity.info;
  bool get isActionable => action != null;
}

// ─── Validation Report ─────────────────────────────────────────────────────────

class TimelineValidationReport {
  final String projectId;
  final List<TimelineIssue> issues;
  final DateTime generatedAt;

  const TimelineValidationReport({
    required this.projectId,
    required this.issues,
    required this.generatedAt,
  });

  int get criticalCount =>
      issues.where((i) => i.severity == TimelineIssueSeverity.critical).length;
  int get errorCount =>
      issues.where((i) => i.severity == TimelineIssueSeverity.error).length;
  int get warningCount =>
      issues.where((i) => i.severity == TimelineIssueSeverity.warning).length;
  int get infoCount =>
      issues.where((i) => i.severity == TimelineIssueSeverity.info).length;

  bool get isEmpty => issues.isEmpty;
  bool get hasBlockingIssues => criticalCount > 0 || errorCount > 0;

  String get summaryText {
    if (isEmpty) return 'No issues found';
    final parts = <String>[];
    if (criticalCount > 0) parts.add('$criticalCount critical');
    if (errorCount > 0) parts.add('$errorCount error${errorCount > 1 ? 's' : ''}');
    if (warningCount > 0) parts.add('$warningCount warning${warningCount > 1 ? 's' : ''}');
    if (infoCount > 0) parts.add('$infoCount info');
    return parts.join(' • ');
  }
}

// ─── Engine Health ─────────────────────────────────────────────────────────────

class EngineHealthStatus {
  EngineHealthStatus._();

  static const String healthy = 'healthy';
  static const String degraded = 'degraded';
  static const String offline = 'offline';
  static const String unknown = 'unknown';
}

class EngineHealthReport {
  final String status;
  final bool methodChannelReachable;
  final bool eventChannelActive;
  final bool sessionActive;
  final int activeSessionCount;
  final String? errorMessage;
  final DateTime checkedAt;

  const EngineHealthReport({
    required this.status,
    required this.methodChannelReachable,
    required this.eventChannelActive,
    required this.sessionActive,
    required this.activeSessionCount,
    this.errorMessage,
    required this.checkedAt,
  });

  bool get isHealthy => status == EngineHealthStatus.healthy;
  bool get isDegraded => status == EngineHealthStatus.degraded;
  bool get isOffline => status == EngineHealthStatus.offline;

  factory EngineHealthReport.unknown() => EngineHealthReport(
        status: EngineHealthStatus.unknown,
        methodChannelReachable: false,
        eventChannelActive: false,
        sessionActive: false,
        activeSessionCount: 0,
        checkedAt: DateTime.now(),
      );
}

// ─── Export Readiness ──────────────────────────────────────────────────────────

class ExportReadinessReport {
  final bool ready;
  final List<TimelineIssue> blockingIssues;
  final List<TimelineIssue> warnings;
  final int estimatedOutputBytes;
  final int availableStorageBytes;

  const ExportReadinessReport({
    required this.ready,
    required this.blockingIssues,
    required this.warnings,
    required this.estimatedOutputBytes,
    required this.availableStorageBytes,
  });

  bool get hasEnoughStorage => availableStorageBytes > estimatedOutputBytes;
}
