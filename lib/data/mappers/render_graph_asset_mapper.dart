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
    final duration = (timecodeInfo['durationMicros'] as num?)?.toInt() ?? 0;
    final width = (videoInfo['width'] as num?)?.toInt() ?? 0;
    final height = (videoInfo['height'] as num?)?.toInt() ?? 0;
    final fps = (videoInfo['fps'] as num?)?.toDouble() ?? 0.0;
    final codec = videoInfo['codec']?.toString() ?? audioInfo['codec']?.toString() ?? '';

    return RenderGraphAssetDto(
      id: row.id,
      type: type,
      originalPath: row.originalPath,
      projectPath: row.projectPath,
      proxyPath: row.proxyPath,
      thumbnailPath: row.thumbnailPath,
      displayName: row.displayName,
      durationMicros: duration,
      width: width,
      height: height,
      hasVideo: type == 'video' || type == 'image',
      hasAudio: type == 'video' || type == 'audio',
      codec: codec.isEmpty ? null : codec,
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

    return NleMediaAsset(
      id: row.id,
      projectId: row.projectId,
      displayName: row.displayName,
      type: _enumByName(
        NleMediaAssetType.values,
        row.type,
        NleMediaAssetType.unknown,
      ),
      importSource: _enumByName(
        NleMediaImportSource.values,
        row.importSource,
        NleMediaImportSource.filePicker,
      ),
      storageMode: _enumByName(
        NleMediaStorageMode.values,
        row.storageMode,
        NleMediaStorageMode.copiedIntoProject,
      ),
      availability: _enumByName(
        NleMediaAvailability.values,
        row.availability,
        NleMediaAvailability.available,
      ),
      originalPath: row.originalPath,
      projectPath: row.projectPath,
      thumbnailPath: row.thumbnailPath,
      waveformCacheId: row.waveformCacheId,
      proxyPath: row.proxyPath,
      proxyStatus: _enumByName(
        NleProxyStatus.values,
        row.proxyStatus,
        NleProxyStatus.none,
      ),
      usageState: _enumByName(
        NleMediaUsageState.values,
        row.usageState,
        NleMediaUsageState.unused,
      ),
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

  T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
    final string = name?.toString();
    if (string == null) return fallback;

    for (final value in values) {
      if (value.name == string) return value;
    }

    return fallback;
  }
}
