import 'package:nle_editor/domain/color_nodes/color_node_models.dart';

enum NleMobileColorStackItemKind {
  input,
  primary,
  curves,
  qualifier,
  lut,
  filmLook,
  output,
  customNode,
}

class NleMobileColorStackItem {
  final String nodeId;
  final String title;
  final String subtitle;
  final NleMobileColorStackItemKind kind;
  final bool enabled;
  final bool bypassed;
  final bool locked;
  final double opacity;
  final String? thumbnailPath;

  const NleMobileColorStackItem({
    required this.nodeId,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.enabled,
    required this.bypassed,
    required this.locked,
    required this.opacity,
    this.thumbnailPath,
  });

  bool get active {
    return enabled && !bypassed && opacity > 0.0;
  }

  factory NleMobileColorStackItem.fromNode(NleColorNode node) {
    return NleMobileColorStackItem(
      nodeId: node.id,
      title: node.name,
      subtitle: _subtitle(node),
      kind: _kind(node.type),
      enabled: node.enabled,
      bypassed: node.bypassed,
      locked: node.locked,
      opacity: node.opacity,
      thumbnailPath: node.thumbnailPath,
    );
  }

  static String _subtitle(NleColorNode node) {
    if (node.bypassed) return 'Bypassed';
    if (!node.enabled) return 'Disabled';

    switch (node.type) {
      case NleColorNodeType.input:
        return 'Source transform';
      case NleColorNodeType.primary:
        return 'Lift, gamma, gain, offset';
      case NleColorNodeType.curves:
        return 'RGB + HSL curves';
      case NleColorNodeType.qualifier:
        return 'HSL secondary correction';
      case NleColorNodeType.lut:
        return 'GPU 3D LUT';
      case NleColorNodeType.filmLook:
        return 'Film science';
      case NleColorNodeType.output:
        return 'Display/output transform';
      case NleColorNodeType.parallel:
        return 'Parallel foundation';
      case NleColorNodeType.layerMixer:
        return 'Layer mixer foundation';
      case NleColorNodeType.adjustment:
        return 'Adjustment layer';
      case NleColorNodeType.serial:
        return 'Serial grade node';
    }
  }

  static NleMobileColorStackItemKind _kind(NleColorNodeType type) {
    switch (type) {
      case NleColorNodeType.input:
        return NleMobileColorStackItemKind.input;
      case NleColorNodeType.primary:
        return NleMobileColorStackItemKind.primary;
      case NleColorNodeType.curves:
        return NleMobileColorStackItemKind.curves;
      case NleColorNodeType.qualifier:
        return NleMobileColorStackItemKind.qualifier;
      case NleColorNodeType.lut:
        return NleMobileColorStackItemKind.lut;
      case NleColorNodeType.filmLook:
        return NleMobileColorStackItemKind.filmLook;
      case NleColorNodeType.output:
        return NleMobileColorStackItemKind.output;
      case NleColorNodeType.adjustment:
      case NleColorNodeType.serial:
      case NleColorNodeType.parallel:
      case NleColorNodeType.layerMixer:
        return NleMobileColorStackItemKind.customNode;
    }
  }
}

class NleMobileColorStack {
  final String ownerId;
  final NleColorNodeScope scope;
  final List<NleMobileColorStackItem> items;

  const NleMobileColorStack({
    required this.ownerId,
    required this.scope,
    required this.items,
  });

  factory NleMobileColorStack.fromGraph(NleColorNodeGraph graph) {
    return NleMobileColorStack(
      ownerId: graph.ownerId,
      scope: graph.scope,
      items: graph.orderedNodes.map(NleMobileColorStackItem.fromNode).toList(),
    );
  }
}
