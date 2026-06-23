import 'dart:async';

import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/domain/preview/preview_monitor.dart';

class NativeEyedropperService {
  final NativeBridgeContract bridge;

  final _samples = StreamController<NlePickedHslSample>.broadcast();

  NativeEyedropperService({
    required this.bridge,
  }) {
    bridge.events.listen(_handleEvent);
  }

  Stream<NlePickedHslSample> get samples => _samples.stream;

  Future<void> pickFromPreview({
    required PreviewMonitor monitor,
    required double normalizedX,
    required double normalizedY,
  }) {
    return bridge.sendCommand(
      NativeCommand(
        type: 'color_pick_hsl_sample',
        payload: {
          'monitorId': monitor.name,
          'x': normalizedX.clamp(0.0, 1.0),
          'y': normalizedY.clamp(0.0, 1.0),
        },
      ),
    );
  }

  void _handleEvent(NativeEvent event) {
    if (event.type != 'color_hsl_sample_picked') return;

    _samples.add(
      NlePickedHslSample.fromJson(
        Map<String, dynamic>.from(event.payload),
      ),
    );
  }

  void dispose() {
    _samples.close();
  }
}
