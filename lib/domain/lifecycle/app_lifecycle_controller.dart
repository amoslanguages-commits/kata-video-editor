import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:nle_editor/domain/lifecycle/project_session_state.dart';
import 'package:nle_editor/domain/services/error_reporting_service.dart';
import 'package:nle_editor/domain/services/project_autosave_service.dart';
import 'package:nle_editor/domain/services/project_session_service.dart';
import 'package:nle_editor/domain/services/resume_project_safety_check_service.dart';
import 'package:nle_editor/native_bridge/native_command_service.dart';

/// Callback that supplies the current editor state as a [ProjectSessionState].
typedef ProjectSessionBuilder = ProjectSessionState Function();

/// Callback invoked on app resume with the safety-check results.
typedef ResumeSafetyCallback = void Function(
    ResumeProjectSafetyReport report);

/// A [WidgetsBindingObserver] that:
///
/// **On pause / background:**
/// 1. Serialises the editor session state → `session_state.json`
/// 2. Triggers an immediate autosave.
/// 3. Sends a native pause command to stop preview playback.
///
/// **On resume:**
/// 1. Runs [ResumeProjectSafetyCheckService] (media permission, missing
///    assets, interrupted jobs).
/// 2. Reports results via [ResumeSafetyCallback].
///
/// The controller is app-wide (registered once in a provider), but only acts
/// when a project is attached via [attachProject].
class AppLifecycleController with WidgetsBindingObserver {
  final ProjectSessionService projectSessionService;
  final ProjectAutosaveController autosaveController;
  final NativeCommandService nativeCommandService;
  final ResumeProjectSafetyCheckService resumeSafetyCheckService;
  final ErrorReportingService errorReportingService;

  String? _activeProjectId;
  ProjectSessionBuilder? _sessionBuilder;
  ResumeSafetyCallback? _onResumeSafetyReport;

  bool _started = false;
  bool _isHandlingPause = false;
  bool _isHandlingResume = false;

  AppLifecycleController({
    required this.projectSessionService,
    required this.autosaveController,
    required this.nativeCommandService,
    required this.resumeSafetyCheckService,
    required this.errorReportingService,
  });

  // ─── Lifecycle registration ────────────────────────────────────────────────

  void start() {
    if (_started) return;
    WidgetsBinding.instance.addObserver(this);
    _started = true;
  }

  void stop() {
    if (!_started) return;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  // ─── Project attach / detach ───────────────────────────────────────────────

  void attachProject({
    required String projectId,
    required ProjectSessionBuilder sessionBuilder,
    ResumeSafetyCallback? onResumeSafetyReport,
  }) {
    _activeProjectId = projectId;
    _sessionBuilder = sessionBuilder;
    _onResumeSafetyReport = onResumeSafetyReport;
    autosaveController.start(projectId);
  }

  void detachProject(String projectId) {
    if (_activeProjectId != projectId) return;
    autosaveController.stop();
    _activeProjectId = null;
    _sessionBuilder = null;
    _onResumeSafetyReport = null;
  }

  // ─── Manual save ──────────────────────────────────────────────────────────

  /// Saves session + triggers autosave immediately (e.g. on Back press).
  Future<void> saveNow() async {
    final projectId = _activeProjectId;
    final builder = _sessionBuilder;
    if (projectId == null || builder == null) return;

    try {
      final session = builder();
      await projectSessionService.saveSession(session);
      await autosaveController.saveNow();
    } catch (e, stack) {
      await errorReportingService.reportException(
        e,
        stackTrace: stack,
        projectId: projectId,
        source: 'app_lifecycle_save_now',
        notify: false,
      );
    }
  }

  // ─── WidgetsBindingObserver ────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_handlePause());
      case AppLifecycleState.resumed:
        unawaited(_handleResume());
    }
  }

  // ─── Internal handlers ────────────────────────────────────────────────────

  Future<void> _handlePause() async {
    if (_isHandlingPause) return;
    _isHandlingPause = true;

    final projectId = _activeProjectId;
    final builder = _sessionBuilder;

    try {
      if (projectId != null && builder != null) {
        final session = builder();
        await projectSessionService.saveSession(session);
        await autosaveController.saveNow();
        await nativeCommandService.pause(projectId);
      }
    } catch (e, stack) {
      await errorReportingService.reportException(
        e,
        stackTrace: stack,
        projectId: projectId,
        source: 'app_lifecycle_pause',
        notify: false,
      );
    } finally {
      _isHandlingPause = false;
    }
  }

  Future<void> _handleResume() async {
    if (_isHandlingResume) return;
    _isHandlingResume = true;

    final projectId = _activeProjectId;

    try {
      if (projectId != null) {
        final report = await resumeSafetyCheckService.checkProjectOnResume(
          projectId,
        );
        _onResumeSafetyReport?.call(report);
      }
    } catch (e, stack) {
      await errorReportingService.reportException(
        e,
        stackTrace: stack,
        projectId: projectId,
        source: 'app_lifecycle_resume',
        notify: false,
      );
    } finally {
      _isHandlingResume = false;
    }
  }

  void dispose() {
    stop();
  }
}
