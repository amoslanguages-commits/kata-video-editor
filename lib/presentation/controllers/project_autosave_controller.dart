// lib/presentation/controllers/project_autosave_controller.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;

enum AutosaveStatus {
  clean,
  dirty,
  saving,
  saved,
  error,
}

class ProjectAutosaveState {
  final AutosaveStatus status;
  final DateTime? lastSavedAt;
  final String? lastReason;
  final String? errorMessage;

  const ProjectAutosaveState({
    required this.status,
    this.lastSavedAt,
    this.lastReason,
    this.errorMessage,
  });

  const ProjectAutosaveState.clean()
      : status = AutosaveStatus.clean,
        lastSavedAt = null,
        lastReason = null,
        errorMessage = null;

  ProjectAutosaveState copyWith({
    AutosaveStatus? status,
    DateTime? lastSavedAt,
    String? lastReason,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProjectAutosaveState(
      status: status ?? this.status,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      lastReason: lastReason ?? this.lastReason,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProjectAutosaveController extends StateNotifier<ProjectAutosaveState> {
  final String projectId;
  final db.AppDatabase database;

  Timer? _timer;

  ProjectAutosaveController({
    required this.projectId,
    required this.database,
  }) : super(const ProjectAutosaveState.clean());

  void markDirty({
    required String reason,
  }) {
    state = state.copyWith(
      status: AutosaveStatus.dirty,
      lastReason: reason,
      clearError: true,
    );

    database.markProjectDirty(projectId).catchError((e) {
      // ignore silently during editing bursts
    });

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 900), saveNow);
  }

  Future<void> saveNow() async {
    if (state.status == AutosaveStatus.saving) return;

    state = state.copyWith(
      status: AutosaveStatus.saving,
      clearError: true,
    );

    try {
      await database.markProjectSaved(projectId);

      state = state.copyWith(
        status: AutosaveStatus.saved,
        lastSavedAt: DateTime.now(),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AutosaveStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
