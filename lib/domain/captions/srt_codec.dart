import 'package:uuid/uuid.dart';

import 'package:nle_editor/domain/captions/caption_segment_models.dart';

class NleSrtCodec {
  static const _uuid = Uuid();

  const NleSrtCodec();

  List<NleCaptionSegment> parse({
    required String trackId,
    required String source,
  }) {
    final normalized = source
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    if (normalized.isEmpty) return const [];

    final blocks = normalized.split(RegExp(r'\n\s*\n'));
    final segments = <NleCaptionSegment>[];

    for (final block in blocks) {
      final lines = block.split('\n').map((e) => e.trim()).toList();

      if (lines.length < 2) continue;

      var timeLineIndex = 0;

      if (RegExp(r'^\d+$').hasMatch(lines.first)) {
        timeLineIndex = 1;
      }

      if (timeLineIndex >= lines.length) continue;

      final timeLine = lines[timeLineIndex];
      final match = RegExp(
        r'(\d{2}:\d{2}:\d{2}[,.]\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2}[,.]\d{3})',
      ).firstMatch(timeLine);

      if (match == null) continue;

      final start = _parseSrtTime(match.group(1)!);
      final end = _parseSrtTime(match.group(2)!);

      final textLines = lines.skip(timeLineIndex + 1).toList();
      final text = textLines.join('\n').trim();

      if (text.isEmpty || end <= start) continue;

      segments.add(
        NleCaptionSegment(
          id: _uuid.v4(),
          trackId: trackId,
          startMicros: start,
          endMicros: end,
          text: _stripBasicTags(text),
          confidence: 1.0,
          locked: false,
          hidden: false,
          words: const [],
          version: 1,
        ),
      );
    }

    segments.sort((a, b) => a.startMicros.compareTo(b.startMicros));

    return segments;
  }

  String encode(List<NleCaptionSegment> segments) {
    final ordered = [...segments]
      ..sort((a, b) => a.startMicros.compareTo(b.startMicros));

    final buffer = StringBuffer();

    for (var i = 0; i < ordered.length; i++) {
      final segment = ordered[i];

      if (segment.hidden) continue;

      buffer.writeln(i + 1);
      buffer.writeln(
        '${_formatSrtTime(segment.startMicros)} --> ${_formatSrtTime(segment.endMicros)}',
      );
      buffer.writeln(segment.text.trim());
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  int _parseSrtTime(String value) {
    final cleaned = value.replaceAll(',', '.');
    final parts = cleaned.split(':');

    if (parts.length != 3) return 0;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final secondsParts = parts[2].split('.');

    final seconds = int.tryParse(secondsParts[0]) ?? 0;
    final millis = secondsParts.length > 1
        ? int.tryParse(secondsParts[1].padRight(3, '0').substring(0, 3)) ?? 0
        : 0;

    return (((hours * 60 + minutes) * 60 + seconds) * 1000 + millis) * 1000;
  }

  String _formatSrtTime(int micros) {
    final totalMillis = micros ~/ 1000;
    final millis = totalMillis % 1000;
    final totalSeconds = totalMillis ~/ 1000;
    final seconds = totalSeconds % 60;
    final totalMinutes = totalSeconds ~/ 60;
    final minutes = totalMinutes % 60;
    final hours = totalMinutes ~/ 60;

    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');

    return '${two(hours)}:${two(minutes)}:${two(seconds)},${three(millis)}';
  }

  String _stripBasicTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
