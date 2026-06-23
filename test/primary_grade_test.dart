import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/film_look_repository.dart';
import 'package:nle_editor/data/repositories/primary_grade_repository.dart';
import 'package:nle_editor/data/repositories/lut_repository.dart';
import 'package:nle_editor/data/repositories/multitrack_timeline_repository.dart';
import 'package:nle_editor/data/repositories/color_curve_repository.dart';
import 'package:nle_editor/data/repositories/secondary_grade_repository.dart';
import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';
import 'package:nle_editor/domain/rendering/multitrack_render_graph_service.dart';
import 'package:nle_editor/data/repositories/hdr_output_repository.dart';

void main() {
  late AppDatabase db;
  late PrimaryGradeRepository primaryGradeRepository;
  late LutRepository lutRepository;
  late MultitrackTimelineRepository timelineRepository;
  late MultitrackRenderGraphService renderGraphService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    primaryGradeRepository = PrimaryGradeRepository(database: db);
    lutRepository = LutRepository(database: db);
    timelineRepository = MultitrackTimelineRepository(database: db);
    final colorCurveRepository = ColorCurveRepository(database: db);
    final secondaryGradeRepository = SecondaryGradeRepository(database: db);
    final filmLookRepository = FilmLookRepository(database: db);
    final hdrOutputRepository = HdrOutputRepository(database: db);
    renderGraphService = MultitrackRenderGraphService(
      database: db,
      timelineRepository: timelineRepository,
      lutRepository: lutRepository,
      primaryGradeRepository: primaryGradeRepository,
      colorCurveRepository: colorCurveRepository,
      secondaryGradeRepository: secondaryGradeRepository,
      filmLookRepository: filmLookRepository,
      hdrOutputRepository: hdrOutputRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('NlePrimaryGrade Models', () {
    test('identity is correct', () {
      const identity = NlePrimaryGrade.identity();
      expect(identity.enabled, isTrue);
      expect(identity.mode, equals(NlePrimaryGradeMode.linear));
      expect(identity.intensity, equals(1.0));
      expect(identity.lift.master, equals(0.0));
      expect(identity.lift.rgb.r, equals(0.0));
      expect(identity.gamma.master, equals(1.0));
      expect(identity.gamma.rgb.g, equals(1.0));
      expect(identity.gain.master, equals(1.0));
      expect(identity.gain.rgb.b, equals(1.0));
      expect(identity.offset.master, equals(0.0));
      expect(identity.offset.rgb.r, equals(0.0));
      expect(identity.contrast, equals(1.0));
      expect(identity.pivot, equals(0.18));
      expect(identity.saturation, equals(1.0));
      expect(identity.isIdentity, isTrue);
    });

    test('toJson/fromJson serialization works', () {
      const custom = NlePrimaryGrade(
        enabled: false,
        mode: NlePrimaryGradeMode.log,
        intensity: 0.75,
        lift: NlePrimaryWheelControl(
          master: -0.1,
          rgb: NleRgbVector(r: -0.05, g: 0.02, b: 0.1),
        ),
        gamma: NlePrimaryWheelControl(
          master: 1.2,
          rgb: NleRgbVector(r: 1.1, g: 0.95, b: 1.05),
        ),
        gain: NlePrimaryWheelControl(
          master: 0.9,
          rgb: NleRgbVector(r: 0.85, g: 0.92, b: 1.0),
        ),
        offset: NlePrimaryWheelControl(
          master: 0.05,
          rgb: NleRgbVector(r: 0.02, g: -0.01, b: 0.04),
        ),
        contrast: 1.15,
        pivot: 0.22,
        saturation: 1.25,
      );

      expect(custom.isIdentity, isFalse);

      final json = custom.toJson();
      final parsed = NlePrimaryGrade.fromJson(json);

      expect(parsed, equals(custom));
      expect(parsed.enabled, isFalse);
      expect(parsed.mode, equals(NlePrimaryGradeMode.log));
      expect(parsed.intensity, equals(0.75));
      expect(parsed.lift.master, equals(-0.1));
      expect(parsed.lift.rgb.r, equals(-0.05));
      expect(parsed.lift.rgb.g, equals(0.02));
      expect(parsed.lift.rgb.b, equals(0.1));
      expect(parsed.contrast, equals(1.15));
      expect(parsed.pivot, equals(0.22));
      expect(parsed.saturation, equals(1.25));
    });
  });

  group('PrimaryGradeRepository & Database Tests', () {
    const projectId = 'proj_color_1';
    const trackId = 'track_color_1';
    const clipId = 'clip_color_1';

    setUp(() async {
      await db.insertProject(
        ProjectsCompanion.insert(
          id: projectId,
          name: 'Color Project',
          aspectRatio: const Value('16:9'),
        ),
      );
      await db.insertTrack(
        TracksCompanion.insert(
          id: trackId,
          projectId: projectId,
          name: 'Video Track',
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
          timelineEndMicros: const Value(2000000),
        ),
      );
    });

    test('getPrimaryGrade on fresh clip returns identity', () async {
      final grade = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(grade.isIdentity, isTrue);
    });

    test('savePrimaryGrade persists configuration', () async {
      const custom = NlePrimaryGrade(
        enabled: true,
        mode: NlePrimaryGradeMode.linear,
        intensity: 0.9,
        lift: NlePrimaryWheelControl(
          master: 0.05,
          rgb: NleRgbVector(r: 0.02, g: 0.01, b: 0.03),
        ),
        gamma: NlePrimaryWheelControl.one(),
        gain: NlePrimaryWheelControl.one(),
        offset: NlePrimaryWheelControl.zero(),
        contrast: 1.05,
        pivot: 0.18,
        saturation: 1.1,
      );

      await primaryGradeRepository.savePrimaryGrade(clipId: clipId, grade: custom);

      final retrieved = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(retrieved, equals(custom));
      expect(retrieved.isIdentity, isFalse);
    });

    test('resetPrimaryGrade reverts config to identity', () async {
      const custom = NlePrimaryGrade(
        enabled: true,
        mode: NlePrimaryGradeMode.log,
        intensity: 0.5,
        lift: NlePrimaryWheelControl.zero(),
        gamma: NlePrimaryWheelControl.one(),
        gain: NlePrimaryWheelControl.one(),
        offset: NlePrimaryWheelControl.zero(),
        contrast: 1.5,
        pivot: 0.3,
        saturation: 0.8,
      );

      await primaryGradeRepository.savePrimaryGrade(clipId: clipId, grade: custom);
      var retrieved = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(retrieved.isIdentity, isFalse);

      await primaryGradeRepository.resetPrimaryGrade(clipId);
      retrieved = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(retrieved.isIdentity, isTrue);
    });

    test('individual update functions mutate state correctly', () async {
      // 1. setEnabled
      await primaryGradeRepository.setEnabled(clipId: clipId, enabled: false);
      var grade = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(grade.enabled, isFalse);

      // 2. setMode
      await primaryGradeRepository.setMode(clipId: clipId, mode: NlePrimaryGradeMode.log);
      grade = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(grade.mode, equals(NlePrimaryGradeMode.log));

      // 3. updateLift
      const newLift = NlePrimaryWheelControl(master: 0.1, rgb: NleRgbVector(r: 0.05, g: 0.06, b: 0.07));
      await primaryGradeRepository.updateLift(clipId: clipId, lift: newLift);
      grade = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(grade.lift, equals(newLift));

      // 4. updateGamma
      const newGamma = NlePrimaryWheelControl(master: 0.9, rgb: NleRgbVector(r: 0.8, g: 0.9, b: 1.0));
      await primaryGradeRepository.updateGamma(clipId: clipId, gamma: newGamma);
      grade = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(grade.gamma, equals(newGamma));

      // 5. updateGain
      const newGain = NlePrimaryWheelControl(master: 1.1, rgb: NleRgbVector(r: 1.0, g: 1.1, b: 1.2));
      await primaryGradeRepository.updateGain(clipId: clipId, gain: newGain);
      grade = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(grade.gain, equals(newGain));

      // 6. updateOffset
      const newOffset = NlePrimaryWheelControl(master: -0.05, rgb: NleRgbVector(r: -0.02, g: -0.03, b: -0.04));
      await primaryGradeRepository.updateOffset(clipId: clipId, offset: newOffset);
      grade = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(grade.offset, equals(newOffset));

      // 7. updateBasic
      await primaryGradeRepository.updateBasic(
        clipId: clipId,
        intensity: 0.8,
        contrast: 1.2,
        pivot: 0.25,
        saturation: 1.3,
      );
      grade = await primaryGradeRepository.getPrimaryGrade(clipId);
      expect(grade.intensity, equals(0.8));
      expect(grade.contrast, equals(1.2));
      expect(grade.pivot, equals(0.25));
      expect(grade.saturation, equals(1.3));
    });
  });

  group('MultitrackRenderGraphService Serialization Integration', () {
    const projectId = 'proj_graph_1';
    const trackId = 'track_graph_1';
    const clipId = 'clip_graph_1';

    setUp(() async {
      await db.insertProject(
        ProjectsCompanion.insert(
          id: projectId,
          name: 'RenderGraph Project',
          aspectRatio: const Value('16:9'),
        ),
      );
      await db.insertTrack(
        TracksCompanion.insert(
          id: trackId,
          projectId: projectId,
          name: 'Video Track',
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
          timelineEndMicros: const Value(3000000),
        ),
      );
    });

    test('serializes default clip with identity primaryGrade and hint false', () async {
      final graph = await renderGraphService.buildGraph(projectId);
      expect(graph.exportHints.containsPrimaryGrades, isFalse);

      final trackDto = graph.tracks.firstWhere((t) => t.id == trackId);
      final clipDto = trackDto.clips.firstWhere((c) => c.id == clipId);

      expect(clipDto.primaryGrade, isNotNull);
      expect(clipDto.primaryGrade!.grade.isIdentity, isTrue);
    });

    test('serializes custom clip with custom primaryGrade and hint true', () async {
      const custom = NlePrimaryGrade(
        enabled: true,
        mode: NlePrimaryGradeMode.log,
        intensity: 0.95,
        lift: NlePrimaryWheelControl(
          master: 0.1,
          rgb: NleRgbVector(r: 0.05, g: 0.06, b: 0.07),
        ),
        gamma: NlePrimaryWheelControl.one(),
        gain: NlePrimaryWheelControl.one(),
        offset: NlePrimaryWheelControl.zero(),
        contrast: 1.15,
        pivot: 0.2,
        saturation: 1.25,
      );

      await primaryGradeRepository.savePrimaryGrade(clipId: clipId, grade: custom);

      final graph = await renderGraphService.buildGraph(projectId);
      expect(graph.exportHints.containsPrimaryGrades, isTrue);

      final trackDto = graph.tracks.firstWhere((t) => t.id == trackId);
      final clipDto = trackDto.clips.firstWhere((c) => c.id == clipId);

      expect(clipDto.primaryGrade, isNotNull);
      expect(clipDto.primaryGrade!.grade.mode, equals(NlePrimaryGradeMode.log));
      expect(clipDto.primaryGrade!.grade.contrast, equals(1.15));
      expect(clipDto.primaryGrade!.grade.lift.master, equals(0.1));
      expect(clipDto.primaryGrade!.grade.lift.rgb.g, equals(0.06));

      // Check full JSON serialization:
      final jsonMap = graph.toJson();
      final tracksList = jsonMap['tracks'] as List;
      final firstTrack = tracksList[0] as Map;
      final clipsList = firstTrack['clips'] as List;
      final firstClip = clipsList[0] as Map;
      final primaryGradeMap = firstClip['primaryGrade'] as Map;

      expect(primaryGradeMap['mode'], equals('log'));
      expect(primaryGradeMap['contrast'], equals(1.15));
      expect(primaryGradeMap['lift']['master'], equals(0.1));
      expect(primaryGradeMap['lift']['rgb']['g'], equals(0.06));
    });
  });
}
