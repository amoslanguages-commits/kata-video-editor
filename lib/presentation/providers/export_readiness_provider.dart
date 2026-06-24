import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/export/export_readiness_models.dart';
import 'package:nle_editor/presentation/controllers/project_autosave_controller.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/project_media_management_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';

final exportReadinessProvider =
    Provider.family<ExportReadiness, String>((ref, projectId) {
  final timelineAsync = ref.watch(realProjectTimelineProvider(projectId));
  final mediaHealthAsync = ref.watch(projectMediaHealthReportProvider(projectId));
  final autosaveState = ref.watch(editorAutosaveControllerProvider(projectId));
  final exportState = ref.watch(exportStateProvider);

  final List<ExportBlockReason> reasons = [];
  String? detailMessage;

  if (exportState.isExporting) {
    reasons.add(ExportBlockReason.alreadyExporting);
  }

  if (autosaveState.status == AutosaveStatus.saving) {
    reasons.add(ExportBlockReason.autosaveSaving);
  }

  timelineAsync.when(
    data: (timeline) {
      if (timeline.clips.isEmpty) {
        reasons.add(ExportBlockReason.noClips);
      }
    },
    error: (_, __) {
      reasons.add(ExportBlockReason.noClips);
    },
    loading: () {
      // Do not block export forever while timeline/readiness providers warm up.
      // The export renderer still performs its own final validation.
    },
  );

  mediaHealthAsync.when(
    data: (report) {
      if (!report.canExport) {
        reasons.add(ExportBlockReason.mediaUnavailable);
        final count = report.blockingItems.length;
        detailMessage = count == 1
            ? '1 timeline media file is unavailable. Open Storage > Media to relink it.'
            : '$count timeline media files are unavailable. Open Storage > Media to relink them.';
      }
    },
    error: (_) {
      // Do not make export unavailable because an advisory media-health scan failed.
      // Missing files and decoder failures are still caught by native export state.
    },
    loading: () {
      // Allow export while the advisory media scan is loading.
    },
  );

  if (reasons.isEmpty) {
    return const ExportReadiness.ready();
  }

  return ExportReadiness.blocked(reasons, detailMessage);
});
