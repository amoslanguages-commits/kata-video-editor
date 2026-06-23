// 33A-PRO: Audio Engine Foundation — Riverpod Providers

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/repositories/audio_repository.dart';
import 'package:nle_editor/domain/audio/nle_audio_model.dart';
import 'package:nle_editor/domain/audio/audio_graph_service.dart';
import 'package:nle_editor/domain/audio/nle_audio_meter.dart';
import 'package:nle_editor/platform/audio/native_audio_engine_service.dart';
import 'package:nle_editor/presentation/controllers/audio_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  return AudioRepository(database: ref.watch(databaseProvider));
});

// ── Domain Services ───────────────────────────────────────────────────────────

final audioGraphServiceProvider = Provider<AudioGraphService>((ref) {
  return AudioGraphService(database: ref.watch(databaseProvider));
});

final nativeAudioEngineServiceProvider =
    Provider<NativeAudioEngineService>((ref) {
  return NativeAudioEngineService(bridge: ref.watch(nativeBridgeProvider));
});

// ── Controller ────────────────────────────────────────────────────────────────

final audioControllerProvider = StateNotifierProvider.family<
    AudioController, AudioTimelineState, String>(
  (ref, projectId) {
    final controller = AudioController(
      projectId:   projectId,
      repository:  ref.watch(audioRepositoryProvider),
      graphService: ref.watch(audioGraphServiceProvider),
      nativeAudio: ref.watch(nativeAudioEngineServiceProvider),
      ref:         ref,
    );
    return controller;
  },
);

// ── Data Streams ──────────────────────────────────────────────────────────────

/// All audio tracks for a project, watched reactively.
final projectAudioTracksProvider =
    StreamProvider.family<List<db.Track>, String>((ref, projectId) {
  return ref.watch(audioRepositoryProvider).watchAudioTracks(projectId);
});

/// Waveform cache entry for an asset, watched reactively.
final assetWaveformCacheProvider =
    StreamProvider.family<db.AudioWaveformCache?, String>((ref, assetId) {
  return ref.watch(audioRepositoryProvider).watchWaveformCache(assetId);
});

/// The computed NleAudioGraph for a project (async, rebuild on demand).
final projectAudioGraphProvider =
    FutureProvider.family<NleAudioGraph, String>((ref, projectId) async {
  // Invalidated by controller after structural changes.
  return ref.watch(audioGraphServiceProvider).buildGraph(projectId);
});

// ── Audio Meter ───────────────────────────────────────────────────────────────

/// Exposes the latest meter reading for a project, derived from native events.
final audioMeterProvider =
    StreamProvider.family<NleAudioMeterState, String>((ref, projectId) {
  final bridge = ref.watch(nativeBridgeProvider);
  return bridge.events
      .where((e) => e.type == NleAudioEventTypes.meterUpdate)
      .where((e) => e.projectId == projectId || e.projectId == null)
      .map((event) {
    try {
      final reading = NleAudioMeterReading.fromJson(
        Map<String, dynamic>.from(event.payload),
      );
      return NleAudioMeterState(reading: reading, isActive: true);
    } catch (_) {
      return NleAudioMeterState.idle(projectId);
    }
  });
});

/// Whether audio meter collection is currently active for [projectId].
final isMeterActiveProvider =
    StateProvider.family<bool, String>((ref, projectId) => false);

// Note: autoDuckingProvider is defined in editor_providers.dart
// and imported by audio_tracks_view.dart from there.
