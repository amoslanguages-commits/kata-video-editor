class BetaTestingPhase {
  final String id;
  final String title;
  final String goal;
  final Duration duration;
  final int targetTesterCount;
  final List<String> testerTasks;
  final List<String> exitCriteria;

  const BetaTestingPhase({
    required this.id,
    required this.title,
    required this.goal,
    required this.duration,
    required this.targetTesterCount,
    required this.testerTasks,
    required this.exitCriteria,
  });
}

class BetaTestingPlan {
  BetaTestingPlan._();

  static const phases = <BetaTestingPhase>[
    BetaTestingPhase(
      id: 'internal_alpha',
      title: 'Internal Alpha',
      goal: 'Find crashes, broken flows, and native engine issues.',
      duration: Duration(days: 7),
      targetTesterCount: 5,
      testerTasks: [
        'Create 3 projects.',
        'Import video, audio, and image files.',
        'Trim and move clips.',
        'Add text and transition.',
        'Generate proxy.',
        'Export with audio.',
        'Test missing media reconnect.',
        'Force-close app and test recovery.',
      ],
      exitCriteria: [
        'No startup crashes.',
        'No project creation crashes.',
        'Export failure shows friendly error.',
        'Missing media reconnect works.',
      ],
    ),
    BetaTestingPhase(
      id: 'closed_beta',
      title: 'Closed Beta',
      goal: 'Test on more devices and gather creator feedback.',
      duration: Duration(days: 14),
      targetTesterCount: 25,
      testerTasks: [
        'Create one real short video.',
        'Test timeline scrolling with 20+ clips.',
        'Test export presets.',
        'Test cache cleanup.',
        'Report slow screens.',
      ],
      exitCriteria: [
        'Crash-free editing sessions improve.',
        'Top 10 usability issues identified.',
        'Export works on common test devices.',
      ],
    ),
    BetaTestingPhase(
      id: 'release_candidate',
      title: 'Release Candidate',
      goal: 'Validate production build before public release.',
      duration: Duration(days: 7),
      targetTesterCount: 50,
      testerTasks: [
        'Install production-signed build.',
        'Test offline editing.',
        'Test permissions from clean install.',
        'Test privacy/data screens.',
        'Test production config hides dev tools.',
      ],
      exitCriteria: [
        'Production config verified.',
        'Store listing assets complete.',
        'Privacy labels ready.',
        'No known critical bugs.',
      ],
    ),
  ];
}
