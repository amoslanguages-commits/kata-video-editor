import 'package:nle_editor/domain/rendering/multitrack_render_graph_service.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';

class NativeCommandService {
  final MultitrackRenderGraphService renderGraphService;
  final NativeBridgeContract nativeBridge;

  NativeCommandService({
    required this.renderGraphService,
    required this.nativeBridge,
  });

  Future<NativeCommandResult> loadProjectToNative(String projectId) async {
    final graph = await renderGraphService.buildGraph(projectId);
    return nativeBridge.loadRenderGraph(graph);
  }

  Future<NativeCommandResult> updateNativeGraph(String projectId) async {
    final graph = await renderGraphService.buildGraph(projectId);
    return nativeBridge.updateRenderGraph(graph);
  }

  Future<void> updateRenderGraph({
    required String projectId,
    required String renderGraphJson,
    required String reason,
  }) async {
    await nativeBridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.updateRenderGraph,
        projectId: projectId,
        payload: {
          'projectId': projectId,
          'renderGraphJson': renderGraphJson,
          'reason': reason,
        },
      ),
    );
  }

  Future<NativeCommandResult> play(String projectId) {
    return nativeBridge.play(projectId);
  }

  Future<NativeCommandResult> pause(String projectId) {
    return nativeBridge.pause(projectId);
  }

  Future<NativeCommandResult> seek({
    required String projectId,
    required int timelineMicros,
    bool accurate = false,
  }) {
    return nativeBridge.seek(
      projectId: projectId,
      timelineMicros: timelineMicros,
      accurate: accurate,
    );
  }

  Future<NativeCommandResult> sendClipChanged({
    required String projectId,
    required String clipId,
    required String action,
  }) async {
    final graph = await renderGraphService.buildGraph(projectId);

    return nativeBridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.updateRenderGraph,
        projectId: projectId,
        payload: {
          'reason': action,
          'clipId': clipId,
          'renderGraph': graph.toJson(),
        },
      ),
    );
  }

  Future<NativeCommandResult> sendTransitionChanged({
    required String projectId,
    required String transitionId,
    required String action,
  }) async {
    final graph = await renderGraphService.buildGraph(projectId);

    return nativeBridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.updateRenderGraph,
        projectId: projectId,
        payload: {
          'reason': action,
          'transitionId': transitionId,
          'renderGraph': graph.toJson(),
        },
      ),
    );
  }

  Future<NativeCommandResult> sendKeyframeChanged({
    required String projectId,
    required String keyframeId,
    required String clipId,
    required String action,
  }) async {
    final graph = await renderGraphService.buildGraph(projectId);

    return nativeBridge.sendCommand(
      NativeCommand(
        type: NativeCommandTypes.updateRenderGraph,
        projectId: projectId,
        payload: {
          'reason': action,
          'keyframeId': keyframeId,
          'clipId': clipId,
          'renderGraph': graph.toJson(),
        },
      ),
    );
  }
}
