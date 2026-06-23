class DevicePerformanceTier {
  DevicePerformanceTier._();

  static const String low = 'low';
  static const String mid = 'mid';
  static const String high = 'high';
  static const String flagship = 'flagship';
}

class PreviewQualityLevel {
  PreviewQualityLevel._();

  static const String auto = 'auto';
  static const String quarter = 'quarter';
  static const String half = 'half';
  static const String full = 'full';
}

class PerformanceModeState {
  final String deviceTier;
  final String previewQuality;
  final bool lowMemoryMode;
  final bool thermalWarning;
  final bool batterySaver;
  final bool pauseBackgroundWorkDuringScrub;
  final int maxTimelineClipWidgets;
  final int maxMediaPoolItemsPerPage;
  final Duration nativeGraphDebounce;
  final Duration autosaveDebounce;
  final Duration playheadThrottle;

  const PerformanceModeState({
    required this.deviceTier,
    required this.previewQuality,
    required this.lowMemoryMode,
    required this.thermalWarning,
    required this.batterySaver,
    required this.pauseBackgroundWorkDuringScrub,
    required this.maxTimelineClipWidgets,
    required this.maxMediaPoolItemsPerPage,
    required this.nativeGraphDebounce,
    required this.autosaveDebounce,
    required this.playheadThrottle,
  });

  factory PerformanceModeState.defaults() {
    return const PerformanceModeState(
      deviceTier: DevicePerformanceTier.mid,
      previewQuality: PreviewQualityLevel.auto,
      lowMemoryMode: false,
      thermalWarning: false,
      batterySaver: false,
      pauseBackgroundWorkDuringScrub: true,
      maxTimelineClipWidgets: 120,
      maxMediaPoolItemsPerPage: 80,
      nativeGraphDebounce: Duration(milliseconds: 180),
      autosaveDebounce: Duration(seconds: 2),
      playheadThrottle: Duration(milliseconds: 33),
    );
  }

  PerformanceModeState copyWith({
    String? deviceTier,
    String? previewQuality,
    bool? lowMemoryMode,
    bool? thermalWarning,
    bool? batterySaver,
    bool? pauseBackgroundWorkDuringScrub,
    int? maxTimelineClipWidgets,
    int? maxMediaPoolItemsPerPage,
    Duration? nativeGraphDebounce,
    Duration? autosaveDebounce,
    Duration? playheadThrottle,
  }) {
    return PerformanceModeState(
      deviceTier: deviceTier ?? this.deviceTier,
      previewQuality: previewQuality ?? this.previewQuality,
      lowMemoryMode: lowMemoryMode ?? this.lowMemoryMode,
      thermalWarning: thermalWarning ?? this.thermalWarning,
      batterySaver: batterySaver ?? this.batterySaver,
      pauseBackgroundWorkDuringScrub:
          pauseBackgroundWorkDuringScrub ?? this.pauseBackgroundWorkDuringScrub,
      maxTimelineClipWidgets:
          maxTimelineClipWidgets ?? this.maxTimelineClipWidgets,
      maxMediaPoolItemsPerPage:
          maxMediaPoolItemsPerPage ?? this.maxMediaPoolItemsPerPage,
      nativeGraphDebounce: nativeGraphDebounce ?? this.nativeGraphDebounce,
      autosaveDebounce: autosaveDebounce ?? this.autosaveDebounce,
      playheadThrottle: playheadThrottle ?? this.playheadThrottle,
    );
  }
}
