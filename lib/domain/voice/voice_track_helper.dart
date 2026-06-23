import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:nle_editor/data/database/app_database.dart' as db_pkg;
import 'package:nle_editor/data/repositories/audio_repository.dart';

class VoiceTrackHelper {
  final AudioRepository audioRepository;

  const VoiceTrackHelper({
    required this.audioRepository,
  });

  Future<String> ensureVoiceTrack(String projectId) async {
    final database = audioRepository.database;

    // Query existing tracks to find a dedicated voiceover track
    final existingTracks = await database.getProjectTracks(projectId);
    final existingVoice = existingTracks.where((t) {
      return t.type == 'audio' && t.trackRole == 'voiceover';
    }).firstOrNull;

    if (existingVoice != null) {
      return existingVoice.id;
    }

    // Create a new voiceover track
    final id = 'track_${projectId}_voiceover_${const Uuid().v4()}';
    final index = existingTracks.length;

    await database.insertTrack(
      db_pkg.TracksCompanion.insert(
        id: id,
        projectId: projectId,
        name: 'Voiceover',
        type: 'audio',
        index: Value(index),
        trackRole: const Value('voiceover'),
      ),
    );

    return id;
  }
}
