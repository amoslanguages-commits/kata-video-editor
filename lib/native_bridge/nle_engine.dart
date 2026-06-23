import 'package:nle_editor/native_bridge/nle_engine_events.dart';

abstract class NleEngine {
  Stream<NlePlaybackPosition> get playbackStream;

  Future<void> initialize();
  Future<void> dispose();

  Future<void> loadProject(String projectId);
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(int timelineMicros);

  Stream<NleExportProgress> exportProject({
    required String projectId,
    required Map<String, dynamic> settings,
  });
}
