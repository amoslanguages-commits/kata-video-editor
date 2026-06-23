class PrivacyDataCategory {
  PrivacyDataCategory._();

  static const String mediaFiles = 'media_files';
  static const String projects = 'projects';
  static const String diagnostics = 'diagnostics';
  static const String crashLogs = 'crash_logs';
  static const String analytics = 'analytics';
  static const String purchases = 'purchases';
  static const String deviceInfo = 'device_info';
}

class PrivacyDataItem {
  final String category;
  final String title;
  final String description;
  final bool storedOnDevice;
  final bool leavesDevice;
  final bool userControlled;
  final String retention;

  const PrivacyDataItem({
    required this.category,
    required this.title,
    required this.description,
    required this.storedOnDevice,
    required this.leavesDevice,
    required this.userControlled,
    required this.retention,
  });
}

class PrivacyDataMap {
  PrivacyDataMap._();

  static const items = <PrivacyDataItem>[
    PrivacyDataItem(
      category: PrivacyDataCategory.mediaFiles,
      title: 'Imported media files',
      description:
          'Videos, images, and audio selected by the user for editing.',
      storedOnDevice: true,
      leavesDevice: false,
      userControlled: true,
      retention: 'Kept until the user removes the project or media.',
    ),
    PrivacyDataItem(
      category: PrivacyDataCategory.projects,
      title: 'Project files',
      description:
          'Timeline edits, clips, tracks, keyframes, transitions, text styles, and local project metadata.',
      storedOnDevice: true,
      leavesDevice: false,
      userControlled: true,
      retention: 'Kept until the user deletes the project.',
    ),
    PrivacyDataItem(
      category: PrivacyDataCategory.diagnostics,
      title: 'Diagnostics logs',
      description:
          'Local technical logs used to troubleshoot exports, permissions, missing files, and native engine issues.',
      storedOnDevice: true,
      leavesDevice: false,
      userControlled: true,
      retention: 'Can be cleared by the user from diagnostics.',
    ),
    PrivacyDataItem(
      category: PrivacyDataCategory.crashLogs,
      title: 'Crash reports',
      description:
          'Optional crash information for production debugging if crash reporting is enabled.',
      storedOnDevice: true,
      leavesDevice: true,
      userControlled: false,
      retention: 'Depends on the selected crash provider.',
    ),
    PrivacyDataItem(
      category: PrivacyDataCategory.analytics,
      title: 'Usage analytics',
      description:
          'Optional anonymous product events if analytics is enabled.',
      storedOnDevice: false,
      leavesDevice: true,
      userControlled: false,
      retention: 'Depends on the selected analytics provider.',
    ),
    PrivacyDataItem(
      category: PrivacyDataCategory.purchases,
      title: 'Purchase state',
      description:
          'Subscription or entitlement status when monetization is added.',
      storedOnDevice: true,
      leavesDevice: true,
      userControlled: false,
      retention: 'Depends on app store billing records.',
    ),
    PrivacyDataItem(
      category: PrivacyDataCategory.deviceInfo,
      title: 'Device capability profile',
      description:
          'Local device performance information used for preview quality, proxies, and export recommendations.',
      storedOnDevice: true,
      leavesDevice: false,
      userControlled: true,
      retention: 'Can be reset by clearing app data.',
    ),
  ];
}
