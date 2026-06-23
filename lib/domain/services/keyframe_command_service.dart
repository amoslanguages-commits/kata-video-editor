import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/keyframe_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/domain/keyframes/keyframe_parameters.dart';
import 'package:nle_editor/native_bridge/native_command_service.dart';

class KeyframeCommandService {
  final KeyframeRepository keyframeRepository;
  final TimelineRepository timelineRepository;
  final NativeCommandService nativeCommandService;

  static const _uuid = Uuid();

  KeyframeCommandService({
    required this.keyframeRepository,
    required this.timelineRepository,
    required this.nativeCommandService,
  });

  Future<String> addOrUpdateKeyframeAtTimelineTime({
    required String projectId,
    required String clipId,
    required String parameter,
    required int timelineMicros,
    String interpolation = KeyframeInterpolation.linear,
    String easing = KeyframeInterpolation.easeInOut,
  }) async {
    final clip = await timelineRepository.getClip(clipId);

    if (clip == null) {
      throw StateError('Clip not found.');
    }

    final timeInsideClip = _timelineToClipTime(
      clip: clip,
      timelineMicros: timelineMicros,
    );

    final parameterInfo = KeyframeParameters.byId(parameter);
    final value = _readClipParameterValue(clip, parameter);

    final existing = await _nearestKeyframeForParameter(
      clipId: clipId,
      parameter: parameter,
      timeInsideClip: timeInsideClip,
      toleranceMicros: 50000,
    );

    final valueJson = jsonEncode({
      'value': value,
    });

    final keyframeId = existing?.id ?? _uuid.v4();

    if (existing == null) {
      await keyframeRepository.insertKeyframe(
        KeyframesCompanion.insert(
          id: keyframeId,
          clipId: clipId,
          parameter: parameter,
          timeMicros: timeInsideClip,
          valueType: Value(parameterInfo.valueType),
          valueJson: valueJson,
          interpolation: Value(interpolation),
          easing: Value(easing),
        ),
      );
    } else {
      await keyframeRepository.updateKeyframeFields(
        existing.id,
        KeyframesCompanion(
          valueType: Value(parameterInfo.valueType),
          valueJson: Value(valueJson),
          interpolation: Value(interpolation),
          easing: Value(easing),
        ),
      );
    }

    await nativeCommandService.sendKeyframeChanged(
      projectId: projectId,
      keyframeId: keyframeId,
      clipId: clipId,
      action: existing == null ? 'add_keyframe' : 'update_keyframe',
    );

    return keyframeId;
  }

  Future<void> deleteNearestKeyframe({
    required String projectId,
    required String clipId,
    required String parameter,
    required int timelineMicros,
  }) async {
    final clip = await timelineRepository.getClip(clipId);

    if (clip == null) {
      throw StateError('Clip not found.');
    }

    final timeInsideClip = _timelineToClipTime(
      clip: clip,
      timelineMicros: timelineMicros,
    );

    final nearest = await _nearestKeyframeForParameter(
      clipId: clipId,
      parameter: parameter,
      timeInsideClip: timeInsideClip,
      toleranceMicros: 250000,
    );

    if (nearest == null) {
      throw StateError('No nearby keyframe found.');
    }

    await keyframeRepository.deleteKeyframe(nearest.id);

    await nativeCommandService.sendKeyframeChanged(
      projectId: projectId,
      keyframeId: nearest.id,
      clipId: clipId,
      action: 'delete_keyframe',
    );
  }

  Future<int?> previousKeyframeTimelineTime({
    required String clipId,
    required String parameter,
    required int timelineMicros,
  }) async {
    final clip = await timelineRepository.getClip(clipId);

    if (clip == null) return null;

    final timeInsideClip = _timelineToClipTime(
      clip: clip,
      timelineMicros: timelineMicros,
    );

    final keyframes = await keyframeRepository.getClipParameterKeyframes(
      clipId: clipId,
      parameter: parameter,
    );

    final previous = keyframes.where((k) => k.timeMicros < timeInsideClip).toList()
      ..sort((a, b) => b.timeMicros.compareTo(a.timeMicros));

    if (previous.isEmpty) return null;

    return clip.timelineStartMicros + previous.first.timeMicros.toInt();
  }

  Future<int?> nextKeyframeTimelineTime({
    required String clipId,
    required String parameter,
    required int timelineMicros,
  }) async {
    final clip = await timelineRepository.getClip(clipId);

    if (clip == null) return null;

    final timeInsideClip = _timelineToClipTime(
      clip: clip,
      timelineMicros: timelineMicros,
    );

    final keyframes = await keyframeRepository.getClipParameterKeyframes(
      clipId: clipId,
      parameter: parameter,
    );

    final next = keyframes.where((k) => k.timeMicros > timeInsideClip).toList()
      ..sort((a, b) => a.timeMicros.compareTo(b.timeMicros));

    if (next.isEmpty) return null;

    return clip.timelineStartMicros + next.first.timeMicros.toInt();
  }

  Future<void> deleteAllClipKeyframes({
    required String projectId,
    required String clipId,
  }) async {
    await keyframeRepository.deleteClipKeyframes(clipId);

    await nativeCommandService.sendKeyframeChanged(
      projectId: projectId,
      keyframeId: 'all',
      clipId: clipId,
      action: 'delete_all_clip_keyframes',
    );
  }

  Future<Keyframe?> _nearestKeyframeForParameter({
    required String clipId,
    required String parameter,
    required int timeInsideClip,
    required int toleranceMicros,
  }) async {
    final keyframes = await keyframeRepository.getClipParameterKeyframes(
      clipId: clipId,
      parameter: parameter,
    );

    Keyframe? best;
    var bestDistance = 1 << 62;

    for (final keyframe in keyframes) {
      final distance = (keyframe.timeMicros - timeInsideClip).abs();

      if (distance < bestDistance) {
        best = keyframe;
        bestDistance = distance;
      }
    }

    if (best == null || bestDistance > toleranceMicros) {
      return null;
    }

    return best;
  }

  int _timelineToClipTime({
    required Clip clip,
    required int timelineMicros,
  }) {
    final raw = timelineMicros - clip.timelineStartMicros;
    final duration = clip.timelineEndMicros - clip.timelineStartMicros;

    return raw.clamp(0, duration);
  }

  double _readClipParameterValue(Clip clip, String parameter) {
    switch (parameter) {
      case 'transform.positionX':
        return clip.positionX;
      case 'transform.positionY':
        return clip.positionY;
      case 'transform.scale':
        return clip.scale;
      case 'transform.rotation':
        return clip.rotation;
      case 'transform.opacity':
        return clip.opacity;

      case 'audio.volume':
        return clip.volume;
      case 'audio.pan':
        return clip.audioPan;

      case 'color.exposure':
        return clip.exposure;
      case 'color.contrast':
        return clip.contrast;
      case 'color.saturation':
        return clip.saturation;
      case 'color.temperature':
        return clip.temperature;
      case 'color.tint':
        return clip.tint;

      default:
        return 0.0;
    }
  }

  double decodeKeyframeNumber(Keyframe keyframe) {
    try {
      final decoded = jsonDecode(keyframe.valueJson);

      if (decoded is Map<String, dynamic>) {
        final value = decoded['value'];

        if (value is num) {
          return value.toDouble();
        }
      }
    } catch (_) {}

    return 0.0;
  }

  String formatNumber(double value) {
    if (value.abs() >= 10) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }
}
