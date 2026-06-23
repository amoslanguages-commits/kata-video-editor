class TimeUtils {
  TimeUtils._();

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final millis = (duration.inMilliseconds.remainder(1000) / 10).floor();

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(2, '0')}';
  }

  static String formatMicros(int micros) {
    return formatDuration(Duration(microseconds: micros));
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static int microsToFrame(int micros, int frameRate) {
    return (micros * frameRate / 1000000).round();
  }

  static int frameToMicros(int frame, int frameRate) {
    return (frame * 1000000 / frameRate).round();
  }
}
