import 'package:flutter_test/flutter_test.dart';

import 'package:nle_editor/domain/timeline/timeline_edit_models.dart';

import 'timeline_test_harness.dart';

void main() {
  late TimelineTestHarness harness;

  setUp(() async {
    harness = await TimelineTestHarness.create();
  });

  tearDown(() async {
    await harness.close();
  });

  test('moveClip updates timing and rejects overlaps', () async {
    await harness.insertClip(id: 'clip_a', start: 0, end: 1000000);
    await harness.insertClip(id: 'clip_b', start: 1400000, end: 2400000);

    await harness.engine.moveClip(
      clipId: 'clip_b',
      targetTrackId: 'track_video',
      targetStartMicros: 1000000,
      options: const TimelineEditOptions(snapping: false),
    );

    final moved = await harness.repository.getClip('clip_b');
    expect(moved!.timelineStartMicros, 1000000);
    expect(moved.timelineEndMicros, 2000000);

    expect(
      () => harness.engine.moveClip(
        clipId: 'clip_b',
        targetTrackId: 'track_video',
        targetStartMicros: 500000,
        options: const TimelineEditOptions(snapping: false),
      ),
      throwsA(isA<TimelineEditException>()),
    );
  });

  test('splitClip creates right side clip with matching source ranges', () async {
    await harness.insertClip(id: 'clip_a', start: 0, end: 2000000, sourceOut: 2000000);

    final result = await harness.engine.splitClip(
      clipId: 'clip_a',
      splitMicros: 750000,
    );

    expect(result.action, 'split_clip');
    expect(result.after, hasLength(2));

    final clips = await harness.repository.getTrackClips('track_video');
    expect(clips, hasLength(2));
    expect(clips.first.timelineEndMicros, 750000);
    expect(clips.first.sourceOutMicros, 750000);
    expect(clips.last.timelineStartMicros, 750000);
    expect(clips.last.sourceInMicros, 750000);
  });

  test('duplicateClip creates independent duplicate after original', () async {
    await harness.insertClip(id: 'clip_a', start: 0, end: 1000000, sourceOut: 1000000);

    final result = await harness.engine.duplicateClip(
      clipId: 'clip_a',
      offsetMicros: 250000,
      options: const TimelineEditOptions(snapping: false),
    );

    expect(result.action, 'duplicate_clip');
    final clips = await harness.repository.getTrackClips('track_video');
    expect(clips, hasLength(2));
    expect(clips.last.id, isNot('clip_a'));
    expect(clips.last.timelineStartMicros, 1250000);
    expect(clips.last.sourceInMicros, 0);
    expect(clips.last.sourceOutMicros, 1000000);
  });
}
