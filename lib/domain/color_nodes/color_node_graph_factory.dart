import 'package:uuid/uuid.dart';

import 'package:nle_editor/domain/color_nodes/color_node_models.dart';

class ColorNodeGraphFactory {
  static const _uuid = Uuid();

  const ColorNodeGraphFactory();

  NleColorNodeGraph createDefaultClipGraph({
    required String clipId,
  }) {
    final nodes = [
      _node(
        name: 'Input',
        type: NleColorNodeType.input,
        scope: NleColorNodeScope.clip,
        order: 0,
      ),
      _node(
        name: 'Primary',
        type: NleColorNodeType.primary,
        scope: NleColorNodeScope.clip,
        order: 1,
      ),
      _node(
        name: 'Curves',
        type: NleColorNodeType.curves,
        scope: NleColorNodeScope.clip,
        order: 2,
      ),
      _node(
        name: 'Qualifier',
        type: NleColorNodeType.qualifier,
        scope: NleColorNodeScope.clip,
        order: 3,
      ),
      _node(
        name: 'LUT',
        type: NleColorNodeType.lut,
        scope: NleColorNodeScope.clip,
        order: 4,
      ),
      _node(
        name: 'Output',
        type: NleColorNodeType.output,
        scope: NleColorNodeScope.clip,
        order: 5,
        locked: true,
      ),
    ];

    return _serialGraph(
      ownerId: clipId,
      scope: NleColorNodeScope.clip,
      nodes: nodes,
    );
  }

  NleColorNodeGraph createDefaultTimelineGraph({
    required String projectId,
  }) {
    final nodes = [
      _node(
        name: 'Timeline Input',
        type: NleColorNodeType.input,
        scope: NleColorNodeScope.timeline,
        order: 0,
        locked: true,
      ),
      _node(
        name: 'Timeline Look',
        type: NleColorNodeType.primary,
        scope: NleColorNodeScope.timeline,
        order: 1,
      ),
      _node(
        name: 'Timeline Curves',
        type: NleColorNodeType.curves,
        scope: NleColorNodeScope.timeline,
        order: 2,
      ),
      _node(
        name: 'Timeline LUT',
        type: NleColorNodeType.lut,
        scope: NleColorNodeScope.timeline,
        order: 3,
      ),
      _node(
        name: 'Output',
        type: NleColorNodeType.output,
        scope: NleColorNodeScope.timeline,
        order: 4,
        locked: true,
      ),
    ];

    return _serialGraph(
      ownerId: projectId,
      scope: NleColorNodeScope.timeline,
      nodes: nodes,
    );
  }

  NleColorNodeGraph createDefaultProjectOutputGraph({
    required String projectId,
  }) {
    final nodes = [
      _node(
        name: 'Project Input',
        type: NleColorNodeType.input,
        scope: NleColorNodeScope.project,
        order: 0,
        locked: true,
      ),
      _node(
        name: 'Output Transform',
        type: NleColorNodeType.output,
        scope: NleColorNodeScope.project,
        order: 1,
        locked: true,
      ),
    ];

    return _serialGraph(
      ownerId: projectId,
      scope: NleColorNodeScope.project,
      nodes: nodes,
    );
  }

  NleColorNode createNode({
    required NleColorNodeType type,
    required NleColorNodeScope scope,
    required int order,
  }) {
    return _node(
      name: _defaultName(type),
      type: type,
      scope: scope,
      order: order,
    );
  }

  NleColorNode _node({
    required String name,
    required NleColorNodeType type,
    required NleColorNodeScope scope,
    required int order,
    bool locked = false,
  }) {
    return NleColorNode(
      id: _uuid.v4(),
      name: name,
      type: type,
      scope: scope,
      enabled: true,
      bypassed: false,
      locked: locked,
      opacity: 1.0,
      blendMode: NleColorNodeBlendMode.normal,
      previewMode: NleColorNodePreviewMode.normal,
      order: order,
      payload: const {},
    );
  }

  NleColorNodeGraph _serialGraph({
    required String ownerId,
    required NleColorNodeScope scope,
    required List<NleColorNode> nodes,
  }) {
    final connections = <NleColorNodeConnection>[];

    for (var i = 0; i < nodes.length - 1; i++) {
      connections.add(
        NleColorNodeConnection(
          fromNodeId: nodes[i].id,
          toNodeId: nodes[i + 1].id,
        ),
      );
    }

    return NleColorNodeGraph(
      id: _uuid.v4(),
      ownerId: ownerId,
      scope: scope,
      enabled: true,
      nodes: nodes,
      connections: connections,
      version: 1,
    );
  }

  String _defaultName(NleColorNodeType type) {
    switch (type) {
      case NleColorNodeType.input:
        return 'Input';
      case NleColorNodeType.primary:
        return 'Primary';
      case NleColorNodeType.curves:
        return 'Curves';
      case NleColorNodeType.qualifier:
        return 'Qualifier';
      case NleColorNodeType.lut:
        return 'LUT';
      case NleColorNodeType.filmLook:
        return 'Film Look';
      case NleColorNodeType.output:
        return 'Output';
      case NleColorNodeType.serial:
        return 'Serial Node';
      case NleColorNodeType.parallel:
        return 'Parallel';
      case NleColorNodeType.layerMixer:
        return 'Layer Mixer';
      case NleColorNodeType.adjustment:
        return 'Adjustment';
    }
  }
}
