class OfflinePrivacySummary {
  static const String shortText =
      'This editor is designed offline-first. Your imported videos, audio, images, timelines, proxies, thumbnails, and exports are stored on your device by default.';

  static const String longText = '''
Kata is designed as an offline-first video editor.

By default:
- Your media stays on your device.
- Your projects are stored locally.
- Proxies, thumbnails, waveforms, autosaves, and exports are stored locally.
- The app does not need a cloud backend to edit or export.
- Diagnostics logs are local unless a future support/export option is added.

Optional future services may include:
- crash reporting
- analytics
- purchases/subscriptions

These should be clearly disclosed before production release.
''';
}
