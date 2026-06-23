import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GpuEffect {
  final String id;
  final String type; // 'blur', 'vhs_glitch', 'overlay_sticker'
  final bool isPremium;
  final Map<String, dynamic> parameters;

  const GpuEffect({
    required this.id,
    required this.type,
    required this.isPremium,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'isPremium': isPremium,
        'parameters': parameters,
      };

  factory GpuEffect.fromJson(Map<String, dynamic> json) {
    return GpuEffect(
      id: json['id'] as String,
      type: json['type'] as String,
      isPremium: json['isPremium'] as bool? ?? false,
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
    );
  }
}

class GpuEffectsService {
  const GpuEffectsService();

  List<GpuEffect> parseEffectStack(String? effectStackJson) {
    if (effectStackJson == null || effectStackJson.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(effectStackJson);
      if (decoded is List) {
        return decoded
            .map((item) => GpuEffect.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  String serializeEffectStack(List<GpuEffect> effects) {
    return jsonEncode(effects.map((e) => e.toJson()).toList());
  }

  Map<String, dynamic> computeOverlayTransformation({
    required GpuEffect effect,
    required double timeSec,
    required double width,
    required double height,
  }) {
    switch (effect.type) {
      case 'vhs_glitch':
        final strength = effect.parameters['strength'] ?? 0.5;
        final shiftX = 5.0 * strength * (timeSec % 0.2);
        return {'shiftX': shiftX, 'scanlines': true};
      case 'blur':
        final radius = effect.parameters['radius'] ?? 10.0;
        return {'blurRadius': radius};
      case 'overlay_sticker':
        final scale = effect.parameters['scale'] ?? 1.0;
        return {'stickerScale': scale};
      default:
        return {};
    }
  }
}

final gpuEffectsServiceProvider = Provider<GpuEffectsService>((ref) {
  return const GpuEffectsService();
});
