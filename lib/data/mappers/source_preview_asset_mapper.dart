// lib/data/mappers/source_preview_asset_mapper.dart
//
// Maps a Drift [Asset] row to a [SourcePreviewAsset].

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/source_preview/source_preview_models.dart';

class SourcePreviewAssetMapper {
  const SourcePreviewAssetMapper();

  SourcePreviewAsset fromDb(db.Asset row) {
    final type = row.fileType.toLowerCase();
    final hasVideo = row.hasVideo;
    final hasAudio = row.hasAudio;

    return SourcePreviewAsset(
      id: row.id,
      projectId: row.projectId,
      name: row.fileName,
      assetType: row.fileType,
      originalPath: _emptyToNull(row.originalPath),
      proxyPath: _emptyToNull(row.proxyPath),
      thumbnailPath: _emptyToNull(row.thumbnailPath),
      durationMicros: row.durationMicros ?? 0,
      width: row.width ?? 0,
      height: row.height ?? 0,
      hasVideo: hasVideo || type == 'video',
      hasAudio: hasAudio || type == 'audio' || type == 'music' || type == 'voice' || type == 'sfx',
    );
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    if (value.trim().isEmpty) return null;
    return value;
  }
}
