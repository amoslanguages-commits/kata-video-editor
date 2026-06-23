class PermissionJustification {
  final String permission;
  final String storeReason;
  final String userFacingReason;
  final bool requiredForCoreFeature;

  const PermissionJustification({
    required this.permission,
    required this.storeReason,
    required this.userFacingReason,
    required this.requiredForCoreFeature,
  });
}

class PermissionJustificationCatalog {
  PermissionJustificationCatalog._();

  static const permissions = <PermissionJustification>[
    PermissionJustification(
      permission: 'Photos / Videos / Media Library',
      storeReason:
          'Used to let users choose videos, images, and audio for editing, reconnect missing media, and save exports.',
      userFacingReason:
          'Allow media access so you can import videos, images, and audio into your project.',
      requiredForCoreFeature: true,
    ),
    PermissionJustification(
      permission: 'Microphone',
      storeReason:
          'Used only if the app adds voice recording or live vocal capture features.',
      userFacingReason:
          'Allow microphone access to record voice or audio directly into your project.',
      requiredForCoreFeature: false,
    ),
    PermissionJustification(
      permission: 'Notifications',
      storeReason:
          'Used to notify users when long exports or proxy jobs finish, if enabled.',
      userFacingReason:
          'Allow notifications to know when exports or proxy jobs finish.',
      requiredForCoreFeature: false,
    ),
    PermissionJustification(
      permission: 'Storage / File access',
      storeReason:
          'Used for local project files, cache, proxies, waveforms, thumbnails, and exported videos.',
      userFacingReason:
          'The editor stores project files and exports locally on your device.',
      requiredForCoreFeature: true,
    ),
  ];
}
