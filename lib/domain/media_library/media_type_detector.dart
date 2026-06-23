import 'package:path/path.dart' as p;

import 'package:nle_editor/domain/media_library/media_asset_value_models.dart';

class MediaTypeDetector {
  const MediaTypeDetector();

  NleMediaAssetType detectFromPath(String path) {
    final ext = p.extension(path).toLowerCase();

    const video = {
      '.mp4',
      '.mov',
      '.m4v',
      '.mkv',
      '.webm',
      '.avi',
      '.3gp',
    };

    const audio = {
      '.mp3',
      '.m4a',
      '.aac',
      '.wav',
      '.flac',
      '.ogg',
      '.opus',
    };

    const image = {
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
      '.heif',
      '.gif',
    };

    if (video.contains(ext)) return NleMediaAssetType.video;
    if (audio.contains(ext)) return NleMediaAssetType.audio;
    if (image.contains(ext)) return NleMediaAssetType.image;

    return NleMediaAssetType.unknown;
  }
}
