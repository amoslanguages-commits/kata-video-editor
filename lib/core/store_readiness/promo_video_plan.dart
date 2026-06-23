class PromoVideoSegment {
  final String id;
  final Duration start;
  final Duration end;
  final String scene;
  final String onScreenText;
  final String motion;
  final String notes;

  const PromoVideoSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.scene,
    required this.onScreenText,
    required this.motion,
    required this.notes,
  });
}

class PromoVideoPlan {
  PromoVideoPlan._();

  static const segments = <PromoVideoSegment>[
    PromoVideoSegment(
      id: 'opening',
      start: Duration(seconds: 0),
      end: Duration(seconds: 3),
      scene: 'Fast montage of app preview and timeline.',
      onScreenText: 'Edit anywhere',
      motion: 'Quick zoom-in to timeline.',
      notes: 'Show phone UI, not abstract animation only.',
    ),
    PromoVideoSegment(
      id: 'import',
      start: Duration(seconds: 3),
      end: Duration(seconds: 6),
      scene: 'Import videos/images/audio into media pool.',
      onScreenText: 'Import your media',
      motion: 'Tap/import animation.',
      notes: 'Use royalty-free sample clips.',
    ),
    PromoVideoSegment(
      id: 'timeline',
      start: Duration(seconds: 6),
      end: Duration(seconds: 10),
      scene: 'Trim, split, move clips on timeline.',
      onScreenText: 'Timeline editing',
      motion: 'Swipe timeline, trim clip handles.',
      notes: 'Show smooth scrolling.',
    ),
    PromoVideoSegment(
      id: 'text',
      start: Duration(seconds: 10),
      end: Duration(seconds: 14),
      scene: 'Apply viral text style.',
      onScreenText: 'Creator captions',
      motion: 'Text appears on preview.',
      notes: 'Use big readable text.',
    ),
    PromoVideoSegment(
      id: 'transitions',
      start: Duration(seconds: 14),
      end: Duration(seconds: 18),
      scene: 'Apply transition between clips.',
      onScreenText: 'Smooth transitions',
      motion: 'Before/after transition preview.',
      notes: 'Keep it short.',
    ),
    PromoVideoSegment(
      id: 'export',
      start: Duration(seconds: 18),
      end: Duration(seconds: 23),
      scene: 'Choose export preset and complete export.',
      onScreenText: 'Export for socials',
      motion: 'Export progress and final preview.',
      notes: 'End with app logo.',
    ),
  ];
}
