import 'package:nle_editor/domain/film_look/film_look_models.dart';

/// Serialises an [NleFilmLookSettings] instance into the RenderGraph JSON
/// format that the native compositor reads.
///
/// Position in the pipeline:
///   Input → Primary → Curves → Qualifier → LUT → Film Look → Output Transform
class RenderGraphFilmLookDto {
  final NleFilmLookSettings settings;

  const RenderGraphFilmLookDto({required this.settings});

  Map<String, dynamic> toJson() {
    if (settings.isIdentity) {
      return {
        'enabled': false,
        'intensity': 1.0,
        'preset': settings.preset.name,
        'placement': settings.placement.name,
      };
    }

    return {
      'enabled': settings.enabled,
      'intensity': settings.intensity,
      'preset': settings.preset.name,
      'placement': settings.placement.name,

      // Film grain
      'grain': settings.grain.toJson(),

      // Optical imperfections
      'halation': settings.halation.toJson(),
      'bloom': settings.bloom.toJson(),

      // Print/tone
      'print': settings.print.toJson(),

      // Spatial effects
      'vignette': settings.vignette.toJson(),
      'gateWeave': settings.gateWeave.toJson(),

      // Chromatic softness
      'chromaticSoftness': settings.chromaticSoftness,
    };
  }
}
