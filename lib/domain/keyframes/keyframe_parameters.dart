class KeyframeValueType {
  KeyframeValueType._();

  static const String number = 'number';
  static const String bool = 'bool';
  static const String string = 'string';
  static const String color = 'color';
  static const String json = 'json';
}

class KeyframeInterpolation {
  KeyframeInterpolation._();

  static const String hold = 'hold';
  static const String linear = 'linear';
  static const String easeIn = 'ease_in';
  static const String easeOut = 'ease_out';
  static const String easeInOut = 'ease_in_out';
  static const String smooth = 'smooth';
}

class KeyframeParameter {
  final String id;
  final String label;
  final String group;
  final String valueType;
  final double? min;
  final double? max;

  const KeyframeParameter({
    required this.id,
    required this.label,
    required this.group,
    required this.valueType,
    this.min,
    this.max,
  });
}

class KeyframeParameters {
  KeyframeParameters._();

  static const List<KeyframeParameter> all = [
    KeyframeParameter(
      id: 'transform.positionX',
      label: 'Position X',
      group: 'Transform',
      valueType: KeyframeValueType.number,
      min: -1.0,
      max: 1.0,
    ),
    KeyframeParameter(
      id: 'transform.positionY',
      label: 'Position Y',
      group: 'Transform',
      valueType: KeyframeValueType.number,
      min: -1.0,
      max: 1.0,
    ),
    KeyframeParameter(
      id: 'transform.scale',
      label: 'Scale',
      group: 'Transform',
      valueType: KeyframeValueType.number,
      min: 0.1,
      max: 5.0,
    ),
    KeyframeParameter(
      id: 'transform.rotation',
      label: 'Rotation',
      group: 'Transform',
      valueType: KeyframeValueType.number,
      min: -180,
      max: 180,
    ),
    KeyframeParameter(
      id: 'transform.opacity',
      label: 'Opacity',
      group: 'Transform',
      valueType: KeyframeValueType.number,
      min: 0.0,
      max: 1.0,
    ),
    KeyframeParameter(
      id: 'audio.volume',
      label: 'Volume',
      group: 'Audio',
      valueType: KeyframeValueType.number,
      min: 0.0,
      max: 2.0,
    ),
    KeyframeParameter(
      id: 'audio.pan',
      label: 'Pan',
      group: 'Audio',
      valueType: KeyframeValueType.number,
      min: -1.0,
      max: 1.0,
    ),
    KeyframeParameter(
      id: 'color.exposure',
      label: 'Exposure',
      group: 'Color',
      valueType: KeyframeValueType.number,
      min: -2.0,
      max: 2.0,
    ),
    KeyframeParameter(
      id: 'color.contrast',
      label: 'Contrast',
      group: 'Color',
      valueType: KeyframeValueType.number,
      min: 0.0,
      max: 2.0,
    ),
    KeyframeParameter(
      id: 'color.saturation',
      label: 'Saturation',
      group: 'Color',
      valueType: KeyframeValueType.number,
      min: 0.0,
      max: 2.0,
    ),
    KeyframeParameter(
      id: 'color.temperature',
      label: 'Temperature',
      group: 'Color',
      valueType: KeyframeValueType.number,
      min: -1.0,
      max: 1.0,
    ),
    KeyframeParameter(
      id: 'color.tint',
      label: 'Tint',
      group: 'Color',
      valueType: KeyframeValueType.number,
      min: -1.0,
      max: 1.0,
    ),
  ];

  static KeyframeParameter byId(String id) {
    return all.firstWhere(
      (preset) => preset.id == id,
      orElse: () => all.first,
    );
  }

  static List<String> groups() {
    return all.map((p) => p.group).toSet().toList();
  }

  static List<KeyframeParameter> byGroup(String group) {
    return all.where((p) => p.group == group).toList();
  }
}
