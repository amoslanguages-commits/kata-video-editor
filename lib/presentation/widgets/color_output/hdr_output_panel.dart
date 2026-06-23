// lib/presentation/widgets/color_output/hdr_output_panel.dart
//
// 30J-PRO: UI inspector panel containing HDR Output transform controls,
// device display/encoder capability card, tone mapping selection,
// and export safety validation feedback.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/color_output/hdr_output_models.dart';
import 'package:nle_editor/presentation/providers/hdr_output_controller_provider.dart';

class HdrOutputPanel extends ConsumerWidget {
  final String projectId;

  const HdrOutputPanel({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hdrOutputControllerProvider(projectId));
    final controller = ref.read(hdrOutputControllerProvider(projectId).notifier);

    if (state.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final validation = state.validation;
    final capability = state.capability;
    final settings = state.settings;

    return ListView(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      children: [
        // ── Validation Status Card ──────────────────────────────────
        _ValidationStatusCard(validation: validation),
        const SizedBox(height: 16),

        // ── Output mode configuration ────────────────────────────────
        _SectionHeader(title: 'OUTPUT COLOR PRESET'),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<NleOutputColorMode>(
                value: settings.colorMode,
                dropdownColor: const Color(0xFF0D1320),
                decoration: const InputDecoration(
                  labelText: 'Color Space & Output Mode',
                  labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                items: NleOutputColorMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(_colorModeName(mode)),
                  );
                }).toList(),
                onChanged: (mode) {
                  if (mode != null) {
                    controller.updateColorMode(mode);
                  }
                },
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Transfer Function', value: settings.transferFunction.name.toUpperCase()),
              _DetailRow(label: 'Default Bit Depth', value: settings.bitDepth == NleOutputBitDepth.tenBit ? '10-bit' : '8-bit'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Tone Mapping Section ─────────────────────────────────────
        _SectionHeader(title: 'TONE MAPPING & PEAK LUMINANCE'),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<NleToneMapOperator>(
                value: settings.toneMapOperator,
                dropdownColor: const Color(0xFF0D1320),
                decoration: const InputDecoration(
                  labelText: 'Tone Mapping Operator',
                  labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                items: NleToneMapOperator.values.map((op) {
                  return DropdownMenuItem(
                    value: op,
                    child: Text(_toneMapName(op)),
                  );
                }).toList(),
                onChanged: (op) {
                  if (op != null) {
                    controller.updateSettings(settings.copyWith(toneMapOperator: op));
                  }
                },
              ),
              if (settings.colorMode == NleOutputColorMode.rec2020PqHdr ||
                  settings.colorMode == NleOutputColorMode.rec2020HlgHdr) ...[
                const SizedBox(height: 12),
                _SliderRow(
                  label: 'Target Peak Nits',
                  value: settings.targetPeakNits,
                  min: 100.0,
                  max: 4000.0,
                  onChanged: (val) {
                    controller.updateSettings(settings.copyWith(targetPeakNits: val));
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Pipeline safety formats ──────────────────────────────────
        _SectionHeader(title: 'PIPELINE OPTIONS'),
        _SectionCard(
          child: Column(
            children: [
              DropdownButtonFormField<NleColorRangeMode>(
                value: settings.colorRange,
                dropdownColor: const Color(0xFF0D1320),
                decoration: const InputDecoration(
                  labelText: 'Color Range Mode',
                  labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                items: NleColorRangeMode.values.map((range) {
                  return DropdownMenuItem(
                    value: range,
                    child: Text(range.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (range) {
                  if (range != null) {
                    controller.updateSettings(settings.copyWith(colorRange: range));
                  }
                },
              ),
              DropdownButtonFormField<NleWideColorPreviewMode>(
                value: settings.previewMode,
                dropdownColor: const Color(0xFF0D1320),
                decoration: const InputDecoration(
                  labelText: 'Wide Gamut Preview Rule',
                  labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                items: NleWideColorPreviewMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(_previewModeName(mode)),
                  );
                }).toList(),
                onChanged: (mode) {
                  if (mode != null) {
                    controller.updateSettings(settings.copyWith(previewMode: mode));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Hardware capability verification ─────────────────────────
        _SectionHeader(title: 'DEVICE COLOR CAPABILITY'),
        _CapabilityCard(capability: capability),
      ],
    );
  }

  String _colorModeName(NleOutputColorMode mode) {
    switch (mode) {
      case NleOutputColorMode.rec709Sdr:
        return 'Rec. 709 (SDR Broadcast)';
      case NleOutputColorMode.srgbSdr:
        return 'sRGB (SDR Web)';
      case NleOutputColorMode.displayP3Sdr:
        return 'Display P3 (Wide Color SDR)';
      case NleOutputColorMode.rec2020Sdr:
        return 'Rec. 2020 SDR (UHD SDR)';
      case NleOutputColorMode.rec2020HlgHdr:
        return 'Rec. 2020 HLG (Hybrid Log-Gamma HDR)';
      case NleOutputColorMode.rec2020PqHdr:
        return 'Rec. 2020 PQ (HDR10/Static Metadata)';
    }
  }

  String _toneMapName(NleToneMapOperator op) {
    switch (op) {
      case NleToneMapOperator.none:
        return 'None (Bypass/Clip)';
      case NleToneMapOperator.reinhard:
        return 'Reinhard Simple';
      case NleToneMapOperator.acesApprox:
        return 'ACES Approximation (Cinematic)';
      case NleToneMapOperator.hable:
        return 'Hable (Filmic)';
      case NleToneMapOperator.mobileFilmSafe:
        return 'Mobile Film Safe (Optimized)';
    }
  }

  String _previewModeName(NleWideColorPreviewMode mode) {
    switch (mode) {
      case NleWideColorPreviewMode.auto:
        return 'Auto (Match Device)';
      case NleWideColorPreviewMode.forceSdrPreview:
        return 'Force SDR Preview';
      case NleWideColorPreviewMode.wideColorPreview:
        return 'Force Display P3 Preview';
      case NleWideColorPreviewMode.hdrPreview:
        return 'Force HDR Preview';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1320),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text('${value.round()} Nits', style: const TextStyle(color: AppTheme.accentPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ValidationStatusCard extends StatelessWidget {
  final NleHdrExportValidation? validation;

  const _ValidationStatusCard({required this.validation});

  @override
  Widget build(BuildContext context) {
    final val = validation;
    if (val == null) {
      return Container(
        padding: const EdgeInsets.all(PremiumSpacing.md),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(PremiumRadius.lg),
          border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.sync_problem_rounded, color: Colors.blueGrey),
            SizedBox(width: 12),
            Text('No validation performed yet.', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
          ],
        ),
      );
    }

    final Color color = val.isHdrSafe
        ? (val.warnings.isNotEmpty ? Colors.amber : Colors.green)
        : Colors.red;

    final IconData icon = val.isHdrSafe
        ? (val.warnings.isNotEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded)
        : Icons.error_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(PremiumRadius.lg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  val.isHdrSafe
                      ? (val.warnings.isNotEmpty ? 'Export Settings Safe (With Warnings)' : 'Export Settings Safe')
                      : 'Export Configuration Error',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          if (val.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...val.errors.map((e) => Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 4),
                  child: Text('• $e', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                )),
          ],
          if (val.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...val.warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 4),
                  child: Text('• $w', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                )),
          ],
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  final NleHdrDeviceCapability capability;

  const _CapabilityCard({required this.capability});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          _CapabilityRow(
            label: 'Display HDR Support',
            supported: capability.displaySupportsHdr,
            details: '${capability.displayMaxNits.round()} Nits Peak',
          ),
          _CapabilityRow(
            label: 'Display Wide Gamut (DCI-P3)',
            supported: capability.displaySupportsWideColor,
          ),
          const Divider(color: AppTheme.borderSubtle, height: 16),
          _CapabilityRow(
            label: 'Encoder HLG HDR',
            supported: capability.encoderSupportsHdrHlg,
          ),
          _CapabilityRow(
            label: 'Encoder PQ HDR (HDR10)',
            supported: capability.encoderSupportsHdrPq,
          ),
          _CapabilityRow(
            label: 'Encoder Wide Color (P3)',
            supported: capability.encoderSupportsWideColorP3,
          ),
          _CapabilityRow(
            label: 'Encoder 10-bit Precision',
            supported: capability.encoderSupportsTenBit,
          ),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final String label;
  final bool supported;
  final String? details;

  const _CapabilityRow({
    required this.label,
    required this.supported,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  supported ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: supported ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              ],
            ),
          ),
          if (details != null)
            Text(details!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
