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

  test('slideClip moves middle clip and adjusts neighbors', () async {
    await harness.insertClip(id: 'left', start: 0, end: 1000000);
    await harness.insertClip(id: 'middle', start: 1000000, end: 2000000);
    await harness.insertClip(id: 'right', start: 2000000, end: 3000000);

    await harness.engine.slideClip(clipId: 'middle', deltaMicros: 200000);

    final left = await harness.repository.getClip('left');
    final middle = await harness.repository.getClip('middle');
    final right = await harness.repository.getClip('right');

    expect(left!.timelineEndMicros, 1200000);
    expect(middle!.timelineStartMicros, 1200000);
    expect(middle.timelineEndMicros, 2200000);
    expect(right!.timelineStartMicros, 2200000);
  });
}
