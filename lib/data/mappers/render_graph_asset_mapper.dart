import 'dart:convert';
import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/media_library/media_asset_models.dart';
import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class RenderGraphAssetMapper {
  const RenderGraphAssetMapper();

  RenderGraphAssetDto fromDb(db.MediaAsset row) {
    Map<String, dynamic> videoInfo = {};
    Map<String, dynamic> audioInfo = {};
    Map<String, dynamic> timecodeInfo = {};
    Map<String, dynamic> fileInfo = {};

    try {
      videoInfo = jsonDecode(row.videoInfoJson) as Map<String, dynamic>;
    } catch (_) {}
    try {
      audioInfo = jsonDecode(row.audioInfoJson) as Map<String, dynamic>;
    } catch (_) {}
    try {
      timecodeInfo = jsonDecode(row.timecodeInfoJson) as Map<String, dynamic>;
    } catch (_) {}
    try {
      fileInfo = jsonDecode(row.fileInfoJson) as Map<String, dynamic>;
    } catch (_) {}

    final type = row.type.toLowerCase();
    final duration = timecodeInfo['durationMicros'] as int? ?? 0;
    final width = videoInfo['width'] as int? ?? 0;
    final height = videoInfo['height'] as int? ?? 0;
    final fps = (videoInfo['fps'] as num?)?.toDouble() ?? 0.0;
    final codec = videoInfo['codec'] as String? ?? audioInfo['codec'] as String? ?? '';

    return RenderGraphAssetDto(
      id: row.id,
      type: type,
      originalPath: row.projectPath ?? row.originalPath,
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
      fileInfo: NleMediaFileInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.fileInfoJson) as Map),
      ),
      videoInfo: NleMediaVideoInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.videoInfoJson) as Map),
      ),
      audioInfo: NleMediaAudioInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.audioInfoJson) as Map),
      ),
      timecodeInfo: NleMediaTimecodeInfo.fromJson(
        Map<String, dynamic>.from(jsonDecode(row.timecodeInfoJson) as Map),
      ),
      notes: row.notes,
      tags: (jsonDecode(row.tagsJson) as List)
          .map((item) => item.toString())
          .toList(),
      importedAt: row.importedAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
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
}
