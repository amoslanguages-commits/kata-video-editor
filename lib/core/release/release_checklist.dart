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
          description: 'Run the app using the prod flavor and confirm production config.',
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
      id: 'ci_gate',
      title: 'CI & Release Candidate Gate',
      items: [
        ReleaseChecklistItem(
          id: 'github_ci_green',
          title: 'GitHub CI is green',
          description: 'Confirm Flutter Android CI passes codegen, formatting, analyze, tests, and dev/staging debug builds.',
        ),
        ReleaseChecklistItem(
          id: 'release_candidate_gate_green',
          title: 'Release candidate gate passes',
          description: 'Run the Release Candidate Gate workflow or dart run tool/release_candidate_gate.dart locally.',
        ),
        ReleaseChecklistItem(
          id: 'prod_bundle_generated',
          title: 'Production bundle generated',
          description: 'Build the prod app bundle from the release candidate workflow or local Flutter command.',
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
          description: 'Confirm upload key, key.properties, and release signing config are ready locally or in CI secrets.',
        ),
        ReleaseChecklistItem(
          id: 'android_aab_builds',
          title: 'AAB builds',
          description: 'Run flutter build appbundle --release --flavor prod -t lib/main.dart.',
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
    ReleaseChecklistGroup(
      id: 'device_failure_matrix',
      title: 'Device Failure Matrix',
      items: [
        ReleaseChecklistItem(
          id: 'low_end_device_export',
          title: 'Low-end device export tested',
          description: 'Test a proxy-assisted export on a low-memory or older Android device.',
        ),
        ReleaseChecklistItem(
          id: 'thermal_interruption_tested',
          title: 'Thermal/interruption behavior tested',
          description: 'Confirm export reports warnings or failure cleanly when interrupted or under thermal pressure.',
        ),
        ReleaseChecklistItem(
          id: 'storage_full_tested',
          title: 'Storage-full failure tested',
          description: 'Confirm export failure is recoverable and cache cleanup remains available when storage is low.',
        ),
      ],
    ),
  ];
}
