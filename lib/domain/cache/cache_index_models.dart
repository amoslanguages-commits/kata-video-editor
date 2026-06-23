class CacheEntryKind {
  static const proxy = 'proxy';
  static const thumbnail = 'thumbnail';
  static const timelineThumbnail = 'timeline_thumbnail';
  static const waveform = 'waveform';
  static const temp = 'temp';
  static const autosave = 'autosave';
  static const export = 'export';
  static const other = 'other';
}

class CacheIndexEntry {
  final String id;
  final String projectId;
  final String? assetId;
  final String kind;
  final String path;
  final int bytes;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime lastAccessedAt;
  final bool exists;
  final bool pinned;
  final bool referencedByDatabase;
  final Map<String, dynamic> metadata;

  const CacheIndexEntry({
    required this.id,
    required this.projectId,
    required this.assetId,
    required this.kind,
    required this.path,
    required this.bytes,
    required this.createdAt,
    required this.modifiedAt,
    required this.lastAccessedAt,
    required this.exists,
    required this.pinned,
    required this.referencedByDatabase,
    this.metadata = const {},
  });

  CacheIndexEntry copyWith({
    int? bytes,
    DateTime? modifiedAt,
    DateTime? lastAccessedAt,
    bool? exists,
    bool? pinned,
    bool? referencedByDatabase,
    Map<String, dynamic>? metadata,
  }) {
    return CacheIndexEntry(
      id: id,
      projectId: projectId,
      assetId: assetId,
      kind: kind,
      path: path,
      bytes: bytes ?? this.bytes,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      exists: exists ?? this.exists,
      pinned: pinned ?? this.pinned,
      referencedByDatabase: referencedByDatabase ?? this.referencedByDatabase,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'assetId': assetId,
        'kind': kind,
        'path': path,
        'bytes': bytes,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
        'exists': exists,
        'pinned': pinned,
        'referencedByDatabase': referencedByDatabase,
        'metadata': metadata,
      };

  factory CacheIndexEntry.fromJson(Map<String, dynamic> json) {
    DateTime date(String key) => DateTime.tryParse(json[key]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return CacheIndexEntry(
      id: json['id'].toString(),
      projectId: json['projectId'].toString(),
      assetId: json['assetId']?.toString(),
      kind: json['kind']?.toString() ?? CacheEntryKind.other,
      path: json['path'].toString(),
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      createdAt: date('createdAt'),
      modifiedAt: date('modifiedAt'),
      lastAccessedAt: date('lastAccessedAt'),
      exists: json['exists'] == true,
      pinned: json['pinned'] == true,
      referencedByDatabase: json['referencedByDatabase'] == true,
      metadata: (json['metadata'] as Map?)?.map((key, value) => MapEntry(key.toString(), value)) ?? const {},
    );
  }
}

class CacheIndexSnapshot {
  final String projectId;
  final DateTime generatedAt;
  final List<CacheIndexEntry> entries;

  const CacheIndexSnapshot({
    required this.projectId,
    required this.generatedAt,
    required this.entries,
  });

  int get totalBytes => entries.fold<int>(0, (sum, entry) => sum + entry.bytes);
  int get totalFiles => entries.where((entry) => entry.exists).length;

  int bytesForKind(String kind) => entries
      .where((entry) => entry.kind == kind)
      .fold<int>(0, (sum, entry) => sum + entry.bytes);

  int countForKind(String kind) => entries.where((entry) => entry.kind == kind && entry.exists).length;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'generatedAt': generatedAt.toIso8601String(),
        'totalBytes': totalBytes,
        'totalFiles': totalFiles,
        'entries': entries.map((entry) => entry.toJson()).toList(),
      };

  factory CacheIndexSnapshot.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List? ?? const [];
    return CacheIndexSnapshot(
      projectId: json['projectId']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      entries: entriesJson
          .whereType<Map>()
          .map((entry) => CacheIndexEntry.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))))
          .toList(),
    );
  }
}

class CacheCleanupPolicy {
  final int? maxCacheBytes;
  final int staleTempAgeDays;
  final int keepNewestAutosaves;
  final bool purgeOrphans;
  final bool includeExports;
  final bool dryRun;
  final Set<String>? allowedKinds;

  const CacheCleanupPolicy({
    this.maxCacheBytes,
    this.staleTempAgeDays = 2,
    this.keepNewestAutosaves = 5,
    this.purgeOrphans = true,
    this.includeExports = false,
    this.dryRun = false,
    this.allowedKinds,
  });

  static const conservative = CacheCleanupPolicy(
    maxCacheBytes: null,
    staleTempAgeDays: 2,
    keepNewestAutosaves: 5,
    purgeOrphans: true,
    includeExports: false,
  );

  static const aggressive = CacheCleanupPolicy(
    maxCacheBytes: 2 * 1024 * 1024 * 1024,
    staleTempAgeDays: 1,
    keepNewestAutosaves: 3,
    purgeOrphans: true,
    includeExports: false,
  );
}

class CacheCleanupReport {
  final String projectId;
  final DateTime startedAt;
  final DateTime completedAt;
  final bool dryRun;
  final int beforeBytes;
  final int afterBytes;
  final int deletedBytes;
  final int deletedFiles;
  final List<String> deletedPaths;
  final List<String> failedPaths;
  final List<String> retainedPaths;

  const CacheCleanupReport({
    required this.projectId,
    required this.startedAt,
    required this.completedAt,
    required this.dryRun,
    required this.beforeBytes,
    required this.afterBytes,
    required this.deletedBytes,
    required this.deletedFiles,
    required this.deletedPaths,
    required this.failedPaths,
    required this.retainedPaths,
  });

  bool get success => failedPaths.isEmpty;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'dryRun': dryRun,
        'beforeBytes': beforeBytes,
        'afterBytes': afterBytes,
        'deletedBytes': deletedBytes,
        'deletedFiles': deletedFiles,
        'deletedPaths': deletedPaths,
        'failedPaths': failedPaths,
        'retainedPaths': retainedPaths,
        'success': success,
      };
}
