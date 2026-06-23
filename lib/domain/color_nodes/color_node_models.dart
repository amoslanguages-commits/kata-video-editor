enum NleColorNodeType {
  input,
  primary,
  curves,
  qualifier,
  lut,
  filmLook,
  output,
  serial,
  parallel,
  layerMixer,
  adjustment,
}

enum NleColorNodeScope {
  clip,
  adjustmentLayer,
  timeline,
  project,
}

enum NleColorNodeBlendMode {
  normal,
  add,
  multiply,
  screen,
  overlay,
  softLight,
}

enum NleColorNodePreviewMode {
  normal,
  bypassBefore,
  soloNode,
  matte,
}

class NleColorNodeConnection {
  final String fromNodeId;
  final String toNodeId;
  final int outputIndex;
  final int inputIndex;

  const NleColorNodeConnection({
    required this.fromNodeId,
    required this.toNodeId,
    this.outputIndex = 0,
    this.inputIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'outputIndex': outputIndex,
      'inputIndex': inputIndex,
    };
  }

  factory NleColorNodeConnection.fromJson(Map<String, dynamic> json) {
    return NleColorNodeConnection(
      fromNodeId: json['fromNodeId']?.toString() ?? '',
      toNodeId: json['toNodeId']?.toString() ?? '',
      outputIndex: (json['outputIndex'] as num?)?.toInt() ?? 0,
      inputIndex: (json['inputIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class NleColorNode {
  final String id;
  final String name;
  final NleColorNodeType type;
  final NleColorNodeScope scope;

  final bool enabled;
  final bool bypassed;
  final bool locked;

  final double opacity;
  final NleColorNodeBlendMode blendMode;
  final NleColorNodePreviewMode previewMode;

  final int order;
  final Map<String, dynamic> payload;

  final String? thumbnailPath;

  const NleColorNode({
    required this.id,
    required this.name,
    required this.type,
    required this.scope,
    required this.enabled,
    required this.bypassed,
    required this.locked,
    required this.opacity,
    required this.blendMode,
    required this.previewMode,
    required this.order,
    required this.payload,
    this.thumbnailPath,
  });

  bool get isActive {
    return enabled && !bypassed && opacity > 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'scope': scope.name,
      'enabled': enabled,
      'bypassed': bypassed,
      'locked': locked,
      'opacity': opacity,
      'blendMode': blendMode.name,
      'previewMode': previewMode.name,
      'order': order,
      'payload': payload,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory NleColorNode.fromJson(Map<String, dynamic> json) {
    return NleColorNode(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Node',
      type: _enumByName(
        NleColorNodeType.values,
        json['type'],
        NleColorNodeType.serial,
      ),
      scope: _enumByName(
        NleColorNodeScope.values,
        json['scope'],
        NleColorNodeScope.clip,
      ),
      enabled: json['enabled'] != false,
      bypassed: json['bypassed'] == true,
      locked: json['locked'] == true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: _enumByName(
        NleColorNodeBlendMode.values,
        json['blendMode'],
        NleColorNodeBlendMode.normal,
      ),
      previewMode: _enumByName(
        NleColorNodePreviewMode.values,
        json['previewMode'],
        NleColorNodePreviewMode.normal,
      ),
      order: (json['order'] as num?)?.toInt() ?? 0,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      thumbnailPath: json['thumbnailPath']?.toString(),
    );
  }

  NleColorNode copyWith({
    String? name,
    bool? enabled,
    bool? bypassed,
    bool? locked,
    double? opacity,
    NleColorNodeBlendMode? blendMode,
    NleColorNodePreviewMode? previewMode,
    int? order,
    Map<String, dynamic>? payload,
    String? thumbnailPath,
  }) {
    return NleColorNode(
      id: id,
      name: name ?? this.name,
      type: type,
      scope: scope,
      enabled: enabled ?? this.enabled,
      bypassed: bypassed ?? this.bypassed,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      previewMode: previewMode ?? this.previewMode,
      order: order ?? this.order,
      payload: payload ?? this.payload,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}

class NleColorNodeGraph {
  final String id;
  final String ownerId;
  final NleColorNodeScope scope;
  final bool enabled;

  final List<NleColorNode> nodes;
  final List<NleColorNodeConnection> connections;

  final int version;

  const NleColorNodeGraph({
    required this.id,
    required this.ownerId,
    required this.scope,
    required this.enabled,
    required this.nodes,
    required this.connections,
    required this.version,
  });

  bool get isEmpty {
    return nodes.isEmpty;
  }

  List<NleColorNode> get orderedNodes {
    final copy = [...nodes];
    copy.sort((a, b) => a.order.compareTo(b.order));
    return copy;
  }

  List<NleColorNode> get activeOrderedNodes {
    return orderedNodes.where((node) => node.isActive).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'scope': scope.name,
      'enabled': enabled,
      'version': version,
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'connections': connections.map((item) => item.toJson()).toList(),
    };
  }

  factory NleColorNodeGraph.fromJson(Map<String, dynamic> json) {
    return NleColorNodeGraph(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      scope: _enumByName(
        NleColorNodeScope.values,
        json['scope'],
        NleColorNodeScope.clip,
      ),
      enabled: json['enabled'] != false,
      version: (json['version'] as num?)?.toInt() ?? 1,
      nodes: (json['nodes'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => NleColorNode.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      connections: (json['connections'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => NleColorNodeConnection.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  NleColorNodeGraph copyWith({
    bool? enabled,
    List<NleColorNode>? nodes,
    List<NleColorNodeConnection>? connections,
    int? version,
  }) {
    return NleColorNodeGraph(
      id: id,
      ownerId: ownerId,
      scope: scope,
      enabled: enabled ?? this.enabled,
      nodes: nodes ?? this.nodes,
      connections: connections ?? this.connections,
      version: version ?? this.version,
    );
  }

  NleColorNodeGraph updateNode(NleColorNode node) {
    final next = <NleColorNode>[];
    var replaced = false;

    for (final current in nodes) {
      if (current.id == node.id) {
        next.add(node);
        replaced = true;
      } else {
        next.add(current);
      }
    }

    if (!replaced) {
      next.add(node);
    }

    return copyWith(nodes: _renumber(next));
  }

  NleColorNodeGraph removeNode(String nodeId) {
    final nextNodes = nodes.where((node) => node.id != nodeId).toList();
    final nextConnections = connections
        .where(
          (connection) =>
              connection.fromNodeId != nodeId && connection.toNodeId != nodeId,
        )
        .toList();

    return copyWith(
      nodes: _renumber(nextNodes),
      connections: nextConnections,
    );
  }

  NleColorNodeGraph reorder({
    required String nodeId,
    required int newIndex,
  }) {
    final ordered = orderedNodes;
    final index = ordered.indexWhere((node) => node.id == nodeId);

    if (index < 0) return this;

    final node = ordered.removeAt(index);
    ordered.insert(newIndex.clamp(0, ordered.length), node);

    return copyWith(nodes: _renumber(ordered));
  }

  static List<NleColorNode> _renumber(List<NleColorNode> nodes) {
    return [
      for (var i = 0; i < nodes.length; i++) nodes[i].copyWith(order: i),
    ];
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
