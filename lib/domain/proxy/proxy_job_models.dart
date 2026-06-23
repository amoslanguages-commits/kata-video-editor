import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class NleProxyJob {
  final String id;
  final String projectId;
  final String assetId;

  final String sourcePath;
  final String outputPath;

  final NleProxyGenerationStatus status;
  final NleProxyGenerationReason reason;
  final NleProxyJobPriority priority;
  final NleProxyVideoSpec spec;

  final double progress;
  final String? error;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int retryCount;
  final int version;

  const NleProxyJob({
    required this.id,
    required this.projectId,
    required this.assetId,
    required this.sourcePath,
    required this.outputPath,
    required this.status,
    required this.reason,
    required this.priority,
    required this.spec,
    required this.progress,
    this.error,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    required this.retryCount,
    required this.version,
  });

  bool get canRun {
    return status == NleProxyGenerationStatus.queued ||
        status == NleProxyGenerationStatus.failed;
  }

  bool get running => status == NleProxyGenerationStatus.generating;
  bool get done => status == NleProxyGenerationStatus.ready;
  bool get failed => status == NleProxyGenerationStatus.failed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'assetId': assetId,
      'sourcePath': sourcePath,
      'outputPath': outputPath,
      'status': status.name,
      'reason': reason.name,
      'priority': priority.name,
      'spec': spec.toJson(),
      'progress': progress,
      'error': error,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'retryCount': retryCount,
      'version': version,
    };
  }

  factory NleProxyJob.fromJson(Map<String, dynamic> json) {
    return NleProxyJob(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      assetId: json['assetId']?.toString() ?? '',
      sourcePath: json['sourcePath']?.toString() ?? '',
      outputPath: json['outputPath']?.toString() ?? '',
      status: _enumByName(
        NleProxyGenerationStatus.values,
        json['status'],
        NleProxyGenerationStatus.queued,
      ),
      reason: _enumByName(
        NleProxyGenerationReason.values,
        json['reason'],
        NleProxyGenerationReason.manual,
      ),
      priority: _enumByName(
        NleProxyJobPriority.values,
        json['priority'],
        NleProxyJobPriority.normal,
      ),
      spec: NleProxyVideoSpec.fromJson(
        Map<String, dynamic>.from(json['spec'] as Map? ?? const {}),
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      error: json['error']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleProxyJob copyWith({
    NleProxyGenerationStatus? status,
    double? progress,
    String? error,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? retryCount,
    int? version,
  }) {
    return NleProxyJob(
      id: id,
      projectId: projectId,
      assetId: assetId,
      sourcePath: sourcePath,
      outputPath: outputPath,
      status: status ?? this.status,
      reason: reason,
      priority: priority,
      spec: spec,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      retryCount: retryCount ?? this.retryCount,
      version: version ?? this.version,
    );
  }
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? name,
  T fallback,
) {
  final string = name?.toString();
  if (string == null) return fallback;

  for (final value in values) {
    if (value.name == string) return value;
  }

  return fallback;
}
