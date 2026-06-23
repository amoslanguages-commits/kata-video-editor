enum NativePreviewSessionPhase {
  idle,
  preparing,
  ready,
  playing,
  paused,
  stopped,
  error,
}

class NativePreviewSessionState {
  final String projectId;
  final String monitorId;
  final NativePreviewSessionPhase phase;
  final int playheadMicros;
  final int maxPreviewWidth;
  final int maxPreviewHeight;
  final String qualityMode;
  final bool preferProxy;
  final String? errorMessage;

  const NativePreviewSessionState({
    required this.projectId,
    this.monitorId = 'program',
    this.phase = NativePreviewSessionPhase.idle,
    this.playheadMicros = 0,
    this.maxPreviewWidth = 1280,
    this.maxPreviewHeight = 720,
    this.qualityMode = 'auto',
    this.preferProxy = true,
    this.errorMessage,
  });

  bool get isPrepared =>
      phase == NativePreviewSessionPhase.ready ||
      phase == NativePreviewSessionPhase.playing ||
      phase == NativePreviewSessionPhase.paused;

  bool get isBusy => phase == NativePreviewSessionPhase.preparing;

  NativePreviewSessionState copyWith({
    String? projectId,
    String? monitorId,
    NativePreviewSessionPhase? phase,
    int? playheadMicros,
    int? maxPreviewWidth,
    int? maxPreviewHeight,
    String? qualityMode,
    bool? preferProxy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NativePreviewSessionState(
      projectId: projectId ?? this.projectId,
      monitorId: monitorId ?? this.monitorId,
      phase: phase ?? this.phase,
      playheadMicros: playheadMicros ?? this.playheadMicros,
      maxPreviewWidth: maxPreviewWidth ?? this.maxPreviewWidth,
      maxPreviewHeight: maxPreviewHeight ?? this.maxPreviewHeight,
      qualityMode: qualityMode ?? this.qualityMode,
      preferProxy: preferProxy ?? this.preferProxy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
