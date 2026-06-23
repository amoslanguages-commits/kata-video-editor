import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/domain/film_look/film_look_models.dart';
import 'package:nle_editor/presentation/controllers/film_look_controller.dart';
import 'package:nle_editor/presentation/providers/film_look_controller_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

class FilmLookPanel extends ConsumerWidget {
  final String? selectedClipId;

  const FilmLookPanel({
    super.key,
    required this.selectedClipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipId = selectedClipId;

    if (clipId == null) {
      return const _EmptyState(message: 'Select a clip to apply film looks.');
    }

    final state = ref.watch(filmLookControllerProvider(clipId));
    final ctrl = ref.read(filmLookControllerProvider(clipId).notifier);

    if (state.loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return _FilmLookContent(settings: state.settings, ctrl: ctrl);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content
// ─────────────────────────────────────────────────────────────────────────────

class _FilmLookContent extends StatelessWidget {
  final NleFilmLookSettings settings;
  final FilmLookController ctrl;

  const _FilmLookContent({
    required this.settings,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      children: [
        // ── Header ────────────────────────────────────────────────────
        Row(
          children: [
            const Expanded(
              child: Text(
                'Film Look',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Switch(
              value: settings.enabled,
              onChanged: ctrl.setEnabled,
            ),
            IconButton(
              onPressed: ctrl.reset,
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'Reset all film look',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Preset selector ───────────────────────────────────────────
        const Text(
          'PRESET',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        _PresetSelector(
          current: settings.preset,
          onSelected: ctrl.applyPreset,
        ),

        const SizedBox(height: 18),

        // ── Intensity ─────────────────────────────────────────────────
        if (settings.enabled) ...[
          _SliderRow(
            label: 'Intensity',
            value: settings.intensity,
            min: 0.0,
            max: 1.0,
            onChanged: ctrl.setIntensity,
          ),
          const SizedBox(height: 18),
        ],

        // ── Film Grain ────────────────────────────────────────────────
        _CollapsibleSection(
          title: 'Film Grain',
          icon: Icons.grain_rounded,
          enabled: settings.grain.enabled,
          onToggle: (v) => ctrl.setGrain(settings.grain.copyWith(enabled: v)),
          child: _GrainEditor(
            grain: settings.grain,
            onChange: ctrl.setGrain,
          ),
        ),

        // ── Halation ──────────────────────────────────────────────────
        _CollapsibleSection(
          title: 'Halation',
          icon: Icons.flare_rounded,
          enabled: settings.halation.enabled,
          onToggle: (v) =>
              ctrl.setHalation(settings.halation.copyWith(enabled: v)),
          child: _HalationEditor(
            halation: settings.halation,
            onChange: ctrl.setHalation,
          ),
        ),

        // ── Bloom ─────────────────────────────────────────────────────
        _CollapsibleSection(
          title: 'Bloom',
          icon: Icons.wb_sunny_outlined,
          enabled: settings.bloom.enabled,
          onToggle: (v) => ctrl.setBloom(settings.bloom.copyWith(enabled: v)),
          child: _BloomEditor(
            bloom: settings.bloom,
            onChange: ctrl.setBloom,
          ),
        ),

        // ── Print / Tone ──────────────────────────────────────────────
        _CollapsibleSection(
          title: 'Print / Tone',
          icon: Icons.tune_rounded,
          enabled: settings.print.enabled,
          onToggle: (v) => ctrl.setPrint(settings.print.copyWith(enabled: v)),
          child: _PrintEditor(
            print: settings.print,
            onChange: ctrl.setPrint,
          ),
        ),

        // ── Vignette ──────────────────────────────────────────────────
        _CollapsibleSection(
          title: 'Vignette',
          icon: Icons.vignette_rounded,
          enabled: settings.vignette.enabled,
          onToggle: (v) =>
              ctrl.setVignette(settings.vignette.copyWith(enabled: v)),
          child: _VignetteEditor(
            vignette: settings.vignette,
            onChange: ctrl.setVignette,
          ),
        ),

        // ── Gate Weave ────────────────────────────────────────────────
        _CollapsibleSection(
          title: 'Gate Weave',
          icon: Icons.swap_horiz_rounded,
          enabled: settings.gateWeave.enabled,
          onToggle: (v) =>
              ctrl.setGateWeave(settings.gateWeave.copyWith(enabled: v)),
          child: _GateWeaveEditor(
            gateWeave: settings.gateWeave,
            onChange: ctrl.setGateWeave,
          ),
        ),

        // ── Chromatic Softness ─────────────────────────────────────────
        _SectionCard(
          child: _SliderRow(
            label: 'Chr. Soft',
            value: settings.chromaticSoftness,
            min: 0.0,
            max: 1.0,
            onChanged: ctrl.setChromaticSoftness,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset selector
// ─────────────────────────────────────────────────────────────────────────────

class _PresetSelector extends StatelessWidget {
  final NleFilmStockPreset current;
  final ValueChanged<NleFilmStockPreset> onSelected;

  const _PresetSelector({
    required this.current,
    required this.onSelected,
  });

  static const _presets = [
    (NleFilmStockPreset.neutral, 'Neutral'),
    (NleFilmStockPreset.kodak2383, 'Kodak 2383'),
    (NleFilmStockPreset.kodakVision3, 'Vision 3'),
    (NleFilmStockPreset.fujiEterna, 'Fuji Eterna'),
    (NleFilmStockPreset.vintagePrint, 'Vintage'),
    (NleFilmStockPreset.bleachBypass, 'Bleach BP'),
    (NleFilmStockPreset.softPastel, 'Soft Pastel'),
    (NleFilmStockPreset.warmDocumentary, 'Warm Doc'),
    (NleFilmStockPreset.coolNoir, 'Cool Noir'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _presets.map((entry) {
        final (preset, label) = entry;
        final isSelected = preset == current;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onSelected(preset),
          labelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
          selectedColor: const Color(0xFFD4AF37),
          backgroundColor: const Color(0xFF131920),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFD4AF37)
                : AppTheme.borderSubtle,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section editors
// ─────────────────────────────────────────────────────────────────────────────

class _GrainEditor extends StatelessWidget {
  final NleFilmGrainSettings grain;
  final ValueChanged<NleFilmGrainSettings> onChange;

  const _GrainEditor({required this.grain, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Amount',
          value: grain.amount,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(grain.copyWith(amount: v)),
        ),
        _SliderRow(
          label: 'Softness',
          value: grain.softness,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(grain.copyWith(softness: v)),
        ),
        _SliderRow(
          label: 'Luma Resp',
          value: grain.responseToLuma,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(grain.copyWith(responseToLuma: v)),
        ),
        _GrainSizeSelector(
          current: grain.size,
          onSelected: (s) => onChange(grain.copyWith(size: s)),
        ),
        SwitchListTile(
          value: grain.monochrome,
          onChanged: (v) => onChange(grain.copyWith(monochrome: v)),
          title: const Text(
            'Monochrome',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          dense: true,
        ),
      ],
    );
  }
}

class _GrainSizeSelector extends StatelessWidget {
  final NleFilmGrainSize current;
  final ValueChanged<NleFilmGrainSize> onSelected;

  const _GrainSizeSelector({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text(
              'Grain Size',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SegmentedButton<NleFilmGrainSize>(
              segments: const [
                ButtonSegment(value: NleFilmGrainSize.fine, label: Text('Fine')),
                ButtonSegment(value: NleFilmGrainSize.medium, label: Text('Med')),
                ButtonSegment(value: NleFilmGrainSize.coarse, label: Text('Coarse')),
              ],
              selected: {current},
              onSelectionChanged: (s) => onSelected(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _HalationEditor extends StatelessWidget {
  final NleHalationSettings halation;
  final ValueChanged<NleHalationSettings> onChange;

  const _HalationEditor({required this.halation, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Amount',
          value: halation.amount,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(halation.copyWith(amount: v)),
        ),
        _SliderRow(
          label: 'Threshold',
          value: halation.threshold,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(halation.copyWith(threshold: v)),
        ),
        _SliderRow(
          label: 'Radius',
          value: halation.radius,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(halation.copyWith(radius: v)),
        ),
        _SliderRow(
          label: 'Red Bias',
          value: halation.redBias,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(halation.copyWith(redBias: v)),
        ),
        _SliderRow(
          label: 'Warmth',
          value: halation.warmth,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(halation.copyWith(warmth: v)),
        ),
      ],
    );
  }
}

class _BloomEditor extends StatelessWidget {
  final NleBloomSettings bloom;
  final ValueChanged<NleBloomSettings> onChange;

  const _BloomEditor({required this.bloom, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Amount',
          value: bloom.amount,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(bloom.copyWith(amount: v)),
        ),
        _SliderRow(
          label: 'Threshold',
          value: bloom.threshold,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(bloom.copyWith(threshold: v)),
        ),
        _SliderRow(
          label: 'Radius',
          value: bloom.radius,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(bloom.copyWith(radius: v)),
        ),
        _SliderRow(
          label: 'Softness',
          value: bloom.softness,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(bloom.copyWith(softness: v)),
        ),
      ],
    );
  }
}

class _PrintEditor extends StatelessWidget {
  final NlePrintSettings print;
  final ValueChanged<NlePrintSettings> onChange;

  const _PrintEditor({required this.print, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Contrast',
          value: print.contrast,
          min: 0.5,
          max: 2.0,
          onChanged: (v) => onChange(print.copyWith(contrast: v)),
        ),
        _SliderRow(
          label: 'Toe',
          value: print.toe,
          min: 0.0,
          max: 0.5,
          onChanged: (v) => onChange(print.copyWith(toe: v)),
        ),
        _SliderRow(
          label: 'Shoulder',
          value: print.shoulder,
          min: 0.0,
          max: 0.6,
          onChanged: (v) => onChange(print.copyWith(shoulder: v)),
        ),
        _SliderRow(
          label: 'Fade',
          value: print.fade,
          min: 0.0,
          max: 0.3,
          onChanged: (v) => onChange(print.copyWith(fade: v)),
        ),
        _SliderRow(
          label: 'Saturation',
          value: print.saturation,
          min: 0.0,
          max: 2.0,
          onChanged: (v) => onChange(print.copyWith(saturation: v)),
        ),
        _SliderRow(
          label: 'HL Rolloff',
          value: print.highlightRolloff,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(print.copyWith(highlightRolloff: v)),
        ),
        _SliderRow(
          label: 'Shd Tint',
          value: print.shadowTint,
          min: -0.5,
          max: 0.5,
          onChanged: (v) => onChange(print.copyWith(shadowTint: v)),
        ),
        _SliderRow(
          label: 'HL Warmth',
          value: print.highlightWarmth,
          min: -0.5,
          max: 0.5,
          onChanged: (v) => onChange(print.copyWith(highlightWarmth: v)),
        ),
      ],
    );
  }
}

class _VignetteEditor extends StatelessWidget {
  final NleVignetteSettings vignette;
  final ValueChanged<NleVignetteSettings> onChange;

  const _VignetteEditor({required this.vignette, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Amount',
          value: vignette.amount,
          min: -1.0,
          max: 1.0,
          onChanged: (v) => onChange(vignette.copyWith(amount: v)),
        ),
        _SliderRow(
          label: 'Radius',
          value: vignette.radius,
          min: 0.1,
          max: 1.5,
          onChanged: (v) => onChange(vignette.copyWith(radius: v)),
        ),
        _SliderRow(
          label: 'Feather',
          value: vignette.feather,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(vignette.copyWith(feather: v)),
        ),
        _SliderRow(
          label: 'Roundness',
          value: vignette.roundness,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(vignette.copyWith(roundness: v)),
        ),
      ],
    );
  }
}

class _GateWeaveEditor extends StatelessWidget {
  final NleGateWeaveSettings gateWeave;
  final ValueChanged<NleGateWeaveSettings> onChange;

  const _GateWeaveEditor({required this.gateWeave, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Amount',
          value: gateWeave.amount,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => onChange(gateWeave.copyWith(amount: v)),
        ),
        _SliderRow(
          label: 'Frequency',
          value: gateWeave.frequency,
          min: 0.1,
          max: 3.0,
          onChanged: (v) => onChange(gateWeave.copyWith(frequency: v)),
        ),
        _SliderRow(
          label: 'Rotation',
          value: gateWeave.rotation,
          min: -0.2,
          max: 0.2,
          onChanged: (v) => onChange(gateWeave.copyWith(rotation: v)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable layout widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onToggle,
    required this.child,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1320),
          borderRadius: BorderRadius.circular(PremiumRadius.lg),
          border: Border.all(
            color: widget.enabled
                ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                : AppTheme.borderSubtle,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(PremiumRadius.lg),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PremiumSpacing.md,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.enabled
                          ? const Color(0xFFD4AF37)
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.enabled
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Switch(
                      value: widget.enabled,
                      onChanged: widget.onToggle,
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PremiumSpacing.md,
                  0,
                  PremiumSpacing.md,
                  PremiumSpacing.md,
                ),
                child: widget.child,
              ),
          ],
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
      margin: const EdgeInsets.only(bottom: 8),
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
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.textMuted),
      ),
    );
  }
}
