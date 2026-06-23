import 'package:nle_editor/domain/keyframes/keyframe_models.dart';

class NleKeyframeClipboardPayload {
  final String sourcePropertyPath;
  final List<NleKeyframe> keyframes;
  final int copiedAtMicros;

  const NleKeyframeClipboardPayload({
    required this.sourcePropertyPath,
    required this.keyframes,
    required this.copiedAtMicros,
  });

  bool get isEmpty => keyframes.isEmpty;
}

class KeyframeClipboard {
  NleKeyframeClipboardPayload? _payload;

  NleKeyframeClipboardPayload? get payload => _payload;

  void copy({
    required String sourcePropertyPath,
    required List<NleKeyframe> selectedKeyframes,
    required int playheadMicros,
  }) {
    _payload = NleKeyframeClipboardPayload(
      sourcePropertyPath: sourcePropertyPath,
      keyframes: selectedKeyframes,
      copiedAtMicros: playheadMicros,
    );
  }

  List<NleKeyframe> pasteAt({
    required int targetMicros,
  }) {
    final current = _payload;
    if (current == null || current.isEmpty) return const [];

    final minTime = current.keyframes
        .map((kf) => kf.timeOffsetMicros)
        .reduce((a, b) => a < b ? a : b);

    return current.keyframes.map((kf) {
      return kf.copyWith(
        timeOffsetMicros: targetMicros + (kf.timeOffsetMicros - minTime),
        selected: true,
      );
    }).toList();
  }

  void clear() {
    _payload = null;
  }
}
