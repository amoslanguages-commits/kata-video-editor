import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';
import 'package:nle_editor/domain/color_curves/color_curve_models.dart';
import 'package:nle_editor/domain/color_lut/color_lut_models.dart';
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';
import 'package:nle_editor/domain/film_look/film_look_models.dart';
import 'package:nle_editor/domain/rendering/render_graph_contract.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_film_look_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_lut_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_primary_grade_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_color_curves_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_secondary_grade_dto.dart';
import 'package:nle_editor/domain/timeline/multitrack_models.dart';
import 'package:nle_editor/domain/timeline/multitrack_timeline_view_model.dart';
import 'package:nle_editor/domain/color_output/hdr_output_models.dart';

class MultitrackRenderGraphMapper {
  const MultitrackRenderGraphMapper();

  List<RenderGraphTrackDto> mapTracks(
    MultitrackTimelineViewModel timeline, {
    bool autoDuckingEnabled = false,
    Map<String, NleClipLutStack> clipLutStacks = const {},
    Map<String, NlePrimaryGrade> clipPrimaryGrades = const {},
    Map<String, NleColorCurveStack> clipColorCurves = const {},
    Map<String, NleSecondaryGradeStack> clipSecondaryGrades = const {},
    Map<String, NleFilmLookSettings> clipFilmLooks = const {},
    Map<String, Map<String, dynamic>?> clipEffectChains = const {},
    Map<String, Map<String, dynamic>?> trackEffectChains = const {},
  }) {
    final visualTracks = timeline.tracks
        .where((track) => track.isVisual)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final audioTracks = timeline.tracks
        .where((track) => track.isAudio)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final result = <RenderGraphTrackDto>[];

    for (var i = 0; i < visualTracks.length; i++) {
      final track = visualTracks[i];
      result.add(
        _mapTrack(
          timeline: timeline,
          track: track,
          layerOrder: i,
          autoDuckingEnabled: autoDuckingEnabled,
          clipLutStacks: clipLutStacks,
          clipPrimaryGrades: clipPrimaryGrades,
          clipColorCurves: clipColorCurves,
          clipSecondaryGrades: clipSecondaryGrades,
          clipFilmLooks: clipFilmLooks,
          clipEffectChains: clipEffectChains,
          trackEffectChains: trackEffectChains,
        ),
      );
    }

    for (var i = 0; i < audioTracks.length; i++) {
      final track = audioTracks[i];
      result.add(
        _mapTrack(
          timeline: timeline,
          track: track,
          layerOrder: i,
          autoDuckingEnabled: autoDuckingEnabled,
          clipLutStacks: clipLutStacks,
          clipPrimaryGrades: clipPrimaryGrades,
          clipColorCurves: clipColorCurves,
          clipSecondaryGrades: clipSecondaryGrades,
          clipFilmLooks: clipFilmLooks,
          clipEffectChains: clipEffectChains,
          trackEffectChains: trackEffectChains,
        ),
      );
    }

    return result;
  }

  RenderGraphCompositionDto mapComposition(
    MultitrackTimelineViewModel timeline,
  ) {
    final visualTracks = timeline.tracks
        .where((track) => track.isVisual)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final audioTracks = timeline.tracks
        .where((track) => track.isAudio)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final hasSoloAudio = audioTracks.any((track) => track.isSolo);

    final enabledAudioTracks = audioTracks.where((track) {
      if (track.isMuted) return false;
      if (hasSoloAudio && !track.isSolo) return false;
      return true;
    }).toList();

    final enabledVisualTracks = visualTracks.where((track) {
      if (track.isHidden) return false;
      if (track.isMuted) return false;
      return true;
    }).toList();

    int durationMicros = 0;
    for (final clip in timeline.clips) {
      if (clip.timelineEndMicros > durationMicros) {
        durationMicros = clip.timelineEndMicros;
      }
    }

    return RenderGraphCompositionDto(
      durationMicros: durationMicros,
      videoTrackCount: visualTracks.where((t) => t.type == MultitrackTrackType.video).length,
      audioTrackCount: audioTracks.length,
      clipCount: timeline.clips.length,
      hasOverlays: visualTracks.any((t) => t.type == MultitrackTrackType.overlay),
      hasText: visualTracks.any((t) => t.type == MultitrackTrackType.text),
      hasAudio: audioTracks.isNotEmpty,
    );
  }

  RenderGraphAudioMixDto mapAudioMix(
    MultitrackTimelineViewModel timeline, {
    Map<String, dynamic>? masterEffectChain,
  }) {
    final audioTracks = timeline.tracks
        .where((track) => track.isAudio)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final hasSoloAudio = audioTracks.any((track) => track.isSolo);

    final soloTrackIds = audioTracks
        .where((track) => track.isSolo)
        .map((track) => track.id)
        .toList();

    final mutedTrackIds = audioTracks
        .where((track) => track.isMuted)
        .map((track) => track.id)
        .toList();

    final activeTrackIds = audioTracks.where((track) {
      if (track.isMuted) return false;
      if (hasSoloAudio && !track.isSolo) return false;
      return true;
    }).map((track) {
      return track.id;
    }).toList();

    return RenderGraphAudioMixDto(
      enabled: true, // Always enabled so visual tracks with embedded audio are processed
      hasSoloAudio: hasSoloAudio,
      soloAudioTrackIds: soloTrackIds,
      mutedAudioTrackIds: mutedTrackIds,
      activeAudioTrackIds: activeTrackIds,
      sampleRate: 48000,
      channels: 2,
      masterEffectChain: masterEffectChain,
    );
  }

  RenderGraphExportHintsDto mapExportHints(
    MultitrackTimelineViewModel timeline, {
    required NleHdrOutputSettings hdrSettings,
    Map<String, NleClipLutStack> clipLutStacks = const {},
    Map<String, NlePrimaryGrade> clipPrimaryGrades = const {},
    Map<String, NleColorCurveStack> clipColorCurves = const {},
    Map<String, NleSecondaryGradeStack> clipSecondaryGrades = const {},
    Map<String, NleFilmLookSettings> clipFilmLooks = const {},
  }) {
    var containsText = false;
    var containsImage = false;
    var containsVideo = false;
    var containsAudio = false;
    var containsAdjustment = false;
    var containsColorAdjustments = false;
    var containsCrop = false;
    var containsSpeedChanges = false;
    var containsFades = false;

    for (final clip in timeline.clips) {
      switch (clip.type) {
        case MultitrackClipType.video:
          containsVideo = true;
          containsAudio = true;
          break;
        case MultitrackClipType.image:
          containsImage = true;
          break;
        case MultitrackClipType.audio:
          containsAudio = true;
          break;
        case MultitrackClipType.text:
          containsText = true;
          break;
        case MultitrackClipType.adjustment:
          containsAdjustment = true;
          break;
        case MultitrackClipType.unknown:
          break;
      }

      if (clip.brightness != 0 || clip.contrast != 1 || clip.saturation != 1) {
        containsColorAdjustments = true;
      }

      if (clip.cropLeft != 0 ||
          clip.cropTop != 0 ||
          clip.cropRight != 0 ||
          clip.cropBottom != 0 ||
          clip.fitMode != RenderGraphFitModes.fit) {
        containsCrop = true;
      }

      if (clip.speed != 1) {
        containsSpeedChanges = true;
      }

      if (clip.fadeInMicros > 0 || clip.fadeOutMicros > 0) {
        containsFades = true;
      }
    }

    final containsLut = clipLutStacks.values.any((stack) => stack.hasEnabledLuts);
    final containsPrimaryGrades = clipPrimaryGrades.values.any((grade) => !grade.isIdentity);
    final containsColorCurves = clipColorCurves.values.any((stack) => !stack.isIdentity);
    final containsSecondaryGrades = clipSecondaryGrades.values.any((stack) => !stack.isIdentity);
    final containsFilmLooks = clipFilmLooks.values.any((s) => !s.isIdentity);

    final isHdrOutput = hdrSettings.colorMode == NleOutputColorMode.rec2020HlgHdr ||
        hdrSettings.colorMode == NleOutputColorMode.rec2020PqHdr;
    final isWideColorOutput = hdrSettings.colorMode == NleOutputColorMode.displayP3Sdr ||
        hdrSettings.colorMode == NleOutputColorMode.rec2020Sdr ||
        isHdrOutput;
    final requiresTenBit = hdrSettings.bitDepth == NleOutputBitDepth.tenBit;

    return RenderGraphExportHintsDto(
      requiresCompositing: containsVideo || containsImage || containsAdjustment || containsCrop || containsSpeedChanges || containsFades,
      requiresAudioMixdown: containsAudio,
      requiresColorPipeline: containsColorAdjustments || containsLut || containsPrimaryGrades || containsColorCurves || containsSecondaryGrades || containsFilmLooks,
      requiresTextLayout: containsText,
      useOriginalForExport: true,
    );
  }



  RenderGraphTrackDto _mapTrack({
    required MultitrackTimelineViewModel timeline,
    required MultitrackTrack track,
    required int layerOrder,
    bool autoDuckingEnabled = false,
    Map<String, NleClipLutStack> clipLutStacks = const {},
    Map<String, NlePrimaryGrade> clipPrimaryGrades = const {},
    Map<String, NleColorCurveStack> clipColorCurves = const {},
    Map<String, NleSecondaryGradeStack> clipSecondaryGrades = const {},
    Map<String, NleFilmLookSettings> clipFilmLooks = const {},
    Map<String, Map<String, dynamic>?> clipEffectChains = const {},
    Map<String, Map<String, dynamic>?> trackEffectChains = const {},
  }) {
    final clips = timeline.clips
        .where((clip) => clip.trackId == track.id)
        .toList()
      ..sort((a, b) => a.timelineStartMicros.compareTo(b.timelineStartMicros));

    return RenderGraphTrackDto(
      id: track.id,
      name: track.name,
      type: _trackType(track),
      trackType: _trackType(track),
      role: _trackRole(track),
      trackRole: _trackRole(track),
      sortOrder: track.sortOrder,
      isMuted: track.isMuted,
      isSolo: track.isSolo,
      isLocked: track.isLocked,
      isHidden: track.isHidden,
      height: track.height,
      colorHex: _colorToHex(track.color),
      isVisual: track.isVisual,
      isAudio: track.isAudio,
      layerOrder: layerOrder,
      effectChain: trackEffectChains[track.id],
      clips: [
        for (var i = 0; i < clips.length; i++)
          _mapClip(
            clip: clips[i],
            zIndex: i,
            timeline: timeline,
            autoDuckingEnabled: autoDuckingEnabled,
            lutStack: clipLutStacks[clips[i].id],
            primaryGrade: clipPrimaryGrades[clips[i].id],
            colorCurveStack: clipColorCurves[clips[i].id],
            secondaryGradeStack: clipSecondaryGrades[clips[i].id],
            filmLook: clipFilmLooks[clips[i].id],
            effectChain: clipEffectChains[clips[i].id],
          ),
      ],
    );
  }

  RenderGraphClipDto _mapClip({
    required MultitrackClip clip,
    required int zIndex,
    required MultitrackTimelineViewModel timeline,
    bool autoDuckingEnabled = false,
    NleClipLutStack? lutStack,
    NlePrimaryGrade? primaryGrade,
    NleColorCurveStack? colorCurveStack,
    NleSecondaryGradeStack? secondaryGradeStack,
    NleFilmLookSettings? filmLook,
    Map<String, dynamic>? effectChain,
  }) {
    double finalVolume = clip.volume;
    if (autoDuckingEnabled && !_isVoiceoverClip(clip, timeline)) {
      final overlapsVoiceover = _overlapsAnyVoiceover(clip, timeline);
      if (overlapsVoiceover) {
        finalVolume = clip.volume * 0.2;
      }
    }

    final lutStackDto = lutStack != null
        ? RenderGraphLutStackDto(
            clipId: clip.id,
            layers: lutStack.layers
                .map((layer) => RenderGraphLutLayerDto(layer: layer))
                .toList(),
          )
        : null;

    final primaryGradeDto = primaryGrade != null
        ? RenderGraphPrimaryGradeDto(grade: primaryGrade)
        : null;

    final colorCurvesDto = colorCurveStack != null
        ? RenderGraphColorCurveStackDto(stack: colorCurveStack)
        : null;

    final secondaryGradesDto = secondaryGradeStack != null
        ? RenderGraphSecondaryGradeStackDto(stack: secondaryGradeStack)
        : null;

    final filmLookDto = filmLook != null
        ? RenderGraphFilmLookDto(settings: filmLook)
        : null;

    return RenderGraphClipDto(
      id: clip.id,
      projectId: clip.projectId,
      trackId: clip.trackId,
      assetId: clip.assetId,
      type: _clipType(clip),
      clipType: _clipType(clip),
      name: clip.name,
      timelineStartMicros: clip.timelineStartMicros,
      timelineEndMicros: clip.timelineEndMicros,
      sourceStartMicros: clip.sourceStartMicros,
      sourceEndMicros: clip.sourceEndMicros,
      speed: clip.speed,
      transform: RenderGraphTransformDto(
        positionX: clip.positionX,
        positionY: clip.positionY,
        scale: clip.scale,
        rotation: clip.rotation,
        opacity: clip.opacity,
      ),
      crop: RenderGraphCropDto(
        fitMode: _safeFitMode(clip.fitMode),
        left: clip.cropLeft,
        top: clip.cropTop,
        right: clip.cropRight,
        bottom: clip.cropBottom,
      ),
      color: RenderGraphColorDto(
        brightness: clip.brightness,
        contrast: clip.contrast,
        saturation: clip.saturation,
      ),
      audio: RenderGraphAudioDto(
        volume: finalVolume,
        fadeInMicros: clip.fadeInMicros,
        fadeOutMicros: clip.fadeOutMicros,
      ),
      text: clip.type == MultitrackClipType.text
          ? RenderGraphTextDto(
              content: clip.textContent ?? '',
              styleJson: clip.textStyleJson,
              colorHex: clip.colorHex,
            )
          : null,
      lutStack: lutStackDto,
      primaryGrade: primaryGradeDto,
      // colorCurves: colorCurvesDto,
      secondaryGrades: secondaryGradesDto,
      filmLook: filmLookDto,
      effectChain: effectChain,
      isDisabled: clip.isDisabled,
      zIndex: zIndex,
    );
  }

  String _trackType(MultitrackTrack track) {
    switch (track.type) {
      case MultitrackTrackType.video:
        return RenderGraphTrackTypes.video;
      case MultitrackTrackType.overlay:
        return RenderGraphTrackTypes.overlay;
      case MultitrackTrackType.text:
        return RenderGraphTrackTypes.text;
      case MultitrackTrackType.adjustment:
        return RenderGraphTrackTypes.adjustment;
      case MultitrackTrackType.audio:
        return RenderGraphTrackTypes.audio;
    }
  }

  String _trackRole(MultitrackTrack track) {
    return track.role.name;
  }

  String _clipType(MultitrackClip clip) {
    switch (clip.type) {
      case MultitrackClipType.video:
        return RenderGraphClipTypes.video;
      case MultitrackClipType.image:
        return RenderGraphClipTypes.image;
      case MultitrackClipType.audio:
        return RenderGraphClipTypes.audio;
      case MultitrackClipType.text:
        return RenderGraphClipTypes.text;
      case MultitrackClipType.adjustment:
        return RenderGraphClipTypes.adjustment;
      case MultitrackClipType.unknown:
        return RenderGraphClipTypes.unknown;
    }
  }

  String _safeFitMode(String value) {
    switch (value.trim().toLowerCase()) {
      case RenderGraphFitModes.fill:
        return RenderGraphFitModes.fill;
      case RenderGraphFitModes.stretch:
        return RenderGraphFitModes.stretch;
      case RenderGraphFitModes.fit:
      default:
        return RenderGraphFitModes.fit;
    }
  }

  String _colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${value.substring(2)}';
  }

  bool _isVoiceoverClip(MultitrackClip clip, MultitrackTimelineViewModel timeline) {
    for (final track in timeline.tracks) {
      if (track.id == clip.trackId) {
        return track.role == MultitrackTrackRole.voice;
      }
    }
    return false;
  }

  bool _overlapsAnyVoiceover(MultitrackClip clip, MultitrackTimelineViewModel timeline) {
    for (final other in timeline.clips) {
      if (other.id == clip.id || other.isDisabled) continue;
      if (_isVoiceoverClip(other, timeline)) {
        final start = math.max(clip.timelineStartMicros, other.timelineStartMicros);
        final end = math.min(clip.timelineEndMicros, other.timelineEndMicros);
        if (start < end) {
          return true;
        }
      }
    }
    return false;
  }
}

