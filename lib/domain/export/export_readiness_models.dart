enum ExportBlockReason {
  noClips,
  qaFailed,
  deviceUnsupported,
  autosaveSaving,
  alreadyExporting,
  previewPreparing,
}

class ExportReadiness {
  final bool isReady;
  final List<ExportBlockReason> reasons;
  final String? detailMessage;

  const ExportReadiness({
    required this.isReady,
    required this.reasons,
    this.detailMessage,
  });

  const ExportReadiness.ready()
      : isReady = true,
        reasons = const [],
        detailMessage = null;

  factory ExportReadiness.blocked(List<ExportBlockReason> reasons, [String? detailMessage]) {
    return ExportReadiness(
      isReady: false,
      reasons: reasons,
      detailMessage: detailMessage,
    );
  }

  String get userMessage {
    if (isReady) return 'Ready to export';

    final primary = reasons.first;
    switch (primary) {
      case ExportBlockReason.noClips:
        return 'Timeline is empty. Add clips before exporting.';
      case ExportBlockReason.qaFailed:
        return 'Project QA checks failed. Please fix timeline errors first.';
      case ExportBlockReason.deviceUnsupported:
        return detailMessage ?? 'Device conditions unsuitable for rendering.';
      case ExportBlockReason.autosaveSaving:
        return 'Saving project edits... Please wait a moment.';
      case ExportBlockReason.alreadyExporting:
        return 'An export job is already running.';
      case ExportBlockReason.previewPreparing:
        return 'Preview is busy. Pause playback to export.';
    }
  }
}
