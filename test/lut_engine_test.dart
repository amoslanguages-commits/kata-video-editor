import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/lut_repository.dart';
import 'package:nle_editor/domain/color_lut/color_lut_models.dart';
import 'package:nle_editor/domain/color_lut/cube_lut_header_parser.dart';

void main() {
  late AppDatabase db;
  late LutRepository repository;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = LutRepository(database: db);
    tempDir = await Directory.systemTemp.createTemp('lut_test');
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  group('LUT Engine Tests', () {
    test('CubeLutHeaderParser parses valid and invalid files', () async {
      // 1. Create a valid mock .cube file
      final validFile = File('${tempDir.path}/valid.cube');
      await validFile.writeAsString('''
# Mock valid LUT
TITLE "Test LUT"
LUT_3D_SIZE 2

0.0 0.0 0.0
1.0 0.0 0.0
0.0 1.0 0.0
1.0 1.0 0.0
0.0 0.0 1.0
1.0 0.0 1.0
0.0 1.0 1.0
1.0 1.0 1.0
''');

      final parser = const CubeLutHeaderParser();
      final header = await parser.parseFile(validFile.path);

      expect(header.valid, isTrue);
      expect(header.title, equals('Test LUT'));
      expect(header.size, equals(2));
      expect(header.dataLineCount, equals(8));

      // 2. Create an invalid mock .cube file (not enough data)
      final invalidFile = File('${tempDir.path}/invalid.cube');
      await invalidFile.writeAsString('''
TITLE "Bad LUT"
LUT_3D_SIZE 4
0.0 0.0 0.0
''');

      final headerBad = await parser.parseFile(invalidFile.path);
      expect(headerBad.valid, isFalse);
      expect(headerBad.error, contains('Not enough LUT data'));
    });

    test('LutRepository imports and applies LUT stack', () async {
      // 1. Import a mock LUT
      final validFile = File('${tempDir.path}/valid.cube');
      await validFile.writeAsString('''
TITLE "Imported LUT"
LUT_3D_SIZE 2
0.0 0.0 0.0
1.0 0.0 0.0
0.0 1.0 0.0
1.0 1.0 0.0
0.0 0.0 1.0
1.0 0.0 1.0
0.0 1.0 1.0
1.0 1.0 1.0
''');

      final imported = await repository.importCubeLut(validFile.path);
      expect(imported.name, equals('Imported LUT'));
      expect(imported.size, equals(2));
      expect(imported.isValid, isTrue);

      // 2. Setup mock clip in DB
      const projectId = 'proj_1';
      const trackId = 'track_1';
      const clipId = 'clip_1';

      await db.insertProject(
        ProjectsCompanion.insert(
          id: projectId,
          name: 'Project 1',
          aspectRatio: const Value('16:9'),
        ),
      );
      await db.insertTrack(
        TracksCompanion.insert(
          id: trackId,
          projectId: projectId,
          name: 'Track 1',
          type: 'video',
        ),
      );
      await db.insertClip(
        ClipsCompanion.insert(
          id: clipId,
          projectId: projectId,
          trackId: trackId,
          clipType: const Value('video'),
          timelineStartMicros: const Value(0),
          timelineEndMicros: const Value(1000000),
        ),
      );

      // 3. Apply LUT to clip
      await repository.applyLutToClip(
        clipId: clipId,
        lutAssetId: imported.id,
        intensity: 0.8,
        domain: NleLutDomain.displayReferred,
      );

      final stack = await repository.getClipLutStack(clipId: clipId);
      expect(stack.layers, hasLength(1));
      expect(stack.layers[0].name, equals('Imported LUT'));
      expect(stack.layers[0].intensity, equals(0.8));
      expect(stack.layers[0].domain, equals(NleLutDomain.displayReferred));

      // 4. Update intensity
      final layerId = stack.layers[0].id;
      await repository.updateLayerIntensity(
        clipId: clipId,
        layerId: layerId,
        intensity: 0.5,
      );

      final updatedStack = await repository.getClipLutStack(clipId: clipId);
      expect(updatedStack.layers[0].intensity, equals(0.5));

      // 5. Remove layer
      await repository.removeLayer(clipId: clipId, layerId: layerId);
      final emptyStack = await repository.getClipLutStack(clipId: clipId);
      expect(emptyStack.layers, isEmpty);
    });
  });
}
