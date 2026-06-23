import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/widgets/export/export_pipeline_panel.dart';
import 'package:nle_editor/presentation/widgets/export/export_preset_builder_panel.dart';

class ExportHubPanel extends StatelessWidget {
  final String projectId;

  const ExportHubPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.surfaceDark,
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.history_rounded), text: 'Queue'),
                Tab(icon: Icon(Icons.tune_rounded), text: 'Builder'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ExportPipelinePanel(projectId: projectId),
                ExportPresetBuilderPanel(projectId: projectId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
