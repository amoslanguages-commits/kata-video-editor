import 'package:flutter_test/flutter_test.dart';

import 'timeline_test_harness.dart';

void main() {
  late TimelineTestHarness harness;

  setUp(() async {
    harness = await TimelineTestHarness.create();
  });

  tearDown(() async {
    await harness.close();
  });

  test('slipClip changes source range without moving timeline range', () async {
    await harness.insertClip(
      id: 'clip_a',
      start: 0,
      end: 1000000,
      sourceIn: 100000,
      sourceOut: 1100000,
    );

    await harness.engine.slipClip(clipId: 'clip_a', deltaMicros: 200000);

    final clip = await harness.repository.getClip('clip_a');
    expect(clip!.timelineStartMicros, 0);
    expect(clip.timelineEndMicros, 1000000);
    expect(clip.sourceInMicros, 300000);
    expect(clip.sourceOutMicros, 1300000);
  });
}
