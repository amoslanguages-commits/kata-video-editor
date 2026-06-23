import 'package:nle_editor/data/repositories/media_asset_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/diagnostics/timeline_issue.dart';
import 'package:nle_editor/domain/render_graph/render_graph.dart';

/// Validates the render graph and timeline for structural issues.
/// This is a pure Dart validator — no native calls.
class RenderGraphValidationService {
  final TimelineRepository timelineRepository;
  final MediaAssetRepository assetRepository;

  RenderGraphValidationService({
    required this.timelineRepository,
    required this.assetRepository,
  });

  Future<TimelineValidationReport> validateProject(String projectId) async {
    final issues = <TimelineIssue>[];

    final tracks = await timelineRepository.getProjectTracks(projectId);
    final clips = await timelineRepository.getProjectClips(projectId);
    final assets = await assetRepository.getAssets(projectId);
    final keyframes = await timelineRepository.getProjectKeyframes(projectId);

    // ── 1. Empty project check ──────────────────────────────────────────────
    if (clips.isEmpty) {
      issues.add(TimelineIssue(
        severity: TimelineIssueSeverity.info,
        category: TimelineIssueCategory.timeline,
        title: 'Empty timeline',
        description: 'No clips have been added to the timeline yet.',
      ));
    }

    // ── 2. Missing media ────────────────────────────────────────────────────
    for (final asset in assets) {
      if (asset.isMissing) {
        issues.add(TimelineIssue(
          severity: TimelineIssueSeverity.critical,
          category: TimelineIssueCategory.media,
          title: 'Missing media file',
          description:
              '"${asset.fileInfo.fileName}" cannot be found at its original location.',
          assetId: asset.id,
          action: TimelineIssueAction(
            label: 'Reconnect',
            actionId: TimelineIssueActionId.reconnectMedia,
            payload: {'assetId': asset.id},
          ),
        ));
      }
    }

    // ── 3. Clip bounds validation ───────────────────────────────────────────
    for (final clip in clips) {
      if (clip.isDisabled) continue;

      // Negative or zero duration
      if (clip.timelineEndMicros <= clip.timelineStartMicros) {
        issues.add(TimelineIssue(
          severity: TimelineIssueSeverity.error,
          category: TimelineIssueCategory.timeline,
          title: 'Invalid clip duration',
          description: 'Clip has a zero or negative duration on the timeline.',
          clipId: clip.id,
          trackId: clip.trackId,
          action: TimelineIssueAction(
            label: 'Remove clip',
            actionId: TimelineIssueActionId.removeClip,
            payload: {'clipId': clip.id},
          ),
        ));
      }

      // Source out <= source in
      if (clip.sourceOutMicros <= clip.sourceInMicros) {
        issues.add(TimelineIssue(
          severity: TimelineIssueSeverity.error,
          category: TimelineIssueCategory.timeline,
          title: 'Invalid clip trim range',
          description:
              'Source in/out points are reversed or equal — no media frames will export.',
          clipId: clip.id,
          trackId: clip.trackId,
          action: TimelineIssueAction(
            label: 'Repair timing',
            actionId: TimelineIssueActionId.repairTiming,
            payload: {'clipId': clip.id},
          ),
        ));
      }

      // Clip on wrong track
      final track = tracks.firstWhere(
        (t) => t.id == clip.trackId,
        orElse: () => throw StateError('Track not found'),
      );

      // Orphaned clip (no assetId for a video clip)
      if (clip.clipType == 'video' && clip.assetId == null) {
        issues.add(TimelineIssue(
          severity: TimelineIssueSeverity.error,
          category: TimelineIssueCategory.media,
          title: 'Clip has no media',
          description:
              'A video clip on track "${track.name}" has no linked asset.',
          clipId: clip.id,
          trackId: clip.trackId,
          action: TimelineIssueAction(
            label: 'Remove clip',
            actionId: TimelineIssueActionId.removeClip,
            payload: {'clipId': clip.id},
          ),
        ));
      }
    }

    // ── 4. Overlapping clips on same video track ────────────────────────────
    final videoTracks = tracks.where((t) => t.type == 'video').toList();
    for (final vt in videoTracks) {
      final trackClips = clips
          .where((c) => c.trackId == vt.id && !c.isDisabled)
          .toList()
        ..sort(
            (a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));

      for (var i = 0; i < trackClips.length - 1; i++) {
        final a = trackClips[i];
        final b = trackClips[i + 1];
        if (b.timelineStartMicros < a.timelineEndMicros) {
          issues.add(TimelineIssue(
            severity: TimelineIssueSeverity.warning,
            category: TimelineIssueCategory.timeline,
            title: 'Overlapping clips',
            description:
                'Two clips on track "${vt.name}" overlap. Only the top clip will export.',
            clipId: b.id,
            trackId: vt.id,
          ));
        }
      }
    }

    // ── 5. Keyframe bounds ─────────────────────────────────────────────────
    final clipMap = {for (final c in clips) c.id: c};
    for (final kf in keyframes) {
      final clip = clipMap[kf.clipId];
      if (clip == null) {
        issues.add(TimelineIssue(
          severity: TimelineIssueSeverity.warning,
          category: TimelineIssueCategory.renderGraph,
          title: 'Orphaned keyframe',
          description: 'A keyframe references a clip that no longer exists.',
          clipId: kf.clipId,
          action: TimelineIssueAction(
            label: 'Repair keyframes',
            actionId: TimelineIssueActionId.repairKeyframes,
            payload: {'clipId': kf.clipId},
          ),
        ));
      } else {
        if (kf.timeMicros < clip.timelineStartMicros ||
            kf.timeMicros > clip.timelineEndMicros) {
          issues.add(TimelineIssue(
            severity: TimelineIssueSeverity.warning,
            category: TimelineIssueCategory.renderGraph,
            title: 'Out-of-range keyframe',
            description:
                'A keyframe is outside its clip\'s timeline range and will be ignored.',
            clipId: kf.clipId,
            action: TimelineIssueAction(
              label: 'Repair keyframes',
              actionId: TimelineIssueActionId.repairKeyframes,
              payload: {'clipId': kf.clipId},
            ),
          ));
        }
      }
    }

    return TimelineValidationReport(
      projectId: projectId,
      issues: issues,
      generatedAt: DateTime.now(),
    );
  }

  /// Validate a pre-built [RenderGraph] for export-readiness without
  /// hitting the database again.
  TimelineValidationReport validateRenderGraph(RenderGraph graph) {
    final issues = <TimelineIssue>[];

    // Missing assets
    for (final asset in graph.assets) {
      if (asset.isMissing) {
        issues.add(TimelineIssue(
          severity: TimelineIssueSeverity.critical,
          category: TimelineIssueCategory.media,
          title: 'Missing media',
          description: '"${asset.fileName}" is missing from disk.',
          assetId: asset.id,
        ));
      }
    }

    // Zero-duration project
    if (graph.project.durationMicros <= 0) {
      issues.add(TimelineIssue(
        severity: TimelineIssueSeverity.error,
        category: TimelineIssueCategory.project,
        title: 'Zero-duration project',
        description: 'The project has no exportable content.',
      ));
    }

    // Invalid transitions (clips no longer exist)
    final clipIds = graph.clips.map((c) => c.id).toSet();
    for (final tx in graph.transitions) {
      if (!clipIds.contains(tx.outgoingClipId) ||
          !clipIds.contains(tx.incomingClipId)) {
        issues.add(TimelineIssue(
          severity: TimelineIssueSeverity.warning,
          category: TimelineIssueCategory.transition,
          title: 'Unlinked transition',
          description:
              'A "${tx.type}" transition references a clip that no longer exists.',
          action: TimelineIssueAction(
            label: 'Repair transition',
            actionId: TimelineIssueActionId.repairTransition,
            payload: {'transitionId': tx.id},
          ),
        ));
      }
    }

    return TimelineValidationReport(
      projectId: graph.project.id,
      issues: issues,
      generatedAt: DateTime.now(),
    );
  }
}
