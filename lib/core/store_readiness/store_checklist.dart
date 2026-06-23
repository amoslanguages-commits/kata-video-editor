import 'package:nle_editor/core/store_readiness/store_metadata.dart';

class StoreChecklistGroup {
  final String id;
  final String title;
  final String platform;
  final List<StoreChecklistItem> items;

  const StoreChecklistGroup({
    required this.id,
    required this.title,
    required this.platform,
    required this.items,
  });
}

class StoreChecklistItem {
  final String id;
  final String title;
  final String description;
  final bool required;
  final String riskIfMissing;

  const StoreChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.required,
    required this.riskIfMissing,
  });
}

class StoreChecklistCatalog {
  StoreChecklistCatalog._();

  static const groups = <StoreChecklistGroup>[
    StoreChecklistGroup(
      id: 'google_play_listing',
      title: 'Google Play Listing',
      platform: StorePlatform.googlePlay,
      items: [
        StoreChecklistItem(
          id: 'play_app_name',
          title: 'App name',
          description: 'Confirm production app name is final and not misleading.',
          required: true,
          riskIfMissing: 'Weak branding or review rejection.',
        ),
        StoreChecklistItem(
          id: 'play_short_description',
          title: 'Short description',
          description: 'Write a clear short description for Play Store.',
          required: true,
          riskIfMissing: 'Low conversion and unclear app purpose.',
        ),
        StoreChecklistItem(
          id: 'play_full_description',
          title: 'Full description',
          description: 'Describe features, offline-first behavior, and creator workflow.',
          required: true,
          riskIfMissing: 'Store page may feel incomplete.',
        ),
        StoreChecklistItem(
          id: 'play_screenshots',
          title: 'Phone screenshots',
          description: 'Prepare screenshots that show real UI and main benefits.',
          required: true,
          riskIfMissing: 'Store listing will look weak or incomplete.',
        ),
        StoreChecklistItem(
          id: 'play_feature_graphic',
          title: 'Feature graphic',
          description: 'Prepare Google Play feature graphic.',
          required: true,
          riskIfMissing: 'Play listing may be incomplete for promotion areas.',
        ),
        StoreChecklistItem(
          id: 'play_data_safety',
          title: 'Data safety form',
          description: 'Complete collection, sharing, security, and deletion answers.',
          required: true,
          riskIfMissing: 'Submission can be blocked or rejected.',
        ),
        StoreChecklistItem(
          id: 'play_content_rating',
          title: 'Content rating',
          description: 'Complete content rating questionnaire.',
          required: true,
          riskIfMissing: 'App may not be publishable.',
        ),
        StoreChecklistItem(
          id: 'play_permissions',
          title: 'Permission declarations',
          description: 'Explain media, audio, notification, and storage-related permissions.',
          required: true,
          riskIfMissing: 'Reviewers may reject sensitive permission usage.',
        ),
        StoreChecklistItem(
          id: 'play_internal_testing',
          title: 'Internal testing track',
          description: 'Prepare tester list and internal release notes.',
          required: true,
          riskIfMissing: 'Bugs may reach production.',
        ),
      ],
    ),
    StoreChecklistGroup(
      id: 'app_store_listing',
      title: 'App Store Listing',
      platform: StorePlatform.appStore,
      items: [
        StoreChecklistItem(
          id: 'ios_app_name',
          title: 'App name',
          description: 'Confirm App Store name fits Apple metadata rules.',
          required: true,
          riskIfMissing: 'Metadata rejection or weak branding.',
        ),
        StoreChecklistItem(
          id: 'ios_subtitle',
          title: 'Subtitle',
          description: 'Write a short value proposition.',
          required: true,
          riskIfMissing: 'Lower search and conversion clarity.',
        ),
        StoreChecklistItem(
          id: 'ios_keywords',
          title: 'Keywords',
          description: 'Use accurate keywords, no irrelevant/trademark stuffing.',
          required: true,
          riskIfMissing: 'Poor discoverability or metadata rejection.',
        ),
        StoreChecklistItem(
          id: 'ios_description',
          title: 'Description',
          description: 'Describe real features and offline-first behavior.',
          required: true,
          riskIfMissing: 'Weak product page.',
        ),
        StoreChecklistItem(
          id: 'ios_screenshots',
          title: 'Screenshots',
          description: 'Prepare screenshots for required device sizes.',
          required: true,
          riskIfMissing: 'App Store submission cannot be completed properly.',
        ),
        StoreChecklistItem(
          id: 'ios_privacy_labels',
          title: 'App privacy details',
          description: 'Complete App Store privacy labels accurately.',
          required: true,
          riskIfMissing: 'App review or update submission can be blocked.',
        ),
        StoreChecklistItem(
          id: 'ios_testflight',
          title: 'TestFlight beta',
          description: 'Prepare internal/external tester notes.',
          required: true,
          riskIfMissing: 'Poor beta feedback and review confidence.',
        ),
        StoreChecklistItem(
          id: 'ios_review_notes',
          title: 'App Review notes',
          description: 'Explain offline-first editor behavior and permission reasons.',
          required: true,
          riskIfMissing: 'Review team may misunderstand app behavior.',
        ),
      ],
    ),
    StoreChecklistGroup(
      id: 'shared_store_assets',
      title: 'Shared Store Assets',
      platform: 'shared',
      items: [
        StoreChecklistItem(
          id: 'promo_video',
          title: 'Promo video',
          description: 'Prepare a short video showing import, edit, text, transition, export.',
          required: false,
          riskIfMissing: 'Store page may be less convincing.',
        ),
        StoreChecklistItem(
          id: 'privacy_policy',
          title: 'Privacy policy URL',
          description: 'Publish final privacy policy page.',
          required: true,
          riskIfMissing: 'Submission may fail.',
        ),
        StoreChecklistItem(
          id: 'support_channel',
          title: 'Support channel',
          description: 'Prepare support email or website.',
          required: true,
          riskIfMissing: 'Users and reviewers cannot contact support.',
        ),
        StoreChecklistItem(
          id: 'beta_feedback_form',
          title: 'Beta feedback form',
          description: 'Create a simple issue-report form for testers.',
          required: true,
          riskIfMissing: 'Tester feedback will be messy.',
        ),
      ],
    ),
  ];
}
