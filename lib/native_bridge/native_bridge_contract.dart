import 'dart:async';

import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/native_bridge/native_command.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

abstract class NativeBridgeContract {
  Stream<NativeEvent> get events;

  Future<void> initialize();

  Future<NativeCommandResult> sendCommand(NativeCommand command);

  Future<NativeCommandResult> loadRenderGraph(RenderGraphDto graph) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.loadRenderGraph,
        projectId: graph.project.id,
        payload: {
          'renderGraph': graph.toJson(),
        },
      ),
    );
  }

  Future<NativeCommandResult> updateRenderGraph(RenderGraphDto graph) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.updateRenderGraph,
        projectId: graph.project.id,
        payload: {
          'renderGraph': graph.toJson(),
        },
      ),
    );
  }

  Future<NativeCommandResult> play(String projectId) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.play,
        projectId: projectId,
      ),
    );
  }

  Future<NativeCommandResult> pause(String projectId) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.pause,
        projectId: projectId,
      ),
    );
  }

  Future<NativeCommandResult> seek({
    required String projectId,
    required int timelineMicros,
    bool accurate = false,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.seek,
        projectId: projectId,
        payload: {
          'timelineMicros': timelineMicros,
          'accurate': accurate,
        },
      ),
    );
  }

  Future<NativeCommandResult> startJob({
    required String projectId,
    required String jobId,
    required String jobType,
    required Map<String, dynamic> payload,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.startJob,
        projectId: projectId,
        payload: {
          'jobId': jobId,
          'jobType': jobType,
          'payload': payload,
        },
      ),
    );
  }

  Future<NativeCommandResult> cancelJob({
    required String projectId,
    required String jobId,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.cancelJob,
        projectId: projectId,
        payload: {
          'jobId': jobId,
        },
      ),
    );
  }

  Future<NativeCommandResult> startProxyJob({
    required String? projectId,
    required String jobId,
    required String assetId,
    required String inputPath,
    required String outputPath,
    required Map<String, dynamic> profile,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.startProxyJob,
        projectId: projectId,
        payload: {
          'jobId': jobId,
          'assetId': assetId,
          'inputPath': inputPath,
          'outputPath': outputPath,
          'profile': profile,
        },
      ),
    );
  }

  Future<NativeCommandResult> cancelProxyJob({
    required String jobId,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.cancelProxyJob,
        payload: {
          'jobId': jobId,
        },
      ),
    );
  }

  Future<NativeCommandResult> startExportJob({
    required String? projectId,
    required String jobId,
    required String renderGraphJson,
    required String outputPath,
    required Map<String, dynamic> profile,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.startExportJob,
        projectId: projectId,
        payload: {
          'jobId': jobId,
          'renderGraphJson': renderGraphJson,
          'outputPath': outputPath,
          'profile': profile,
        },
      ),
    );
  }

  Future<NativeCommandResult> cancelExportJob({
    required String jobId,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.cancelExportJob,
        payload: {
          'jobId': jobId,
        },
      ),
    );
  }

  Future<NativeCommandResult> createPreviewTexture({
    required String? projectId,
    required int width,
    required int height,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.createPreviewTexture,
        projectId: projectId,
        payload: {
          'width': width,
          'height': height,
        },
      ),
    );
  }

  Future<NativeCommandResult> attachPreviewTexture({
    required String projectId,
    required int textureId,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.attachPreviewTexture,
        projectId: projectId,
        payload: {
          'textureId': textureId,
        },
      ),
    );
  }

  Future<NativeCommandResult> resizePreviewTexture({
    required int textureId,
    required int width,
    required int height,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.resizePreviewTexture,
        payload: {
          'textureId': textureId,
          'width': width,
          'height': height,
        },
      ),
    );
  }

  Future<NativeCommandResult> renderPreviewPlaceholder({
    required int textureId,
    required String label,
    required int playheadMicros,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.renderPreviewPlaceholder,
        payload: {
          'textureId': textureId,
          'label': label,
          'playheadMicros': playheadMicros,
        },
      ),
    );
  }

  Future<NativeCommandResult> disposePreviewTexture({
    required int textureId,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.disposePreviewTexture,
        payload: {
          'textureId': textureId,
        },
      ),
    );
  }

  Future<NativeCommandResult> setPlaybackRate({
    required String projectId,
    required double rate,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.setPlaybackRate,
        projectId: projectId,
        payload: {
          'rate': rate,
        },
      ),
    );
  }

  Future<NativeCommandResult> getAudioEngineState({
    required String projectId,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.getAudioEngineState,
        projectId: projectId,
        payload: {},
      ),
    );
  }

  Future<NativeCommandResult> probeDeviceCapabilities() {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.probeDeviceCapabilities,
        payload: const {},
      ),
    );
  }

  Future<NativeCommandResult> renderGpuPreviewFrame({
    required String projectId,
    required String renderGraphJson,
    required int timelineTimeMicros,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.renderGpuPreviewFrame,
        projectId: projectId,
        payload: {
          'renderGraphJson':    renderGraphJson,
          'timelineTimeMicros': timelineTimeMicros,
        },
      ),
    );
  }

  Future<NativeCommandResult> qaValidateRenderGraph({
    required String renderGraphJson,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.qaValidateRenderGraph,
        payload: {
          'renderGraphJson': renderGraphJson,
        },
      ),
    );
  }

  Future<NativeCommandResult> qaProbeVisual({
    required String renderGraphJson,
    required int timelineTimeUs,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.qaProbeVisual,
        payload: {
          'renderGraphJson': renderGraphJson,
          'timelineTimeUs': timelineTimeUs,
        },
      ),
    );
  }

  Future<NativeCommandResult> qaProbeAudio({
    required String renderGraphJson,
    required int windowStartUs,
    required int windowEndUs,
  }) {
    return sendCommand(
      NativeCommand(
        type: NativeCommandTypes.qaProbeAudio,
        payload: {
          'renderGraphJson': renderGraphJson,
          'windowStartUs': windowStartUs,
          'windowEndUs': windowEndUs,
        },
      ),
    );
  }

  Future<void> dispose();
}
