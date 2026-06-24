import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';

class RenderGraphAssetMapper {
  const RenderGraphAssetMapper();

  RenderGraphAssetDto fromDb(db.MediaAsset row) {
    final videoInfo = _decodeMap(row.videoInfoJson);
    final audioInfo = _decodeMap(row.audioInfoJson);
    final timecodeInfo = _decodeMap(row.timecodeInfoJson);

    final type = row.type.toLowerCase();
    final duration = _int(timecodeInfo['durationMicros']);
    final width = _int(videoInfo['width']);
    final height = _int(videoInfo['height']);
    final fps = _double(videoInfo['fps']);
    final codec = videoInfo['codec']?.toString().trim().isNotEmpty == true
        ? videoInfo['codec'].toString()
        : audioInfo['codec']?.toString();

    final availability = _enumByName(
      NleMediaAvailability.values,
      row.availability,
      NleMediaAvailability.available,
    );
    final proxyStatus = _enumByName(
      NleProxyStatus.values,
      row.proxyStatus,
      NleProxyStatus.none,
    );
    final fullResolutionPath = availability == NleMediaAvailability.available
        ? _firstNonBlank(row.projectPath, row.originalPath)
        : null;
    final proxyPath = _clean(row.proxyPath);
    final usedProxy = proxyStatus == NleProxyStatus.ready && proxyPath != null;
    final selectedMediaPath = usedProxy ? proxyPath : fullResolutionPath;

    return RenderGraphAssetDto(
      id: row.id,
      type: type,
      originalPath: row.originalPath,
      projectPath: row.projectPath,
      proxyPath: row.proxyPath,
      resolvedPath: selectedMediaPath,
      sourcePolicy: usedProxy ? 'proxy_ready' : 'full_resolution',
      usedProxy: usedProxy,
      thumbnailPath: row.thumbnailPath,
      displayName: row.displayName,
      durationMicros: duration,
      width: width,
      height: height,
      hasVideo: type == 'video' || type == 'image',
      hasAudio: type == 'video' || type == 'audio',
      codec: codec?.isEmpty == true ? null : codec,
      frameRate: fps == 0.0 ? null : fps,
      rotationDegrees: 0,
    );
  }

  NleMediaAsset toMediaAsset(db.MediaAsset row) {
    final fileInfo = _decodeMap(row.fileInfoJson);
    final videoInfo = _decodeMap(row.videoInfoJson);
    final audioInfo = _decodeMap(row.audioInfoJson);
    final timecodeInfo = _decodeMap(row.timecodeInfoJson);
    final tags = _decodeStringList(row.tagsJson);
    final availability = _enumByName(
      NleMediaAvailability.values,
      row.availability,
      NleMediaAvailability.available,
    );
    final proxyStatus = _enumByName(
      NleProxyStatus.values,
      row.proxyStatus,
      NleProxyStatus.none,
    );
    final fullResolutionPath = availability == NleMediaAvailability.available
        ? _firstNonBlank(row.projectPath, row.originalPath)
        : null;
    final proxyPath = _clean(row.proxyPath);
    final selectedMediaPath = proxyStatus == NleProxyStatus.ready && proxyPath != null
        ? proxyPath
        : fullResolutionPath;

    return NleMediaAsset(
      id: row.id,
      projectId: row.projectId,
      displayName: row.displayName,
      type: _enumByName(NleMediaAssetType.values, row.type, NleMediaAssetType.unknown),
      importSource: _enumByName(NleMediaImportSource.values, row.importSource, NleMediaImportSource.filePicker),
      storageMode: _enumByName(NleMediaStorageMode.values, row.storageMode, NleMediaStorageMode.copiedIntoProject),
      availability: availability,
      originalPath: row.originalPath,
      projectPath: row.projectPath,
      resolvedPath: fullResolutionPath,
      selectedMediaPath: selectedMediaPath,
      thumbnailPath: row.thumbnailPath,
      waveformCacheId: row.waveformCacheId,
      proxyPath: row.proxyPath,
      proxyStatus: proxyStatus,
      usageState: _enumByName(NleMediaUsageState.values, row.usageState, NleMediaUsageState.unused),
      fileInfo: NleMediaFileInfo.fromJson(fileInfo),
      videoInfo: NleMediaVideoInfo.fromJson(videoInfo),
      audioInfo: NleMediaAudioInfo.fromJson(audioInfo),
      timecodeInfo: NleMediaTimecodeInfo.fromJson(timecodeInfo),
      notes: row.notes,
      tags: tags,
      importedAt: row.importedAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }

  Map<String, dynamic> _decodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
      if (decoded is Map) return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {}
    return const <String, dynamic>{};
  }

  List<String> _decodeStringList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((item) => item.toString()).toList();
    } catch (_) {}
    return const <String>[];
  }

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _double(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String? _firstNonBlank(String? first, [String? second]) {
    final firstClean = _clean(first);
    if (firstClean != null) return firstClean;
    return _clean(second);
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
    final string = name?.toString();
    if (string == null) return fallback;
    for (final value in values) {
      if (value.name == string) return value;
    }
    return fallback;
  }
}
