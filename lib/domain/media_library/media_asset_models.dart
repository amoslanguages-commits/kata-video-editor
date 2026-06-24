import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

class NleMediaAsset {
  final String id;
  final String projectId;

  final String displayName;
  final NleMediaAssetType type;
  final NleMediaImportSource importSource;
  final NleMediaStorageMode storageMode;
  final NleMediaAvailability availability;
  final NleMediaLifecycleState lifecycleState;

  /// The immutable user/source location captured at import time.
  ///
  /// Never overwrite this during proxy generation, cache moves, render graph
  /// building, export, missing-media checks, or relink operations.
  final String? originalPath;

  /// The durable full-resolution path currently owned by the project, when the
  /// media was copied into the local project folder.
  final String? projectPath;

  /// The full-resolution path the app should use after availability/relink
  /// resolution. This is separate from [originalPath] so relink does not erase
  /// the original source path.
  final String? resolvedPath;

  /// The concrete path selected for the current media operation. Render/export
  /// code should open this field, not [originalPath]. It may point at a proxy
  /// when proxies are ready and preferred.
  final String? selectedMediaPath;

  final String? thumbnailPath;
  final String? waveformCacheId;
  final String? proxyPath;

  final NleProxyStatus proxyStatus;
  final NleMediaUsageState usageState;

  final NleMediaFileInfo fileInfo;
  final NleMediaVideoInfo videoInfo;
  final NleMediaAudioInfo audioInfo;
  final NleMediaTimecodeInfo timecodeInfo;

  final String? notes;
  final List<String> tags;

  final DateTime importedAt;
  final DateTime updatedAt;
  final int version;

  const NleMediaAsset({
    required this.id,
    required this.projectId,
    required this.displayName,
    required this.type,
    required this.importSource,
    required this.storageMode,
    required this.availability,
    this.lifecycleState = NleMediaLifecycleState.imported,
    this.originalPath,
    this.projectPath,
    this.resolvedPath,
    this.selectedMediaPath,
    this.thumbnailPath,
    this.waveformCacheId,
    this.proxyPath,
    required this.proxyStatus,
    required this.usageState,
    required this.fileInfo,
    required this.videoInfo,
    required this.audioInfo,
    required this.timecodeInfo,
    this.notes,
    required this.tags,
    required this.importedAt,
    required this.updatedAt,
    required this.version,
  });

  String? get resolvedEditPath {
    if (availability != NleMediaAvailability.available) return null;
    return selectedMediaPath ?? resolvedPath ?? projectPath ?? originalPath;
  }

  String? get resolvedOriginalPath {
    return resolvedPath ?? projectPath ?? originalPath;
  }

  bool get isVideo => type == NleMediaAssetType.video;
  bool get isAudio => type == NleMediaAssetType.audio;
  bool get isImage => type == NleMediaAssetType.image;
  bool get isMissing => availability == NleMediaAvailability.missing;
  bool get isUsed => usageState != NleMediaUsageState.unused;
  bool get hasProxyReady => proxyStatus == NleProxyStatus.ready &&
      proxyPath != null &&
      proxyPath!.trim().isNotEmpty;

  int get durationMicros => timecodeInfo.durationMicros;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'displayName': displayName,
      'type': type.name,
      'importSource': importSource.name,
      'storageMode': storageMode.name,
      'availability': availability.name,
      'lifecycleState': lifecycleState.name,
      'originalPath': originalPath,
      'projectPath': projectPath,
      'resolvedPath': resolvedPath,
      'selectedMediaPath': selectedMediaPath,
      'thumbnailPath': thumbnailPath,
      'waveformCacheId': waveformCacheId,
      'proxyPath': proxyPath,
      'proxyStatus': proxyStatus.name,
      'usageState': usageState.name,
      'fileInfo': fileInfo.toJson(),
      'videoInfo': videoInfo.toJson(),
      'audioInfo': audioInfo.toJson(),
      'timecodeInfo': timecodeInfo.toJson(),
      'notes': notes,
      'tags': tags,
      'importedAt': importedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  factory NleMediaAsset.fromJson(Map<String, dynamic> json) {
    return NleMediaAsset(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Media',
      type: _enumByName(
        NleMediaAssetType.values,
        json['type'],
        NleMediaAssetType.unknown,
      ),
      importSource: _enumByName(
        NleMediaImportSource.values,
        json['importSource'],
        NleMediaImportSource.filePicker,
      ),
      storageMode: _enumByName(
        NleMediaStorageMode.values,
        json['storageMode'],
        NleMediaStorageMode.copiedIntoProject,
      ),
      availability: _enumByName(
        NleMediaAvailability.values,
        json['availability'],
        NleMediaAvailability.available,
      ),
      lifecycleState: _enumByName(
        NleMediaLifecycleState.values,
        json['lifecycleState'],
        NleMediaLifecycleState.imported,
      ),
      originalPath: json['originalPath']?.toString(),
      projectPath: json['projectPath']?.toString(),
      resolvedPath: json['resolvedPath']?.toString(),
      selectedMediaPath: json['selectedMediaPath']?.toString(),
      thumbnailPath: json['thumbnailPath']?.toString(),
      waveformCacheId: json['waveformCacheId']?.toString(),
      proxyPath: json['proxyPath']?.toString(),
      proxyStatus: _enumByName(
        NleProxyStatus.values,
        json['proxyStatus'],
        NleProxyStatus.none,
      ),
      usageState: _enumByName(
        NleMediaUsageState.values,
        json['usageState'],
        NleMediaUsageState.unused,
      ),
      fileInfo: NleMediaFileInfo.fromJson(
        Map<String, dynamic>.from(json['fileInfo'] as Map? ?? const {}),
      ),
      videoInfo: NleMediaVideoInfo.fromJson(
        Map<String, dynamic>.from(json['videoInfo'] as Map? ?? const {}),
      ),
      audioInfo: NleMediaAudioInfo.fromJson(
        Map<String, dynamic>.from(json['audioInfo'] as Map? ?? const {}),
      ),
      timecodeInfo: NleMediaTimecodeInfo.fromJson(
        Map<String, dynamic>.from(json['timecodeInfo'] as Map? ?? const {}),
      ),
      notes: json['notes']?.toString(),
      tags: (json['tags'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      importedAt: DateTime.tryParse(json['importedAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleMediaAsset copyWith({
    String? displayName,
    NleMediaAssetType? type,
    NleMediaAvailability? availability,
    NleMediaLifecycleState? lifecycleState,
    String? originalPath,
    String? projectPath,
    String? resolvedPath,
    String? selectedMediaPath,
    String? thumbnailPath,
    String? waveformCacheId,
    String? proxyPath,
    NleProxyStatus? proxyStatus,
    NleMediaUsageState? usageState,
    NleMediaFileInfo? fileInfo,
    NleMediaVideoInfo? videoInfo,
    NleMediaAudioInfo? audioInfo,
    NleMediaTimecodeInfo? timecodeInfo,
    String? notes,
    List<String>? tags,
    DateTime? updatedAt,
    int? version,
  }) {
    return NleMediaAsset(
      id: id,
      projectId: projectId,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      importSource: importSource,
      storageMode: storageMode,
      availability: availability ?? this.availability,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      originalPath: originalPath ?? this.originalPath,
      projectPath: projectPath ?? this.projectPath,
      resolvedPath: resolvedPath ?? this.resolvedPath,
      selectedMediaPath: selectedMediaPath ?? this.selectedMediaPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      waveformCacheId: waveformCacheId ?? this.waveformCacheId,
      proxyPath: proxyPath ?? this.proxyPath,
      proxyStatus: proxyStatus ?? this.proxyStatus,
      usageState: usageState ?? this.usageState,
      fileInfo: fileInfo ?? this.fileInfo,
      videoInfo: videoInfo ?? this.videoInfo,
      audioInfo: audioInfo ?? this.audioInfo,
      timecodeInfo: timecodeInfo ?? this.timecodeInfo,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      importedAt: importedAt,
      updatedAt: updatedAt ?? DateTime.now(),
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
