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

  test('rollEdit moves adjacent edit point and updates source ranges', () async {
    await harness.insertClip(
      id: 'left',
      start: 0,
      end: 1000000,
      sourceIn: 0,
      sourceOut: 1000000,
    );
    await harness.insertClip(
      id: 'right',
      start: 1000000,
      end: 2000000,
      sourceIn: 1000000,
      sourceOut: 2000000,
    );

    await harness.engine.rollEdit(
      leftClipId: 'left',
      rightClipId: 'right',
      deltaMicros: 250000,
    );

    final left = await harness.repository.getClip('left');
    final right = await harness.repository.getClip('right');

    expect(left!.timelineEndMicros, 1250000);
    expect(left.sourceOutMicros, 1250000);
    expect(right!.timelineStartMicros, 1250000);
    expect(right.sourceInMicros, 1250000);
  });
}
