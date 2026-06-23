class AppConstants {
  AppConstants._();

  static const Map<String, String> aspectRatioLabels = {
    '9:16': 'TikTok / Reels / Shorts',
    '16:9': 'YouTube',
    '1:1': 'Instagram Feed',
    '4:5': 'Social Posts',
    '21:9': 'Cinematic',
    'custom': 'Custom',
  };

  static const List<String> aspectRatios = [
    '9:16',
    '16:9',
    '1:1',
    '4:5',
    '21:9',
    'custom',
  ];

  static const List<int> frameRates = [24, 25, 30, 50, 60];

  static const List<int> resolutions = [720, 1080, 2160];

  static const int defaultTimelineWidth = 1920;
  static const int defaultTimelineHeight = 1080;
  static const int defaultFrameRate = 30;

  static const int minClipDurationMicros = 100000;
  static const int defaultImageDurationMicros = 5000000;
  static const int defaultTextDurationMicros = 5000000;

  static const Map<String, Map<String, dynamic>> exportPresets = {
    'draft': {
      'label': 'Draft',
      'resolution': 720,
      'bitrate': '2M',
      'description': 'Fast export, lower quality',
    },
    'standard': {
      'label': 'Standard',
      'resolution': 1080,
      'bitrate': '8M',
      'description': 'Good balance of quality and size',
    },
    'high': {
      'label': 'High Quality',
      'resolution': 1080,
      'bitrate': '16M',
      'description': 'Best 1080p quality',
    },
    'premium': {
      'label': 'Premium',
      'resolution': 2160,
      'bitrate': '40M',
      'description': '4K export',
    },
  };

  static const List<String> trackTypes = [
    'video',
    'overlay',
    'audio',
    'text',
    'adjustment',
  ];

  static const Map<String, int> proxyHeights = {
    'low': 540,
    'medium': 720,
    'high': 1080,
  };
}
