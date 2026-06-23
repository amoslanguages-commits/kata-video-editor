import 'package:drift/drift.dart';
import 'package:nle_editor/data/database/app_database.dart';

class TimelineRepository {
  final AppDatabase _db;

  TimelineRepository(this._db);

  // ── Tracks ──────────────────────────────────────────────────────────────────

  Stream<List<Track>> watchProjectTracks(String projectId) =>
      _db.watchProjectTracks(projectId);

  Future<List<Track>> getProjectTracks(String projectId) =>
      _db.getProjectTracks(projectId);

  Future<Track> getTrack(String trackId) => _db.getTrack(trackId);

  Future<Track?> getFirstTrackByType(String projectId, String type) =>
      _db.getFirstTrackByType(projectId, type);

  Future<void> insertTrack(TracksCompanion track) => _db.insertTrack(track);

  Future<void> updateTrackFields(String trackId, TracksCompanion companion) =>
      _db.updateTrackFields(trackId, companion);

  // ── Clips ───────────────────────────────────────────────────────────────────

  Stream<List<Clip>> watchTrackClips(String trackId) =>
      _db.watchTrackClips(trackId);

  Stream<List<Clip>> watchProjectClips(String projectId) =>
      _db.watchProjectClips(projectId);

  Future<List<Clip>> getProjectClips(String projectId) =>
      _db.getProjectClips(projectId);

  Future<Clip?> getClip(String clipId) => _db.getClip(clipId);

  Future<void> insertClip(ClipsCompanion clip) => _db.insertClip(clip);

  Future<void> updateClipFields(String clipId, ClipsCompanion companion) =>
      _db.updateClipFields(clipId, companion);

  Future<int> deleteClip(String clipId) => _db.deleteClip(clipId);

  Future<List<Clip>> getTrackClips(String trackId) {
    return _db.getTrackClips(trackId);
  }

  // ── History ─────────────────────────────────────────────────────────────────

  Future<void> insertHistory(UndoStackCompanion entry) =>
      _db.insertHistory(entry);

  Future<UndoStackData?> getLastUndo(String projectId) =>
      _db.getLastHistory(projectId, 'undo');

  Future<UndoStackData?> getLastRedo(String projectId) =>
      _db.getLastHistory(projectId, 'redo');

  Future<void> moveHistoryToRedo(String historyId) =>
      _db.moveHistoryToStack(historyId, 'redo');

  Future<void> moveHistoryToUndo(String historyId) =>
      _db.moveHistoryToStack(historyId, 'undo');

  Future<void> clearRedoStack(String projectId) =>
      _db.clearRedoStack(projectId);

  Future<void> clearAllHistory(String projectId) =>
      _db.clearAllHistory(projectId);

  // ── Computed ─────────────────────────────────────────────────────────────────

  Future<int> calculateProjectDuration(String projectId) async {
    final clips = await _db.getProjectClips(projectId);
    if (clips.isEmpty) return 0;
    var maxEnd = 0;
    for (final clip in clips) {
      if (!clip.isDisabled && clip.timelineEndMicros > maxEnd) {
        maxEnd = clip.timelineEndMicros;
      }
    }
    return maxEnd;
  }

  Future<void> createDefaultTracks(String projectId) async {
    const defaultTracks = [
      (name: 'Overlay', type: 'overlay', index: 0, height: 64),
      (name: 'Video', type: 'video', index: 1, height: 72),
      (name: 'Text', type: 'text', index: 2, height: 64),
      (name: 'Audio', type: 'audio', index: 3, height: 64),
      (name: 'Music', type: 'audio', index: 4, height: 64),
    ];

    for (final track in defaultTracks) {
      await insertTrack(
        TracksCompanion.insert(
          id: 'track_${projectId}_${track.type}_${track.index}',
          projectId: projectId,
          name: track.name,
          type: track.type,
          index: Value(track.index),
          height: Value(track.height),
        ),
      );
    }
  }

  Future<List<Keyframe>> getClipKeyframes(String clipId) {
    return _db.getClipKeyframes(clipId);
  }

  Future<List<Keyframe>> getProjectKeyframes(String projectId) {
    return _db.getProjectKeyframes(projectId);
  }
}
