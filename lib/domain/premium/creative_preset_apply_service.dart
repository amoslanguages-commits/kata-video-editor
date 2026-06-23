import 'package:drift/drift.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/data/repositories/transition_repository.dart';
import 'package:nle_editor/domain/premium/creative_pack.dart';
import 'package:nle_editor/domain/premium/entitlement_state.dart';
import 'package:nle_editor/native_bridge/native_export_job.dart';

class PresetApplyResult {
  final bool success;
  final String message;
  final bool locked;

  const PresetApplyResult({
    required this.success,
    required this.message,
    this.locked = false,
  });

  factory PresetApplyResult.ok(String message) {
    return PresetApplyResult(
      success: true,
      message: message,
    );
  }

  factory PresetApplyResult.locked(String message) {
    return PresetApplyResult(
      success: false,
      locked: true,
      message: message,
    );
  }

  factory PresetApplyResult.failed(String message) {
    return PresetApplyResult(
      success: false,
      message: message,
    );
  }
}

class CreativePresetApplyService {
  final TimelineRepository timelineRepository;
  final TransitionRepository transitionRepository;

  const CreativePresetApplyService({
    required this.timelineRepository,
    required this.transitionRepository,
  });

  Future<PresetApplyResult> applyToClip({
    required CreativePackItem item,
    required Clip clip,
    required EntitlementState entitlement,
  }) async {
    if (item.isLocked(entitlement.hasFeature)) {
      return PresetApplyResult.locked('This preset requires Pro.');
    }

    switch (item.type) {
      case CreativePackItemType.effectPreset:
      case CreativePackItemType.colorPreset:
        return _applyEffectOrColorPreset(item: item, clip: clip);

      case CreativePackItemType.textPreset:
        return _applyTextPreset(item: item, clip: clip);

      default:
        return PresetApplyResult.failed('This preset cannot be applied to a clip.');
    }
  }

  Future<PresetApplyResult> applyTransition({
    required CreativePackItem item,
    required String transitionId,
    required EntitlementState entitlement,
  }) async {
    if (item.isLocked(entitlement.hasFeature)) {
      return PresetApplyResult.locked('This transition requires Pro.');
    }

    if (item.type != CreativePackItemType.transitionPreset) {
      return PresetApplyResult.failed('This is not a transition preset.');
    }

    final payload = item.payload;

    await transitionRepository.updateTransitionFields(
      transitionId,
      ClipTransitionsCompanion(
        transitionType: Value(payload['transitionType']?.toString() ?? 'dissolve'),
        durationMicros: Value(_asInt(payload['durationMicros']) ?? 500000),
        direction: Value(payload['direction']?.toString() ?? 'none'),
        easing: Value(payload['easing']?.toString() ?? 'smooth'),
        parametersJson: Value(payload.toString()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return PresetApplyResult.ok('Transition preset applied.');
  }

  NativeExportProfile? exportProfileFromPreset({
    required CreativePackItem item,
    required EntitlementState entitlement,
  }) {
    if (item.type != CreativePackItemType.exportPreset) return null;

    if (item.isLocked(entitlement.hasFeature)) {
      return null;
    }

    final payload = item.payload;

    return NativeExportProfile(
      width: _asInt(payload['width']) ?? 1920,
      height: _asInt(payload['height']) ?? 1080,
      frameRate: _asInt(payload['frameRate']) ?? 30,
      bitrateBps: _asInt(payload['bitrateBps']) ?? _asInt(payload['videoBitrate']) ?? 8000000,
    );
  }

  Future<PresetApplyResult> _applyEffectOrColorPreset({
    required CreativePackItem item,
    required Clip clip,
  }) async {
    final payload = item.payload;

    await timelineRepository.updateClipFields(
      clip.id,
      ClipsCompanion(
        scale: payload.containsKey('scale')
            ? Value(_asDouble(payload['scale']) ?? clip.scale)
            : const Value.absent(),
        rotation: payload.containsKey('rotation')
            ? Value(_asDouble(payload['rotation']) ?? clip.rotation)
            : const Value.absent(),
        opacity: payload.containsKey('opacity')
            ? Value(_asDouble(payload['opacity']) ?? clip.opacity)
            : const Value.absent(),
        exposure: payload.containsKey('brightness')
            ? Value(_asDouble(payload['brightness']) ?? clip.exposure)
            : const Value.absent(),
        contrast: payload.containsKey('contrast')
            ? Value(_asDouble(payload['contrast']) ?? clip.contrast)
            : const Value.absent(),
        saturation: payload.containsKey('saturation')
            ? Value(_asDouble(payload['saturation']) ?? clip.saturation)
            : const Value.absent(),
        temperature: payload.containsKey('temperature')
            ? Value(_asDouble(payload['temperature']) ?? clip.temperature)
            : const Value.absent(),
        tint: payload.containsKey('tint')
            ? Value(_asDouble(payload['tint']) ?? clip.tint)
            : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    return PresetApplyResult.ok('Preset applied to clip.');
  }

  Future<PresetApplyResult> _applyTextPreset({
    required CreativePackItem item,
    required Clip clip,
  }) async {
    if (clip.clipType != 'text') {
      return PresetApplyResult.failed('Text presets can only be applied to text clips.');
    }

    await timelineRepository.updateClipFields(
      clip.id,
      ClipsCompanion(
        textStyle: Value(item.payload.toString()),
        modifiedAt: Value(DateTime.now()),
      ),
    );

    return PresetApplyResult.ok('Text preset applied.');
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }
}
