import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/timeline/timeline_diagnostics.dart';

class TimelineDiagnosticsService {
  final TimelineRepository repository;
  final Uuid _uuid;

  const TimelineDiagnosticsService({
    required this.repository,
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid;

  Future<TimelineDiagnosticsReport> inspectProject(String projectId) async {
    return _inspect(projectId: projectId, repair: false);
  }

  Future<TimelineDiagnosticsReport> repairProject(String projectId) async {
    return _inspect(projectId: projectId, repair: true);
  }

  Future<TimelineDiagnosticsReport> _inspect({
    required String projectId,
    required bool repair,
  }) async {
    final tracks = await repository.getProjectTracks(projectId);
    final clips = await repository.getProjectClips(projectId);
    final trackIds = tracks.map((track) => track.id).toSet();
    final issues = <TimelineDiagnosticIssue>[];
    final repairs = <TimelineRepairAction>[];

    if (tracks.isEmpty) {
      issues.add(const TimelineDiagnosticIssue(
        code: 'no_tracks',
        severity: TimelineDiagnosticSeverity.error,
        message: 'Project has no timeline tracks.',
      ));
      if (repair) {
        await repository.createDefaultTracks(projectId);
        repairs.add(const TimelineRepairAction(
          code: 'created_default_tracks',
          message: 'Created default timeline tracks.',
        ));
      }
    }

    final activeTrackIds = repair && tracks.isEmpty
        ? (await repository.getProjectTracks(projectId)).map((track) => track.id).toSet()
        : trackIds;

    for (final clip in clips) {
      if (!activeTrackIds.contains(clip.trackId)) {
        issues.add(TimelineDiagnosticIssue(
          code: 'missing_track',
          severity: TimelineDiagnosticSeverity.error,
          message: 'Clip ${clip.id} references a missing track.',
          clipId: clip.id,
          trackId: clip.trackId,
        ));
        if (repair) {
          await _repairMissingTrack(projectId: projectId, clip: clip, repairs: repairs);
        }
      }

      if (clip.timelineStartMicros < 0) {
        issues.add(TimelineDiagnosticIssue(
          code: 'negative_start',
          severity: TimelineDiagnosticSeverity.error,
          message: 'Clip ${clip.id} starts before zero.',
          clipId: clip.id,
          trackId: clip.trackId,
        ));
        if (repair) {
          final duration = _safeDuration(clip);
          await repository.updateClipFields(
            clip.id,
            ClipsCompanion(
              timelineStartMicros: const Value(0),
              timelineEndMicros: Value(duration),
              modifiedAt: Value(DateTime.now()),
            ),
          );
          repairs.add(TimelineRepairAction(
            code: 'shifted_negative_clip_to_zero',
            message: 'Shifted clip ${clip.id} to start at zero.',
            clipId: clip.id,
            trackId: clip.trackId,
          ));
        }
      }

      if (clip.timelineEndMicros <= clip.timelineStartMicros) {
        issues.add(TimelineDiagnosticIssue(
          code: 'invalid_duration',
          severity: TimelineDiagnosticSeverity.error,
          message: 'Clip ${clip.id} has invalid timeline duration.',
          clipId: clip.id,
          trackId: clip.trackId,
        ));
        if (repair) {
          final start = clip.timelineStartMicros.clamp(0, 1 << 62).toInt();
          await repository.updateClipFields(
            clip.id,
            ClipsCompanion(
              timelineStartMicros: Value(start),
              timelineEndMicros: Value(start + 100000),
              modifiedAt: Value(DateTime.now()),
            ),
          );
          repairs.add(TimelineRepairAction(
            code: 'fixed_invalid_duration',
            message: 'Set clip ${clip.id} to a minimum valid duration.',
            clipId: clip.id,
            trackId: clip.trackId,
          ));
        }
      }

      if (clip.sourceOutMicros < clip.sourceInMicros) {
        issues.add(TimelineDiagnosticIssue(
          code: 'invalid_source_range',
          severity: TimelineDiagnosticSeverity.error,
          message: 'Clip ${clip.id} has invalid source range.',
          clipId: clip.id,
          trackId: clip.trackId,
        ));
        if (repair) {
          final timelineDuration = _safeDuration(clip);
          await repository.updateClipFields(
            clip.id,
            ClipsCompanion(
              sourceOutMicros: Value(clip.sourceInMicros + timelineDuration),
              modifiedAt: Value(DateTime.now()),
            ),
          );
          repairs.add(TimelineRepairAction(
            code: 'fixed_invalid_source_range',
            message: 'Expanded source range for clip ${clip.id}.',
            clipId: clip.id,
            trackId: clip.trackId,
          ));
        }
      }

      if (clip.speed <= 0) {
        issues.add(TimelineDiagnosticIssue(
          code: 'invalid_speed',
          severity: TimelineDiagnosticSeverity.error,
          message: 'Clip ${clip.id} has invalid playback speed.',
          clipId: clip.id,
          trackId: clip.trackId,
        ));
        if (repair) {
          await repository.updateClipFields(
            clip.id,
            ClipsCompanion(
              speed: const Value(1.0),
              modifiedAt: Value(DateTime.now()),
            ),
          );
          repairs.add(TimelineRepairAction(
            code: 'reset_invalid_speed',
            message: 'Reset clip ${clip.id} speed to 1.0.',
            clipId: clip.id,
            trackId: clip.trackId,
          ));
        }
      }
    }

    await _inspectAndRepairOverlaps(
      projectId: projectId,
      repair: repair,
      issues: issues,
      repairs: repairs,
    );

    if (repair && repairs.isNotEmpty) {
      await _recordRepairHistory(projectId, repairs);
    }

    return TimelineDiagnosticsReport(
      projectId: projectId,
      issues: issues,
      repairs: repairs,
    );
  }

  Future<void> _inspectAndRepairOverlaps({
    required String projectId,
    required bool repair,
    required List<TimelineDiagnosticIssue> issues,
    required List<TimelineRepairAction> repairs,
  }) async {
    final tracks = await repository.getProjectTracks(projectId);
    for (final track in tracks) {
      final clips = (await repository.getTrackClips(track.id))
          .where((clip) => !clip.isDisabled)
          .toList()
        ..sort((a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));
      var lastEnd = 0;
      for (final clip in clips) {
        if (clip.timelineStartMicros < lastEnd) {
          issues.add(TimelineDiagnosticIssue(
            code: 'clip_overlap',
            severity: TimelineDiagnosticSeverity.error,
            message: 'Clip ${clip.id} overlaps the previous clip on ${track.name}.',
            clipId: clip.id,
            trackId: track.id,
          ));
          if (repair) {
            final duration = _safeDuration(clip);
            await repository.updateClipFields(
              clip.id,
              ClipsCompanion(
                timelineStartMicros: Value(lastEnd),
                timelineEndMicros: Value(lastEnd + duration),
                modifiedAt: Value(DateTime.now()),
              ),
            );
            repairs.add(TimelineRepairAction(
              code: 'pushed_overlapping_clip',
              message: 'Moved clip ${clip.id} after the previous clip on ${track.name}.',
              clipId: clip.id,
              trackId: track.id,
            ));
            lastEnd += duration;
          } else {
            lastEnd = clip.timelineEndMicros > lastEnd ? clip.timelineEndMicros : lastEnd;
          }
        } else {
          lastEnd = clip.timelineEndMicros > lastEnd ? clip.timelineEndMicros : lastEnd;
        }
      }
    }
  }

  Future<void> _repairMissingTrack({
    required String projectId,
    required Clip clip,
    required List<TimelineRepairAction> repairs,
  }) async {
    var tracks = await repository.getProjectTracks(projectId);
    if (tracks.isEmpty) {
      await repository.createDefaultTracks(projectId);
      tracks = await repository.getProjectTracks(projectId);
    }
    if (tracks.isEmpty) return;
    final target = tracks.firstWhere(
      (track) => track.type == clip.clipType,
      orElse: () => tracks.first,
    );
    await repository.updateClipFields(
      clip.id,
      ClipsCompanion(
        trackId: Value(target.id),
        modifiedAt: Value(DateTime.now()),
      ),
    );
    repairs.add(TimelineRepairAction(
      code: 'reassigned_missing_track_clip',
      message: 'Moved clip ${clip.id} to track ${target.name}.',
      clipId: clip.id,
      trackId: target.id,
    ));
  }

  int _safeDuration(Clip clip) {
    final duration = clip.timelineEndMicros - clip.timelineStartMicros;
    return duration <= 0 ? 100000 : duration;
  }

  Future<void> _recordRepairHistory(
    String projectId,
    List<TimelineRepairAction> repairs,
  ) async {
    final payload = jsonEncode({
      'action': 'timeline_repair',
      'repairs': repairs.map((repair) => repair.toJson()).toList(),
    });
    await repository.insertHistory(
      UndoStackCompanion.insert(
        id: 'history_${_uuid.v4()}',
        projectId: projectId,
        actionType: 'timeline_repair',
        description: const Value('Repair timeline integrity'),
        payload: payload,
        sequence: DateTime.now().microsecondsSinceEpoch,
      ),
    );
    await repository.clearRedoStack(projectId);
  }
}
