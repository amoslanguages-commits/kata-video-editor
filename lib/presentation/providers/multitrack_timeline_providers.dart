import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/multitrack_timeline_resolver.dart';
import 'package:nle_editor/presentation/controllers/multitrack_timeline_controller.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

MultitrackTrackType parseTrackType(String typeStr) {
  switch (typeStr.toLowerCase()) {
    case 'video':
      return MultitrackTrackType.video;
    case 'overlay':
      return MultitrackTrackType.overlay;
    case 'text':
      return MultitrackTrackType.text;
    case 'adjustment':
      return MultitrackTrackType.adjustment;
    case 'audio':
      return MultitrackTrackType.audio;
    default:
      return MultitrackTrackType.video;
  }
}

MultitrackTrackRole parseTrackRole(String? roleStr) {
  if (roleStr == null) return MultitrackTrackRole.unknown;
  switch (roleStr) {
    case 'mainVideo':
      return MultitrackTrackRole.mainVideo;
    case 'broll':
      return MultitrackTrackRole.broll;
    case 'overlay':
      return MultitrackTrackRole.overlay;
    case 'text':
      return MultitrackTrackRole.text;
    case 'adjustment':
      return MultitrackTrackRole.adjustment;
    case 'voice':
      return MultitrackTrackRole.voice;
    case 'music':
      return MultitrackTrackRole.music;
    case 'sfx':
      return MultitrackTrackRole.sfx;
    default:
      return MultitrackTrackRole.unknown;
  }
}

MultitrackClipType parseClipType(String typeStr) {
  switch (typeStr.toLowerCase()) {
    case 'video':
    case 'media':
      return MultitrackClipType.video;
    case 'image':
      return MultitrackClipType.image;
    case 'audio':
      return MultitrackClipType.audio;
    case 'text':
      return MultitrackClipType.text;
    case 'adjustment':
      return MultitrackClipType.adjustment;
    default:
      return MultitrackClipType.unknown;
  }
}

Color parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF00E5FF);
  try {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return Color(int.parse(cleaned, radix: 16));
  } catch (_) {
    return const Color(0xFF00E5FF);
  }
}

final multitrackTracksProvider =
    Provider.family<AsyncValue<List<MultitrackTrack>>, String>(
        (ref, projectId) {
  final tracksAsync = ref.watch(projectTracksProvider(projectId));
  return tracksAsync.whenData((tracks) {
    return tracks.map((track) {
      return MultitrackTrack(
        id: track.id,
        projectId: track.projectId,
        name: track.name,
        type: parseTrackType(track.type),
        role: parseTrackRole(track.trackRole),
        sortOrder: track.index,
        isMuted: track.isMuted,
        isSolo: track.isSolo,
        isLocked: track.isLocked,
        isHidden: track.isHidden || !track.isVisible,
        height: track.height.toDouble(),
        color: parseColor(track.colorHex ?? track.color),
      );
    }).toList();
  });
});

final multitrackClipsProvider =
    Provider.family<AsyncValue<List<MultitrackClip>>, String>((ref, projectId) {
  final clipsAsync = ref.watch(projectClipsProvider(projectId));
  final selectedClipId =
      ref.watch(editorStateProvider.select((s) => s.selectedClipId));

  return clipsAsync.whenData((clips) {
    return clips.map((clip) {
      return MultitrackClip(
        id: clip.id,
        projectId: clip.projectId,
        trackId: clip.trackId,
        assetId: clip.assetId,
        type: parseClipType(clip.clipType),
        name: clip.textContent ?? 'Clip',
        timelineStartMicros: clip.timelineStartMicros,
        timelineEndMicros: clip.timelineEndMicros,
        sourceStartMicros: clip.sourceInMicros,
        sourceEndMicros: clip.sourceOutMicros,
        speed: clip.speed,
        opacity: clip.opacity,
        positionX: clip.positionX,
        positionY: clip.positionY,
        scale: clip.scale,
        rotation: clip.rotation,
        textContent: clip.textContent,
        isSelected: clip.id == selectedClipId,
        isDisabled: clip.isDisabled,
      );
    }).toList();
  });
});

final multitrackTimelineControllerProvider = StateNotifierProvider<
    MultitrackTimelineController, MultitrackTimelineUiState>((ref) {
  final controller = MultitrackTimelineController();

  ref.listen<int>(
    editorStateProvider.select((s) => s.currentTimeMicros),
    (previous, next) {
      controller.setPlayheadMicros(next);
    },
    fireImmediately: true,
  );

  // Sync selected clip and track from editor state
  ref.listen<String?>(
    editorStateProvider.select((s) => s.selectedClipId),
    (previous, next) {
      if (next == null) {
        controller.clearSelection();
      } else {
        controller.selectClip(next);
      }
    },
    fireImmediately: true,
  );

  ref.listen<String?>(
    editorStateProvider.select((s) => s.selectedTrackId),
    (previous, next) {
      if (next != null) {
        controller.selectTrack(next);
      }
    },
    fireImmediately: true,
  );

  return controller;
});

final resolvedTimelineFrameProvider =
    Provider.family<ResolvedTimelineFrame?, String>((ref, projectId) {
  final tracksAsync = ref.watch(multitrackTracksProvider(projectId));
  final clipsAsync = ref.watch(multitrackClipsProvider(projectId));
  final uiState = ref.watch(multitrackTimelineControllerProvider);

  final tracks = tracksAsync.value;
  final clips = clipsAsync.value;

  if (tracks == null || clips == null) return null;

  const resolver = MultitrackTimelineResolver();
  return resolver.resolveAt(
    timelineTimeMicros: uiState.playheadMicros,
    tracks: tracks,
    clips: clips,
  );
});
