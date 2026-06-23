import 'package:nle_editor/data/database/app_database.dart' as db;

class TrackControlsRepository {
  final db.AppDatabase database;

  const TrackControlsRepository({
    required this.database,
  });

  Future<db.Track> getTrack(String trackId) {
    return database.getTrack(trackId);
  }

  Future<void> toggleMute(String trackId) async {
    final track = await database.getTrack(trackId);

    await database.setTrackMuted(
      trackId: trackId,
      muted: !track.isMuted,
    );
  }

  Future<void> toggleSolo(String trackId) async {
    final track = await database.getTrack(trackId);

    await database.setTrackSolo(
      trackId: trackId,
      solo: !track.isSolo,
    );
  }

  Future<void> toggleLock(String trackId) async {
    final track = await database.getTrack(trackId);

    await database.setTrackLocked(
      trackId: trackId,
      locked: !track.isLocked,
    );
  }

  Future<void> toggleHide(String trackId) async {
    final track = await database.getTrack(trackId);

    await database.setTrackHidden(
      trackId: trackId,
      hidden: !track.isHidden,
    );
  }

  Future<void> renameTrack({
    required String trackId,
    required String name,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('Track name cannot be empty.');
    }

    await database.renameTrack(
      trackId: trackId,
      name: cleanName,
    );
  }

  Future<void> resizeTrackBy({
    required String trackId,
    required double delta,
  }) async {
    final track = await database.getTrack(trackId);

    await database.setTrackHeight(
      trackId: trackId,
      height: track.height + delta,
    );
  }

  Future<void> setTrackHeight({
    required String trackId,
    required double height,
  }) {
    return database.setTrackHeight(
      trackId: trackId,
      height: height,
    );
  }

  Future<void> resetTrackHeight(String trackId) async {
    final track = await database.getTrack(trackId);

    final defaultHeight = track.type == 'audio'
        ? 54.0
        : track.type == 'text'
            ? 52.0
            : track.type == 'adjustment'
                ? 44.0
                : 64.0;

    await database.setTrackHeight(
      trackId: trackId,
      height: defaultHeight,
    );
  }
}
