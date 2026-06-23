import 'dart:io';
import 'package:path/path.dart' as p;

class TimelineMediaCacheManager {
  const TimelineMediaCacheManager();

  String getWaveformPath(String waveformsDir, String assetId) {
    return p.join(waveformsDir, '$assetId.waveform.json');
  }

  String getThumbnailPath(String thumbnailsDir, String assetId, int timeMs) {
    final name = timeMs == 0 ? '$assetId.jpg' : '${assetId}_$timeMs.jpg';
    return p.join(thumbnailsDir, name);
  }

  /// Calculates the total bytes of cached assets in the project folders
  Future<int> getCacheSize(List<String> directories) async {
    int totalBytes = 0;
    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          await for (final file in dir.list(recursive: true, followLinks: false)) {
            if (file is File) {
              totalBytes += await file.length();
            }
          }
        } catch (_) {}
      }
    }
    return totalBytes;
  }

  /// Clears waveforms and thumbnails from project folder caches
  Future<void> clearCache(List<String> directories) async {
    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          await for (final file in dir.list(recursive: false, followLinks: false)) {
            if (file is File) {
              await file.delete();
            }
          }
        } catch (_) {}
      }
    }
  }
}
