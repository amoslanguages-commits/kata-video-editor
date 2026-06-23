// 33A-PRO: Audio Engine Foundation — Native Audio Engine Service
//
// Wraps the existing NativeBridgeContract to send audio-specific commands
// to the native Android audio mixer via the shared method channel.
//
// All commands here are layered on top of the existing channel — no new
// MethodChannel is required. The method name is sent as the "type" in the
// NativeCommand payload, which the Kotlin NleAudioEngineHandler reads.

import 'dart:convert';

import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';
import 'package:nle_editor/domain/audio/nle_audio_model.dart';

/// Native method-channel names for audio engine commands.
abstract final class NleAudioCommandTypes {
  NleAudioCommandTypes._();

  static const String loadAudioGraph    = 'audio_load_graph';
  static const String updateAudioGraph  = 'audio_update_graph';
  static const String setTrackVolume    = 'audio_set_track_volume';
  static const String setTrackMute      = 'audio_set_track_mute';
  static const String setTrackSolo      = 'audio_set_track_solo';
  static const String setClipVolume     = 'audio_set_clip_volume';
  static const String setClipMute       = 'audio_set_clip_mute';
  static const String setClipFade       = 'audio_set_clip_fade';
  static const String requestMixdown    = 'audio_request_mixdown';
  static const String getMeterState     = 'audio_get_meter_state';
  static const String startMeterUpdates = 'audio_start_meter';
  static const String stopMeterUpdates  = 'audio_stop_meter';
}

/// Audio event types emitted by the native side via the EventChannel.
abstract final class NleAudioEventTypes {
  NleAudioEventTypes._();

  static const String meterUpdate    = 'audio_meter_update';
  static const String mixdownComplete = 'audio_mixdown_complete';
  static const String mixdownError   = 'audio_mixdown_error';
  static const String graphLoaded    = 'audio_graph_loaded';
}

/// High-level service that translates Dart audio operations into
/// typed NativeCommand objects and dispatches them to the bridge.
class NativeAudioEngineService {
  final NativeBridgeContract _bridge;

  const NativeAudioEngineService({
    required NativeBridgeContract bridge,
  }) : _bridge = bridge;

  // ── Graph lifecycle ────────────────────────────────────────────────────────

  /// Loads (replaces) the full audio graph on the native side.
  Future<NativeCommandResult> loadAudioGraph(NleAudioGraph graph) async {
    final graphJson = jsonEncode(graph.toJson());
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.loadAudioGraph,
        projectId: graph.projectId,
        payload:   {'audioGraphJson': graphJson},
      ),
    );
  }

  /// Performs a partial / delta update of the audio graph.
  Future<NativeCommandResult> updateAudioGraph(NleAudioGraph graph) async {
    final graphJson = jsonEncode(graph.toJson());
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.updateAudioGraph,
        projectId: graph.projectId,
        payload:   {'audioGraphJson': graphJson, 'reason': 'update'},
      ),
    );
  }

  // ── Real-time parameter overrides ──────────────────────────────────────────

  Future<NativeCommandResult> setTrackVolume({
    required String projectId,
    required String trackId,
    required double volume,
  }) {
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.setTrackVolume,
        projectId: projectId,
        payload:   {'trackId': trackId, 'volume': volume},
      ),
    );
  }

  Future<NativeCommandResult> setTrackMute({
    required String projectId,
    required String trackId,
    required bool isMuted,
  }) {
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.setTrackMute,
        projectId: projectId,
        payload:   {'trackId': trackId, 'isMuted': isMuted},
      ),
    );
  }

  Future<NativeCommandResult> setTrackSolo({
    required String projectId,
    required String trackId,
    required bool isSolo,
  }) {
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.setTrackSolo,
        projectId: projectId,
        payload:   {'trackId': trackId, 'isSolo': isSolo},
      ),
    );
  }

  Future<NativeCommandResult> setClipVolume({
    required String projectId,
    required String trackId,
    required String clipId,
    required double volume,
  }) {
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.setClipVolume,
        projectId: projectId,
        payload:   {'trackId': trackId, 'clipId': clipId, 'volume': volume},
      ),
    );
  }

  Future<NativeCommandResult> setClipMute({
    required String projectId,
    required String trackId,
    required String clipId,
    required bool isMuted,
  }) {
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.setClipMute,
        projectId: projectId,
        payload: {
          'trackId': trackId,
          'clipId':  clipId,
          'isMuted': isMuted,
        },
      ),
    );
  }

  // ── Export / Mixdown ───────────────────────────────────────────────────────

  Future<NativeCommandResult> requestMixdown({
    required String projectId,
    required String outputPath,
    required NleAudioGraph graph,
    required Map<String, dynamic> exportProfile,
  }) {
    final graphJson = jsonEncode(graph.toJson());
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.requestMixdown,
        projectId: projectId,
        payload:   {
          'audioGraphJson': graphJson,
          'outputPath':     outputPath,
          'profile':        exportProfile,
        },
      ),
    );
  }

  // ── Meters ─────────────────────────────────────────────────────────────────

  Future<NativeCommandResult> startMeterUpdates(String projectId) {
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.startMeterUpdates,
        projectId: projectId,
        payload:   {},
      ),
    );
  }

  Future<NativeCommandResult> stopMeterUpdates(String projectId) {
    return _bridge.sendCommand(
      NativeCommand(
        type:      NleAudioCommandTypes.stopMeterUpdates,
        projectId: projectId,
        payload:   {},
      ),
    );
  }

  Future<NativeCommandResult> pause([String projectId = '']) {
    return _bridge.pause(projectId);
  }
}
