import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/timeline/timeline_edit_engine.dart';

class TimelineTestHarness {
  final AppDatabase db;
  final TimelineRepository repository;
  final TimelineEditEngine engine;

  TimelineTestHarness._(this.db, this.repository, this.engine);

  static Future<TimelineTestHarness> create() async {
    final db = AppDatabase(NativeDatabase.memory());
    final repository = TimelineRepository(db);
    final engine = TimelineEditEngine(repository: repository);
    await seedProject(db);
    return TimelineTestHarness._(db, repository, engine);
  }

  Future<void> close() => db.close();

  static Future<void> seedProject(AppDatabase db) async {
    await db.insertProject(
      ProjectsCompanion.insert(
        id: 'project_1',
        name: 'Timeline Test',
      ),
    );
    await db.insertTrack(
      TracksCompanion.insert(
        id: 'track_video',
        projectId: 'project_1',
        name: 'Video',
        type: 'video',
        index: const Value(0),
      ),
    );
  }

  Future<void> insertClip({
    required String id,
    required int start,
    required int end,
    int sourceIn = 0,
    int? sourceOut,
    double speed = 1.0,
  }) async {
    await db.insertClip(
      ClipsCompanion.insert(
        id: id,
        projectId: 'project_1',
        trackId: 'track_video',
        assetId: const Value(null),
        clipType: const Value('video'),
        timelineStartMicros: Value(start),
        timelineEndMicros: Value(end),
        sourceInMicros: Value(sourceIn),
        sourceOutMicros: Value(sourceOut ?? (sourceIn + (end - start).abs())),
        speed: Value(speed),
      ),
    );
  }
}
