import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/caption_repository.dart';
import 'package:nle_editor/domain/captions/caption_segment_models.dart';
import 'package:nle_editor/domain/captions/caption_value_models.dart';
import 'package:nle_editor/domain/captions/caption_timing_tools.dart';
import 'package:nle_editor/domain/captions/srt_codec.dart';
import 'package:nle_editor/domain/captions/webvtt_codec.dart';
import 'package:nle_editor/domain/captions/subtitle_track_models.dart';

void main() {
  group('SRT Codec Tests', () {
    const srtCodec = NleSrtCodec();

    test('SRT Parse and Encode', () {
      const srtSource = '''1
00:00:01,000 --> 00:00:04,500
Hello World!

2
00:00:05,200 --> 00:00:08,000
<i>This is a subtitle</i>''';

      final segments = srtCodec.parse(trackId: 'track_1', source: srtSource);
      expect(segments.length, equals(2));
      expect(segments[0].startMicros, equals(1000000));
      expect(segments[0].endMicros, equals(4500000));
      expect(segments[0].text, equals('Hello World!'));

      expect(segments[1].startMicros, equals(5200000));
      expect(segments[1].endMicros, equals(8000000));
      // Basic tags stripped
      expect(segments[1].text, equals('This is a subtitle'));

      final encoded = srtCodec.encode(segments);
      expect(encoded, contains('1'));
      expect(encoded, contains('00:00:01,000 --> 00:00:04,500'));
      expect(encoded, contains('Hello World!'));
    });
  });

  group('WebVTT Codec Tests', () {
    const webVttCodec = NleWebVttCodec();

    test('WebVTT Parse and Encode', () {
      const vttSource = '''WEBVTT

00:00:02.000 --> 00:00:05.123
First WebVTT segment

00:06.000 --> 00:08.500
Second WebVTT segment''';

      final segments = webVttCodec.parse(trackId: 'track_1', source: vttSource);
      expect(segments.length, equals(2));
      expect(segments[0].startMicros, equals(2000000));
      expect(segments[0].endMicros, equals(5123000));
      expect(segments[0].text, equals('First WebVTT segment'));

      expect(segments[1].startMicros, equals(6000000));
      expect(segments[1].endMicros, equals(8500000));
      expect(segments[1].text, equals('Second WebVTT segment'));

      final encoded = webVttCodec.encode(segments);
      expect(encoded, contains('WEBVTT'));
      expect(encoded, contains('00:00:02.000 --> 00:00:05.123'));
      expect(encoded, contains('First WebVTT segment'));
    });
  });

  group('CaptionTimingTools Tests', () {
    const tools = CaptionTimingTools();
    final baseSegment = NleCaptionSegment(
      id: 'seg_1',
      trackId: 'track_1',
      startMicros: 1000000,
      endMicros: 3000000,
      text: 'Original subtitle words',
      confidence: 1.0,
      locked: false,
      hidden: false,
      words: const [],
      version: 1,
    );

    test('trimStart & trimEnd', () {
      final trimmedStart = tools.trimStart(segment: baseSegment, newStartMicros: 1500000);
      expect(trimmedStart.startMicros, equals(1500000));

      // Min duration guard check (default 250ms)
      final trimmedStartGuard = tools.trimStart(segment: baseSegment, newStartMicros: 2900000);
      expect(trimmedStartGuard.startMicros, equals(2750000));

      final trimmedEnd = tools.trimEnd(segment: baseSegment, newEndMicros: 2500000);
      expect(trimmedEnd.endMicros, equals(2500000));

      final trimmedEndGuard = tools.trimEnd(segment: baseSegment, newEndMicros: 1100000);
      expect(trimmedEndGuard.endMicros, equals(1250000));
    });

    test('shift', () {
      final shifted = tools.shift(segment: baseSegment, deltaMicros: 500000);
      expect(shifted.startMicros, equals(1500000));
      expect(shifted.endMicros, equals(3500000));

      // Clamp shift to non-negative start time
      final negativeShifted = tools.shift(segment: baseSegment, deltaMicros: -2000000);
      expect(negativeShifted.startMicros, equals(0));
      expect(negativeShifted.endMicros, equals(2000000));
    });

    test('split', () {
      final parts = tools.split(
        segment: baseSegment,
        splitMicros: 2000000,
        firstId: 'part_1',
        secondId: 'part_2',
      );

      expect(parts.length, equals(2));
      expect(parts[0].id, equals('part_1'));
      expect(parts[0].startMicros, equals(1000000));
      expect(parts[0].endMicros, equals(2000000));
      expect(parts[0].text, equals('Original subtitle'));

      expect(parts[1].id, equals('part_2'));
      expect(parts[1].startMicros, equals(2000000));
      expect(parts[1].endMicros, equals(3000000));
      expect(parts[1].text, equals('words'));
    });

    test('merge', () {
      final first = baseSegment.copyWith(id: 'part_1', endMicros: 2000000, text: 'Hello');
      final second = baseSegment.copyWith(id: 'part_2', startMicros: 2000000, endMicros: 3500000, text: 'World');

      final merged = tools.merge(first: first, second: second);
      expect(merged.startMicros, equals(1000000));
      expect(merged.endMicros, equals(3500000));
      expect(merged.text, equals('Hello World'));
    });

    test('fixOverlaps', () {
      final List<NleCaptionSegment> segs = [
        baseSegment.copyWith(id: 's1', startMicros: 1000000, endMicros: 3000000),
        baseSegment.copyWith(id: 's2', startMicros: 2500000, endMicros: 5000000),
        baseSegment.copyWith(id: 's3', startMicros: 6000000, endMicros: 8000000),
      ];

      final fixed = tools.fixOverlaps(segs);
      expect(fixed.length, equals(3));
      expect(fixed[0].endMicros, equals(3000000));
      expect(fixed[1].startMicros, equals(3000000));
      expect(fixed[1].endMicros, equals(5000000));
      expect(fixed[2].startMicros, equals(6000000));
    });

    test('snapTime', () {
      final List<NleCaptionSegment> segs = [
        baseSegment.copyWith(id: 's1', startMicros: 1000000, endMicros: 3000000),
        baseSegment.copyWith(id: 's2', startMicros: 3200000, endMicros: 5000000),
      ];

      // Snap to previous caption end (previous end = 3000000)
      final snappedPrev = tools.snapTime(
        timeMicros: 3100000, // 3.1s is within 150ms of 3.0s
        mode: NleCaptionSnapMode.toPreviousCaptionEnd,
        segments: segs,
        activeSegmentId: 's2',
      );
      expect(snappedPrev, equals(3000000));

      // Snap to next caption start (next start = 3200000)
      final snappedNext = tools.snapTime(
        timeMicros: 3100000, // 3.1s is within 150ms of 3.2s
        mode: NleCaptionSnapMode.toNextCaptionStart,
        segments: segs,
        activeSegmentId: 's1',
      );
      expect(snappedNext, equals(3200000));

      // Snap to timeline playhead
      final snappedPlayhead = tools.snapTime(
        timeMicros: 2050000,
        mode: NleCaptionSnapMode.toTimelinePlayhead,
        segments: segs,
        activeSegmentId: 's1',
        playheadMicros: 2000000,
      );
      expect(snappedPlayhead, equals(2000000));
    });
  });

  group('Caption DB Repository Integration Tests', () {
    late AppDatabase db;
    late CaptionRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = CaptionRepository(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Create, Upsert, Get, Delete Subtitle Tracks & Caption Segments', () async {
      const projectId = 'proj_1';

      await db.into(db.projects).insert(
        ProjectsCompanion.insert(
          id: projectId,
          name: 'Test Project',
        ),
      );

      final trackId = await repository.createTrack(
        projectId: projectId,
        name: 'English Subtitles',
        langCode: 'en',
      );

      final tracks = await repository.getTracks(projectId);
      expect(tracks.length, equals(1));
      expect(tracks[0].id, equals(trackId));
      expect(tracks[0].name, equals('English Subtitles'));

      final track = await repository.getTrack(trackId);
      expect(track.id, equals(trackId));

      final segId = await repository.createSegment(
        projectId: projectId,
        trackId: trackId,
        startMicros: 1000000,
        endMicros: 3000000,
        text: 'Hello DB Subtitle',
      );

      final reloadedTrack = await repository.getTrack(trackId);
      expect(reloadedTrack.segments.length, equals(1));
      expect(reloadedTrack.segments[0].id, equals(segId));
      expect(reloadedTrack.segments[0].text, equals('Hello DB Subtitle'));

      // Test Import SRT
      const srtSource = '''1
00:00:04,000 --> 00:00:06,000
SRT Imported Text''';

      final importedCount = await repository.importSrt(
        projectId: projectId,
        trackId: trackId,
        source: srtSource,
      );
      expect(importedCount, equals(1));

      final trackAfterImport = await repository.getTrack(trackId);
      expect(trackAfterImport.segments.length, equals(2));

      // Test Export SRT
      final exportedSrt = await repository.exportSrt(trackId);
      expect(exportedSrt, contains('Hello DB Subtitle'));
      expect(exportedSrt, contains('SRT Imported Text'));

      // Test Export WebVTT
      final exportedVtt = await repository.exportWebVtt(trackId);
      expect(exportedVtt, contains('WEBVTT'));
      expect(exportedVtt, contains('Hello DB Subtitle'));
      expect(exportedVtt, contains('SRT Imported Text'));

      // Clean up segment
      await repository.deleteSegment(segId);
      final trackAfterDelSeg = await repository.getTrack(trackId);
      expect(trackAfterDelSeg.segments.length, equals(1));

      // Clean up track
      await repository.deleteTrack(trackId);
      final tracksAfterDelTrack = await repository.getTracks(projectId);
      expect(tracksAfterDelTrack.isEmpty, isTrue);
    });
  });
}
