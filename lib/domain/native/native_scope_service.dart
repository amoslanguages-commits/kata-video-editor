import 'dart:async';

import 'package:nle_editor/domain/color_scopes/color_scope_models.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/domain/preview/preview_monitor.dart';

class NativeScopeService {
  final NativeBridgeContract bridge;

  final _frames = StreamController<NleScopeFrameData>.broadcast();

  NativeScopeService({
    required this.bridge,
  }) {
    bridge.events.listen(_handleEvent);
  }

  Stream<NleScopeFrameData> get frames => _frames.stream;

  Future<void> configureScopes({
    required NleScopeSettings settings,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: 'scopes_configure',
        payload: settings.toJson(),
      ),
    );
  }

  Future<void> requestFrame({
    required PreviewMonitor monitor,
    required int timestampMicros,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: 'scopes_request_frame',
        payload: {
          'monitorId': monitor.name,
          'timestampMicros': timestampMicros,
        },
      ),
    );
  }

  Future<void> startLive({
    required PreviewMonitor monitor,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: 'scopes_start_live',
        payload: {
          'monitorId': monitor.name,
        },
      ),
    );
  }

  Future<void> stopLive() {
    return bridge.sendCommand(
      NativeCommand(
        type: 'scopes_stop_live',
        payload: {},
      ),
    );
  }

  void _handleEvent(NativeEvent event) {
    if (event.type != 'scopes_frame_data') return;

    _frames.add(
      NleScopeFrameData.fromJson(
        Map<String, dynamic>.from(event.payload),
      ),
    );
  }

  void dispose() {
    _frames.close();
  }
}
