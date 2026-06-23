import 'dart:convert';

class AppSettings {
  final String settingsVersion;

  final String themeMode;
  final String languageCode;

  final String defaultAspectRatio;
  final int defaultResolutionHeight;
  final int defaultFrameRate;

  final String previewQuality;
  final String proxyMode;
  final String exportPreference;

  final String defaultExportPreset;
  final String defaultExportCodec;
  final String defaultExportContainer;
  final String defaultExportBitrate;
  final String defaultAudioBitrate;

  final bool showSafeArea;
  final bool snapClips;
  final bool showWaveforms;
  final bool showThumbnails;
  final bool autoCreateProxies;
  final bool autoSaveEnabled;

  final int autosaveFrequencySeconds;

  final bool hapticsEnabled;
  final bool keepScreenAwakeDuringExport;
  final bool reducePerformanceOnLowBattery;
  final bool saveToGalleryAutomatically;
  final bool askBeforeOverwrite;

  final bool watermarkEnabledByDefault;

  final String timelineZoomBehavior;

  final DateTime updatedAt;

  const AppSettings({
    required this.settingsVersion,
    required this.themeMode,
    required this.languageCode,
    required this.defaultAspectRatio,
    required this.defaultResolutionHeight,
    required this.defaultFrameRate,
    required this.previewQuality,
    required this.proxyMode,
    required this.exportPreference,
    required this.defaultExportPreset,
    required this.defaultExportCodec,
    required this.defaultExportContainer,
    required this.defaultExportBitrate,
    required this.defaultAudioBitrate,
    required this.showSafeArea,
    required this.snapClips,
    required this.showWaveforms,
    required this.showThumbnails,
    required this.autoCreateProxies,
    required this.autoSaveEnabled,
    required this.autosaveFrequencySeconds,
    required this.hapticsEnabled,
    required this.keepScreenAwakeDuringExport,
    required this.reducePerformanceOnLowBattery,
    required this.saveToGalleryAutomatically,
    required this.askBeforeOverwrite,
    required this.watermarkEnabledByDefault,
    required this.timelineZoomBehavior,
    required this.updatedAt,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      settingsVersion: '1.0.0',
      themeMode: 'dark',
      languageCode: 'system',
      defaultAspectRatio: '9:16',
      defaultResolutionHeight: 1080,
      defaultFrameRate: 30,
      previewQuality: 'auto',
      proxyMode: 'auto',
      exportPreference: 'compatibility',
      defaultExportPreset: 'standard',
      defaultExportCodec: 'h264',
      defaultExportContainer: 'mp4',
      defaultExportBitrate: '8M',
      defaultAudioBitrate: '192k',
      showSafeArea: true,
      snapClips: true,
      showWaveforms: true,
      showThumbnails: true,
      autoCreateProxies: true,
      autoSaveEnabled: true,
      autosaveFrequencySeconds: 8,
      hapticsEnabled: true,
      keepScreenAwakeDuringExport: true,
      reducePerformanceOnLowBattery: true,
      saveToGalleryAutomatically: true,
      askBeforeOverwrite: true,
      watermarkEnabledByDefault: true,
      timelineZoomBehavior: 'pinch_and_buttons',
      updatedAt: DateTime.now(),
    );
  }

  AppSettings copyWith({
    String? settingsVersion,
    String? themeMode,
    String? languageCode,
    String? defaultAspectRatio,
    int? defaultResolutionHeight,
    int? defaultFrameRate,
    String? previewQuality,
    String? proxyMode,
    String? exportPreference,
    String? defaultExportPreset,
    String? defaultExportCodec,
    String? defaultExportContainer,
    String? defaultExportBitrate,
    String? defaultAudioBitrate,
    bool? showSafeArea,
    bool? snapClips,
    bool? showWaveforms,
    bool? showThumbnails,
    bool? autoCreateProxies,
    bool? autoSaveEnabled,
    int? autosaveFrequencySeconds,
    bool? hapticsEnabled,
    bool? keepScreenAwakeDuringExport,
    bool? reducePerformanceOnLowBattery,
    bool? saveToGalleryAutomatically,
    bool? askBeforeOverwrite,
    bool? watermarkEnabledByDefault,
    String? timelineZoomBehavior,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      settingsVersion: settingsVersion ?? this.settingsVersion,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      defaultAspectRatio: defaultAspectRatio ?? this.defaultAspectRatio,
      defaultResolutionHeight: defaultResolutionHeight ?? this.defaultResolutionHeight,
      defaultFrameRate: defaultFrameRate ?? this.defaultFrameRate,
      previewQuality: previewQuality ?? this.previewQuality,
      proxyMode: proxyMode ?? this.proxyMode,
      exportPreference: exportPreference ?? this.exportPreference,
      defaultExportPreset: defaultExportPreset ?? this.defaultExportPreset,
      defaultExportCodec: defaultExportCodec ?? this.defaultExportCodec,
      defaultExportContainer: defaultExportContainer ?? this.defaultExportContainer,
      defaultExportBitrate: defaultExportBitrate ?? this.defaultExportBitrate,
      defaultAudioBitrate: defaultAudioBitrate ?? this.defaultAudioBitrate,
      showSafeArea: showSafeArea ?? this.showSafeArea,
      snapClips: snapClips ?? this.snapClips,
      showWaveforms: showWaveforms ?? this.showWaveforms,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      autoCreateProxies: autoCreateProxies ?? this.autoCreateProxies,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      autosaveFrequencySeconds:
          autosaveFrequencySeconds ?? this.autosaveFrequencySeconds,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      keepScreenAwakeDuringExport:
          keepScreenAwakeDuringExport ?? this.keepScreenAwakeDuringExport,
      reducePerformanceOnLowBattery:
          reducePerformanceOnLowBattery ?? this.reducePerformanceOnLowBattery,
      saveToGalleryAutomatically:
          saveToGalleryAutomatically ?? this.saveToGalleryAutomatically,
      askBeforeOverwrite: askBeforeOverwrite ?? this.askBeforeOverwrite,
      watermarkEnabledByDefault:
          watermarkEnabledByDefault ?? this.watermarkEnabledByDefault,
      timelineZoomBehavior: timelineZoomBehavior ?? this.timelineZoomBehavior,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settingsVersion': settingsVersion,
      'themeMode': themeMode,
      'languageCode': languageCode,
      'defaultAspectRatio': defaultAspectRatio,
      'defaultResolutionHeight': defaultResolutionHeight,
      'defaultFrameRate': defaultFrameRate,
      'previewQuality': previewQuality,
      'proxyMode': proxyMode,
      'exportPreference': exportPreference,
      'defaultExportPreset': defaultExportPreset,
      'defaultExportCodec': defaultExportCodec,
      'defaultExportContainer': defaultExportContainer,
      'defaultExportBitrate': defaultExportBitrate,
      'defaultAudioBitrate': defaultAudioBitrate,
      'showSafeArea': showSafeArea,
      'snapClips': snapClips,
      'showWaveforms': showWaveforms,
      'showThumbnails': showThumbnails,
      'autoCreateProxies': autoCreateProxies,
      'autoSaveEnabled': autoSaveEnabled,
      'autosaveFrequencySeconds': autosaveFrequencySeconds,
      'hapticsEnabled': hapticsEnabled,
      'keepScreenAwakeDuringExport': keepScreenAwakeDuringExport,
      'reducePerformanceOnLowBattery': reducePerformanceOnLowBattery,
      'saveToGalleryAutomatically': saveToGalleryAutomatically,
      'askBeforeOverwrite': askBeforeOverwrite,
      'watermarkEnabledByDefault': watermarkEnabledByDefault,
      'timelineZoomBehavior': timelineZoomBehavior,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();

    return AppSettings(
      settingsVersion: json['settingsVersion'] as String? ?? defaults.settingsVersion,
      themeMode: json['themeMode'] as String? ?? defaults.themeMode,
      languageCode: json['languageCode'] as String? ?? defaults.languageCode,
      defaultAspectRatio:
          json['defaultAspectRatio'] as String? ?? defaults.defaultAspectRatio,
      defaultResolutionHeight:
          (json['defaultResolutionHeight'] as num?)?.round() ??
              defaults.defaultResolutionHeight,
      defaultFrameRate:
          (json['defaultFrameRate'] as num?)?.round() ?? defaults.defaultFrameRate,
      previewQuality: json['previewQuality'] as String? ?? defaults.previewQuality,
      proxyMode: json['proxyMode'] as String? ?? defaults.proxyMode,
      exportPreference:
          json['exportPreference'] as String? ?? defaults.exportPreference,
      defaultExportPreset:
          json['defaultExportPreset'] as String? ?? defaults.defaultExportPreset,
      defaultExportCodec:
          json['defaultExportCodec'] as String? ?? defaults.defaultExportCodec,
      defaultExportContainer:
          json['defaultExportContainer'] as String? ??
              defaults.defaultExportContainer,
      defaultExportBitrate:
          json['defaultExportBitrate'] as String? ??
              defaults.defaultExportBitrate,
      defaultAudioBitrate:
          json['defaultAudioBitrate'] as String? ?? defaults.defaultAudioBitrate,
      showSafeArea: json['showSafeArea'] as bool? ?? defaults.showSafeArea,
      snapClips: json['snapClips'] as bool? ?? defaults.snapClips,
      showWaveforms: json['showWaveforms'] as bool? ?? defaults.showWaveforms,
      showThumbnails: json['showThumbnails'] as bool? ?? defaults.showThumbnails,
      autoCreateProxies:
          json['autoCreateProxies'] as bool? ?? defaults.autoCreateProxies,
      autoSaveEnabled:
          json['autoSaveEnabled'] as bool? ?? defaults.autoSaveEnabled,
      autosaveFrequencySeconds:
          (json['autosaveFrequencySeconds'] as num?)?.round() ??
              defaults.autosaveFrequencySeconds,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? defaults.hapticsEnabled,
      keepScreenAwakeDuringExport:
          json['keepScreenAwakeDuringExport'] as bool? ??
              defaults.keepScreenAwakeDuringExport,
      reducePerformanceOnLowBattery:
          json['reducePerformanceOnLowBattery'] as bool? ??
              defaults.reducePerformanceOnLowBattery,
      saveToGalleryAutomatically:
          json['saveToGalleryAutomatically'] as bool? ??
              defaults.saveToGalleryAutomatically,
      askBeforeOverwrite:
          json['askBeforeOverwrite'] as bool? ?? defaults.askBeforeOverwrite,
      watermarkEnabledByDefault:
          json['watermarkEnabledByDefault'] as bool? ??
              defaults.watermarkEnabledByDefault,
      timelineZoomBehavior:
          json['timelineZoomBehavior'] as String? ?? defaults.timelineZoomBehavior,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          defaults.updatedAt,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
