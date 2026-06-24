import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/constants/app_constants.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/native_bridge/native_event.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/real_multitrack_timeline_providers.dart';
import 'package:nle_editor/presentation/providers/real_native_preview_provider.dart';
import 'package:nle_editor/presentation/widgets/panels/tool_panel.dart';
import 'package:nle_editor/presentation/widgets/preview/dual_preview_area.dart';
import 'package:nle_editor/presentation/providers/dual_preview_layout_providers.dart';
import 'package:nle_editor/presentation/widgets/timeline/real_project_multitrack_timeline.dart';
import 'package:nle_editor/presentation/screens/storage/project_storage_screen.dart';
import 'package:nle_editor/presentation/screens/settings/settings_screen.dart';
import 'package:nle_editor/presentation/screens/premium/pack_browser_screen.dart';
import 'package:nle_editor/presentation/widgets/recovery/recovery_prompt_dialog.dart';
import 'package:nle_editor/presentation/screens/monetization/pro_paywall_screen.dart';
import 'package:nle_editor/presentation/providers/monetization_providers.dart';
import 'package:nle_editor/domain/premium/premium_feature.dart';
import 'package:nle_editor/domain/polish/editor_hint.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/widgets/polish/editor_hint_banner.dart';
import 'package:nle_editor/presentation/widgets/polish/first_project_guide_sheet.dart';
import 'package:nle_editor/presentation/screens/export/export_success_screen.dart';
import 'package:nle_editor/presentation/widgets/editor/history_toolbar.dart';
import 'package:nle_editor/presentation/widgets/editor/mobile_editing_toolbar.dart';
import 'package:nle_editor/presentation/widgets/editor/resizable_panel_divider.dart';
import 'package:nle_editor/presentation/widgets/export/safe_export_button.dart';
import 'package:nle_editor/presentation/widgets/timeline/timeline_empty_state.dart';
import 'package:nle_editor/presentation/widgets/beta/beta_feedback_dialog.dart';
import 'package:nle_editor/presentation/providers/color_scope_providers.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/professional_scopes_panel.dart';
import 'package:nle_editor/presentation/widgets/color_scopes/scope_toggle_button.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_editor_layout.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_color_layout.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_audio_layout.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_vfx_layout.dart';
import 'package:nle_editor/presentation/widgets/editor/desktop_multicam_layout.dart';
import 'package:nle_editor/presentation/widgets/timeline/virtual_jog_wheel.dart';
import 'package:nle_editor/presentation/screens/auth/auth_screen.dart';
import 'package:nle_editor/presentation/screens/auth/profile_screen.dart';
import 'package:nle_editor/presentation/providers/supabase_auth_providers.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  StreamSubscription<NativeEvent>? _nativeErrorSub;

  /// ID of the project we have already bootstrapped (lifecycle attached,
  /// recovery prompt shown, autosave started). Guards against running
  /// bootstrap twice if the widget rebuilds.
  String? _bootstrappedProjectId;

  /// Ensures the recovery prompt is only shown once per editor session.
  bool _recoveryPromptShown = false;

  /// Ensures the first-project guide is only shown once per editor session.
  bool _guideShown = false;

  /// Prevents navigating to ExportSuccessScreen more than once per export job.
  bool _exportSuccessNavigated = false;

  double _toolPanelHeight = 190.0;
  double _timelineHeight = 220.0;

  @override
  void initState() {
    super.initState();
    _startNativeErrorListener();
  }

  void _startNativeErrorListener() {
    _nativeErrorSub ??= ref.read(nativeBridgeProvider).events.listen((event) {
      const errorTypes = {
        NativeEventTypes.missingFile,
        NativeEventTypes.decoderError,
        NativeEventTypes.memoryWarning,
        NativeEventTypes.thermalWarning,
        NativeEventTypes.exportFailed,
        NativeEventTypes.proxyFailed,
        NativeEventTypes.engineError,
        NativeEventTypes.previewError,
      };

      if (errorTypes.contains(event.type)) {
        ref.read(errorReportingServiceProvider).reportNativeEvent(event);
      }
    });
  }

  // ─── Bootstrap ────────────────────────────────────────────────────────────

  void _bootstrapProjectOnce(Project project) {
    if (_bootstrappedProjectId == project.id) return;
    _bootstrappedProjectId = project.id;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Ensure job queue is alive.
      ref.read(jobQueueServiceProvider);

      // Attach to lifecycle controller — starts autosave, registers session
      // builder and resume callback.
      final lifecycle = ref.read(appLifecycleControllerProvider);
      lifecycle.attachProject(
        projectId: project.id,
        sessionBuilder: () {
          final s = ref.read(editorStateProvider);
          return ProjectSessionState(
            projectId: project.id,
            currentTimeMicros: s.currentTimeMicros,
            selectedClipId: s.selectedClipId,
            selectedTrackId: s.selectedTrackId,
            activeTool: s.activeTool,
            timelineZoom: s.timelineZoom,
            showSafeArea: s.showSafeArea,
            snapEnabled: s.snapEnabled,
            previewWasPlaying: s.isPlaying,
            savedAt: DateTime.now(),
          );
        },
        onResumeSafetyReport: (report) {
          if (mounted) _handleResumeSafetyReport(report);
        },
      );

      // Load render graph into native engine.
      await ref
          .read(nativeCommandServiceProvider)
          .loadProjectToNative(project.id);

      // Show recovery prompt if needed (once per session).
      if (mounted) await _maybeShowRecoveryPrompt(project.id);

      // Show the first-project guide on first open (once per install).
      if (mounted) await _maybeShowFirstProjectGuide();

      // Check for missing media.
      if (!mounted) return;
      final report = await ref
          .read(missingMediaServiceProvider)
          .checkProjectMedia(project.id);

      if (!mounted) return;
      if (report.hasMissing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${report.missingAssets} media file(s) are missing.',
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // ─── Recovery ─────────────────────────────────────────────────────────────

  Future<void> _maybeShowRecoveryPrompt(String projectId) async {
    if (_recoveryPromptShown) return;
    _recoveryPromptShown = true;

    final info = await ref
        .read(recoverySnapshotDetectorProvider)
        .inspectProject(projectId);

    if (!mounted) return;

    // The SQLite database is updated in real-time, so there is no timeline data to "recover".
    // We simply restore the UI session state (playhead position, active tool, etc.) silently
    // so the user can seamlessly resume their work without a confusing "Crash" dialog.
    if (info.hasSession) {
      final session =
          await ref.read(projectSessionServiceProvider).readSession(projectId);

      if (session != null && mounted) {
        await ref.read(editorStateProvider.notifier).restoreSession(session);
      }
    }
  }

  // ─── First-project guide ───────────────────────────────────────────────────

  Future<void> _maybeShowFirstProjectGuide() async {
    if (_guideShown) return;
    _guideShown = true;

    final seen = await ref
        .read(onboardingStateServiceProvider)
        .hasSeenFirstProjectGuide();
    if (!mounted || seen) return;

    await FirstProjectGuideSheet.show(context);
    ref.invalidate(hasSeenFirstProjectGuideProvider);
  }

  // ─── Resume safety ───────────────────────────────────────────────────────

  void _handleResumeSafetyReport(ResumeProjectSafetyReport report) {
    if (!mounted || !report.hasWarnings) return;

    final messages = <String>[];
    if (report.missingAssets > 0) {
      messages.add('${report.missingAssets} missing media file(s)');
    }
    if (report.interruptedJobs > 0) {
      messages.add('${report.interruptedJobs} interrupted job(s)');
    }
    if (!report.mediaPermissionAvailable) {
      messages.add('media permission needs attention');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messages.join(' • ')),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _nativeErrorSub?.cancel();
    final projectId = _bootstrappedProjectId;
    if (projectId != null) {
      try {
        ref.read(appLifecycleControllerProvider).detachProject(projectId);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectId = ref.watch(selectedProjectIdProvider);
    final projectAsync = ref.watch(selectedProjectProvider);
    final editorState = ref.watch(editorStateProvider);
    final editorNotifier = ref.read(editorStateProvider.notifier);
    final scopesSettings = ref.watch(colorScopeControllerProvider).settings;
    final authState = ref.watch(supabaseAuthStateProvider);

    // Navigate to ExportSuccessScreen when export finishes.
    ref.listen<ExportState>(exportStateProvider, (prev, next) {
      if (next.progress >= 100 &&
          next.outputPath != null &&
          !_exportSuccessNavigated) {
        _exportSuccessNavigated = true;
        // Close the export dialog if open, then push the success screen.
        Navigator.popUntil(context,
            (route) => route.isFirst || route.settings.name == '/editor');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExportSuccessScreen(
              outputPath: next.outputPath!,
              presetName: next.stage.isNotEmpty ? next.stage : 'Custom',
            ),
          ),
        ).then((_) => _exportSuccessNavigated = false);
      }
    });

    if (projectId == null) {
      return const Scaffold(
        body: Center(child: Text('No project selected')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () async {
            // Save session + autosave before leaving the editor.
            await ref.read(appLifecycleControllerProvider).saveNow();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        title: projectAsync.when(
          data: (project) {
            if (project != null) _bootstrapProjectOnce(project);
            return Text(project?.name ?? 'Editor');
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          if (projectAsync.value != null) ...[
            HistoryToolbar(projectId: projectAsync.value!.id),
            const SizedBox(width: 4),
            const ScopeToggleButton(),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.feedback_rounded, size: 20),
            onPressed: () => BetaFeedbackDialog.show(context),
            tooltip: 'Submit Feedback',
          ),
          IconButton(
            icon: Icon(
              editorState.showSafeArea
                  ? Icons.grid_on_rounded
                  : Icons.grid_off_rounded,
              color: editorState.showSafeArea
                  ? AppTheme.accentPrimary
                  : AppTheme.textSecondary,
              size: 20,
            ),
            onPressed: editorNotifier.toggleSafeArea,
            tooltip: 'Toggle Safe Area',
          ),
          IconButton(
            icon: Icon(
              editorState.snapEnabled
                  ? Icons.bolt
                  : Icons.offline_bolt_outlined,
              color: editorState.snapEnabled
                  ? AppTheme.accentPrimary
                  : AppTheme.textSecondary,
              size: 20,
            ),
            onPressed: editorNotifier.toggleSnap,
            tooltip: 'Toggle Snapping',
          ),
          PopupMenuButton<WorkspaceLayout>(
            icon: Icon(
              editorState.workspaceLayout == WorkspaceLayout.classic
                  ? Icons.phone_iphone_rounded
                  : editorState.workspaceLayout == WorkspaceLayout.desktop
                      ? Icons.desktop_mac_rounded
                      : editorState.workspaceLayout == WorkspaceLayout.colorDesktop
                          ? Icons.palette_rounded
                          : editorState.workspaceLayout == WorkspaceLayout.audioDesktop
                              ? Icons.tune_rounded
                              : editorState.workspaceLayout == WorkspaceLayout.vfxDesktop
                                  ? Icons.animation_rounded
                                  : Icons.grid_view_rounded,
              color: AppTheme.accentPrimary,
              size: 20,
            ),
            tooltip: 'Switch Workspace',
            onSelected: editorNotifier.setWorkspaceLayout,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: WorkspaceLayout.classic,
                child: Text('Mobile / Classic Workspace'),
              ),
              PopupMenuItem(
                value: WorkspaceLayout.desktop,
                child: Text('Desktop Edit Workspace'),
              ),
              PopupMenuItem(
                value: WorkspaceLayout.colorDesktop,
                child: Text('Desktop Color Workspace'),
              ),
              PopupMenuItem(
                value: WorkspaceLayout.audioDesktop,
                child: Text('Desktop Audio Workspace'),
              ),
              PopupMenuItem(
                value: WorkspaceLayout.vfxDesktop,
                child: Text('Desktop VFX Workspace'),
              ),
              PopupMenuItem(
                value: WorkspaceLayout.multicamDesktop,
                child: Text('Media & Multicam Workspace'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.storage_rounded, size: 20),
            onPressed: () {
              final project = projectAsync.value;
              if (project != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectStorageScreen(projectId: project.id),
                  ),
                );
              }
            },
            tooltip: 'Project Storage',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_motion, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PackBrowserScreen(),
                ),
              );
            },
            tooltip: 'Creative Packs',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: authState.isAuthenticated 
                ? CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.accentPrimary,
                    child: Text(
                      authState.user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                : const Icon(Icons.account_circle_outlined, size: 20),
            onPressed: () {
              if (authState.isAuthenticated) {
                ProfileScreen.show(context);
              } else {
                AuthScreen.show(context);
              }
            },
            tooltip: authState.isAuthenticated ? 'Profile' : 'Log In',
          ),
          const SizedBox(width: 8),
          if (projectAsync.value != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SafeExportButton(
                projectId: projectAsync.value!.id,
                onTriggerExport: () => _showExportDialog(context),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;
          
          if (isLargeScreen) {
            if (editorState.workspaceLayout == WorkspaceLayout.desktop) {
              return DesktopEditorLayout(projectId: projectId);
            } else if (editorState.workspaceLayout == WorkspaceLayout.colorDesktop) {
              return DesktopColorLayout(projectId: projectId);
            } else if (editorState.workspaceLayout == WorkspaceLayout.audioDesktop) {
              return DesktopAudioLayout(projectId: projectId);
            } else if (editorState.workspaceLayout == WorkspaceLayout.vfxDesktop) {
              return DesktopVfxLayout(projectId: projectId);
            } else if (editorState.workspaceLayout == WorkspaceLayout.multicamDesktop) {
              return DesktopMulticamLayout(projectId: projectId);
            }
          }

          return Column(
            children: [
              // 1. Preview Area (with Scopes Row if landscape/tablet)
              Expanded(
                flex: 5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = constraints.maxWidth > constraints.maxHeight;
                    final previewWidget = DualPreviewArea(
                      projectId: projectId,
                      onClipInserted: (_) {
                        final preview = ref.read(realNativePreviewProvider(projectId));
                        final controller = ref.read(realNativePreviewProvider(projectId).notifier);
                        if (preview.hasSurface) {
                          controller.requestFrame(ref.read(editorStateProvider).currentTimeMicros);
                        } else {
                          controller.prepare();
                        }
                      },
                    );

                    if (isLandscape && scopesSettings.enabled) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: previewWidget),
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 360,
                            child: ProfessionalScopesPanel(),
                          ),
                        ],
                      );
                    }

                    return previewWidget;
                  },
                ),
              ),
              if (MediaQuery.of(context).size.width <= MediaQuery.of(context).size.height && scopesSettings.enabled) ...[
                const SizedBox(
                  height: 220,
                  child: ProfessionalScopesPanel(),
                ),
                const SizedBox(height: 8),
              ],

              // 2. Active Editing Panel (MediaPool, Transitions, inspector, etc.)
              if (editorState.activeTool.isNotEmpty) ...[
                ResizablePanelDivider(
                  currentHeight: _toolPanelHeight,
                  minHeight: 100.0,
                  maxHeight: 350.0,
                  onHeightChanged: (newHeight) {
                    setState(() {
                      _toolPanelHeight = newHeight;
                    });
                  },
                  onDoubleTap: () {
                    setState(() {
                      _toolPanelHeight = 190.0;
                    });
                  },
                ),
                SizedBox(
                  height: _toolPanelHeight,
                  child: const ToolPanel(),
                ),
              ],

              // 3. Import-media hint banner (hidden once dismissed or media added)
              EditorHintBanner(
                hint: EditorHintCatalog.hints.firstWhere(
                  (h) => h.id == EditorHintId.importMedia,
                ),
                onAction: () => editorNotifier.setTool('media'),
              ),

              // Pro Mobile: Virtual Jog Wheel
              VirtualJogWheel(projectId: projectId),

              // 4. Timeline Area with unified tracks and ruler scrolling
              ResizablePanelDivider(
                currentHeight: _timelineHeight,
                minHeight: 120.0,
                maxHeight: 400.0,
                onHeightChanged: (newHeight) {
                  setState(() {
                    _timelineHeight = newHeight;
                  });
                },
                onDoubleTap: () {
                  setState(() {
                    _timelineHeight = 220.0;
                  });
                },
              ),
              SizedBox(
                height: _timelineHeight,
                child: ref.watch(realProjectTimelineProvider(projectId)).when(
                      data: (timeline) {
                        if (timeline.clips.isEmpty) {
                          return const TimelineEmptyState();
                        }
                        return RealProjectMultitrackTimeline(
                          projectId: projectId,
                          onSeek: (micros) async {
                            ref
                                .read(dualPreviewLayoutControllerProvider.notifier)
                                .showProgram();
                            ref
                                .read(multitrackTimelineControllerProvider.notifier)
                                .setPlayheadMicros(micros);

                            await ref.read(nativeCommandServiceProvider).seek(
                                  projectId: projectId,
                                  timelineMicros: micros,
                                );
                          },
                          onClipSelected: (clipId) async {
                            ref
                                .read(dualPreviewLayoutControllerProvider.notifier)
                                .showProgram();
                            ref
                                .read(editorStateProvider.notifier)
                                .selectClip(clipId, null);
                            final clip = await ref
                                .read(timelineRepositoryProvider)
                                .getClip(clipId);
                            if (clip != null) {
                              final tool =
                                  clip.clipType == 'text' ? 'text' : 'edit';
                              ref.read(editorStateProvider.notifier).setTool(tool);
                            }
                          },
                          onTrackSelected: (trackId) {
                            ref
                                .read(dualPreviewLayoutControllerProvider.notifier)
                                .showProgram();
                            ref
                                .read(editorStateProvider.notifier)
                                .selectClip(null, trackId);
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accentPrimary),
                      ),
                      error: (err, _) => Center(
                        child: Text('Timeline error: $err',
                            style: const TextStyle(color: AppTheme.error)),
                      ),
                    ),
              ),

              // 5. Mobile bottom context-aware toolbar
              MobileEditingToolbar(projectId: projectId),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final export = ref.watch(exportStateProvider);
            final exportNotifier = ref.read(exportStateProvider.notifier);
            final selectedProjectId = ref.watch(selectedProjectIdProvider);

            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text('Export Project'),
              content: export.isExporting
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: export.progress / 100.0,
                          color: AppTheme.accentPrimary,
                        ),
                        const SizedBox(height: 16),
                        Text('Stage: ${export.stage}'),
                        const SizedBox(height: 8),
                        Text('Progress: ${export.progress}%'),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedProjectId != null) ...[
// _WatermarkToggle(projectId: selectedProjectId),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                        ],
                        ...AppConstants.exportPresets.entries.map((entry) {
                          return ListTile(
                            title: Text(entry.value['label'] as String),
                            subtitle:
                                Text(entry.value['description'] as String),
                            trailing: Text('${entry.value["resolution"]}p'),
                            onTap: () async {
                              final projectId =
                                  ref.read(selectedProjectIdProvider);
                              if (projectId == null) return;

                              final project = await ref
                                  .read(projectRepositoryProvider)
                                  .getProject(projectId);
                              final resolutionHeight =
                                  entry.value['resolution'] as int? ?? 1080;

                              // Estimate width
                              int targetWidth = resolutionHeight * 16 ~/ 9;
                              if (project != null) {
                                if (project.aspectRatio == '9:16') {
                                  targetWidth = resolutionHeight * 9 ~/ 16;
                                } else if (project.aspectRatio == '1:1') {
                                  targetWidth = resolutionHeight;
                                } else if (project.aspectRatio == '4:5') {
                                  targetWidth = resolutionHeight * 4 ~/ 5;
                                } else if (project.aspectRatio == '21:9') {
                                  targetWidth = resolutionHeight * 21 ~/ 9;
                                }
                              }
                              targetWidth = (targetWidth ~/ 2) * 2;

                              final monetization =
                                  ref.read(monetizationProvider);
                              final rules = ref.read(proPlanRulesProvider);
                              final removeWatermarkRequested =
                                  project != null && !project.hasWatermark;

                              final decision = rules.checkExport(
                                entitlement: monetization.entitlement,
                                width: targetWidth,
                                height: resolutionHeight,
                                removeWatermarkRequested:
                                    removeWatermarkRequested,
                              );

                              if (!decision.allowed) {
                                Navigator.pop(context); // close export dialog
                                if (context.mounted) {
                                  final feature = PremiumFeatureCatalog.byId(
                                      decision.requiredFeatureId ?? '');
                                  ProPaywallScreen.show(
                                    context,
                                    requiredFeatureTitle: feature?.title,
                                    requiredFeatureDescription:
                                        feature?.description,
                                  );
                                }
                                return;
                              }

                              exportNotifier.startExport(
                                projectId: projectId,
                                settings: {
                                  'preset': entry.key,
                                  'resolution': entry.value['resolution'],
                                  'bitrate': entry.value['bitrate'],
                                },
                              );
                            },
                          );
                        }).toList(),
                      ],
                    ),
              actions: [
                if (!export.isExporting)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  )
                else
                  TextButton(
                    onPressed: () {
                      exportNotifier.cancelExport();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel Export'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}