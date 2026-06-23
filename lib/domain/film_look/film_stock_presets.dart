import 'package:nle_editor/domain/film_look/film_look_models.dart';

class FilmStockPresets {
  const FilmStockPresets();

  NleFilmLookSettings preset(NleFilmStockPreset preset) {
    switch (preset) {
      case NleFilmStockPreset.neutral:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.neutral,
          intensity: 1.0,
        );

      case NleFilmStockPreset.kodak2383:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.kodak2383,
          intensity: 1.0,
          print: const NlePrintSettings(
            enabled: true,
            contrast: 1.18,
            toe: 0.16,
            shoulder: 0.28,
            fade: 0.01,
            saturation: 1.08,
            highlightRolloff: 0.55,
            shadowTint: 0.03,
            highlightWarmth: 0.12,
          ),
          halation: const NleHalationSettings(
            enabled: true,
            amount: 0.12,
            threshold: 0.74,
            radius: 0.40,
            redBias: 0.82,
            warmth: 0.42,
          ),
          grain: const NleFilmGrainSettings(
            enabled: true,
            amount: 0.09,
            softness: 0.45,
            size: NleFilmGrainSize.fine,
            monochrome: false,
            responseToLuma: 0.65,
          ),
        );

      case NleFilmStockPreset.kodakVision3:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.kodakVision3,
          intensity: 1.0,
          print: const NlePrintSettings(
            enabled: true,
            contrast: 1.10,
            toe: 0.12,
            shoulder: 0.35,
            fade: 0.00,
            saturation: 1.04,
            highlightRolloff: 0.68,
            shadowTint: 0.01,
            highlightWarmth: 0.08,
          ),
          bloom: const NleBloomSettings(
            enabled: true,
            amount: 0.07,
            threshold: 0.82,
            radius: 0.45,
            softness: 0.45,
          ),
          grain: const NleFilmGrainSettings(
            enabled: true,
            amount: 0.07,
            softness: 0.50,
            size: NleFilmGrainSize.fine,
            monochrome: false,
            responseToLuma: 0.55,
          ),
        );

      case NleFilmStockPreset.fujiEterna:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.fujiEterna,
          intensity: 1.0,
          print: const NlePrintSettings(
            enabled: true,
            contrast: 1.06,
            toe: 0.10,
            shoulder: 0.36,
            fade: 0.02,
            saturation: 0.94,
            highlightRolloff: 0.60,
            shadowTint: -0.04,
            highlightWarmth: 0.02,
          ),
          grain: const NleFilmGrainSettings(
            enabled: true,
            amount: 0.06,
            softness: 0.55,
            size: NleFilmGrainSize.fine,
            monochrome: false,
            responseToLuma: 0.50,
          ),
        );

      case NleFilmStockPreset.vintagePrint:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.vintagePrint,
          intensity: 1.0,
          print: const NlePrintSettings(
            enabled: true,
            contrast: 1.02,
            toe: 0.20,
            shoulder: 0.30,
            fade: 0.12,
            saturation: 0.88,
            highlightRolloff: 0.50,
            shadowTint: 0.12,
            highlightWarmth: 0.18,
          ),
          vignette: const NleVignetteSettings(
            enabled: true,
            amount: 0.14,
            radius: 0.72,
            feather: 0.55,
            roundness: 1.0,
          ),
          gateWeave: const NleGateWeaveSettings(
            enabled: true,
            amount: 0.08,
            frequency: 0.65,
            rotation: 0.02,
          ),
          grain: const NleFilmGrainSettings(
            enabled: true,
            amount: 0.16,
            softness: 0.35,
            size: NleFilmGrainSize.medium,
            monochrome: false,
            responseToLuma: 0.72,
          ),
        );

      case NleFilmStockPreset.bleachBypass:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.bleachBypass,
          intensity: 1.0,
          print: const NlePrintSettings(
            enabled: true,
            contrast: 1.35,
            toe: 0.18,
            shoulder: 0.18,
            fade: 0.00,
            saturation: 0.58,
            highlightRolloff: 0.32,
            shadowTint: -0.02,
            highlightWarmth: 0.05,
          ),
          grain: const NleFilmGrainSettings(
            enabled: true,
            amount: 0.10,
            softness: 0.32,
            size: NleFilmGrainSize.medium,
            monochrome: true,
            responseToLuma: 0.60,
          ),
        );

      case NleFilmStockPreset.softPastel:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.softPastel,
          intensity: 1.0,
          print: const NlePrintSettings(
            enabled: true,
            contrast: 0.92,
            toe: 0.14,
            shoulder: 0.55,
            fade: 0.05,
            saturation: 0.92,
            highlightRolloff: 0.78,
            shadowTint: 0.02,
            highlightWarmth: 0.10,
          ),
          bloom: const NleBloomSettings(
            enabled: true,
            amount: 0.13,
            threshold: 0.72,
            radius: 0.62,
            softness: 0.65,
          ),
          chromaticSoftness: 0.10,
        );

      case NleFilmStockPreset.warmDocumentary:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.warmDocumentary,
          intensity: 1.0,
          print: const NlePrintSettings(
            enabled: true,
            contrast: 1.08,
            toe: 0.11,
            shoulder: 0.42,
            fade: 0.015,
            saturation: 1.02,
            highlightRolloff: 0.52,
            shadowTint: 0.03,
            highlightWarmth: 0.16,
          ),
          halation: const NleHalationSettings(
            enabled: true,
            amount: 0.08,
            threshold: 0.78,
            radius: 0.35,
            redBias: 0.75,
            warmth: 0.55,
          ),
          grain: const NleFilmGrainSettings(
            enabled: true,
            amount: 0.055,
            softness: 0.50,
            size: NleFilmGrainSize.fine,
            monochrome: false,
            responseToLuma: 0.50,
          ),
        );

      case NleFilmStockPreset.coolNoir:
        return const NleFilmLookSettings.identity().copyWith(
          enabled: true,
          preset: NleFilmStockPreset.coolNoir,
          intensity: 1.0,
          print: const NlePrintSettings(
            enabled: true,
            contrast: 1.22,
            toe: 0.18,
            shoulder: 0.22,
            fade: 0.00,
            saturation: 0.72,
            highlightRolloff: 0.38,
            shadowTint: -0.16,
            highlightWarmth: -0.04,
          ),
          vignette: const NleVignetteSettings(
            enabled: true,
            amount: 0.18,
            radius: 0.70,
            feather: 0.50,
            roundness: 0.95,
          ),
          grain: const NleFilmGrainSettings(
            enabled: true,
            amount: 0.12,
            softness: 0.38,
            size: NleFilmGrainSize.medium,
            monochrome: true,
            responseToLuma: 0.70,
          ),
        );
    }
  }
}
