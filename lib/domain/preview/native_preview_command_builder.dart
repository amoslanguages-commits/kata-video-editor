import 'package:nle_editor/native_bridge/native_command.dart';

class NativePreviewCommandBuilder {
  const NativePreviewCommandBuilder();

  NativeCommand prepare({
    required String projectId,
    required String monitorId,
    required String renderGraphJson,
    required String qualityMode,
    required bool preferProxy,
    required int maxPreviewWidth,
    required int maxPreviewHeight,
  }) {
    return NativeCommand(
      type: NativeCommandTypes.prepareTruePreview,
      projectId: projectId,
      payload: {
        'projectId': projectId,
        'monitorId': monitorId,
        'renderGraphJson': renderGraphJson,
        'qualityMode': qualityMode,
        'preferProxy': preferProxy,
        'maxPreviewWidth': maxPreviewWidth,
        'maxPreviewHeight': maxPreviewHeight,
      },
    );
  }

  NativeCommand renderFrame({
    required String monitorId,
    required int timelineMicros,
  }) {
    return NativeCommand(
      type: NativeCommandTypes.renderPreviewFrame,
      payload: {
        'monitorId': monitorId,
        'timelineTimeUs': timelineMicros,
        'timelineTimeMicros': timelineMicros,
      },
    );
  }

  NativeCommand play({required String monitorId, required int fromMicros}) {
    return NativeCommand(
      type: NativeCommandTypes.startTruePreview,
      payload: {
        'monitorId': monitorId,
        'fromTimelineTimeUs': fromMicros,
        'fromTimelineTimeMicros': fromMicros,
      },
    );
  }

  NativeCommand pause({required String monitorId}) {
    return NativeCommand(
      type: NativeCommandTypes.pauseTruePreview,
      payload: {'monitorId': monitorId},
    );
  }

  NativeCommand stop({required String monitorId}) {
    return NativeCommand(
      type: NativeCommandTypes.stopTruePreview,
      payload: {'monitorId': monitorId},
    );
  }

  NativeCommand disposeSession({required String monitorId}) {
    return NativeCommand(
      type: NativeCommandTypes.disposeTruePreview,
      payload: {'monitorId': monitorId},
    );
  }
}
