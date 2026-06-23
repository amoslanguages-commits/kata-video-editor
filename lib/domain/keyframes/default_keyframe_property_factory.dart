import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

class DefaultKeyframePropertyFactory {
  const DefaultKeyframePropertyFactory();

  List<NleAnimatableProperty> titleProperties({
    required String ownerId,
  }) {
    return [
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.title,
        propertyPath: 'title.layout.box.x',
        label: 'Position X',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 0.0,
        min: 0.0,
        max: 1.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.title,
        propertyPath: 'title.layout.box.y',
        label: 'Position Y',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 0.0,
        min: 0.0,
        max: 1.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.title,
        propertyPath: 'title.motion.scale',
        label: 'Scale',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 1.0,
        min: 0.0,
        max: 4.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.title,
        propertyPath: 'title.motion.rotationDegrees',
        label: 'Rotation',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 0.0,
        min: -180.0,
        max: 180.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.title,
        propertyPath: 'title.motion.opacity',
        label: 'Opacity',
        group: NleKeyframePropertyGroup.visual,
        defaultValue: 1.0,
        min: 0.0,
        max: 1.0,
      ),
    ];
  }

  List<NleAnimatableProperty> overlayProperties({
    required String ownerId,
  }) {
    return [
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.overlay,
        propertyPath: 'overlay.transform.box.x',
        label: 'Position X',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 0.0,
        min: 0.0,
        max: 1.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.overlay,
        propertyPath: 'overlay.transform.box.y',
        label: 'Position Y',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 0.0,
        min: 0.0,
        max: 1.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.overlay,
        propertyPath: 'overlay.transform.box.width',
        label: 'Width',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 0.3,
        min: 0.01,
        max: 1.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.overlay,
        propertyPath: 'overlay.transform.box.height',
        label: 'Height',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 0.3,
        min: 0.01,
        max: 1.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.overlay,
        propertyPath: 'overlay.transform.scale',
        label: 'Scale',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 1.0,
        min: 0.0,
        max: 4.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.overlay,
        propertyPath: 'overlay.transform.rotationDegrees',
        label: 'Rotation',
        group: NleKeyframePropertyGroup.transform,
        defaultValue: 0.0,
        min: -180.0,
        max: 180.0,
      ),
      number(
        ownerId: ownerId,
        ownerType: NleKeyframeOwnerType.overlay,
        propertyPath: 'overlay.transform.opacity',
        label: 'Opacity',
        group: NleKeyframePropertyGroup.visual,
        defaultValue: 1.0,
        min: 0.0,
        max: 1.0,
      ),
    ];
  }

  NleAnimatableProperty number({
    required String ownerId,
    required NleKeyframeOwnerType ownerType,
    required String propertyPath,
    required String label,
    required NleKeyframePropertyGroup group,
    required double defaultValue,
    double? min,
    double? max,
  }) {
    return NleAnimatableProperty(
      id: '$ownerId:$propertyPath',
      ownerId: ownerId,
      ownerType: ownerType,
      propertyPath: propertyPath,
      label: label,
      group: group,
      valueType: NleKeyframeValueType.number,
      defaultValue: NleKeyframeValue.number(defaultValue),
      min: min,
      max: max,
      enabled: true,
      keyframes: const [],
    );
  }
}
