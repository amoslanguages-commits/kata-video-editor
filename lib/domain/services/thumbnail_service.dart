import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  Future<String?> generateThumbnail({
    required String sourcePath,
    required String outputDirectory,
    required String assetId,
    required String fileType,
    int timeMs = 0,
  }) async {
    try {
      if (fileType == 'video') {
        final outputPath = await VideoThumbnail.thumbnailFile(
          video: sourcePath,
          thumbnailPath: outputDirectory,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 120, // Lower resolution thumbnails for timeline performance
          quality: 60,
          timeMs: timeMs,
        );

        if (outputPath == null) return null;

        final name = timeMs == 0 ? '$assetId.jpg' : '${assetId}_$timeMs.jpg';
        final normalized = p.join(outputDirectory, name);
        final generated = File(outputPath);

        if (await generated.exists()) {
          final target = await generated.copy(normalized);
          if (target.path != generated.path) {
            try {
              await generated.delete();
            } catch (_) {}
          }
          return target.path;
        }

        return outputPath;
      }

      if (fileType == 'image') {
        final extension = p.extension(sourcePath).toLowerCase();
        final safeExtension = extension.isEmpty ? '.jpg' : extension;
        final outputPath = p.join(outputDirectory, '$assetId$safeExtension');
        await File(sourcePath).copy(outputPath);
        return outputPath;
      }

      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
