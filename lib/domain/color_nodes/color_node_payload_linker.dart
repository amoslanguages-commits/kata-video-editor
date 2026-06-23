import 'package:nle_editor/domain/color_nodes/color_node_models.dart';

class NleColorNodePayloadLinker {
  const NleColorNodePayloadLinker();

  Map<String, dynamic> buildPayloadReference({
    required NleColorNodeType type,
    required String ownerId,
    required NleColorNodeScope scope,
  }) {
    switch (type) {
      case NleColorNodeType.input:
        return {
          'source': 'inputColorTransform',
          'ownerId': ownerId,
        };

      case NleColorNodeType.primary:
        return {
          'source': 'primaryGrade',
          'ownerId': ownerId,
        };

      case NleColorNodeType.curves:
        return {
          'source': 'colorCurves',
          'ownerId': ownerId,
        };

      case NleColorNodeType.qualifier:
        return {
          'source': 'secondaryGrades',
          'ownerId': ownerId,
        };

      case NleColorNodeType.lut:
        return {
          'source': 'lutStack',
          'ownerId': ownerId,
        };

      case NleColorNodeType.filmLook:
        return {
          'source': 'filmLook',
          'ownerId': ownerId,
        };

      case NleColorNodeType.output:
        return {
          'source': 'outputTransform',
          'ownerId': ownerId,
        };

      case NleColorNodeType.adjustment:
        return {
          'source': 'adjustmentColorGraph',
          'ownerId': ownerId,
        };

      case NleColorNodeType.serial:
      case NleColorNodeType.parallel:
      case NleColorNodeType.layerMixer:
        return {
          'source': 'customNode',
          'ownerId': ownerId,
          'scope': scope.name,
        };
    }
  }
}
