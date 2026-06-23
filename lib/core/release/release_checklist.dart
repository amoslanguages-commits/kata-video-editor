class ReleaseChecklistGroup {
  final String id;
  final String title;
  final List<ReleaseChecklistItem> items;

  const ReleaseChecklistGroup({
    required this.id,
    required this.title,
    required this.items,
  });
}

class ReleaseChecklistItem {
  final String id;
  final String title;
  final String description;
  final bool requiredForProduction;

  const ReleaseChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.requiredForProduction = true,
  });
}

class ReleaseChecklistCatalog {
  ReleaseChecklistCatalog._();

  static const groups = <ReleaseChecklistGroup>[
    ReleaseChecklistGroup(
      id: 'build_config',
      title: 'Build Configuration',
      items: [
        ReleaseChecklistItem(
          id: 'prod_flavor_runs',
          title: 'Production flavor runs',
          description: 'Run the app using main_prod.dart and confirm production config.',
        ),
        ReleaseChecklistItem(
          id: 'dev_tools_hidden',
          title: 'Developer tools hidden',
          description: 'Confirm diagnostics/dev Pro unlock are hidden or restricted in production.',
        ),
        ReleaseChecklistItem(
          id: 'package_name_correct',
          title: 'Package name correct',
          description: 'Confirm app ID/package name uses production identifier.',
        ),
        ReleaseChecklistItem(
          id: 'version_updated',
          title: 'Version updated',
          description: 'Confirm version and build number are correct.',
        ),
      ],
    ),
    ReleaseChecklistGroup(
      id: 'android',
      title: 'Android Release',
      items: [
        ReleaseChecklistItem(
          id: 'android_signing_ready',
          title: 'Signing configured',
          description: 'Confirm upload key, key.properties, and release signing config are ready.',
        ),
        ReleaseChecklistItem(
          id: 'android_aab_builds',
          title: 'AAB builds',
          description: 'Run flutter build appbundle for production flavor.',
        ),
        ReleaseChecklistItem(
          id: 'android_permissions_reviewed',
          title: 'Permissions reviewed',
          description: 'Check AndroidManifest permissions match app features.',
        ),
      ],
    ),
    ReleaseChecklistGroup(
      id: 'ios',
      title: 'iOS Release',
      items: [
        ReleaseChecklistItem(
          id: 'ios_bundle_id_ready',
          title: 'Bundle ID ready',
          description: 'Confirm production Bundle Identifier in Xcode.',
        ),
        ReleaseChecklistItem(
          id: 'ios_signing_ready',
          title: 'Signing ready',
          description: 'Confirm Apple Developer team and provisioning settings.',
        ),
        ReleaseChecklistItem(
          id: 'ios_archive_builds',
          title: 'Archive builds',
          description: 'Create release archive in Xcode or Flutter build ipa.',
        ),
      ],
    ),
    ReleaseChecklistGroup(
      id: 'privacy',
      title: 'Privacy & Compliance',
      items: [
        ReleaseChecklistItem(
          id: 'privacy_policy_ready',
          title: 'Privacy policy ready',
          description: 'Publish privacy policy and update production URL.',
        ),
        ReleaseChecklistItem(
          id: 'data_map_reviewed',
          title: 'Data map reviewed',
          description: 'Review local data, crash logs, analytics, and purchase data disclosures.',
        ),
        ReleaseChecklistItem(
          id: 'offline_claim_verified',
          title: 'Offline-first claim verified',
          description: 'Confirm editing/export works without internet when no online features are used.',
        ),
      ],
    ),
    ReleaseChecklistGroup(
      id: 'qa',
      title: 'Internal Testing',
      items: [
        ReleaseChecklistItem(
          id: 'import_tested',
          title: 'Import tested',
          description: 'Test video, audio, and image import.',
        ),
        ReleaseChecklistItem(
          id: 'export_tested',
          title: 'Export tested',
          description: 'Test export with text, transition, effects, and audio.',
        ),
        ReleaseChecklistItem(
          id: 'recovery_tested',
          title: 'Recovery tested',
          description: 'Force-close app and confirm autosave/recovery works.',
        ),
        ReleaseChecklistItem(
          id: 'low_storage_tested',
          title: 'Low storage tested',
          description: 'Confirm storage warnings and cleanup tools.',
        ),
        ReleaseChecklistItem(
          id: 'missing_media_tested',
          title: 'Missing media tested',
          description: 'Confirm missing-media reconnect flow.',
        ),
      ],
    ),
  ];
}
