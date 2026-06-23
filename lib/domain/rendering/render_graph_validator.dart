import 'package:nle_editor/domain/rendering/render_graph_dto.dart';

enum RenderGraphIssueSeverity {
  warning,
  error,
}

class RenderGraphIssue {
  final RenderGraphIssueSeverity severity;
  final String code;
  final String message;

  const RenderGraphIssue({
    required this.severity,
    required this.code,
    required this.message,
  });

  bool get isError => severity == RenderGraphIssueSeverity.error;
}

class RenderGraphValidationResult {
  final List<RenderGraphIssue> issues;

  const RenderGraphValidationResult({
    required this.issues,
  });

  bool get isValid => issues.every((issue) => !issue.isError);
  bool get hasWarnings => issues.any(
        (issue) => issue.severity == RenderGraphIssueSeverity.warning,
      );
}

class RenderGraphValidator {
  const RenderGraphValidator();

  RenderGraphValidationResult validate(RenderGraphDto graph) {
    final issues = <RenderGraphIssue>[];

    if (graph.project.id.trim().isEmpty) {
      issues.add(
        const RenderGraphIssue(
          severity: RenderGraphIssueSeverity.error,
          code: 'project_missing_id',
          message: 'Project id is missing.',
        ),
      );
    }

    if (graph.project.durationMicros <= 0) {
      issues.add(
        const RenderGraphIssue(
          severity: RenderGraphIssueSeverity.error,
          code: 'project_invalid_duration',
          message: 'Project duration must be greater than zero.',
        ),
      );
    }

    if (graph.tracks.isEmpty) {
      issues.add(
        const RenderGraphIssue(
          severity: RenderGraphIssueSeverity.warning,
          code: 'no_tracks',
          message: 'RenderGraph has no tracks.',
        ),
      );
    }

    final assetIds = graph.assets.map((asset) => asset.id).toSet();

    for (final track in graph.tracks) {
      if (track.id.trim().isEmpty) {
        issues.add(
          const RenderGraphIssue(
            severity: RenderGraphIssueSeverity.error,
            code: 'track_missing_id',
            message: 'A track is missing its id.',
          ),
        );
      }

      for (final clip in track.clips) {
        if (clip.timelineEndMicros <= clip.timelineStartMicros) {
          issues.add(
            RenderGraphIssue(
              severity: RenderGraphIssueSeverity.error,
              code: 'clip_invalid_timing',
              message: 'Clip ${clip.id} has invalid timing.',
            ),
          );
        }

        if (clip.assetId != null &&
            clip.assetId!.trim().isNotEmpty &&
            !assetIds.contains(clip.assetId)) {
          issues.add(
            RenderGraphIssue(
              severity: RenderGraphIssueSeverity.warning,
              code: 'clip_missing_asset',
              message: 'Clip ${clip.id} references missing asset ${clip.assetId}.',
            ),
          );
        }

        if (clip.transform.scale <= 0) {
          issues.add(
            RenderGraphIssue(
              severity: RenderGraphIssueSeverity.error,
              code: 'clip_invalid_scale',
              message: 'Clip ${clip.id} has invalid scale.',
            ),
          );
        }

        if (clip.transform.opacity < 0 || clip.transform.opacity > 1) {
          issues.add(
            RenderGraphIssue(
              severity: RenderGraphIssueSeverity.error,
              code: 'clip_invalid_opacity',
              message: 'Clip ${clip.id} opacity must be between 0 and 1.',
            ),
          );
        }

        if (clip.speed <= 0) {
          issues.add(
            RenderGraphIssue(
              severity: RenderGraphIssueSeverity.error,
              code: 'clip_invalid_speed',
              message: 'Clip ${clip.id} speed must be greater than zero.',
            ),
          );
        }
      }
    }

    return RenderGraphValidationResult(issues: issues);
  }
}
