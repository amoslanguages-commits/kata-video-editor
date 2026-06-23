class StoreScreenshot {
  final String id;
  final String title;
  final String caption;
  final String scene;
  final String requiredUiState;
  final List<String> notes;

  const StoreScreenshot({
    required this.id,
    required this.title,
    required this.caption,
    required this.scene,
    required this.requiredUiState,
    this.notes = const [],
  });
}

class StoreScreenshotPlan {
  StoreScreenshotPlan._();

  static const phoneScreenshots = <StoreScreenshot>[
    StoreScreenshot(
      id: 'shot_01_timeline',
      title: 'Premium Timeline Editor',
      caption: 'Edit videos with a real mobile timeline',
      scene: 'Main editor with multi-track timeline and preview visible.',
      requiredUiState:
          'Project open, 3 video clips, 1 audio clip, 1 text clip, playhead visible.',
      notes: [
        'Use vertical 9:16 project.',
        'Show clean premium UI.',
        'Avoid copyrighted media.',
      ],
    ),
    StoreScreenshot(
      id: 'shot_02_text',
      title: 'Creator Text Styles',
      caption: 'Add captions, titles, and hooks fast',
      scene: 'Text style panel with bold caption on preview.',
      requiredUiState: 'Selected text clip, text style panel open.',
      notes: [
        'Use sample text like WAIT FOR IT or NEW LOOK.',
        'Do not use famous brand names.',
      ],
    ),
    StoreScreenshot(
      id: 'shot_03_transitions',
      title: 'Smooth Transitions',
      caption: 'Make clips flow with cinematic motion',
      scene: 'Transition panel open with preview timeline.',
      requiredUiState: 'Two clips connected with dissolve or push transition.',
    ),
    StoreScreenshot(
      id: 'shot_04_proxy',
      title: 'Smooth Editing With Proxies',
      caption: 'Create proxy files for heavy videos',
      scene: 'Media pool with proxy recommendation banner.',
      requiredUiState: 'Large video imported, proxy recommendation visible.',
    ),
    StoreScreenshot(
      id: 'shot_05_export',
      title: 'Export For Social Media',
      caption: 'Use ready presets for Shorts, Reels, and TikTok',
      scene: 'Export screen with Social 1080p preset selected.',
      requiredUiState: 'Export options visible, include audio enabled.',
    ),
    StoreScreenshot(
      id: 'shot_06_diagnostics',
      title: 'Reliable Project Recovery',
      caption: 'Diagnostics help fix missing media and failed exports',
      scene: 'Diagnostics screen with healthy status cards.',
      requiredUiState: 'Diagnostics screen open, no critical issues.',
    ),
    StoreScreenshot(
      id: 'shot_07_offline',
      title: 'Offline-First Editing',
      caption: 'Your projects stay on your device by default',
      scene: 'Privacy & Data screen or project storage screen.',
      requiredUiState: 'Offline privacy summary visible.',
    ),
  ];
}
