import 'dart:convert';

import 'package:nle_editor/domain/media_library/media_asset_models.dart';

/// 34C-PRO: Project Archive / Relink / Media Management models.
///
/// These models are intentionally pure Dart so the archive, relink, cleanup,
/// and health-check services can run offline without native or cloud services.

enum NleProjectArchiveMode {
  fullProject,
  usedMediaOnly,
  manifestOnly,
}

enum NleMediaHealthStatus {
  healthy,
  warning,
  missing,
  offline,
  corrupted,
}

enum NleRelinkMatchStrength {
  exact,
  strong,
  weak,
  manual,
  none,
}

enum NleProjectCleanupScope {
  unusedMediaRows,
  unusedCopiedFiles,
  proxies,
  thumbnails,
  waveforms,
  tempFiles,
}

class NleProjectStorageBreakdown {
  final int mediaBytes;
  final int usedMediaBytes;
  final int unusedMediaBytes;
  final int proxyBytes;
  final int thumbnailBytes;
  final int waveformBytes;
  final int exportBytes;
  final int tempBytes;
  final int totalBytes;

  const NleProjectStorageBreakdown({
    required this.mediaBytes,
    required this.usedMediaBytes,
    required this.unusedMediaBytes,
    required this.proxyBytes,
    required this.thumbnailBytes,
    required this.waveformBytes,
    required this.exportBytes,
    required this.tempBytes,
    required this.totalBytes,
  });

  factory NleProjectStorageBreakdown.empty() {
    return const NleProjectStorageBreakdown(
      mediaBytes: 0,
      usedMediaBytes: 0,
      unusedMediaBytes: 0,
      proxyBytes: 0,
      thumbnailBytes: 0,
      waveformBytes: 0,
      exportBytes: 0,
      tempBytes: 0,
      totalBytes: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaBytes': mediaBytes,
      'usedMediaBytes': usedMediaBytes,
      'unusedMediaBytes': unusedMediaBytes,
      'proxyBytes': proxyBytes,
      'thumbnailBytes': thumbnailBytes,
      'waveformBytes': waveformBytes,
      'exportBytes': exportBytes,
      'tempBytes': tempBytes,
      'totalBytes': totalBytes,
    };
  }
}

class NleProjectMediaHealthItem {
  final String assetId;
  final String displayName;
  final String? expectedPath;
  final bool isUsedInTimeline;
  final NleMediaHealthStatus status;
  final String message;
  final NleMediaAsset? asset;

  const NleProjectMediaHealthItem({
    required this.assetId,
    required this.displayName,
    required this.expectedPath,
    required this.isUsedInTimeline,
    required this.status,
    required this.message,
    this.asset,
  });

  bool get blocksExport {
    return isUsedInTimeline &&
        (status == NleMediaHealthStatus.missing ||
            status == NleMediaHealthStatus.corrupted);
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'displayName': displayName,
      'expectedPath': expectedPath,
      'isUsedInTimeline': isUsedInTimeline,
      'status': status.name,
      'message': message,
      'blocksExport': blocksExport,
    };
  }
}

class NleProjectMediaHealthReport {
  final String projectId;
  final DateTime createdAt;
  final List<NleProjectMediaHealthItem> items;
  final NleProjectStorageBreakdown storage;

  const NleProjectMediaHealthReport({
    required this.projectId,
    required this.createdAt,
    required this.items,
    required this.storage,
  });

  int get missingCount =>
      items.where((item) => item.status == NleMediaHealthStatus.missing).length;

  int get corruptedCount =>
      items.where((item) => item.status == NleMediaHealthStatus.corrupted).length;

  int get usedCount => items.where((item) => item.isUsedInTimeline).length;

  int get unusedCount => items.length - usedCount;

  bool get canExport => items.where((item) => item.blocksExport).isEmpty;

  List<NleProjectMediaHealthItem> get blockingItems =>
      items.where((item) => item.blocksExport).toList(growable: false);

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'missingCount': missingCount,
      'corruptedCount': corruptedCount,
      'usedCount': usedCount,
      'unusedCount': unusedCount,
      'canExport': canExport,
      'storage': storage.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class NleProjectArchiveManifest {
  final String schema;
  final int version;
  final String projectId;
  final String projectName;
  final DateTime createdAt;
  final NleProjectArchiveMode mode;
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> clips;
  final Map<String, dynamic> storage;

  const NleProjectArchiveManifest({
    required this.schema,
    required this.version,
    required this.projectId,
    required this.projectName,
    required this.createdAt,
    required this.mode,
    required this.assets,
    required this.clips,
    required this.storage,
  });

  Map<String, dynamic> toJson() {
    return {
      'schema': schema,
      'version': version,
      'projectId': projectId,
      'projectName': projectName,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'mode': mode.name,
      'assets': assets,
      'clips': clips,
      'storage': storage,
    };
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class NleProjectArchiveResult {
  final String archiveRootPath;
  final String manifestPath;
  final int copiedFiles;
  final int skippedFiles;
  final int copiedBytes;
  final List<String> warnings;

  const NleProjectArchiveResult({
    required this.archiveRootPath,
    required this.manifestPath,
    required this.copiedFiles,
    required this.skippedFiles,
    required this.copiedBytes,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

class NleRelinkCandidate {
  final String assetId;
  final String displayName;
  final String candidatePath;
  final NleRelinkMatchStrength strength;
  final String reason;

  const NleRelinkCandidate({
    required this.assetId,
    required this.displayName,
    required this.candidatePath,
    required this.strength,
    required this.reason,
  });
}

class NleRelinkResult {
  final int relinkedCount;
  final int skippedCount;
  final List<NleRelinkCandidate> candidates;
  final List<String> warnings;

  const NleRelinkResult({
    required this.relinkedCount,
    required this.skippedCount,
    required this.candidates,
    required this.warnings,
  });
}

class NleProjectCleanupResult {
  final int deletedFiles;
  final int deletedRows;
  final int freedBytes;
  final List<String> warnings;

  const NleProjectCleanupResult({
    required this.deletedFiles,
    required this.deletedRows,
    required this.freedBytes,
    required this.warnings,
  });
}
