/// Progress event emitted during temporary FFmpeg-based export.
class TemporaryExportProgress {
  final int progress; // 0–100
  final String stage;
  final String? outputPath;

  const TemporaryExportProgress({
    required this.progress,
    required this.stage,
    this.outputPath,
  });
}
