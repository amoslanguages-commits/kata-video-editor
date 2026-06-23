// lib/presentation/providers/source_preview_providers.dart
//
// 29F: Riverpod providers for Source Preview.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/source_insert_repository.dart';

import 'package:nle_editor/domain/source_preview/source_preview_models.dart';
import 'package:nle_editor/presentation/controllers/source_preview_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/native_true_preview_providers.dart';

import 'package:nle_editor/presentation/providers/clip_interactions_providers.dart';



final sourceInsertRepositoryProvider = Provider<SourceInsertRepository>((ref) {
  return SourceInsertRepository(database: ref.watch(databaseProvider));
});

final sourcePreviewControllerProvider = StateNotifierProvider.family<
    SourcePreviewController,
    SourcePreviewState,
    String>((ref, projectId) {
  return SourcePreviewController(
    projectId:        projectId,
    insertRepository: ref.watch(sourceInsertRepositoryProvider),
    previewService:   ref.watch(nativeTruePreviewServiceProvider),
    ref:              ref,
    database:         ref.watch(databaseProvider),
    refreshBridge:    ref.watch(timelineEditRefreshBridgeProvider),
  );
});
