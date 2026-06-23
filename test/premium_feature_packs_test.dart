import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:nle_editor/data/database/app_database.dart';
import 'package:nle_editor/data/repositories/creative_pack_repository.dart';
import 'package:nle_editor/data/repositories/timeline_repository.dart';
import 'package:nle_editor/data/repositories/transition_repository.dart';
import 'package:nle_editor/domain/premium/creative_preset_apply_service.dart';
import 'package:nle_editor/domain/premium/creative_pack.dart';
import 'package:nle_editor/domain/premium/entitlement_state.dart';
import 'package:nle_editor/domain/premium/premium_feature.dart';
import 'package:nle_editor/domain/premium/user_creative_preset.dart';

void main() {
  late AppDatabase db;
  late CreativePackRepository creativePackRepository;
  late TimelineRepository timelineRepository;
  late TransitionRepository transitionRepository;
  late CreativePresetApplyService applyService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    creativePackRepository = CreativePackRepository(db: db);
    timelineRepository = TimelineRepository(db);
    transitionRepository = TransitionRepository(db);
    applyService = CreativePresetApplyService(
      timelineRepository: timelineRepository,
      transitionRepository: transitionRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('EntitlementState Tests', () {
    test('free plan has correct access', () {
      final state = EntitlementState.free();
      expect(state.isPro, isFalse);
      expect(state.hasFeature(PremiumFeatureId.proExport1080p),
          isTrue); // not pro-only
      expect(state.hasFeature(PremiumFeatureId.proExport4k), isFalse);
      expect(state.hasFeature(PremiumFeatureId.premiumTransitions), isFalse);
    });

    test('proLocalDev plan has correct access', () {
      final state = EntitlementState.proLocalDev();
      expect(state.isPro, isTrue);
      expect(state.hasFeature(PremiumFeatureId.proExport4k), isTrue);
      expect(state.hasFeature(PremiumFeatureId.premiumTransitions), isTrue);
    });

    test('free plan with specific unlocked feature has access', () {
      final state = EntitlementState.free().copyWith(
        unlockedFeatureIds: {PremiumFeatureId.premiumTransitions},
      );
      expect(state.isPro, isFalse);
      expect(state.hasFeature(PremiumFeatureId.premiumTransitions), isTrue);
      expect(state.hasFeature(PremiumFeatureId.proExport4k), isFalse);
    });
  });

  group('Built-in Packs Tests', () {
    test('getBuiltInPacks loads predefined packs', () async {
      final packs = await creativePackRepository.getBuiltInPacks();
      expect(packs, isNotEmpty);
      expect(packs.any((p) => p.type == CreativePackType.color), isTrue);
      expect(packs.any((p) => p.type == CreativePackType.effects), isTrue);
      expect(packs.any((p) => p.type == CreativePackType.transitions), isTrue);
    });

    test('getPacksByType filters packs', () async {
      final colorPacks =
          await creativePackRepository.getPacksByType(CreativePackType.color);
      expect(colorPacks.every((p) => p.type == CreativePackType.color), isTrue);
    });
  });

  group('CreativePresetApplyService Tests', () {
    test('applyToClip fails or locks appropriately based on entitlement',
        () async {
      // Setup DB records for repository update to succeed
      await db.into(db.projects).insert(
          ProjectsCompanion.insert(id: 'project_1', name: 'Test Project'));
      await db.into(db.tracks).insert(TracksCompanion.insert(
          id: 'track_1',
          projectId: 'project_1',
          name: 'Track 1',
          type: 'video'));
      await db.into(db.clips).insert(ClipsCompanion.insert(
            id: 'clip_1',
            projectId: 'project_1',
            trackId: 'track_1',
            clipType: const Value('media'),
          ));

      final clip = await timelineRepository.getClip('clip_1');
      expect(clip, isNotNull);

      final premiumItem = CreativePackItem(
        id: 'item_cinematic',
        packId: 'pack_1',
        type: CreativePackItemType.colorPreset,
        title: 'Cinematic Color',
        description: 'Pro color grading preset',
        proOnly: true,
        requiredFeatureId: PremiumFeatureId.premiumColorPresets,
        payload: const {'contrast': 1.2, 'saturation': 1.1},
      );

      final freeEntitlement = EntitlementState.free();
      final resultLocked = await applyService.applyToClip(
        item: premiumItem,
        clip: clip!,
        entitlement: freeEntitlement,
      );
      expect(resultLocked.locked, isTrue);
      expect(resultLocked.success, isFalse);

      final proEntitlement = EntitlementState.proLocalDev();
      final resultOk = await applyService.applyToClip(
        item: premiumItem,
        clip: clip,
        entitlement: proEntitlement,
      );
      expect(resultOk.success, isTrue);

      final updatedClip = await db.getClip('clip_1');
      expect(updatedClip?.contrast, equals(1.2));
      expect(updatedClip?.saturation, equals(1.1));
    });

    test('applyTransition updates DB correctly', () async {
      final transitionItem = CreativePackItem(
        id: 'trans_whip',
        packId: 'pack_transitions',
        type: CreativePackItemType.transitionPreset,
        title: 'Whip Pan',
        description: 'Pro whip pan transition',
        proOnly: true,
        requiredFeatureId: PremiumFeatureId.premiumTransitions,
        payload: const {
          'transitionType': 'whip_pan',
          'durationMicros': 300000,
          'direction': 'left',
          'easing': 'smooth_step'
        },
      );

      await db.into(db.projects).insert(
          ProjectsCompanion.insert(id: 'project_1', name: 'Test Project'));
      await db.into(db.tracks).insert(TracksCompanion.insert(
          id: 'track_1',
          projectId: 'project_1',
          name: 'Track 1',
          type: 'video'));
      await db.into(db.clips).insert(ClipsCompanion.insert(
          id: 'clip_1',
          projectId: 'project_1',
          trackId: 'track_1',
          clipType: const Value('media')));
      await db.into(db.clips).insert(ClipsCompanion.insert(
          id: 'clip_2',
          projectId: 'project_1',
          trackId: 'track_1',
          clipType: const Value('media')));

      await db.into(db.clipTransitions).insert(ClipTransitionsCompanion.insert(
            id: 'trans_1',
            projectId: 'project_1',
            outgoingClipId: 'clip_1',
            incomingClipId: 'clip_2',
          ));

      final result = await applyService.applyTransition(
        item: transitionItem,
        transitionId: 'trans_1',
        entitlement: EntitlementState.proLocalDev(),
      );

      expect(result.success, isTrue);

      final updatedTrans = await (db.select(db.clipTransitions)
            ..where((t) => t.id.equals('trans_1')))
          .getSingle();
      expect(updatedTrans.transitionType, equals('whip_pan'));
      expect(updatedTrans.durationMicros, equals(300000));
      expect(updatedTrans.direction, equals('left'));
      expect(updatedTrans.easing, equals('smooth_step'));
    });
  });

  group('User presets CRUD Database Tests', () {
    test('save, watch, delete custom user presets', () async {
      final preset = UserCreativePreset.create(
        name: 'My Custom Filter',
        type: CreativePackItemType.effectPreset,
        sourceItemId: 'clip_1',
        payload: const {'exposure': 0.1, 'contrast': 1.1},
      );

      await creativePackRepository.saveUserPreset(preset);

      final presets = await creativePackRepository
          .watchUserPresets(CreativePackItemType.effectPreset)
          .first;
      expect(presets.length, equals(1));
      expect(presets.first.id, equals(preset.id));
      expect(presets.first.name, equals('My Custom Filter'));
      expect(presets.first.payload['exposure'], equals(0.1));

      await creativePackRepository.deleteUserPreset(preset.id);

      final presetsAfterDelete = await creativePackRepository
          .watchUserPresets(CreativePackItemType.effectPreset)
          .first;
      expect(presetsAfterDelete.isEmpty, isTrue);
    });
  });
}
