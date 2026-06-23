import 'package:nle_editor/data/database/app_database.dart';

class TransitionRepository {
  final AppDatabase _db;

  TransitionRepository(this._db);

  Stream<List<ClipTransition>> watchProjectTransitions(String projectId) {
    return _db.watchProjectTransitions(projectId);
  }

  Future<List<ClipTransition>> getProjectTransitions(String projectId) {
    return _db.getProjectTransitions(projectId);
  }

  Future<ClipTransition?> getTransition(String transitionId) {
    return _db.getClipTransition(transitionId);
  }

  Future<ClipTransition?> getTransitionBetween({
    required String outgoingClipId,
    required String incomingClipId,
  }) {
    return _db.getTransitionBetween(
      outgoingClipId: outgoingClipId,
      incomingClipId: incomingClipId,
    );
  }

  Future<void> insertTransition(ClipTransitionsCompanion transition) {
    return _db.insertClipTransition(transition);
  }

  Future<void> updateTransitionFields(
    String transitionId,
    ClipTransitionsCompanion companion,
  ) {
    return _db.updateClipTransitionFields(transitionId, companion);
  }

  Future<int> deleteTransition(String transitionId) {
    return _db.deleteClipTransition(transitionId);
  }

  Future<int> deleteTransitionsForClip(String clipId) {
    return _db.deleteTransitionsForClip(clipId);
  }
}
