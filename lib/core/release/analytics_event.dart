class AnalyticsEventName {
  AnalyticsEventName._();

  static const String appOpened = 'app_opened';
  static const String projectCreated = 'project_created';
  static const String mediaImported = 'media_imported';
  static const String timelineClipAdded = 'timeline_clip_added';
  static const String exportStarted = 'export_started';
  static const String exportCompleted = 'export_completed';
  static const String exportFailed = 'export_failed';
  static const String proxyStarted = 'proxy_started';
  static const String proxyCompleted = 'proxy_completed';
  static const String premiumPackOpened = 'premium_pack_opened';
  static const String proUpgradeViewed = 'pro_upgrade_viewed';
  static const String diagnosticsOpened = 'diagnostics_opened';
}

class AnalyticsEvent {
  final String name;
  final Map<String, Object?> parameters;

  const AnalyticsEvent({
    required this.name,
    this.parameters = const {},
  });
}
