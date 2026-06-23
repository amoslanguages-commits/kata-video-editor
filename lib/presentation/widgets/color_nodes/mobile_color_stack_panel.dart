import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/color_nodes/color_node_models.dart';
import 'package:nle_editor/presentation/providers/mobile_color_stack_controller_provider.dart';

class MobileColorStackPanel extends ConsumerWidget {
  final String ownerId;
  final NleColorNodeScope scope;

  const MobileColorStackPanel({
    super.key,
    required this.ownerId,
    required this.scope,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = MobileColorStackOwner(
      ownerId: ownerId,
      scope: scope,
    );

    final state = ref.watch(mobileColorStackControllerProvider(owner));
    final controller =
        ref.read(mobileColorStackControllerProvider(owner).notifier);

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final graph = state.graph;

    if (graph == null) {
      return const Center(
        child: Text(
          'No color stack loaded.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final nodes = graph.orderedNodes;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(PremiumSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _title(scope),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              PopupMenuButton<NleColorNodeType>(
                tooltip: 'Add node',
                onSelected: controller.addNode,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: NleColorNodeType.primary,
                    child: Text('Primary'),
                  ),
                  PopupMenuItem(
                    value: NleColorNodeType.curves,
                    child: Text('Curves'),
                  ),
                  PopupMenuItem(
                    value: NleColorNodeType.qualifier,
                    child: Text('Qualifier'),
                  ),
                  PopupMenuItem(
                    value: NleColorNodeType.lut,
                    child: Text('LUT'),
                  ),
                  PopupMenuItem(
                    value: NleColorNodeType.filmLook,
                    child: Text('Film Look'),
                  ),
                  PopupMenuItem(
                    value: NleColorNodeType.parallel,
                    child: Text('Parallel Foundation'),
                  ),
                ],
                child: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
            itemCount: nodes.length,
            onReorder: (oldIndex, newIndex) {
              final fixedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
              final node = nodes[oldIndex];

              controller.reorder(
                nodeId: node.id,
                newIndex: fixedIndex,
              );
            },
            itemBuilder: (context, index) {
              final node = nodes[index];
              final selected = node.id == state.selectedNodeId;

              return _ColorStackNodeTile(
                key: ValueKey(node.id),
                node: node,
                selected: selected,
                onSelect: () => controller.selectNode(node.id),
                onToggle: () => controller.toggleNode(node.id),
                onBypass: () => controller.bypassNode(node.id),
                onRemove: () => controller.removeNode(node.id),
                onPreviewMode: (mode) {
                  controller.setPreviewMode(
                    nodeId: node.id,
                    mode: mode,
                  );
                },
              );
            },
          ),
        ),
        if (state.selectedNode != null)
          _SelectedNodeEditor(
            node: state.selectedNode!,
            onOpacity: (value) {
              controller.setNodeOpacity(
                nodeId: state.selectedNode!.id,
                opacity: value,
              );
            },
            onRename: (name) {
              controller.renameNode(
                nodeId: state.selectedNode!.id,
                name: name,
              );
            },
          ),
      ],
    );
  }

  String _title(NleColorNodeScope scope) {
    switch (scope) {
      case NleColorNodeScope.clip:
        return 'Clip Color Stack';
      case NleColorNodeScope.adjustmentLayer:
        return 'Adjustment Color Stack';
      case NleColorNodeScope.timeline:
        return 'Timeline Color Stack';
      case NleColorNodeScope.project:
        return 'Project Output Stack';
    }
  }
}

class _ColorStackNodeTile extends StatelessWidget {
  final NleColorNode node;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onToggle;
  final VoidCallback onBypass;
  final VoidCallback onRemove;
  final ValueChanged<NleColorNodePreviewMode> onPreviewMode;

  const _ColorStackNodeTile({
    super.key,
    required this.node,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
    required this.onBypass,
    required this.onRemove,
    required this.onPreviewMode,
  });

  @override
  Widget build(BuildContext context) {
    final active = node.enabled && !node.bypassed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? AppTheme.accentPrimary.withOpacity(0.13) : const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(
          color: selected ? AppTheme.accentPrimary.withOpacity(0.45) : AppTheme.borderSubtle,
        ),
      ),
      child: ListTile(
        onTap: onSelect,
        leading: _NodeIcon(type: node.type, active: active),
        title: Text(
          node.name,
          style: TextStyle(
            color: active ? AppTheme.textPrimary : AppTheme.textMuted,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          _subtitle(node),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: node.enabled ? 'Disable' : 'Enable',
              onPressed: node.locked ? null : onToggle,
              icon: Icon(
                node.enabled
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 19,
              ),
            ),
            IconButton(
              tooltip: node.bypassed ? 'Unbypass' : 'Bypass',
              onPressed: node.locked ? null : onBypass,
              icon: Icon(
                node.bypassed
                    ? Icons.radio_button_unchecked_rounded
                    : Icons.power_settings_new_rounded,
                size: 19,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'normal':
                    onPreviewMode(NleColorNodePreviewMode.normal);
                    break;
                  case 'solo':
                    onPreviewMode(NleColorNodePreviewMode.soloNode);
                    break;
                  case 'before':
                    onPreviewMode(NleColorNodePreviewMode.bypassBefore);
                    break;
                  case 'matte':
                    onPreviewMode(NleColorNodePreviewMode.matte);
                    break;
                  case 'remove':
                    onRemove();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'normal',
                  child: Text('Preview normal'),
                ),
                const PopupMenuItem(
                  value: 'solo',
                  child: Text('Solo this node'),
                ),
                const PopupMenuItem(
                  value: 'before',
                  child: Text('Before this node'),
                ),
                const PopupMenuItem(
                  value: 'matte',
                  child: Text('Show matte'),
                ),
                if (!node.locked)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove node'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _subtitle(NleColorNode node) {
    if (node.bypassed) return 'Bypassed';
    if (!node.enabled) return 'Disabled';

    switch (node.type) {
      case NleColorNodeType.input:
        return 'Source transform';
      case NleColorNodeType.primary:
        return 'Lift, gamma, gain, offset';
      case NleColorNodeType.curves:
        return 'RGB + HSL curves';
      case NleColorNodeType.qualifier:
        return 'HSL secondary correction';
      case NleColorNodeType.lut:
        return 'GPU 3D LUT';
      case NleColorNodeType.filmLook:
        return 'Film science';
      case NleColorNodeType.output:
        return 'Display/output transform';
      case NleColorNodeType.parallel:
        return 'Parallel foundation';
      case NleColorNodeType.layerMixer:
        return 'Layer mixer foundation';
      case NleColorNodeType.adjustment:
        return 'Adjustment layer';
      case NleColorNodeType.serial:
        return 'Serial grade node';
    }
  }
}

class _NodeIcon extends StatelessWidget {
  final NleColorNodeType type;
  final bool active;

  const _NodeIcon({
    required this.type,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;

    switch (type) {
      case NleColorNodeType.input:
        iconData = Icons.login_rounded;
        color = Colors.blue;
        break;
      case NleColorNodeType.primary:
        iconData = Icons.tune_rounded;
        color = Colors.amber;
        break;
      case NleColorNodeType.curves:
        iconData = Icons.bubble_chart_rounded;
        color = Colors.purple;
        break;
      case NleColorNodeType.qualifier:
        iconData = Icons.colorize_rounded;
        color = Colors.teal;
        break;
      case NleColorNodeType.lut:
        iconData = Icons.grid_on_rounded;
        color = Colors.deepOrange;
        break;
      case NleColorNodeType.filmLook:
        iconData = Icons.movie_filter_rounded;
        color = Colors.pink;
        break;
      case NleColorNodeType.output:
        iconData = Icons.logout_rounded;
        color = Colors.green;
        break;
      case NleColorNodeType.serial:
        iconData = Icons.link_rounded;
        color = Colors.lightBlue;
        break;
      case NleColorNodeType.parallel:
        iconData = Icons.call_split_rounded;
        color = Colors.lightGreen;
        break;
      case NleColorNodeType.layerMixer:
        iconData = Icons.layers_rounded;
        color = Colors.indigo;
        break;
      case NleColorNodeType.adjustment:
        iconData = Icons.auto_awesome_rounded;
        color = Colors.cyan;
        break;
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: active ? color.withOpacity(0.18) : Colors.grey.withOpacity(0.1),
      child: Icon(
        iconData,
        color: active ? color : Colors.grey,
        size: 18,
      ),
    );
  }
}

class _SelectedNodeEditor extends StatefulWidget {
  final NleColorNode node;
  final ValueChanged<double> onOpacity;
  final ValueChanged<String> onRename;

  const _SelectedNodeEditor({
    required this.node,
    required this.onOpacity,
    required this.onRename,
  });

  @override
  State<_SelectedNodeEditor> createState() => _SelectedNodeEditorState();
}

class _SelectedNodeEditorState extends State<_SelectedNodeEditor> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.node.name);
  }

  @override
  void didUpdateWidget(covariant _SelectedNodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _nameController.text = widget.node.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderSubtle,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Editing: ${widget.node.name}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!widget.node.locked) ...[
                const SizedBox(width: PremiumSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Rename Node'),
                        content: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Node Name',
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              widget.onRename(_nameController.text);
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: PremiumSpacing.sm),
          Row(
            children: [
              const Text(
                'Node Opacity',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Slider(
                  value: widget.node.opacity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: widget.node.locked ? null : widget.onOpacity,
                ),
              ),
              Text(
                '${(widget.node.opacity * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
