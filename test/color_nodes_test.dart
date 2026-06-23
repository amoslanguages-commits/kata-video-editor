import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/color_nodes/color_node_models.dart';
import 'package:nle_editor/domain/color_nodes/color_node_graph_factory.dart';
import 'package:nle_editor/domain/color_nodes/color_node_payload_linker.dart';
import 'package:nle_editor/domain/color_nodes/mobile_color_stack_models.dart';

void main() {
  group('Color Nodes & Connections', () {
    test('NleColorNodeConnection serialization', () {
      const conn = NleColorNodeConnection(
        fromNodeId: 'node_a',
        toNodeId: 'node_b',
        outputIndex: 1,
        inputIndex: 2,
      );

      final json = conn.toJson();
      final decoded = NleColorNodeConnection.fromJson(json);

      expect(decoded.fromNodeId, equals('node_a'));
      expect(decoded.toNodeId, equals('node_b'));
      expect(decoded.outputIndex, equals(1));
      expect(decoded.inputIndex, equals(2));
    });

    test('NleColorNode isActive checks', () {
      const node = NleColorNode(
        id: 'node_1',
        name: 'Primary Correction',
        type: NleColorNodeType.primary,
        scope: NleColorNodeScope.clip,
        enabled: true,
        bypassed: false,
        locked: false,
        opacity: 1.0,
        blendMode: NleColorNodeBlendMode.normal,
        previewMode: NleColorNodePreviewMode.normal,
        order: 0,
        payload: {},
      );

      expect(node.isActive, isTrue);

      expect(node.copyWith(enabled: false).isActive, isFalse);
      expect(node.copyWith(bypassed: true).isActive, isFalse);
      expect(node.copyWith(opacity: 0.0).isActive, isFalse);
    });

    test('NleColorNode serialization', () {
      final node = NleColorNode(
        id: 'node_1',
        name: 'Curves Node',
        type: NleColorNodeType.curves,
        scope: NleColorNodeScope.timeline,
        enabled: true,
        bypassed: true,
        locked: true,
        opacity: 0.75,
        blendMode: NleColorNodeBlendMode.overlay,
        previewMode: NleColorNodePreviewMode.soloNode,
        order: 2,
        payload: const {'ref': 'data'},
        thumbnailPath: 'thumbs/node_1.png',
      );

      final json = node.toJson();
      final decoded = NleColorNode.fromJson(json);

      expect(decoded.id, equals('node_1'));
      expect(decoded.name, equals('Curves Node'));
      expect(decoded.type, equals(NleColorNodeType.curves));
      expect(decoded.scope, equals(NleColorNodeScope.timeline));
      expect(decoded.enabled, isTrue);
      expect(decoded.bypassed, isTrue);
      expect(decoded.locked, isTrue);
      expect(decoded.opacity, equals(0.75));
      expect(decoded.blendMode, equals(NleColorNodeBlendMode.overlay));
      expect(decoded.previewMode, equals(NleColorNodePreviewMode.soloNode));
      expect(decoded.order, equals(2));
      expect(decoded.payload['ref'], equals('data'));
      expect(decoded.thumbnailPath, equals('thumbs/node_1.png'));
    });
  });

  group('NleColorNodeGraph Operations', () {
    test('Default Clip Graph Factory', () {
      const factory = ColorNodeGraphFactory();
      final graph = factory.createDefaultClipGraph(clipId: 'clip_abc');

      expect(graph.ownerId, equals('clip_abc'));
      expect(graph.scope, equals(NleColorNodeScope.clip));
      expect(graph.enabled, isTrue);
      expect(graph.nodes.length, equals(6));
      expect(graph.orderedNodes.first.type, equals(NleColorNodeType.input));
      expect(graph.orderedNodes.last.type, equals(NleColorNodeType.output));
      expect(graph.orderedNodes.last.locked, isTrue);

      // Verify serial connections
      expect(graph.connections.length, equals(5));
      expect(graph.connections[0].fromNodeId, equals(graph.orderedNodes[0].id));
      expect(graph.connections[0].toNodeId, equals(graph.orderedNodes[1].id));
    });

    test('Graph updateNode, removeNode, and reorder', () {
      const factory = ColorNodeGraphFactory();
      var graph = factory.createDefaultClipGraph(clipId: 'clip_1');

      // Update Node
      final firstNode = graph.orderedNodes.first;
      final updatedNode = firstNode.copyWith(name: 'Custom Source');
      graph = graph.updateNode(updatedNode);
      expect(graph.orderedNodes.first.name, equals('Custom Source'));

      // Reorder Node
      final curvesNode = graph.orderedNodes.firstWhere((n) => n.type == NleColorNodeType.curves);
      graph = graph.reorder(nodeId: curvesNode.id, newIndex: 0);
      expect(graph.orderedNodes.first.id, equals(curvesNode.id));
      // Re-numbering order indices check
      expect(graph.orderedNodes.first.order, equals(0));
      expect(graph.orderedNodes[1].order, equals(1));

      // Remove Node
      final qualifierNode = graph.orderedNodes.firstWhere((n) => n.type == NleColorNodeType.qualifier);
      graph = graph.removeNode(qualifierNode.id);
      expect(graph.nodes.any((n) => n.id == qualifierNode.id), isFalse);
    });

    test('JSON serialization roundtrip for graph', () {
      const factory = ColorNodeGraphFactory();
      final graph = factory.createDefaultClipGraph(clipId: 'clip_123');

      final json = graph.toJson();
      final decoded = NleColorNodeGraph.fromJson(json);

      expect(decoded.id, equals(graph.id));
      expect(decoded.ownerId, equals(graph.ownerId));
      expect(decoded.scope, equals(graph.scope));
      expect(decoded.enabled, equals(graph.enabled));
      expect(decoded.nodes.length, equals(graph.nodes.length));
      expect(decoded.connections.length, equals(graph.connections.length));
    });
  });

  group('Mobile Color Stack Adaption', () {
    test('Stack items from graph', () {
      const factory = ColorNodeGraphFactory();
      final graph = factory.createDefaultClipGraph(clipId: 'clip_stack');
      final stack = NleMobileColorStack.fromGraph(graph);

      expect(stack.ownerId, equals('clip_stack'));
      expect(stack.scope, equals(NleColorNodeScope.clip));
      expect(stack.items.length, equals(6));

      final firstItem = stack.items.first;
      expect(firstItem.title, equals('Input'));
      expect(firstItem.kind, equals(NleMobileColorStackItemKind.input));
      expect(firstItem.active, isTrue);
    });
  });

  group('Color Node Payload Linker', () {
    test('Build references for all types', () {
      const linker = NleColorNodePayloadLinker();

      final inputRef = linker.buildPayloadReference(
        type: NleColorNodeType.input,
        ownerId: 'clip_x',
        scope: NleColorNodeScope.clip,
      );
      expect(inputRef['source'], equals('inputColorTransform'));
      expect(inputRef['ownerId'], equals('clip_x'));

      final primaryRef = linker.buildPayloadReference(
        type: NleColorNodeType.primary,
        ownerId: 'clip_x',
        scope: NleColorNodeScope.clip,
      );
      expect(primaryRef['source'], equals('primaryGrade'));

      final serialRef = linker.buildPayloadReference(
        type: NleColorNodeType.serial,
        ownerId: 'clip_x',
        scope: NleColorNodeScope.clip,
      );
      expect(serialRef['source'], equals('customNode'));
      expect(serialRef['scope'], equals(NleColorNodeScope.clip.name));
    });
  });
}
