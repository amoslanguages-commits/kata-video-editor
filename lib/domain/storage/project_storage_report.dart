class ProjectStorageReport {
  final String projectId;

  final int totalBytes;

  final int thumbnailsBytes;
  final int timelineThumbnailsBytes;
  final int waveformsBytes;
  final int proxiesBytes;
  final int exportsBytes;
  final int tempBytes;
  final int autosavesBytes;
  final int otherBytes;

  final int thumbnailFileCount;
  final int timelineThumbnailFileCount;
  final int waveformFileCount;
  final int proxyFileCount;
  final int exportFileCount;
  final int tempFileCount;
  final int autosaveFileCount;
  final int otherFileCount;

  final DateTime calculatedAt;

  const ProjectStorageReport({
    required this.projectId,
    required this.totalBytes,
    required this.thumbnailsBytes,
    required this.timelineThumbnailsBytes,
    required this.waveformsBytes,
    required this.proxiesBytes,
    required this.exportsBytes,
    required this.tempBytes,
    required this.autosavesBytes,
    required this.otherBytes,
    required this.thumbnailFileCount,
    required this.timelineThumbnailFileCount,
    required this.waveformFileCount,
    required this.proxyFileCount,
    required this.exportFileCount,
    required this.tempFileCount,
    required this.autosaveFileCount,
    required this.otherFileCount,
    required this.calculatedAt,
  });

  int get visualCacheBytes => thumbnailsBytes + timelineThumbnailsBytes;

  int get editableCacheBytes => thumbnailsBytes + timelineThumbnailsBytes + waveformsBytes + proxiesBytes;

  int get cleanupSafeBytes => thumbnailsBytes + timelineThumbnailsBytes + waveformsBytes + proxiesBytes + tempBytes;

  int get totalCacheFileCount {
    return thumbnailFileCount +
        timelineThumbnailFileCount +
        waveformFileCount +
        proxyFileCount +
        tempFileCount +
        autosaveFileCount +
        otherFileCount;
  }

  ProjectStorageReport copyWith({
    int? totalBytes,
    int? thumbnailsBytes,
    int? timelineThumbnailsBytes,
    int? waveformsBytes,
    int? proxiesBytes,
    int? exportsBytes,
    int? tempBytes,
    int? autosavesBytes,
    int? otherBytes,
    int? thumbnailFileCount,
    int? timelineThumbnailFileCount,
    int? waveformFileCount,
    int? proxyFileCount,
    int? exportFileCount,
    int? tempFileCount,
    int? autosaveFileCount,
    int? otherFileCount,
    DateTime? calculatedAt,
  }) {
    return ProjectStorageReport(
      projectId: projectId,
      totalBytes: totalBytes ?? this.totalBytes,
      thumbnailsBytes: thumbnailsBytes ?? this.thumbnailsBytes,
      timelineThumbnailsBytes: timelineThumbnailsBytes ?? this.timelineThumbnailsBytes,
      waveformsBytes: waveformsBytes ?? this.waveformsBytes,
      proxiesBytes: proxiesBytes ?? this.proxiesBytes,
      exportsBytes: exportsBytes ?? this.exportsBytes,
      tempBytes: tempBytes ?? this.tempBytes,
      autosavesBytes: autosavesBytes ?? this.autosavesBytes,
      otherBytes: otherBytes ?? this.otherBytes,
      thumbnailFileCount: thumbnailFileCount ?? this.thumbnailFileCount,
      timelineThumbnailFileCount: timelineThumbnailFileCount ?? this.timelineThumbnailFileCount,
      waveformFileCount: waveformFileCount ?? this.waveformFileCount,
      proxyFileCount: proxyFileCount ?? this.proxyFileCount,
      exportFileCount: exportFileCount ?? this.exportFileCount,
      tempFileCount: tempFileCount ?? this.tempFileCount,
      autosaveFileCount: autosaveFileCount ?? this.autosaveFileCount,
      otherFileCount: otherFileCount ?? this.otherFileCount,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  static ProjectStorageReport empty(String projectId) {
    return ProjectStorageReport(
      projectId: projectId,
      totalBytes: 0,
      thumbnailsBytes: 0,
      timelineThumbnailsBytes: 0,
      waveformsBytes: 0,
      proxiesBytes: 0,
      exportsBytes: 0,
      tempBytes: 0,
      autosavesBytes: 0,
      otherBytes: 0,
      thumbnailFileCount: 0,
      timelineThumbnailFileCount: 0,
      waveformFileCount: 0,
      proxyFileCount: 0,
      exportFileCount: 0,
      tempFileCount: 0,
      autosaveFileCount: 0,
      otherFileCount: 0,
      calculatedAt: DateTime.now(),
    );
  }
}

class FolderStorageStat {
  final int bytes;
  final int files;

  const FolderStorageStat({
    required this.bytes,
    required this.files,
  });

  static const empty = FolderStorageStat(
    bytes: 0,
    files: 0,
  );
}

class CacheClearResult {
  final String projectId;
  final String action;
  final int deletedBytes;
  final int deletedFiles;
  final bool success;
  final String? message;

  const CacheClearResult({
    required this.projectId,
    required this.action,
    required this.deletedBytes,
    required this.deletedFiles,
    required this.success,
    this.message,
  });
}
