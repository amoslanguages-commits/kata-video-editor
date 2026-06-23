import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

class NleBezierHandle {
  final double x;
  final double y;

  const NleBezierHandle({
    required this.x,
    required this.y,
  });

  const NleBezierHandle.easeIn()
      : x = 0.42,
        y = 0.0;

  const NleBezierHandle.easeOut()
      : x = 0.58,
        y = 1.0;

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory NleBezierHandle.fromJson(Map<String, dynamic> json) {
    return NleBezierHandle(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NleKeyframe {
  final String id;
  final int timeOffsetMicros;
  final NleKeyframeValue value;
  final NleKeyframeInterpolation interpolation;
  final NleBezierHandle inHandle;
  final NleBezierHandle outHandle;
  final bool selected;
  final bool locked;

  const NleKeyframe({
    required this.id,
    required this.timeOffsetMicros,
    required this.value,
    required this.interpolation,
    required this.inHandle,
    required this.outHandle,
    required this.selected,
    required this.locked,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeOffsetMicros': timeOffsetMicros,
      'value': value.toJson(),
      'interpolation': interpolation.name,
      'inHandle': inHandle.toJson(),
      'outHandle': outHandle.toJson(),
      'selected': selected,
      'locked': locked,
    };
  }

  factory NleKeyframe.fromJson(Map<String, dynamic> json) {
    return NleKeyframe(
      id: json['id']?.toString() ?? '',
      timeOffsetMicros: (json['timeOffsetMicros'] as num?)?.toInt() ?? 0,
      value: NleKeyframeValue.fromJson(
        Map<String, dynamic>.from(json['value'] as Map? ?? const {}),
      ),
      interpolation: _enumByName(
        NleKeyframeInterpolation.values,
        json['interpolation'],
        NleKeyframeInterpolation.easeInOut,
      ),
      inHandle: NleBezierHandle.fromJson(
        Map<String, dynamic>.from(json['inHandle'] as Map? ?? const {}),
      ),
      outHandle: NleBezierHandle.fromJson(
        Map<String, dynamic>.from(json['outHandle'] as Map? ?? const {}),
      ),
      selected: json['selected'] == true,
      locked: json['locked'] == true,
    );
  }

  NleKeyframe copyWith({
    int? timeOffsetMicros,
    NleKeyframeValue? value,
    NleKeyframeInterpolation? interpolation,
    NleBezierHandle? inHandle,
    NleBezierHandle? outHandle,
    bool? selected,
    bool? locked,
  }) {
    return NleKeyframe(
      id: id,
      timeOffsetMicros: timeOffsetMicros ?? this.timeOffsetMicros,
      value: value ?? this.value,
      interpolation: interpolation ?? this.interpolation,
      inHandle: inHandle ?? this.inHandle,
      outHandle: outHandle ?? this.outHandle,
      selected: selected ?? this.selected,
      locked: locked ?? this.locked,
    );
  }
}

class NleAnimatableProperty {
  final String id;
  final String ownerId;
  final NleKeyframeOwnerType ownerType;
  final String propertyPath;
  final String label;
  final NleKeyframePropertyGroup group;
  final NleKeyframeValueType valueType;
  final NleKeyframeValue defaultValue;
  final double? min;
  final double? max;
  final bool enabled;
  final List<NleKeyframe> keyframes;

  const NleAnimatableProperty({
    required this.id,
    required this.ownerId,
    required this.ownerType,
    required this.propertyPath,
    required this.label,
    required this.group,
    required this.valueType,
    required this.defaultValue,
    this.min,
    this.max,
    required this.enabled,
    required this.keyframes,
  });

  List<NleKeyframe> get orderedKeyframes {
    final next = [...keyframes];
    next.sort((a, b) => a.timeOffsetMicros.compareTo(b.timeOffsetMicros));
    return next;
  }

  bool get hasKeyframes => keyframes.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerType': ownerType.name,
      'propertyPath': propertyPath,
      'label': label,
      'group': group.name,
      'valueType': valueType.name,
      'defaultValue': defaultValue.toJson(),
      'min': min,
      'max': max,
      'enabled': enabled,
      'keyframes': orderedKeyframes.map((item) => item.toJson()).toList(),
    };
  }

  factory NleAnimatableProperty.fromJson(Map<String, dynamic> json) {
    return NleAnimatableProperty(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      ownerType: _enumByName(
        NleKeyframeOwnerType.values,
        json['ownerType'],
        NleKeyframeOwnerType.clip,
      ),
      propertyPath: json['propertyPath']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      group: _enumByName(
        NleKeyframePropertyGroup.values,
        json['group'],
        NleKeyframePropertyGroup.transform,
      ),
      valueType: _enumByName(
        NleKeyframeValueType.values,
        json['valueType'],
        NleKeyframeValueType.number,
      ),
      defaultValue: NleKeyframeValue.fromJson(
        Map<String, dynamic>.from(json['defaultValue'] as Map? ?? const {}),
      ),
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      enabled: json['enabled'] != false,
      keyframes: (json['keyframes'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleKeyframe.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  NleAnimatableProperty copyWith({
    String? label,
    NleKeyframeValue? defaultValue,
    double? min,
    double? max,
    bool? enabled,
    List<NleKeyframe>? keyframes,
  }) {
    return NleAnimatableProperty(
      id: id,
      ownerId: ownerId,
      ownerType: ownerType,
      propertyPath: propertyPath,
      label: label ?? this.label,
      group: group,
      valueType: valueType,
      defaultValue: defaultValue ?? this.defaultValue,
      min: min ?? this.min,
      max: max ?? this.max,
      enabled: enabled ?? this.enabled,
      keyframes: keyframes ?? this.keyframes,
    );
  }
}

class NleKeyframeTrack {
  final String ownerId;
  final NleKeyframeOwnerType ownerType;
  final List<NleAnimatableProperty> properties;
  final int clipDurationMicros;
  final int version;

  const NleKeyframeTrack({
    required this.ownerId,
    required this.ownerType,
    required this.properties,
    required this.clipDurationMicros,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'ownerType': ownerType.name,
      'properties': properties.map((item) => item.toJson()).toList(),
      'clipDurationMicros': clipDurationMicros,
      'version': version,
    };
  }

  factory NleKeyframeTrack.fromJson(Map<String, dynamic> json) {
    return NleKeyframeTrack(
      ownerId: json['ownerId']?.toString() ?? '',
      ownerType: _enumByName(
        NleKeyframeOwnerType.values,
        json['ownerType'],
        NleKeyframeOwnerType.clip,
      ),
      properties: (json['properties'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleAnimatableProperty.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      clipDurationMicros:
          (json['clipDurationMicros'] as num?)?.toInt() ?? 4000000,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  NleKeyframeTrack copyWith({
    List<NleAnimatableProperty>? properties,
    int? clipDurationMicros,
    int? version,
  }) {
    return NleKeyframeTrack(
      ownerId: ownerId,
      ownerType: ownerType,
      properties: properties ?? this.properties,
      clipDurationMicros: clipDurationMicros ?? this.clipDurationMicros,
      version: version ?? this.version,
    );
  }
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? name,
  T fallback,
) {
  final string = name?.toString();
  if (string == null) return fallback;

  for (final value in values) {
    if (value.name == string) return value;
  }

  return fallback;
}
