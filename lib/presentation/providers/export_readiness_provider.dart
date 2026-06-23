import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/export/export_readiness_models.dart';
import 'package:nle_editor/presentation/controllers/project_autosave_controller.dart';
import 'package:nle_editor/presentation/providers/device_qa_controller.dart';
import 'package:nle_editor/presentation/providers/editor_history_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_qa_providers.dart';
import 'package:nle_editor/presentation/providers/project_media_management_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';

final exportReadinessProvider =
    Provider.family<ExportReadiness, String>((ref, projectId) {
  final timelineAsync = ref.watch(realProjectTimelineProvider(projectId));
  final qaReportAsync = ref.watch(projectMultitrackQaReportProvider(projectId));
  final mediaHealthAsync = ref.watch(projectMediaHealthReportProvider(projectId));
  final deviceState = ref.watch(deviceQaControllerProvider);
  final autosaveState = ref.watch(editorAutosaveControllerProvider(projectId));
  final exportState = ref.watch(exportStateProvider);

  final List<ExportBlockReason> reasons = [];
  String? detailMessage;

  // 1. Check if exporting already
  if (exportState.isExporting) {
    reasons.add(ExportBlockReason.alreadyExporting);
  }

  // 2. Check if autosave is currently saving
  if (autosaveState.status == AutosaveStatus.saving) {
    reasons.add(ExportBlockReason.autosaveSaving);
  }

  // 3. Check timeline clips (synchronously from AsyncValue if present)
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
      // If loading, treat as preparing
      reasons.add(ExportBlockReason.previewPreparing);
    },
  );

  // 4. Check 34C media health report. Final export should never start when
  // timeline media is unavailable or corrupted.
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
    error: (error, _) {
      reasons.add(ExportBlockReason.mediaUnavailable);
      detailMessage = 'Media health scan failed: $error';
    },
    loading: () {
      reasons.add(ExportBlockReason.previewPreparing);
    },
  );

  // 5. Check QA report
  qaReportAsync.when(
    data: (report) {
      if (!report.passed) {
        reasons.add(ExportBlockReason.qaFailed);
      }
    },
    error: (_, __) {
      reasons.add(ExportBlockReason.qaFailed);
    },
    loading: () {
      reasons.add(ExportBlockReason.previewPreparing);
    },
  );

  // 6. Check Device Compatibility (e.g. thermal throttling, low memory, failed compatibility run)
  if (deviceState.qaReport != null) {
    if (!deviceState.qaReport!.passed) {
      reasons.add(ExportBlockReason.deviceUnsupported);
      final failedIssue = deviceState.qaReport!.issues.firstWhere(
        (i) => i.isFail,
        orElse: () => deviceState.qaReport!.issues.first,
      );
      detailMessage = failedIssue.message;
    } else if (deviceState.qaReport!.capabilityReport.thermal.shouldBlockLongExport) {
      reasons.add(ExportBlockReason.deviceUnsupported);
      detailMessage = 'Device thermal temperature too high. Wait for device to cool down.';
    }
  }

  if (reasons.isEmpty) {
    return const ExportReadiness.ready();
  }

  return ExportReadiness.blocked(reasons, detailMessage);
});
