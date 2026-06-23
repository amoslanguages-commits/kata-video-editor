class StorePlatform {
  StorePlatform._();

  static const String googlePlay = 'google_play';
  static const String appStore = 'app_store';
}

class StoreListingText {
  final String appName;
  final String shortDescription;
  final String fullDescription;
  final String subtitle;
  final String promotionalText;
  final List<String> keywords;
  final String supportEmail;
  final String privacyPolicyUrl;
  final String marketingUrl;

  const StoreListingText({
    required this.appName,
    required this.shortDescription,
    required this.fullDescription,
    required this.subtitle,
    required this.promotionalText,
    required this.keywords,
    required this.supportEmail,
    required this.privacyPolicyUrl,
    required this.marketingUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'subtitle': subtitle,
      'promotionalText': promotionalText,
      'keywords': keywords,
      'supportEmail': supportEmail,
      'privacyPolicyUrl': privacyPolicyUrl,
      'marketingUrl': marketingUrl,
    };
  }

  String toMarkdown() {
    return '''
# $appName

## Short Description

$shortDescription

## Subtitle

$subtitle

## Promotional Text

$promotionalText

## Full Description

$fullDescription

## Keywords

${keywords.join(', ')}

## Support

$supportEmail

## Privacy Policy

$privacyPolicyUrl

## Marketing URL

$marketingUrl
''';
  }
}

class StoreMetadataDrafts {
  StoreMetadataDrafts._();

  static const nleEditor = StoreListingText(
    appName: 'Kata',
    shortDescription:
        'Premium offline video editor with timeline editing, text, transitions, proxies, and high-quality export.',
    subtitle: 'Offline creator video editor',
    promotionalText:
        'Create premium short videos with offline timeline editing, text, transitions, proxies, and creator export presets.',
    fullDescription: '''
Kata is a powerful offline-first mobile video editor built for creators who want fast, professional editing directly on their phone.

Edit videos with a real timeline, trim clips, add text, apply transitions, create proxies for smoother editing, and export high-quality videos without needing a cloud workflow.

Key features:
- Offline-first project editing
- Multi-track timeline
- Video, audio, image, and text clips
- Native preview foundation
- Proxy workflow for smoother editing
- Text styles and creator presets
- Transitions and color presets
- Export presets for social media
- Local project recovery and diagnostics
- Privacy-focused local storage

Designed for:
- TikTok creators
- YouTube Shorts creators
- Instagram Reels creators
- Mobile filmmakers
- Social media editors
- Offline editing workflows

Kata keeps your projects and media on your device by default. Imported videos, images, audio, timelines, thumbnails, waveforms, proxies, autosaves, and exports are stored locally unless future optional online services are added.
''',
    keywords: [
      'video editor',
      'offline editor',
      'reels editor',
      'shorts editor',
      'timeline editor',
      'creator tools',
      'mobile editing',
      'video maker',
      'captions',
      'transitions',
      'export',
    ],
    supportEmail: 'support@example.com',
    privacyPolicyUrl: 'https://example.com/privacy',
    marketingUrl: 'https://example.com',
  );
}
