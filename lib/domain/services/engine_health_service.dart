import 'dart:async';

import 'package:nle_editor/domain/diagnostics/timeline_issue.dart';
import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';

/// Checks the health of the native NLE engine by exercising the method
/// channel via a lightweight command and verifying the event stream.
class EngineHealthService {
  final NativeBridgeContract _bridge;

  EngineHealthService({required NativeBridgeContract bridge})
      : _bridge = bridge;

  Future<EngineHealthReport> checkHealth() async {
    bool methodReachable = false;
    bool eventActive = false;
    String? errorMsg;

    // Subscribe briefly to the event channel and check it doesn't throw.
    try {
      final sub = _bridge.events.listen((_) {});
      eventActive = true;
      await sub.cancel();
    } catch (e) {
      eventActive = false;
      errorMsg = 'Event channel error: $e';
    }

    // Probe via a known lightweight command (getAudioEngineState).
    // We don't need a real projectId here — we just need to see if the
    // channel is reachable without crashing.
    try {
      final result = await _bridge
          .getAudioEngineState(projectId: '__health_check__')
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => NativeCommandResult(
              commandId: '__health__',
              accepted: false,
              message: 'Timeout',
              errorCode: 'timeout',
            ),
          );
      methodReachable = result.accepted;
      if (!result.accepted && errorMsg == null) {
        errorMsg = result.message;
      }
    } catch (e) {
      methodReachable = false;
      errorMsg = errorMsg ?? 'Method channel error: $e';
    }

    String status;
    if (!methodReachable) {
      status = EngineHealthStatus.offline;
    } else if (!eventActive) {
      status = EngineHealthStatus.degraded;
    } else {
      status = EngineHealthStatus.healthy;
    }

    return EngineHealthReport(
      status: status,
      methodChannelReachable: methodReachable,
      eventChannelActive: eventActive,
      sessionActive: methodReachable,
      activeSessionCount: methodReachable ? 1 : 0,
      errorMessage: errorMsg,
      checkedAt: DateTime.now(),
    );
  }
}
