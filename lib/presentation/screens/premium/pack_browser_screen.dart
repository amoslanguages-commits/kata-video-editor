import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/domain/premium/creative_pack.dart';
import 'package:nle_editor/domain/premium/user_creative_preset.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';
import 'package:nle_editor/presentation/providers/premium_providers.dart';
import 'package:nle_editor/presentation/widgets/premium/pack_item_card.dart';
import 'package:nle_editor/presentation/widgets/premium/pro_upgrade_sheet.dart';

class PackBrowserScreen extends ConsumerStatefulWidget {
  const PackBrowserScreen({super.key});

  @override
  ConsumerState<PackBrowserScreen> createState() => _PackBrowserScreenState();
}

class _PackBrowserScreenState extends ConsumerState<PackBrowserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<(String, String)> _tabs = [
    (CreativePackType.effects, 'Effects'),
    (CreativePackType.transitions, 'Transitions'),
    (CreativePackType.text, 'Text/Titles'),
    (CreativePackType.color, 'Color/LUTs'),
    (CreativePackType.template, 'Templates'),
    (CreativePackType.export, 'Exports'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(entitlementProvider);
    final selectedClip = ref.watch(selectedClipProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.editorBackground,
      appBar: AppBar(
        title: const Text(
          'Creative Packs Browser',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!entitlement.isPro)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => ProUpgradeSheet.show(context),
                icon: const Icon(Icons.workspace_premium_rounded, color: Colors.orangeAccent),
                label: const Text(
                  'UPGRADE',
                  style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.accentPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.accentPrimary,
          tabs: _tabs.map((tab) => Tab(text: tab.$2)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Save Preset Banner
          if (selectedClip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.surfaceMedium,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Selected Clip: ${selectedClip.clipType} (${selectedClip.id})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveCustomPreset(context, selectedClip),
                    icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                    label: const Text('Save as Preset', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final packType = tab.$1;
                final packsAsync = ref.watch(creativePacksByTypeProvider(packType));
                final userPresetsAsync = ref.watch(userCreativePresetsProvider(_mapToItemType(packType)));

                return packsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (packs) {
                    if (packs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No packs available.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Built-in packs
                        ...packs.map((pack) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pack.title,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      pack.subtitle,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.4,
                                ),
                                itemCount: pack.items.length,
                                itemBuilder: (context, index) {
                                  final item = pack.items[index];
                                  final isLocked = item.isLocked(entitlement.hasFeature);

                                  return PackItemCard(
                                    item: item,
                                    locked: isLocked,
                                    onLockedTap: () => ProUpgradeSheet.show(
                                      context,
                                      featureTitle: item.title,
                                    ),
                                    onTap: () => _applyPreset(context, item),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }),

                        // User Presets section
                        userPresetsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (presets) {
                            if (presets.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 32),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12.0),
                                  child: Text(
                                    'My Custom Presets',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.4,
                                  ),
                                  itemCount: presets.length,
                                  itemBuilder: (context, index) {
                                    final preset = presets[index];
                                    final item = CreativePackItem(
                                      id: preset.id,
                                      packId: 'user_presets',
                                      type: preset.type,
                                      title: preset.name,
                                      description: 'Saved custom preset',
                                      proOnly: false,
                                      payload: preset.payload,
                                    );

                                    return Stack(
                                      children: [
                                        PackItemCard(
                                          item: item,
                                          locked: false,
                                          onTap: () => _applyPreset(context, item),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.black.withOpacity(0.6),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                              onPressed: () => _deletePreset(preset.id),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _mapToItemType(String packType) {
    switch (packType) {
      case CreativePackType.effects:
        return CreativePackItemType.effectPreset;
      case CreativePackType.transitions:
        return CreativePackItemType.transitionPreset;
      case CreativePackType.text:
        return CreativePackItemType.textPreset;
      case CreativePackType.color:
        return CreativePackItemType.colorPreset;
      case CreativePackType.export:
        return CreativePackItemType.exportPreset;
      case CreativePackType.template:
        return CreativePackItemType.socialTemplate;
      default:
        return '';
    }
  }

  Future<void> _applyPreset(BuildContext context, CreativePackItem item) async {
    final applyService = ref.read(creativePresetApplyServiceProvider);
    final entitlement = ref.read(entitlementProvider);

    if (item.type == CreativePackItemType.effectPreset ||
        item.type == CreativePackItemType.colorPreset ||
        item.type == CreativePackItemType.textPreset) {
      final selectedClip = ref.read(selectedClipProvider).value;
      if (selectedClip == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a clip on the timeline first.')),
        );
        return;
      }

      final result = await applyService.applyToClip(
        item: item,
        clip: selectedClip,
        entitlement: entitlement,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } else if (item.type == CreativePackItemType.transitionPreset) {
      final projectId = ref.read(selectedProjectIdProvider);
      if (projectId == null) return;
      final transitions = await ref.read(creativePresetApplyServiceProvider).transitionRepository.getProjectTransitions(projectId);
      
      if (transitions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add a transition in the timeline first.')),
          );
        }
        return;
      }

      final selectedTransitionId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Apply Transition Preset'),
          backgroundColor: AppTheme.surface,
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: transitions.length,
              itemBuilder: (context, index) {
                final t = transitions[index];
                return ListTile(
                  title: Text('Transition ${index + 1} (${t.transitionType})'),
                  subtitle: Text('Duration: ${(t.durationMicros / 1000000).toStringAsFixed(1)}s'),
                  onTap: () => Navigator.pop(context, t.id),
                );
              },
            ),
          ),
        ),
      );

      if (selectedTransitionId != null && mounted) {
        final result = await applyService.applyTransition(
          item: item,
          transitionId: selectedTransitionId,
          entitlement: entitlement,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } else if (item.type == CreativePackItemType.exportPreset) {
      final projectId = ref.read(selectedProjectIdProvider);
      if (projectId != null) {
        await ref.read(projectRepositoryProvider).updateProjectFields(
          projectId,
          ProjectsCompanion(
            exportPreset: Value(item.id),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Applied export preset: ${item.title}')),
          );
        }
      }
    }
  }

  Future<void> _saveCustomPreset(BuildContext context, Clip selectedClip) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Save Current Style as Preset'),
          backgroundColor: AppTheme.surface,
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Preset Name',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentPrimary)),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, textController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      final Map<String, dynamic> payload;
      final String type;
      if (selectedClip.clipType == 'text') {
        type = CreativePackItemType.textPreset;
        payload = {'textStyle': selectedClip.textStyle};
      } else {
        type = CreativePackItemType.effectPreset;
        payload = {
          'scale': selectedClip.scale,
          'rotation': selectedClip.rotation,
          'opacity': selectedClip.opacity,
          'brightness': selectedClip.exposure,
          'contrast': selectedClip.contrast,
          'saturation': selectedClip.saturation,
          'temperature': selectedClip.temperature,
          'tint': selectedClip.tint,
        };
      }

      final preset = UserCreativePreset.create(
        name: name,
        type: type,
        sourceItemId: selectedClip.id,
        payload: payload,
      );

      await ref.read(creativePackRepositoryProvider).saveUserPreset(preset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom preset saved successfully.')),
        );
      }
    }
  }

  Future<void> _deletePreset(String id) async {
    await ref.read(creativePackRepositoryProvider).deleteUserPreset(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preset deleted.')),
      );
    }
  }
}
