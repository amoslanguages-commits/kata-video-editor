import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/widgets/export/export_advanced_settings_card.dart';
import 'package:nle_editor/presentation/widgets/export/export_pipeline_panel.dart';
import 'package:nle_editor/presentation/widgets/export/export_preset_builder_panel.dart';
import 'package:nle_editor/presentation/widgets/export/export_queue_cleanup_panel.dart' as history;

class ExportHubPanel extends StatelessWidget {
  final String projectId;

  const ExportHubPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: AppTheme.surfaceDark,
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.history_rounded), text: 'Queue'),
                Tab(icon: Icon(Icons.tune_rounded), text: 'Builder'),
                Tab(icon: Icon(Icons.settings_suggest_rounded), text: 'Advanced'),
                Tab(icon: Icon(Icons.more_horiz_rounded), text: 'More'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ExportPipelinePanel(projectId: projectId),
                ExportPresetBuilderPanel(projectId: projectId),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ExportAdvancedSettingsCard(projectId: projectId),
                  ],
                ),
                history.ExportQueueCleanupPanel(projectId: projectId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
