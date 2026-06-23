import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/domain/color_nodes/color_node_graph_factory.dart';
import 'package:nle_editor/domain/color_nodes/color_node_models.dart';

class ColorNodeGraphRepository {
  final db.AppDatabase database;
  final ColorNodeGraphFactory factory;

  const ColorNodeGraphRepository({
    required this.database,
    this.factory = const ColorNodeGraphFactory(),
  });

  Future<NleColorNodeGraph> getClipGraph(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      final graph = factory.createDefaultClipGraph(clipId: clipId);
      await saveClipGraph(clipId: clipId, graph: graph);
      return graph;
    }
    final raw = clip.colorNodeGraphJson;

    if (raw == null || raw.trim().isEmpty) {
      final graph = factory.createDefaultClipGraph(clipId: clipId);
      await saveClipGraph(clipId: clipId, graph: graph);
      return graph;
    }

    try {
      return NleColorNodeGraph.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      final graph = factory.createDefaultClipGraph(clipId: clipId);
      await saveClipGraph(clipId: clipId, graph: graph);
      return graph;
    }
  }

  Future<void> saveClipGraph({
    required String clipId,
    required NleColorNodeGraph graph,
  }) {
    return database.updateClipColorNodeGraphJson(
      clipId: clipId,
      colorNodeGraphJson: jsonEncode(graph.toJson()),
    );
  }

  Future<NleColorNodeGraph> getAdjustmentGraph(String clipId) async {
    final clip = await database.getClip(clipId);
    if (clip == null) {
      final graph = factory.createDefaultClipGraph(clipId: clipId);
      await saveAdjustmentGraph(clipId: clipId, graph: graph);
      return graph;
    }
    final raw = clip.adjustmentColorGraphJson;

    if (raw == null || raw.trim().isEmpty) {
      final graph = factory.createDefaultClipGraph(clipId: clipId);
      await saveAdjustmentGraph(clipId: clipId, graph: graph);
      return graph;
    }

    try {
      return NleColorNodeGraph.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      final graph = factory.createDefaultClipGraph(clipId: clipId);
      await saveAdjustmentGraph(clipId: clipId, graph: graph);
      return graph;
    }
  }

  Future<void> saveAdjustmentGraph({
    required String clipId,
    required NleColorNodeGraph graph,
  }) {
    return database.updateClipAdjustmentColorGraphJson(
      clipId: clipId,
      adjustmentColorGraphJson: jsonEncode(graph.toJson()),
    );
  }

  Future<NleColorNodeGraph> getTimelineGraph(String projectId) async {
    final project = await database.getProjectById(projectId);
    final raw = project.timelineColorGraphJson;

    if (raw == null || raw.trim().isEmpty) {
      final graph = factory.createDefaultTimelineGraph(projectId: projectId);
      await saveTimelineGraph(projectId: projectId, graph: graph);
      return graph;
    }

    try {
      return NleColorNodeGraph.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      final graph = factory.createDefaultTimelineGraph(projectId: projectId);
      await saveTimelineGraph(projectId: projectId, graph: graph);
      return graph;
    }
  }

  Future<void> saveTimelineGraph({
    required String projectId,
    required NleColorNodeGraph graph,
  }) {
    return database.updateProjectTimelineColorGraphJson(
      projectId: projectId,
      timelineColorGraphJson: jsonEncode(graph.toJson()),
    );
  }

  Future<NleColorNodeGraph> getProjectOutputGraph(String projectId) async {
    final project = await database.getProjectById(projectId);
    final raw = project.projectOutputColorGraphJson;

    if (raw == null || raw.trim().isEmpty) {
      final graph = factory.createDefaultProjectOutputGraph(
        projectId: projectId,
      );
      await saveProjectOutputGraph(projectId: projectId, graph: graph);
      return graph;
    }

    try {
      return NleColorNodeGraph.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      final graph = factory.createDefaultProjectOutputGraph(
        projectId: projectId,
      );
      await saveProjectOutputGraph(projectId: projectId, graph: graph);
      return graph;
    }
  }

  Future<void> saveProjectOutputGraph({
    required String projectId,
    required NleColorNodeGraph graph,
  }) {
    return database.updateProjectOutputColorGraphJson(
      projectId: projectId,
      projectOutputColorGraphJson: jsonEncode(graph.toJson()),
    );
  }

  Future<void> updateClipNode({
    required String clipId,
    required NleColorNode node,
  }) async {
    final graph = await getClipGraph(clipId);
    await saveClipGraph(
      clipId: clipId,
      graph: graph.updateNode(node),
    );
  }

  Future<void> reorderClipNode({
    required String clipId,
    required String nodeId,
    required int newIndex,
  }) async {
    final graph = await getClipGraph(clipId);
    await saveClipGraph(
      clipId: clipId,
      graph: graph.reorder(nodeId: nodeId, newIndex: newIndex),
    );
  }
}
