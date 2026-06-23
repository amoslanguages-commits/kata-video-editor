import 'package:nle_editor/domain/captions/caption_segment_models.dart';
import 'package:nle_editor/domain/captions/caption_value_models.dart';

class CaptionTimingTools {
  const CaptionTimingTools();

  NleCaptionSegment trimStart({
    required NleCaptionSegment segment,
    required int newStartMicros,
    int minDurationMicros = 250000,
  }) {
    final safeStart = newStartMicros.clamp(
      0,
      segment.endMicros - minDurationMicros,
    );

    return segment.copyWith(startMicros: safeStart);
  }

  NleCaptionSegment trimEnd({
    required NleCaptionSegment segment,
    required int newEndMicros,
    int minDurationMicros = 250000,
  }) {
    final safeEnd = newEndMicros.clamp(
      segment.startMicros + minDurationMicros,
      1 << 62,
    );

    return segment.copyWith(endMicros: safeEnd);
  }

  NleCaptionSegment shift({
    required NleCaptionSegment segment,
    required int deltaMicros,
  }) {
    final shifted = segment.shifted(deltaMicros);

    if (shifted.startMicros < 0) {
      return segment.shifted(-segment.startMicros);
    }

    return shifted;
  }

  List<NleCaptionSegment> split({
    required NleCaptionSegment segment,
    required int splitMicros,
    required String firstId,
    required String secondId,
  }) {
    if (splitMicros <= segment.startMicros ||
        splitMicros >= segment.endMicros) {
      return [segment];
    }

    final words = segment.text.trim().split(RegExp(r'\s+'));

    final firstText = words.length > 1
        ? words.take((words.length / 2).ceil()).join(' ')
        : segment.text;

    final secondText = words.length > 1
        ? words.skip((words.length / 2).ceil()).join(' ')
        : '';

    return [
      NleCaptionSegment(
        id: firstId,
        trackId: segment.trackId,
        startMicros: segment.startMicros,
        endMicros: splitMicros,
        text: firstText,
        speaker: segment.speaker,
        confidence: segment.confidence,
        locked: segment.locked,
        hidden: segment.hidden,
        styleOverride: segment.styleOverride,
        words: const [],
        version: segment.version,
      ),
      NleCaptionSegment(
        id: secondId,
        trackId: segment.trackId,
        startMicros: splitMicros,
        endMicros: segment.endMicros,
        text: secondText,
        speaker: segment.speaker,
        confidence: segment.confidence,
        locked: segment.locked,
        hidden: segment.hidden,
        styleOverride: segment.styleOverride,
        words: const [],
        version: segment.version,
      ),
    ];
  }

  NleCaptionSegment merge({
    required NleCaptionSegment first,
    required NleCaptionSegment second,
  }) {
    return first.copyWith(
      endMicros: second.endMicros,
      text: '${first.text.trim()} ${second.text.trim()}'.trim(),
      words: [...first.words, ...second.words],
    );
  }

  List<NleCaptionSegment> fixOverlaps(List<NleCaptionSegment> segments) {
    final ordered = [...segments]
      ..sort((a, b) => a.startMicros.compareTo(b.startMicros));

    final fixed = <NleCaptionSegment>[];

    for (var i = 0; i < ordered.length; i++) {
      final current = ordered[i];

      if (fixed.isEmpty) {
        fixed.add(current);
        continue;
      }

      final previous = fixed.last;

      if (current.startMicros < previous.endMicros) {
        final next = current.copyWith(startMicros: previous.endMicros);
        if (next.endMicros > next.startMicros) fixed.add(next);
      } else {
        fixed.add(current);
      }
    }

    return fixed;
  }

  int snapTime({
    required int timeMicros,
    required NleCaptionSnapMode mode,
    required List<NleCaptionSegment> segments,
    required String activeSegmentId,
    int? playheadMicros,
    List<int>? clipCutsMicros,
    int snapThresholdMicros = 150000,
  }) {
    if (mode == NleCaptionSnapMode.off) return timeMicros;

    int? candidate;
    int minDiff = snapThresholdMicros;

    void checkCandidate(int snapPoint) {
      final diff = (timeMicros - snapPoint).abs();
      if (diff < minDiff) {
        minDiff = diff;
        candidate = snapPoint;
      }
    }

    if (mode == NleCaptionSnapMode.toTimelinePlayhead && playheadMicros != null) {
      checkCandidate(playheadMicros);
    }

    if (mode == NleCaptionSnapMode.toNearestClipCut && clipCutsMicros != null) {
      for (final cut in clipCutsMicros) {
        checkCandidate(cut);
      }
    }

    for (final segment in segments) {
      if (segment.id == activeSegmentId) continue;

      if (mode == NleCaptionSnapMode.toPreviousCaptionEnd) {
        checkCandidate(segment.endMicros);
      }

      if (mode == NleCaptionSnapMode.toNextCaptionStart) {
        checkCandidate(segment.startMicros);
      }
    }

    return candidate ?? timeMicros;
  }
}
