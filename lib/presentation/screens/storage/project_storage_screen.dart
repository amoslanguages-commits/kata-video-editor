import 'package:flutter/material.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/presentation/widgets/device/device_capability_card.dart';
import 'package:nle_editor/presentation/widgets/storage/project_storage_panel.dart';

class ProjectStorageScreen extends StatelessWidget {
  final String projectId;

  const ProjectStorageScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text('Project Storage'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: DeviceCapabilityCard(),
          ),
          Expanded(
            child: ProjectStoragePanel(projectId: projectId),
          ),
        ],
      ),
    );
  }
}
