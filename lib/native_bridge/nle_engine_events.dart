class NlePlaybackPosition {
  final bool isPlaying;
  final int timelineMicros;

  const NlePlaybackPosition({
    required this.isPlaying,
    required this.timelineMicros,
  });
}

class NleExportProgress {
  final int progress;   // 0–100
  final String stage;
  final String? outputPath;

  const NleExportProgress({
    required this.progress,
    required this.stage,
    this.outputPath,
  });
}
