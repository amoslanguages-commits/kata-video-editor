import 'dart:async';
import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/mappers/multitrack_db_mapper.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/multitrack_timeline_view_model.dart';
import 'package:nle_editor/domain/timeline/timeline_duration_calculator.dart';

class MultitrackTimelineRepository {
  final db.AppDatabase database;
  final MultitrackDbMapper mapper;
  final TimelineDurationCalculator durationCalculator;

  const MultitrackTimelineRepository({
    required this.database,
    this.mapper = const MultitrackDbMapper(),
    this.durationCalculator = const TimelineDurationCalculator(),
  });

  Future<void> ensureDefaultTracks(String projectId) {
    return database.ensureDefaultMultitrackTracks(projectId);
  }

  Stream<MultitrackTimelineViewModel> watchProjectTimeline(String projectId) {
    final controller = StreamController<MultitrackTimelineViewModel>.broadcast();

    List<MultitrackTrack>? latestTracks;
    List<MultitrackClip>? latestClips;

    StreamSubscription<List<db.Track>>? trackSub;
    StreamSubscription<List<db.Clip>>? clipSub;

    void emitIfReady() {
      final tracks = latestTracks;
      final clips = latestClips;

      if (tracks == null || clips == null) {
        return;
      }

      final durationMicros = durationCalculator.calculateFromClips(clips);

      controller.add(
        MultitrackTimelineViewModel(
          projectId: projectId,
          durationMicros: durationMicros,
          tracks: _sortTracksForTimeline(tracks),
          clips: _sortClips(clips),
        ),
      );
    }

    trackSub = database.watchProjectTracks(projectId).listen(
      (rows) {
        latestTracks = rows.map(mapper.trackFromDb).toList();
        emitIfReady();
      },
      onError: controller.addError,
    );

    clipSub = database.watchProjectClips(projectId).listen(
      (rows) {
        latestClips = rows.map(mapper.clipFromDb).toList();
        emitIfReady();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await trackSub?.cancel();
      await clipSub?.cancel();
    };

    return controller.stream;
  }

  Future<MultitrackTimelineViewModel> getProjectTimelineOnce(
    String projectId,
  ) async {
    final trackRows = await database.getProjectTracksOnce(projectId);
    final clipRows = await database.getProjectClipsOnce(projectId);

    final tracks = trackRows.map(mapper.trackFromDb).toList();
    final clips = clipRows.map(mapper.clipFromDb).toList();

    return MultitrackTimelineViewModel(
      projectId: projectId,
      durationMicros: durationCalculator.calculateFromClips(clips),
      tracks: _sortTracksForTimeline(tracks),
      clips: _sortClips(clips),
    );
  }

  List<MultitrackTrack> _sortTracksForTimeline(
    List<MultitrackTrack> tracks,
  ) {
    final copy = [...tracks];

    copy.sort((a, b) {
      if (a.isVisual && b.isAudio) return -1;
      if (a.isAudio && b.isVisual) return 1;

      if (a.isVisual && b.isVisual) {
        // Display visual tracks top-down: V5, V4, V3, V2, V1.
        return b.sortOrder.compareTo(a.sortOrder);
      }

      // Display audio tracks top-down: A1, A2, A3.
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return copy;
  }

  List<MultitrackClip> _sortClips(List<MultitrackClip> clips) {
    final copy = [...clips];

    copy.sort((a, b) {
      final trackCompare = a.trackId.compareTo(b.trackId);

      if (trackCompare != 0) {
        return trackCompare;
      }

      return a.timelineStartMicros.compareTo(b.timelineStartMicros);
    });

    return copy;
  }
}
