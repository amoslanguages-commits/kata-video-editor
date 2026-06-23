import 'package:flutter_test/flutter_test.dart';

import 'package:nle_editor/domain/timeline/timeline_diagnostics_service.dart';

import 'timeline_test_harness.dart';

void main() {
  late TimelineTestHarness harness;

  setUp(() async {
    harness = await TimelineTestHarness.create();
  });

  tearDown(() async {
    await harness.close();
  });

  test('repairProject fixes invalid timeline integrity issues', () async {
    await harness.insertClip(id: 'invalid_duration', start: 2000000, end: 1000000, sourceOut: -1);
    await harness.insertClip(id: 'invalid_speed', start: -500000, end: 500000, speed: 0);
    await harness.insertClip(id: 'overlap_a', start: 3000000, end: 4000000);
    await harness.insertClip(id: 'overlap_b', start: 3500000, end: 4500000);

    final service = TimelineDiagnosticsService(repository: harness.repository);
    final before = await service.inspectProject('project_1');
    expect(before.hasErrors, true);

    final repaired = await service.repairProject('project_1');
    expect(repaired.repairs, isNotEmpty);

    final after = await service.inspectProject('project_1');
    expect(after.hasErrors, false);
  });
}
