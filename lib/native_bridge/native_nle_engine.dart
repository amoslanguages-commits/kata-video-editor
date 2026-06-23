import 'dart:async';

import 'package:nle_editor/native_bridge/nle_engine.dart';
import 'package:nle_editor/native_bridge/nle_engine_events.dart';

/// STEP 23 — Skeleton for the future native C++/Metal/Vulkan NLE engine.
/// All methods are stubs. Replace with real FFI calls when the native layer is ready.
class NativeNleEngine implements NleEngine {
  final _playbackController =
      StreamController<NlePlaybackPosition>.broadcast();

  @override
  Stream<NlePlaybackPosition> get playbackStream => _playbackController.stream;

  @override
  Future<void> initialize() async {
    // TODO(native): Load native dynamic library.
    // TODO(native): Create engine handle.
    // TODO(native): Register playback callbacks → _playbackController.
    // TODO(native): Start native command queue.
  }

  @override
  Future<void> loadProject(String projectId) async {
    // TODO(native): Serialize project graph → native render graph via FFI.
  }

  @override
  Future<void> play() async {
    // TODO(native): nle_play(engineHandle)
  }

  @override
  Future<void> pause() async {
    // TODO(native): nle_pause(engineHandle)
  }

  @override
  Future<void> seekTo(int timelineMicros) async {
    // TODO(native): nle_seek_us(engineHandle, timelineMicros)
  }

  @override
  Stream<NleExportProgress> exportProject({
    required String projectId,
    required Map<String, dynamic> settings,
  }) async* {
    // TODO(native): Start native export job, emit callbacks from native layer.
    yield const NleExportProgress(
      progress: 0,
      stage: 'Native engine not connected yet — use TemporaryExportService',
    );
  }

  @override
  Future<void> dispose() async {
    // TODO(native): nle_destroy_engine(engineHandle)
    if (!_playbackController.isClosed) {
      await _playbackController.close();
    }
  }
}
