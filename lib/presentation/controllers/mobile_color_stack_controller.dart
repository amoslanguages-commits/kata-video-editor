import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/color_node_graph_repository.dart';
import 'package:nle_editor/domain/color_nodes/color_node_graph_factory.dart';
import 'package:nle_editor/domain/color_nodes/color_node_models.dart';

class MobileColorStackState {
  final bool loading;
  final NleColorNodeGraph? graph;
  final String? selectedNodeId;
  final String? error;

  const MobileColorStackState({
    required this.loading,
    this.graph,
    this.selectedNodeId,
    this.error,
  });

  const MobileColorStackState.initial()
      : loading = false,
        graph = null,
        selectedNodeId = null,
        error = null;

  NleColorNode? get selectedNode {
    final g = graph;
    if (g == null) return null;

    if (selectedNodeId == null) {
      return g.orderedNodes.isNotEmpty ? g.orderedNodes.first : null;
    }

    return g.nodes.where((node) => node.id == selectedNodeId).firstOrNull;
  }

  MobileColorStackState copyWith({
    bool? loading,
    NleColorNodeGraph? graph,
    String? selectedNodeId,
    String? error,
    bool clearError = false,
  }) {
    return MobileColorStackState(
      loading: loading ?? this.loading,
      graph: graph ?? this.graph,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class MobileColorStackController extends StateNotifier<MobileColorStackState> {
  final String ownerId;
  final NleColorNodeScope scope;
  final ColorNodeGraphRepository repository;
  final ColorNodeGraphFactory factory;

  MobileColorStackController({
    required this.ownerId,
    required this.scope,
    required this.repository,
    this.factory = const ColorNodeGraphFactory(),
  }) : super(const MobileColorStackState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final graph = await _loadGraph();

      state = state.copyWith(
        loading: false,
        graph: graph,
        selectedNodeId:
            graph.orderedNodes.isNotEmpty ? graph.orderedNodes.first.id : null,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> selectNode(String nodeId) async {
    state = state.copyWith(selectedNodeId: nodeId);
  }

  Future<void> updateNode(NleColorNode node) async {
    final graph = state.graph;
    if (graph == null) return;

    final next = graph.updateNode(node);

    state = state.copyWith(graph: next, selectedNodeId: node.id);

    await _saveGraph(next);
  }

  Future<void> toggleNode(String nodeId) async {
    final node = state.graph?.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null || node.locked) return;

    await updateNode(node.copyWith(enabled: !node.enabled));
  }

  Future<void> bypassNode(String nodeId) async {
    final node = state.graph?.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null || node.locked) return;

    await updateNode(node.copyWith(bypassed: !node.bypassed));
  }

  Future<void> renameNode({
    required String nodeId,
    required String name,
  }) async {
    final node = state.graph?.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null || node.locked) return;

    await updateNode(node.copyWith(name: name.trim().isEmpty ? node.name : name));
  }

  Future<void> setNodeOpacity({
    required String nodeId,
    required double opacity,
  }) async {
    final node = state.graph?.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null || node.locked) return;

    await updateNode(node.copyWith(opacity: opacity.clamp(0.0, 1.0)));
  }

  Future<void> setPreviewMode({
    required String nodeId,
    required NleColorNodePreviewMode mode,
  }) async {
    final node = state.graph?.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    await updateNode(node.copyWith(previewMode: mode));
  }

  Future<void> reorder({
    required String nodeId,
    required int newIndex,
  }) async {
    final graph = state.graph;
    if (graph == null) return;

    final node = graph.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null || node.locked) return;

    final next = graph.reorder(nodeId: nodeId, newIndex: newIndex);

    state = state.copyWith(graph: next, selectedNodeId: nodeId);
    await _saveGraph(next);
  }

  Future<void> addNode(NleColorNodeType type) async {
    final graph = state.graph;
    if (graph == null) return;

    final insertOrder = graph.orderedNodes.length;

    final node = factory.createNode(
      type: type,
      scope: scope,
      order: insertOrder,
    );

    final next = graph.updateNode(node);

    state = state.copyWith(graph: next, selectedNodeId: node.id);
    await _saveGraph(next);
  }

  Future<void> removeNode(String nodeId) async {
    final graph = state.graph;
    if (graph == null) return;

    final node = graph.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null || node.locked) return;

    final next = graph.removeNode(nodeId);

    state = state.copyWith(
      graph: next,
      selectedNodeId: next.orderedNodes.isNotEmpty ? next.orderedNodes.first.id : null,
    );

    await _saveGraph(next);
  }

  Future<NleColorNodeGraph> _loadGraph() {
    switch (scope) {
      case NleColorNodeScope.clip:
        return repository.getClipGraph(ownerId);
      case NleColorNodeScope.adjustmentLayer:
        return repository.getAdjustmentGraph(ownerId);
      case NleColorNodeScope.timeline:
        return repository.getTimelineGraph(ownerId);
      case NleColorNodeScope.project:
        return repository.getProjectOutputGraph(ownerId);
    }
  }

  Future<void> _saveGraph(NleColorNodeGraph graph) {
    switch (scope) {
      case NleColorNodeScope.clip:
        return repository.saveClipGraph(clipId: ownerId, graph: graph);
      case NleColorNodeScope.adjustmentLayer:
        return repository.saveAdjustmentGraph(clipId: ownerId, graph: graph);
      case NleColorNodeScope.timeline:
        return repository.saveTimelineGraph(projectId: ownerId, graph: graph);
      case NleColorNodeScope.project:
        return repository.saveProjectOutputGraph(projectId: ownerId, graph: graph);
    }
  }
}
