import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';

/// Real Android native bridge — communicates with the Kotlin [NleEditorPlugin]
/// via MethodChannel (commands) and EventChannel (async events).
///
/// Drop-in replacement for [FakeNativeBridge] on Android.
class AndroidNativeBridge extends NativeBridgeContract {
  static const MethodChannel _methodChannel = MethodChannel(
    'nle_editor/native_methods',
  );

  static const EventChannel _eventChannel = EventChannel(
    'nle_editor/native_events',
  );

  static const _uuid = Uuid();

  final StreamController<NativeEvent> _eventsController =
      StreamController<NativeEvent>.broadcast();

  StreamSubscription<dynamic>? _nativeEventSub;
  bool _initialized = false;

  // ── NativeBridgeContract ─────────────────────────────────────────────────

  @override
  Stream<NativeEvent> get events => _eventsController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Subscribe to native EventChannel before sending initialize so we never
    // miss the ENGINE_READY event.
    _nativeEventSub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic raw) {
        final event = _decodeEvent(raw);
        if (event != null) _eventsController.add(event);
      },
      onError: (Object error, StackTrace st) {
        _eventsController.add(
          _errorEvent(
            code:    'dart_event_channel_error',
            message: 'Native event stream failed.',
            tech:    error.toString(),
          ),
        );
      },
    );

    final result = await _invoke(NativeCommandTypes.initialize, const {});

    if (!result.accepted) {
      throw StateError(
        result.message ??
            result.errorCode ??
            'Android native engine failed to initialize.',
      );
    }

    _initialized = true;
  }

  @override
  Future<NativeCommandResult> sendCommand(NativeCommand command) async {
    await initialize();

    final methodName = _commandTypeToMethod(command.type);

    return _invoke(
      methodName,
      {
        'commandId': command.id,
        'projectId': command.projectId,
        ...command.payload,
      },
    );
  }

  // -- Convenience overrides (avoid double JSON-encoding via sendCommand) ----

  @override
  Future<NativeCommandResult> loadRenderGraph(RenderGraphDto graph) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.loadRenderGraph,
      {
        'commandId':       _uuid.v4(),
        'projectId':       graph.project.id,
        'renderGraphJson': jsonEncode(graph.toJson()),
      },
    );
  }

  @override
  Future<NativeCommandResult> updateRenderGraph(RenderGraphDto graph) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.updateRenderGraph,
      {
        'commandId':       _uuid.v4(),
        'projectId':       graph.project.id,
        'renderGraphJson': jsonEncode(graph.toJson()),
        'reason':          'update',
      },
    );
  }

  @override
  Future<NativeCommandResult> play(String projectId) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.play,
      {'commandId': _uuid.v4(), 'projectId': projectId},
    );
  }

  @override
  Future<NativeCommandResult> pause(String projectId) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.pause,
      {'commandId': _uuid.v4(), 'projectId': projectId},
    );
  }

  @override
  Future<NativeCommandResult> seek({
    required String projectId,
    required int timelineMicros,
    bool accurate = false,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.seek,
      {
        'commandId':      _uuid.v4(),
        'projectId':      projectId,
        'timelineMicros': timelineMicros,
        'accurate':       accurate,
      },
    );
  }

  @override
  Future<NativeCommandResult> startJob({
    required String projectId,
    required String jobId,
    required String jobType,
    required Map<String, dynamic> payload,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.startJob,
      {
        'commandId': _uuid.v4(),
        'projectId': projectId,
        'jobId':     jobId,
        'jobType':   jobType,
        'payload':   payload,
      },
    );
  }

  @override
  Future<NativeCommandResult> cancelJob({
    required String projectId,
    required String jobId,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.cancelJob,
      {
        'commandId': _uuid.v4(),
        'projectId': projectId,
        'jobId':     jobId,
      },
    );
  }

  @override
  Future<NativeCommandResult> startProxyJob({
    required String? projectId,
    required String jobId,
    required String assetId,
    required String inputPath,
    required String outputPath,
    required Map<String, dynamic> profile,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.startProxyJob,
      {
        'commandId': _uuid.v4(),
        'projectId': projectId,
        'jobId':     jobId,
        'assetId':   assetId,
        'inputPath': inputPath,
        'outputPath': outputPath,
        'profile':   profile,
      },
    );
  }

  @override
  Future<NativeCommandResult> cancelProxyJob({
    required String jobId,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.cancelProxyJob,
      {
        'commandId': _uuid.v4(),
        'jobId':     jobId,
      },
    );
  }

  @override
  Future<NativeCommandResult> startExportJob({
    required String? projectId,
    required String jobId,
    required String renderGraphJson,
    required String outputPath,
    required Map<String, dynamic> profile,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.startExportJob,
      {
        'commandId':       _uuid.v4(),
        'projectId':       projectId,
        'jobId':           jobId,
        'renderGraphJson': renderGraphJson,
        'outputPath':      outputPath,
        'profile':         profile,
      },
    );
  }

  @override
  Future<NativeCommandResult> cancelExportJob({
    required String jobId,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.cancelExportJob,
      {
        'commandId': _uuid.v4(),
        'jobId':     jobId,
      },
    );
  }

  // ── Additional Android-specific helpers ──────────────────────────────────

  Future<NativeCommandResult> probeDeviceCapabilities() async {
    await initialize();
    return _invoke(
      NativeCommandTypes.probeDeviceCapabilities,
      {'commandId': _uuid.v4()},
    );
  }

  Future<NativeCommandResult> getSessionState(String projectId) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.getSessionState,
      {'commandId': _uuid.v4(), 'projectId': projectId},
    );
  }

  @override
  Future<NativeCommandResult> setPlaybackRate({
    required String projectId,
    required double rate,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.setPlaybackRate,
      {'commandId': _uuid.v4(), 'projectId': projectId, 'rate': rate},
    );
  }

  @override
  Future<NativeCommandResult> renderGpuPreviewFrame({
    required String projectId,
    required String renderGraphJson,
    required int timelineTimeMicros,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.renderGpuPreviewFrame,
      {
        'commandId':          _uuid.v4(),
        'projectId':          projectId,
        'renderGraphJson':    renderGraphJson,
        'timelineTimeMicros': timelineTimeMicros,
      },
    );
  }

  @override
  Future<NativeCommandResult> getAudioEngineState({
    required String projectId,
  }) async {
    await initialize();
    return _invoke(
      NativeCommandTypes.getAudioEngineState,
      {'commandId': _uuid.v4(), 'projectId': projectId},
    );
  }

  // ── Dispose ──────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    try {
      if (_initialized) {
        await _invoke(NativeCommandTypes.dispose, {'commandId': _uuid.v4()});
      }
    } catch (_) {}

    await _nativeEventSub?.cancel();
    _nativeEventSub = null;
    _initialized = false;

    if (!_eventsController.isClosed) {
      await _eventsController.close();
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<NativeCommandResult> _invoke(
    String method,
    Map<String, dynamic> arguments,
  ) async {
    final commandId = arguments['commandId']?.toString() ?? _uuid.v4();
    try {
      final raw = await _methodChannel.invokeMethod<dynamic>(method, arguments);
      final map = _toStringDynamic(raw);

      if (map['success'] == true) {
        return NativeCommandResult(
          commandId: commandId,
          accepted:  true,
          message:   'OK',
        );
      }

      final error = _toStringDynamic(map['error']);
      return NativeCommandResult(
        commandId: commandId,
        accepted:  false,
        errorCode: error['code']?.toString(),
        message:   error['message']?.toString() ??
            error['technicalMessage']?.toString() ??
            'Android native command failed.',
      );
    } on PlatformException catch (e) {
      return NativeCommandResult(
        commandId: commandId,
        accepted:  false,
        errorCode: e.code,
        message:   e.message ?? 'Android platform channel error.',
      );
    } catch (e) {
      return NativeCommandResult(
        commandId: commandId,
        accepted:  false,
        errorCode: 'android_bridge_error',
        message:   e.toString(),
      );
    }
  }

  NativeEvent? _decodeEvent(dynamic raw) {
    try {
      final map = _toStringDynamic(raw);
      final payload = _toStringDynamic(map['payload']);

      return NativeEvent(
        id:        _uuid.v4(),
        type:      map['type']?.toString() ?? NativeEventTypes.engineError,
        projectId: map['projectId']?.toString(),
        commandId: map['commandId']?.toString(),
        jobId:     map['jobId']?.toString(),
        payload:   payload,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[AndroidNativeBridge] event decode error: $e  raw=$raw');
      return _errorEvent(
        code:    'dart_native_event_decode_failed',
        message: 'Could not decode native event.',
        tech:    raw.toString(),
      );
    }
  }

  NativeEvent _errorEvent({
    required String code,
    required String message,
    String? tech,
  }) {
    return NativeEvent(
      id:        _uuid.v4(),
      type:      NativeEventTypes.engineError,
      payload:   {
        'code':             code,
        'message':          message,
        'technicalMessage': tech,
      },
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _toStringDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }

  /// Maps the Dart command-type constant to the Kotlin method-channel name.
  /// Both sides currently share the same string values, so this is an
  /// identity mapping — but having it here keeps the contract explicit.
  String _commandTypeToMethod(String type) {
    // All NativeCommandTypes strings match the Kotlin NleNativeCommandType values.
    return type;
  }
}
