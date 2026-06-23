class AppPermissionType {
  AppPermissionType._();

  static const String mediaLibrary = 'media_library';
  static const String mediaImages = 'media_images';
  static const String mediaVideos = 'media_videos';
  static const String mediaAudio = 'media_audio';
  static const String gallerySave = 'gallery_save';
  static const String microphone = 'microphone';
  static const String notifications = 'notifications';
}

class AppPermissionStatusValue {
  AppPermissionStatusValue._();

  static const String unknown = 'unknown';
  static const String granted = 'granted';
  static const String limited = 'limited';
  static const String denied = 'denied';
  static const String permanentlyDenied = 'permanently_denied';
  static const String restricted = 'restricted';
  static const String notSupported = 'not_supported';
}

class AppPermissionPurpose {
  final String title;
  final String message;
  final String primaryButton;
  final String secondaryButton;
  final String deniedTitle;
  final String deniedMessage;
  final String settingsMessage;
  final String iconName;

  const AppPermissionPurpose({
    required this.title,
    required this.message,
    required this.primaryButton,
    required this.secondaryButton,
    required this.deniedTitle,
    required this.deniedMessage,
    required this.settingsMessage,
    required this.iconName,
  });
}

class AppPermissionState {
  final String type;
  final String status;
  final bool canRequestAgain;
  final bool shouldOpenSettings;
  final bool hasLimitedAccess;
  final DateTime checkedAt;
  final String? platformRawStatus;

  const AppPermissionState({
    required this.type,
    required this.status,
    required this.canRequestAgain,
    required this.shouldOpenSettings,
    required this.hasLimitedAccess,
    required this.checkedAt,
    this.platformRawStatus,
  });

  bool get isGranted => status == AppPermissionStatusValue.granted;

  bool get isLimited => status == AppPermissionStatusValue.limited;

  bool get isDenied => status == AppPermissionStatusValue.denied;

  bool get isPermanentlyDenied =>
      status == AppPermissionStatusValue.permanentlyDenied;

  bool get hasAccess => isGranted || isLimited || hasLimitedAccess;

  AppPermissionState copyWith({
    String? status,
    bool? canRequestAgain,
    bool? shouldOpenSettings,
    bool? hasLimitedAccess,
    DateTime? checkedAt,
    String? platformRawStatus,
  }) {
    return AppPermissionState(
      type: type,
      status: status ?? this.status,
      canRequestAgain: canRequestAgain ?? this.canRequestAgain,
      shouldOpenSettings: shouldOpenSettings ?? this.shouldOpenSettings,
      hasLimitedAccess: hasLimitedAccess ?? this.hasLimitedAccess,
      checkedAt: checkedAt ?? this.checkedAt,
      platformRawStatus: platformRawStatus ?? this.platformRawStatus,
    );
  }

  factory AppPermissionState.unknown(String type) {
    return AppPermissionState(
      type: type,
      status: AppPermissionStatusValue.unknown,
      canRequestAgain: true,
      shouldOpenSettings: false,
      hasLimitedAccess: false,
      checkedAt: DateTime.now(),
    );
  }
}

class AppPermissionPurposes {
  AppPermissionPurposes._();

  static AppPermissionPurpose forType(String type) {
    switch (type) {
      case AppPermissionType.mediaLibrary:
        return const AppPermissionPurpose(
          title: 'Import your media',
          message:
              'To import your videos, images, and audio, allow access to your media library.',
          primaryButton: 'Allow Media Access',
          secondaryButton: 'Not Now',
          deniedTitle: 'Media access is off',
          deniedMessage:
              'You can still use the app, but you need media access to import videos into a project.',
          settingsMessage:
              'Open settings and allow media access to import your videos.',
          iconName: 'video_library',
        );

      case AppPermissionType.mediaImages:
        return const AppPermissionPurpose(
          title: 'Import your images',
          message:
              'To import images, allow access to your photos.',
          primaryButton: 'Allow Image Access',
          secondaryButton: 'Not Now',
          deniedTitle: 'Image access is off',
          deniedMessage:
              'You can still use the app, but you need image access to import images into a project.',
          settingsMessage:
              'Open settings and allow photo access to import your images.',
          iconName: 'image',
        );

      case AppPermissionType.mediaVideos:
        return const AppPermissionPurpose(
          title: 'Import your videos',
          message:
              'To import videos, allow access to your video library.',
          primaryButton: 'Allow Video Access',
          secondaryButton: 'Not Now',
          deniedTitle: 'Video access is off',
          deniedMessage:
              'You can still use the app, but you need video access to import videos into a project.',
          settingsMessage:
              'Open settings and allow video access to import your videos.',
          iconName: 'videocam',
        );

      case AppPermissionType.mediaAudio:
        return const AppPermissionPurpose(
          title: 'Import your audio',
          message:
              'To import audio, allow access to your audio files.',
          primaryButton: 'Allow Audio Access',
          secondaryButton: 'Not Now',
          deniedTitle: 'Audio access is off',
          deniedMessage:
              'You can still use the app, but you need audio access to import music and sound effects.',
          settingsMessage:
              'Open settings and allow audio access to import your audio files.',
          iconName: 'audiotrack',
        );

      case AppPermissionType.gallerySave:
        return const AppPermissionPurpose(
          title: 'Save exported videos',
          message:
              'To save your finished video to your gallery, allow photo library save access.',
          primaryButton: 'Allow Saving',
          secondaryButton: 'Not Now',
          deniedTitle: 'Gallery save access is off',
          deniedMessage:
              'The export may finish, but the app cannot add it to your gallery without permission.',
          settingsMessage:
              'Open settings and allow photo library access to save exports.',
          iconName: 'save_alt',
        );

      case AppPermissionType.microphone:
        return const AppPermissionPurpose(
          title: 'Record voiceover',
          message:
              'To record voiceovers inside your project, allow microphone access.',
          primaryButton: 'Allow Microphone',
          secondaryButton: 'Not Now',
          deniedTitle: 'Microphone access is off',
          deniedMessage:
              'Voiceover recording needs microphone permission. You can still edit existing media.',
          settingsMessage:
              'Open settings and allow microphone access to record voiceovers.',
          iconName: 'mic',
        );

      case AppPermissionType.notifications:
        return const AppPermissionPurpose(
          title: 'Export progress notifications',
          message:
              'Allow notifications so the app can tell you when long exports finish.',
          primaryButton: 'Allow Notifications',
          secondaryButton: 'Not Now',
          deniedTitle: 'Notifications are off',
          deniedMessage:
              'Export will still work, but the app may not notify you when it finishes in the background.',
          settingsMessage:
              'Open settings and allow notifications for export progress.',
          iconName: 'notifications',
        );

      default:
        return const AppPermissionPurpose(
          title: 'Permission needed',
          message: 'This feature needs permission to continue.',
          primaryButton: 'Allow',
          secondaryButton: 'Not Now',
          deniedTitle: 'Permission is off',
          deniedMessage: 'Allow this permission to use the feature.',
          settingsMessage: 'Open settings and allow permission.',
          iconName: 'lock',
        );
    }
  }
}
