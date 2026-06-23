import 'package:nle_editor/domain/proxy/proxy_value_models.dart';

class NleProjectProxySettings {
  final bool enabled;
  final bool autoGenerateOnImport;
  final bool autoGenerateFor4k;
  final bool autoGenerateForHighBitrate;
  final bool autoGenerateForHdr;
  final bool autoGenerateForLongClips;

  final NleProxyPreviewMode previewMode;
  final NleProxyExportMode exportMode;
  final NleProxyResolutionPreset resolutionPreset;
  final NleProxyStoragePolicy storagePolicy;

  final int highBitrateThreshold;
  final int longClipThresholdMicros;
  final int maxConcurrentJobs;
  final bool pauseProxyGenerationDuringPlayback;

  const NleProjectProxySettings({
    required this.enabled,
    required this.autoGenerateOnImport,
    required this.autoGenerateFor4k,
    required this.autoGenerateForHighBitrate,
    required this.autoGenerateForHdr,
    required this.autoGenerateForLongClips,
    required this.previewMode,
    required this.exportMode,
    required this.resolutionPreset,
    required this.storagePolicy,
    required this.highBitrateThreshold,
    required this.longClipThresholdMicros,
    required this.maxConcurrentJobs,
    required this.pauseProxyGenerationDuringPlayback,
  });

  const NleProjectProxySettings.defaults()
      : enabled = true,
        autoGenerateOnImport = false,
        autoGenerateFor4k = true,
        autoGenerateForHighBitrate = true,
        autoGenerateForHdr = true,
        autoGenerateForLongClips = true,
        previewMode = NleProxyPreviewMode.automatic,
        exportMode = NleProxyExportMode.original,
        resolutionPreset = NleProxyResolutionPreset.p720,
        storagePolicy = NleProxyStoragePolicy.keepUntilDeleted,
        highBitrateThreshold = 50000000,
        longClipThresholdMicros = 120000000,
        maxConcurrentJobs = 1,
        pauseProxyGenerationDuringPlayback = true;

  NleProxyVideoSpec get videoSpec {
    return NleProxyVideoSpec.fromPreset(resolutionPreset);
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'autoGenerateOnImport': autoGenerateOnImport,
      'autoGenerateFor4k': autoGenerateFor4k,
      'autoGenerateForHighBitrate': autoGenerateForHighBitrate,
      'autoGenerateForHdr': autoGenerateForHdr,
      'autoGenerateForLongClips': autoGenerateForLongClips,
      'previewMode': previewMode.name,
      'exportMode': exportMode.name,
      'resolutionPreset': resolutionPreset.name,
      'storagePolicy': storagePolicy.name,
      'highBitrateThreshold': highBitrateThreshold,
      'longClipThresholdMicros': longClipThresholdMicros,
      'maxConcurrentJobs': maxConcurrentJobs,
      'pauseProxyGenerationDuringPlayback': pauseProxyGenerationDuringPlayback,
    };
  }

  factory NleProjectProxySettings.fromJson(Map<String, dynamic> json) {
    return NleProjectProxySettings(
      enabled: json['enabled'] != false,
      autoGenerateOnImport: json['autoGenerateOnImport'] == true,
      autoGenerateFor4k: json['autoGenerateFor4k'] != false,
      autoGenerateForHighBitrate: json['autoGenerateForHighBitrate'] != false,
      autoGenerateForHdr: json['autoGenerateForHdr'] != false,
      autoGenerateForLongClips: json['autoGenerateForLongClips'] != false,
      previewMode: _enumByName(
        NleProxyPreviewMode.values,
        json['previewMode'],
        NleProxyPreviewMode.automatic,
      ),
      exportMode: _enumByName(
        NleProxyExportMode.values,
        json['exportMode'],
        NleProxyExportMode.original,
      ),
      resolutionPreset: _enumByName(
        NleProxyResolutionPreset.values,
        json['resolutionPreset'],
        NleProxyResolutionPreset.p720,
      ),
      storagePolicy: _enumByName(
        NleProxyStoragePolicy.values,
        json['storagePolicy'],
        NleProxyStoragePolicy.keepUntilDeleted,
      ),
      highBitrateThreshold:
          (json['highBitrateThreshold'] as num?)?.toInt() ?? 50000000,
      longClipThresholdMicros:
          (json['longClipThresholdMicros'] as num?)?.toInt() ?? 120000000,
      maxConcurrentJobs: (json['maxConcurrentJobs'] as num?)?.toInt() ?? 1,
      pauseProxyGenerationDuringPlayback:
          json['pauseProxyGenerationDuringPlayback'] != false,
    );
  }

  NleProjectProxySettings copyWith({
    bool? enabled,
    bool? autoGenerateOnImport,
    bool? autoGenerateFor4k,
    bool? autoGenerateForHighBitrate,
    bool? autoGenerateForHdr,
    bool? autoGenerateForLongClips,
    NleProxyPreviewMode? previewMode,
    NleProxyExportMode? exportMode,
    NleProxyResolutionPreset? resolutionPreset,
    NleProxyStoragePolicy? storagePolicy,
    int? highBitrateThreshold,
    int? longClipThresholdMicros,
    int? maxConcurrentJobs,
    bool? pauseProxyGenerationDuringPlayback,
  }) {
    return NleProjectProxySettings(
      enabled: enabled ?? this.enabled,
      autoGenerateOnImport:
          autoGenerateOnImport ?? this.autoGenerateOnImport,
      autoGenerateFor4k: autoGenerateFor4k ?? this.autoGenerateFor4k,
      autoGenerateForHighBitrate:
          autoGenerateForHighBitrate ?? this.autoGenerateForHighBitrate,
      autoGenerateForHdr: autoGenerateForHdr ?? this.autoGenerateForHdr,
      autoGenerateForLongClips:
          autoGenerateForLongClips ?? this.autoGenerateForLongClips,
      previewMode: previewMode ?? this.previewMode,
      exportMode: exportMode ?? this.exportMode,
      resolutionPreset: resolutionPreset ?? this.resolutionPreset,
      storagePolicy: storagePolicy ?? this.storagePolicy,
      highBitrateThreshold:
          highBitrateThreshold ?? this.highBitrateThreshold,
      longClipThresholdMicros:
          longClipThresholdMicros ?? this.longClipThresholdMicros,
      maxConcurrentJobs: maxConcurrentJobs ?? this.maxConcurrentJobs,
      pauseProxyGenerationDuringPlayback:
          pauseProxyGenerationDuringPlayback ??
              this.pauseProxyGenerationDuringPlayback,
    );
  }
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? name,
  T fallback,
) {
  final string = name?.toString();
  if (string == null) return fallback;

  for (final value in values) {
    if (value.name == string) return value;
  }

  return fallback;
}
