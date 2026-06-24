import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nle_editor/domain/export/device_capability_profile.dart';
import 'package:nle_editor/domain/rendering/render_graph_contract.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_versioning.dart';

class NleNativeBridgeErrorCode {
  static const String commandFailed = 'command_failed';
  static const String invalidArguments = 'invalid_arguments';
  static const String unsupportedProtocol = 'unsupported_protocol';
  static const String unsupportedRenderGraph = 'unsupported_render_graph';
  static const String nativeError = 'native_error';

  const NleNativeBridgeErrorCode._();
}

class NleNativeBridgeException implements Exception {
  final String code;
  final String message;
  final String? technicalMessage;
  final Map<String, Object?> context;

  const NleNativeBridgeException({
    required this.code,
    required this.message,
    this.technicalMessage,
    this.context = const {},
  });

  @override
  String toString() {
    final detail = technicalMessage == null ? '' : ' ($technicalMessage)';
    return 'NleNativeBridgeException[$code]: $message$detail';
  }
}

class NleNativeBridgeCommand {
  final String method;
  final String? projectId;
  final Map<String, Object?> payload;
  final VersionedRenderGraphPayload? renderGraph;

  const NleNativeBridgeCommand({
    required this.method,
    this.projectId,
    this.payload = const {},
    this.renderGraph,
  });

  Map<String, Object?> toMethodArguments({String? commandId}) {
    final args = <String, Object?>{
      RenderGraphContract.payloadProtocolVersionKey:
          RenderGraphContract.nativeBridgeProtocolVersion,
      if (commandId != null) RenderGraphContract.payloadCommandIdKey: commandId,
      if (projectId != null) RenderGraphContract.payloadProjectIdKey: projectId,
      ...payload,
    };

    final graph = renderGraph;
    if (graph != null) {
      args.addAll(graph.toBridgeFields());
    }

    return args;
  }
}

class NleNativeBridgeResponse<T> {
  final bool success;
  final String method;
  final T? result;
  final NleNativeBridgeException? error;
  final Map<String, Object?> raw;

  const NleNativeBridgeResponse({
    required this.success,
    required this.method,
    required this.result,
    required this.error,
    required this.raw,
  });

  T requireResult() {
    if (!success) throw error ?? const NleNativeBridgeException(
      code: NleNativeBridgeErrorCode.commandFailed,
      message: 'Native command failed without a structured error.',
    );
    return result as T;
  }
}

class NleTypedNativeBridge {
  final MethodChannel _channel;

  NleTypedNativeBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(RenderGraphContract.nativeBridgeName);

  Future<NleNativeBridgeResponse<Map<String, Object?>>> invoke(
    NleNativeBridgeCommand command,
  ) async {
    _validateCommand(command);
    final commandId = _newCommandId(command.method);
    final raw = await _channel.invokeMethod<Object?>(
      command.method,
      command.toMethodArguments(commandId: commandId),
    );
    return _parseResponse(command.method, raw);
  }

  Future<NleNativeBridgeResponse<Map<String, Object?>>> initialize() {
    return invoke(const NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.initialize,
    ));
  }

  Future<NleNativeBridgeResponse<Map<String, Object?>>> dispose() {
    return invoke(const NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.dispose,
    ));
  }

  Future<NleNativeBridgeResponse<Map<String, Object?>>> loadRenderGraph({
    required String projectId,
    required RenderGraphDto graph,
  }) {
    return invoke(NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.loadRenderGraph,
      projectId: projectId,
      renderGraph: VersionedRenderGraphPayload.fromGraph(graph),
    ));
  }

  Future<NleNativeBridgeResponse<Map<String, Object?>>> updateRenderGraph({
    required String projectId,
    required RenderGraphDto graph,
    String? reason,
  }) {
    return invoke(NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.updateRenderGraph,
      projectId: projectId,
      payload: {
        if (reason != null) 'reason': reason,
      },
      renderGraph: VersionedRenderGraphPayload.fromGraph(graph),
    ));
  }

  Future<NleNativeBridgeResponse<Map<String, Object?>>> validateRenderGraph({
    required String projectId,
    required RenderGraphDto graph,
  }) {
    return invoke(NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.validateRenderGraph,
      projectId: projectId,
      renderGraph: VersionedRenderGraphPayload.fromGraph(graph),
    ));
  }

  Future<NleNativeBridgeResponse<Map<String, Object?>>> startExportJob({
    required String projectId,
    required String jobId,
    required RenderGraphDto graph,
    required String outputPath,
    required Map<String, Object?> profile,
  }) {
    return invoke(NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.startExportJob,
      projectId: projectId,
      payload: {
        'jobId': jobId,
        'outputPath': outputPath,
        'profile': profile,
      },
      renderGraph: VersionedRenderGraphPayload.fromGraph(graph),
    ));
  }

  Future<NleNativeBridgeResponse<Map<String, Object?>>> cancelExportJob({
    required String jobId,
  }) {
    return invoke(NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.cancelExportJob,
      payload: {'jobId': jobId},
    ));
  }

  Future<NleNativeBridgeResponse<DeviceCapabilityProfile>> probeDeviceCapabilities() async {
    final response = await invoke(const NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.probeDeviceCapabilities,
    ));
    if (!response.success) {
      return NleNativeBridgeResponse<DeviceCapabilityProfile>(
        success: false,
        method: response.method,
        result: null,
        error: response.error,
        raw: response.raw,
      );
    }
    final result = response.requireResult();
    return NleNativeBridgeResponse<DeviceCapabilityProfile>(
      success: true,
      method: response.method,
      result: DeviceCapabilityProfile.fromNativePayload(result),
      error: null,
      raw: response.raw,
    );
  }

  Future<NleNativeBridgeResponse<Map<String, Object?>>> renderGpuPreviewFrame({
    required String projectId,
    required RenderGraphDto graph,
    required int timelineTimeMicros,
  }) {
    return invoke(NleNativeBridgeCommand(
      method: RenderGraphNativeMethods.renderGpuPreviewFrame,
      projectId: projectId,
      payload: {'timelineTimeMicros': timelineTimeMicros},
      renderGraph: VersionedRenderGraphPayload.fromGraph(graph),
    ));
  }

  void _validateCommand(NleNativeBridgeCommand command) {
    if (!RenderGraphContract.supportsNativeBridgeProtocol(
      RenderGraphContract.nativeBridgeProtocolVersion,
    )) {
      throw const NleNativeBridgeException(
        code: NleNativeBridgeErrorCode.unsupportedProtocol,
        message: 'Native bridge protocol version is not supported.',
      );
    }

    final graph = command.renderGraph;
    if (graph != null && !RenderGraphContract.supportsVersion(graph.version)) {
      throw NleNativeBridgeException(
        code: NleNativeBridgeErrorCode.unsupportedRenderGraph,
        message: 'Render graph version is not supported by this app build.',
        context: {
          'version': graph.version,
          'minSupportedVersion': RenderGraphContract.minSupportedVersion,
          'maxSupportedVersion': RenderGraphContract.maxSupportedVersion,
        },
      );
    }
  }

  NleNativeBridgeResponse<Map<String, Object?>> _parseResponse(
    String method,
    Object? raw,
  ) {
    final map = _map(raw);
    final success = map['success'] == true;
    final result = _map(map['result']);
    final error = _error(map['error']);
    return NleNativeBridgeResponse<Map<String, Object?>>(
      success: success,
      method: map['method']?.toString() ?? method,
      result: result,
      error: error,
      raw: map,
    );
  }

  NleNativeBridgeException? _error(Object? value) {
    final map = _map(value);
    if (map.isEmpty) return null;
    return NleNativeBridgeException(
      code: map['code']?.toString() ?? NleNativeBridgeErrorCode.nativeError,
      message: map['message']?.toString() ?? 'Native command failed.',
      technicalMessage: map['technicalMessage']?.toString(),
      context: map,
    );
  }

  Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, Object?>{};
  }

  String _newCommandId(String method) {
    return '${method}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
