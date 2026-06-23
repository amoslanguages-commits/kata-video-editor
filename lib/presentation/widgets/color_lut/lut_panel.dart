import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/color_lut/color_lut_models.dart';
import 'package:nle_editor/presentation/providers/lut_providers.dart';

class LutPanel extends ConsumerWidget {
  final String? selectedClipId;

  const LutPanel({
    super.key,
    required this.selectedClipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedClipId == null) {
      return const Center(
        child: Text(
          'Select a clip to apply LUTs.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final luts = ref.watch(lutAssetsProvider);
    final stack = ref.watch(clipLutStackProvider(selectedClipId!));

    return Column(
      children: [
        _CurrentLutStack(
          clipId: selectedClipId!,
          stack: stack,
        ),
        const Divider(height: 1),
        Expanded(
          child: luts.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (error, stackTrace) => Center(
              child: Text(
                'LUT error: $error',
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const _EmptyLutLibrary();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(PremiumSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final lut = items[index];

                  return _LutTile(
                    lut: lut,
                    onApply: () async {
                      await ref.read(lutRepositoryProvider).applyLutToClip(
                            clipId: selectedClipId!,
                            lutAssetId: lut.id,
                            intensity: 1.0,
                            domain: NleLutDomain.sceneLinear,
                          );

                      ref.invalidate(clipLutStackProvider(selectedClipId!));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CurrentLutStack extends ConsumerWidget {
  final String clipId;
  final AsyncValue<NleClipLutStack> stack;

  const _CurrentLutStack({
    required this.clipId,
    required this.stack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return stack.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stack) {
        if (stack.layers.isEmpty) {
          return Container(
            height: 56,
            alignment: Alignment.center,
            child: const Text(
              'No LUT applied',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        return Column(
          children: stack.layers.map((layer) {
            return ListTile(
              dense: true,
              title: Text(
                layer.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Slider(
                value: layer.intensity.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                onChanged: (value) async {
                  await ref.read(lutRepositoryProvider).updateLayerIntensity(
                        clipId: clipId,
                        layerId: layer.id,
                        intensity: value,
                      );

                  ref.invalidate(clipLutStackProvider(clipId));
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  await ref.read(lutRepositoryProvider).removeLayer(
                        clipId: clipId,
                        layerId: layer.id,
                      );

                  ref.invalidate(clipLutStackProvider(clipId));
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LutTile extends StatelessWidget {
  final NleLutAsset lut;
  final VoidCallback onApply;

  const _LutTile({
    required this.lut,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final color = lut.isValid ? AppTheme.success : AppTheme.warning;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF111827),
                Color(0xFF9333EA),
                Color(0xFF22D3EE),
              ],
            ),
          ),
          child: Center(
            child: Text(
              '${lut.size}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        title: Text(
          lut.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          lut.isValid ? 'GPU LUT • ${lut.size}³' : 'Invalid LUT',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: FilledButton(
          onPressed: lut.isValid ? onApply : null,
          child: const Text('Apply'),
        ),
      ),
    );
  }
}

class _EmptyLutLibrary extends StatelessWidget {
  const _EmptyLutLibrary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No LUTs imported yet.',
        style: TextStyle(color: AppTheme.textMuted),
      ),
    );
  }
}
