import 'dart:async';

import 'package:nle_editor/native_bridge/nle_engine.dart';
import 'package:nle_editor/native_bridge/nle_engine_events.dart';

/// Fake NLE engine that simulates playback with a timer.
/// Replace this with a real FFI engine when the native layer is ready.
class FakeNleEngine implements NleEngine {
  final _controller = StreamController<NlePlaybackPosition>.broadcast();
  Timer? _playbackTimer;
  bool _isPlaying = false;
  int _currentTimeMicros = 0;

  @override
  Stream<NlePlaybackPosition> get playbackStream => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {
    _playbackTimer?.cancel();
    if (!_controller.isClosed) await _controller.close();
  }

  @override
  Future<void> loadProject(String projectId) async {
    _currentTimeMicros = 0;
    _isPlaying = false;
  }

  @override
  Future<void> play() async {
    if (_isPlaying) return;
    _isPlaying = true;
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _currentTimeMicros += 33000;
      _emit();
    });
    _emit();
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _emit();
  }

  @override
  Future<void> seekTo(int timelineMicros) async {
    _currentTimeMicros = timelineMicros.clamp(0, 1 << 62);
    _emit();
  }

  @override
  Stream<NleExportProgress> exportProject({
    required String projectId,
    required Map<String, dynamic> settings,
  }) async* {
    for (var i = 0; i <= 100; i += 5) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      yield NleExportProgress(
        progress: i,
        stage: i < 50
            ? 'Rendering frames'
            : i < 90
                ? 'Encoding'
                : i < 100
                    ? 'Muxing'
                    : 'Complete',
        outputPath: i >= 100 ? '/fake/output/export.mp4' : null,
      );
    }
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(NlePlaybackPosition(
        isPlaying: _isPlaying,
        timelineMicros: _currentTimeMicros,
      ));
    }
  }
}
