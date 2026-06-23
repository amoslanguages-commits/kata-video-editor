class TransitionPreset {
  final String id;
  final String name;
  final String category;
  final String description;
  final bool isPremium;
  final bool gpuRequired;
  final Map<String, dynamic> defaultParameters;

  const TransitionPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.isPremium,
    required this.gpuRequired,
    required this.defaultParameters,
  });
}

class TransitionPresets {
  TransitionPresets._();

  static const List<TransitionPreset> all = [
    TransitionPreset(
      id: 'dissolve',
      name: 'Dissolve',
      category: 'Basic',
      description: 'Soft blend between two clips.',
      isPremium: false,
      gpuRequired: false,
      defaultParameters: {},
    ),
    TransitionPreset(
      id: 'fade_black',
      name: 'Fade Black',
      category: 'Basic',
      description: 'Fade through black.',
      isPremium: false,
      gpuRequired: false,
      defaultParameters: {
        'color': '#000000',
      },
    ),
    TransitionPreset(
      id: 'fade_white',
      name: 'Fade White',
      category: 'Basic',
      description: 'Fade through white.',
      isPremium: false,
      gpuRequired: false,
      defaultParameters: {
        'color': '#FFFFFF',
      },
    ),
    TransitionPreset(
      id: 'slide_left',
      name: 'Slide Left',
      category: 'Motion',
      description: 'Incoming clip slides from the right.',
      isPremium: false,
      gpuRequired: true,
      defaultParameters: {
        'direction': 'left',
      },
    ),
    TransitionPreset(
      id: 'slide_right',
      name: 'Slide Right',
      category: 'Motion',
      description: 'Incoming clip slides from the left.',
      isPremium: false,
      gpuRequired: true,
      defaultParameters: {
        'direction': 'right',
      },
    ),
    TransitionPreset(
      id: 'push_up',
      name: 'Push Up',
      category: 'Motion',
      description: 'Push transition upward.',
      isPremium: false,
      gpuRequired: true,
      defaultParameters: {
        'direction': 'up',
      },
    ),
    TransitionPreset(
      id: 'zoom_blur',
      name: 'Zoom Blur',
      category: 'Premium',
      description: 'Fast creator-style zoom blur.',
      isPremium: true,
      gpuRequired: true,
      defaultParameters: {
        'blur': 0.6,
        'zoom': 1.25,
      },
    ),
    TransitionPreset(
      id: 'flash',
      name: 'Flash',
      category: 'Social',
      description: 'Quick flash cut for energetic videos.',
      isPremium: false,
      gpuRequired: true,
      defaultParameters: {
        'intensity': 0.8,
      },
    ),
    TransitionPreset(
      id: 'glitch',
      name: 'Glitch',
      category: 'Premium',
      description: 'Digital glitch transition.',
      isPremium: true,
      gpuRequired: true,
      defaultParameters: {
        'strength': 0.7,
        'rgbSplit': 0.5,
      },
    ),
    TransitionPreset(
      id: 'wipe_left',
      name: 'Wipe Left',
      category: 'Wipe',
      description: 'Wipe transition to the left.',
      isPremium: false,
      gpuRequired: true,
      defaultParameters: {
        'direction': 'left',
        'sweepWidth': 0.2,
      },
    ),
    TransitionPreset(
      id: 'wipe_right',
      name: 'Wipe Right',
      category: 'Wipe',
      description: 'Wipe transition to the right.',
      isPremium: false,
      gpuRequired: true,
      defaultParameters: {
        'direction': 'right',
        'sweepWidth': 0.2,
      },
    ),
  ];

  static TransitionPreset byId(String id) {
    return all.firstWhere(
      (preset) => preset.id == id,
      orElse: () => all.first,
    );
  }
}
