// ============================================================================
// performance_hud.dart
//
// An overlay HUD that shows real-time performance metrics: current preview
// quality, device tier, memory-pressure flags, and throttle / debounce
// durations.
//
// Usage:
//   Stack(
//     children: [
//       // ... your editor UI ...
//       const PerformanceHud(),
//     ],
//   )
//
// Visibility is controlled by [showPerformanceHudProvider].
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/performance/performance_mode.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

// ─── Visibility toggle ───────────────────────────────────────────────────────

final showPerformanceHudProvider = StateProvider<bool>((ref) => false);

// ─── Widget ──────────────────────────────────────────────────────────────────

class PerformanceHud extends ConsumerWidget {
  const PerformanceHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(showPerformanceHudProvider);
    if (!visible) return const SizedBox.shrink();

    final mode = ref.watch(performanceModeControllerProvider);

    return Positioned(
      top: 8,
      right: 8,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _borderColorFor(mode),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HudRow(label: '⚙ Tier', value: mode.deviceTier),
                _HudRow(label: '🎞 Quality', value: mode.previewQuality),
                _HudRow(
                  label: '🧠 Graph debounce',
                  value: '${mode.nativeGraphDebounce.inMilliseconds} ms',
                ),
                _HudRow(
                  label: '⏱ Autosave debounce',
                  value: '${mode.autosaveDebounce.inSeconds} s',
                ),
                _HudRow(
                  label: '🔄 Playhead throttle',
                  value: '${mode.playheadThrottle.inMilliseconds} ms',
                ),
                const Divider(color: Colors.white24, height: 12),
                _HudFlag(
                  label: '🔴 Low memory',
                  active: mode.lowMemoryMode,
                ),
                _HudFlag(
                  label: '🌡 Thermal warning',
                  active: mode.thermalWarning,
                ),
                _HudFlag(
                  label: '🔋 Battery saver',
                  active: mode.batterySaver,
                ),
                _HudFlag(
                  label: '⏸ Pause bg on scrub',
                  active: mode.pauseBackgroundWorkDuringScrub,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _borderColorFor(PerformanceModeState mode) {
    if (mode.thermalWarning || mode.lowMemoryMode) return Colors.red.shade400;
    if (mode.batterySaver) return Colors.orange.shade400;
    if (mode.deviceTier == DevicePerformanceTier.low) {
      return Colors.yellow.shade600;
    }
    return Colors.green.shade600;
  }
}

// ─── Internal helpers ────────────────────────────────────────────────────────

class _HudRow extends StatelessWidget {
  final String label;
  final String value;

  const _HudRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _HudFlag extends StatelessWidget {
  final String label;
  final bool active;

  const _HudFlag({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontSize: 10.5,
              fontFamily: 'monospace',
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.greenAccent : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}
