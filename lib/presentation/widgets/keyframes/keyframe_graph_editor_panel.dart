import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';
import 'package:nle_editor/presentation/providers/keyframe_providers.dart';
import 'package:nle_editor/presentation/widgets/keyframes/keyframe_graph_view.dart';
import 'package:nle_editor/presentation/widgets/keyframes/keyframe_property_lane.dart';

class KeyframeGraphEditorPanel extends ConsumerWidget {
  final String clipId;
  final String clipType;
  final int clipDurationMicros;
  final int localPlayheadMicros;

  const KeyframeGraphEditorPanel({
    super.key,
    required this.clipId,
    required this.clipType,
    required this.clipDurationMicros,
    required this.localPlayheadMicros,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = KeyframeControllerArgs(
      clipId: clipId,
      clipType: clipType,
      clipDurationMicros: clipDurationMicros,
    );

    final state = ref.watch(keyframeControllerProvider(args));
    final controller = ref.read(keyframeControllerProvider(args).notifier);

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final track = state.track;

    if (track == null) {
      return const Center(
        child: Text(
          'No keyframe track.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final selectedProperty = state.selectedProperty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(PremiumSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.timeline_rounded, color: AppTheme.accentPrimary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Keyframe Graph Editor',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: selectedProperty == null
                    ? null
                    : () {
                        controller.addKeyframeAt(
                          timeOffsetMicros: localPlayheadMicros,
                          value: selectedProperty.defaultValue,
                        );
                      },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Keyframe'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 260,
                child: _PropertyList(
                  properties: track.properties,
                  selectedPropertyId: state.selectedPropertyId,
                  onSelect: controller.selectProperty,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    if (selectedProperty != null)
                      KeyframePropertyLane(
                        property: selectedProperty,
                        clipDurationMicros: track.clipDurationMicros,
                        playheadMicros: localPlayheadMicros,
                        selectedKeyframeId: state.selectedKeyframeId,
                        onSelectKeyframe: controller.selectKeyframe,
                      ),
                    const SizedBox(height: 12),
                    if (selectedProperty != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
                          child: KeyframeGraphView(
                            property: selectedProperty,
                            clipDurationMicros: track.clipDurationMicros,
                            playheadMicros: localPlayheadMicros,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PropertyList extends StatelessWidget {
  final List<NleAnimatableProperty> properties;
  final String? selectedPropertyId;
  final ValueChanged<String> onSelect;

  const _PropertyList({
    required this.properties,
    required this.selectedPropertyId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final prop = properties[index];
        final isSelected = prop.id == selectedPropertyId;

        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: AppTheme.accentPrimary.withValues(alpha: 0.1),
          title: Text(
            prop.label,
            style: TextStyle(
              color: isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          onTap: () => onSelect(prop.id),
        );
      },
    );
  }
}
