import 'package:nle_editor/domain/rendering/multitrack_render_graph_service.dart';

class RenderGraphService {
  final MultitrackRenderGraphService multitrackService;

  const RenderGraphService({
    required this.multitrackService,
  });

  Future<String> buildProjectGraph(String projectId) {
    return multitrackService.buildGraphJsonString(projectId, isExport: true);
  }

  Future<Map<String, dynamic>> buildProjectGraphMap(String projectId) {
    return multitrackService.buildGraphJson(projectId, isExport: true);
  }
}
