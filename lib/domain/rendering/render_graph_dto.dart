import 'dart:convert';

import 'package:nle_editor/domain/rendering/render_graph_contract.dart';
import 'package:nle_editor/domain/rendering/render_graph_film_look_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_lut_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_primary_grade_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_color_curves_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_secondary_grade_dto.dart';
import 'package:nle_editor/domain/rendering/render_graph_hdr_output_dto.dart';


class RenderGraphDto {
  final String schema;
  final int version;
  final String source;
  final RenderGraphProjectDto project;
  final List<RenderGraphAssetDto> assets;
  final List<RenderGraphTrackDto> tracks;
  final RenderGraphCompositionDto composition;
  final RenderGraphAudioMixDto audioMix;
  final RenderGraphExportHintsDto exportHints;
  final RenderGraphColorPipelineDto? colorPipeline;
  final RenderGraphHdrOutputDto? hdrOutput;
  final Map<String, dynamic> metadata;

  const RenderGraphDto({
    required this.schema,
    required this.version,
    required this.source,
    required this.project,
    required this.assets,
    required this.tracks,
    required this.composition,
    required this.audioMix,
    required this.exportHints,
    this.colorPipeline,
    this.hdrOutput,
    this.metadata = const {},
  });

  factory RenderGraphDto.create({
    required RenderGraphProjectDto project,
    required List<RenderGraphAssetDto> assets,
    required List<RenderGraphTrackDto> tracks,
    required RenderGraphCompositionDto composition,
    required RenderGraphAudioMixDto audioMix,
    required RenderGraphExportHintsDto exportHints,
    RenderGraphColorPipelineDto? colorPipeline,
    RenderGraphHdrOutputDto? hdrOutput,
    Map<String, dynamic> metadata = const {},
  }) {
    return RenderGraphDto(
      schema: RenderGraphContract.schema,
      version: RenderGraphContract.version,
      source: RenderGraphContract.source,
      project: project,
      assets: assets,
      tracks: tracks,
      composition: composition,
      audioMix: audioMix,
      exportHints: exportHints,
      colorPipeline: colorPipeline,
      hdrOutput: hdrOutput,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema': schema,
      'version': version,
      'source': source,
      'project': project.toJson(),
      'assets': assets.map((asset) => asset.toJson()).toList(),
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'composition': composition.toJson(),
      'audioMix': audioMix.toJson(),
      'exportHints': exportHints.toJson(),
      if (colorPipeline != null) 'colorPipeline': colorPipeline!.toJson(),
      if (hdrOutput != null) 'hdrOutput': hdrOutput!.toJson(),
      'metadata': metadata,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class RenderGraphProjectDto {
  final String id;
  final String name;
  final int durationMicros;
  final int width;
  final int height;
  final double frameRate;
  final String aspectRatio;
  final String backgroundColor;

  const RenderGraphProjectDto({
    required this.id,
    required this.name,
    required this.durationMicros,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.aspectRatio,
    this.backgroundColor = '#000000',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationMicros': durationMicros,
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'aspectRatio': aspectRatio,
      'backgroundColor': backgroundColor,
    };
  }
}

class RenderGraphAssetDto {
  final String id;
  final String type;
  final String? originalPath;
  final String? proxyPath;
  final String? thumbnailPath;
  final String? displayName;
  final int durationMicros;
  final int width;
  final int height;
  final bool hasVideo;
  final bool hasAudio;
  final String? codec;
  final double? frameRate;
  final int rotationDegrees;

  const RenderGraphAssetDto({
    required this.id,
    required this.type,
    required this.durationMicros,
    required this.width,
    required this.height,
    required this.hasVideo,
    required this.hasAudio,
    this.originalPath,
    this.proxyPath,
    this.thumbnailPath,
    this.displayName,
    this.codec,
    this.frameRate,
    this.rotationDegrees = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'originalPath': originalPath,
      'proxyPath': proxyPath,
      'thumbnailPath': thumbnailPath,
      'displayName': displayName,
      'durationMicros': durationMicros,
      'width': width,
      'height': height,
      'hasVideo': hasVideo,
      'hasAudio': hasAudio,
      'codec': codec,
      'frameRate': frameRate,
      'rotationDegrees': rotationDegrees,
    };
  }
}

class RenderGraphTrackDto {
  final String id;
  final String name;
  final String type;
  final String trackType;
  final String role;
  final String trackRole;
  final int sortOrder;
  final bool isMuted;
  final bool isSolo;
  final bool isLocked;
  final bool isHidden;
  final double height;
  final String? colorHex;
  final bool isVisual;
  final bool isAudio;
  final int layerOrder;
  final List<RenderGraphClipDto> clips;
  final Map<String, dynamic>? effectChain;

  const RenderGraphTrackDto({
    required this.id,
    required this.name,
    required this.type,
    required this.trackType,
    required this.role,
    required this.trackRole,
    required this.sortOrder,
    required this.isMuted,
    required this.isSolo,
    required this.isLocked,
    required this.isHidden,
    required this.height,
    required this.colorHex,
    required this.isVisual,
    required this.isAudio,
    required this.layerOrder,
    required this.clips,
    this.effectChain,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'trackType': trackType,
      'role': role,
      'trackRole': trackRole,
      'sortOrder': sortOrder,
      'isMuted': isMuted,
      'isSolo': isSolo,
      'isLocked': isLocked,
      'isHidden': isHidden,
      'height': height,
      'colorHex': colorHex,
      'isVisual': isVisual,
      'isAudio': isAudio,
      'layerOrder': layerOrder,
      'clips': clips.map((clip) => clip.toJson()).toList(),
      if (effectChain != null) 'effectChain': effectChain,
    };
  }
}

class RenderGraphClipDto {
  final String id;
  final String projectId;
  final String trackId;
  final String? assetId;
  final String type;
  final String clipType;
  final String name;

  final int timelineStartMicros;
  final int timelineEndMicros;
  final int sourceStartMicros;
  final int sourceEndMicros;
  final int durationMicros;

  final double speed;

  final RenderGraphTransformDto transform;
  final RenderGraphCropDto crop;
  final RenderGraphColorDto color;
  final RenderGraphAudioDto audio;
  final RenderGraphTextDto? text;
  final RenderGraphLutStackDto? lutStack;
  final RenderGraphPrimaryGradeDto? primaryGrade;
  final RenderGraphColorCurveStackDto? colorCurves;
  final RenderGraphSecondaryGradeStackDto? secondaryGrades;
  final RenderGraphFilmLookDto? filmLook;
  final Map<String, dynamic>? effectChain;

  final bool isDisabled;
  final int zIndex;

  const RenderGraphClipDto({
    required this.id,
    required this.projectId,
    required this.trackId,
    required this.assetId,
    required this.type,
    required this.clipType,
    required this.name,
    required this.timelineStartMicros,
    required this.timelineEndMicros,
    required this.sourceStartMicros,
    required this.sourceEndMicros,
    required this.durationMicros,
    required this.speed,
    required this.transform,
    required this.crop,
    required this.color,
    required this.audio,
    required this.text,
    this.lutStack,
    this.primaryGrade,
    this.colorCurves,
    this.secondaryGrades,
    this.filmLook,
    this.effectChain,
    required this.isDisabled,
    required this.zIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'trackId': trackId,
      'assetId': assetId,
      'type': type,
      'clipType': clipType,
      'name': name,
      'timelineStartMicros': timelineStartMicros,
      'timelineEndMicros': timelineEndMicros,
      'sourceStartMicros': sourceStartMicros,
      'sourceEndMicros': sourceEndMicros,
      'durationMicros': durationMicros,
      'speed': speed,

      // Flattened fields for native compatibility:
      'opacity': transform.opacity,
      'positionX': transform.positionX,
      'positionY': transform.positionY,
      'scale': transform.scale,
      'rotation': transform.rotation,
      'fitMode': crop.fitMode,
      'cropLeft': crop.left,
      'cropTop': crop.top,
      'cropRight': crop.right,
      'cropBottom': crop.bottom,
      'brightness': color.brightness,
      'contrast': color.contrast,
      'saturation': color.saturation,
      'volume': audio.volume,
      'fadeInMicros': audio.fadeInMicros,
      'fadeOutMicros': audio.fadeOutMicros,
      'textContent': text?.content,
      'textStyleJson': text?.styleJson,
      'colorHex': text?.colorHex,

      // Structured fields for future native parser:
      'transform': transform.toJson(),
      'crop': crop.toJson(),
      'color': color.toJson(),
      'audio': audio.toJson(),
      'text': text?.toJson(),
      if (lutStack != null) 'lutStack': lutStack!.toJson(),
      if (primaryGrade != null) 'primaryGrade': primaryGrade!.toJson(),
      if (colorCurves != null) 'colorCurves': colorCurves!.toJson(),
      if (secondaryGrades != null) 'secondaryGrades': secondaryGrades!.toJson(),
      if (filmLook != null) 'filmLook': filmLook!.toJson(),
      if (effectChain != null) 'effectChain': effectChain,
      'isDisabled': isDisabled,
      'zIndex': zIndex,
    };
  }
}

class RenderGraphTransformDto {
  final double positionX;
  final double positionY;
  final double scale;
  final double rotation;
  final double opacity;

  const RenderGraphTransformDto({
    required this.positionX,
    required this.positionY,
    required this.scale,
    required this.rotation,
    required this.opacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'positionX': positionX,
      'positionY': positionY,
      'scale': scale,
      'rotation': rotation,
      'opacity': opacity,
    };
  }
}

class RenderGraphCropDto {
  final String fitMode;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const RenderGraphCropDto({
    required this.fitMode,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toJson() {
    return {
      'fitMode': fitMode,
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }
}

class RenderGraphColorDto {
  final double brightness;
  final double contrast;
  final double saturation;

  const RenderGraphColorDto({
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });

  Map<String, dynamic> toJson() {
    return {
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
    };
  }
}

class RenderGraphAudioDto {
  final double volume;
  final int fadeInMicros;
  final int fadeOutMicros;

  const RenderGraphAudioDto({
    required this.volume,
    required this.fadeInMicros,
    required this.fadeOutMicros,
  });

  Map<String, dynamic> toJson() {
    return {
      'volume': volume,
      'fadeInMicros': fadeInMicros,
      'fadeOutMicros': fadeOutMicros,
    };
  }
}

class RenderGraphTextDto {
  final String content;
  final String? styleJson;
  final String? colorHex;

  const RenderGraphTextDto({
    required this.content,
    required this.styleJson,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'styleJson': styleJson,
      'colorHex': colorHex,
    };
  }
}

class RenderGraphCompositionDto {
  final List<String> visualTrackIdsBottomToTop;
  final List<String> enabledVisualTrackIdsBottomToTop;
  final List<String> audioTrackIds;
  final List<String> enabledAudioTrackIds;
  final bool hasSoloAudio;
  final bool hasHiddenTracks;
  final int visualLayerCount;
  final int audioLayerCount;

  const RenderGraphCompositionDto({
    required this.visualTrackIdsBottomToTop,
    required this.enabledVisualTrackIdsBottomToTop,
    required this.audioTrackIds,
    required this.enabledAudioTrackIds,
    required this.hasSoloAudio,
    required this.hasHiddenTracks,
    required this.visualLayerCount,
    required this.audioLayerCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'visualTrackIdsBottomToTop': visualTrackIdsBottomToTop,
      'enabledVisualTrackIdsBottomToTop': enabledVisualTrackIdsBottomToTop,
      'audioTrackIds': audioTrackIds,
      'enabledAudioTrackIds': enabledAudioTrackIds,
      'hasSoloAudio': hasSoloAudio,
      'hasHiddenTracks': hasHiddenTracks,
      'visualLayerCount': visualLayerCount,
      'audioLayerCount': audioLayerCount,
    };
  }
}

class RenderGraphAudioMixDto {
  final bool enabled;
  final bool hasSoloAudio;
  final List<String> soloAudioTrackIds;
  final List<String> mutedAudioTrackIds;
  final List<String> activeAudioTrackIds;
  final int sampleRate;
  final int channels;
  final Map<String, dynamic>? masterEffectChain;

  const RenderGraphAudioMixDto({
    required this.enabled,
    required this.hasSoloAudio,
    required this.soloAudioTrackIds,
    required this.mutedAudioTrackIds,
    required this.activeAudioTrackIds,
    this.sampleRate = 48000,
    this.channels = 2,
    this.masterEffectChain,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'hasSoloAudio': hasSoloAudio,
      'soloAudioTrackIds': soloAudioTrackIds,
      'mutedAudioTrackIds': mutedAudioTrackIds,
      'activeAudioTrackIds': activeAudioTrackIds,
      'sampleRate': sampleRate,
      'channels': channels,
      if (masterEffectChain != null) 'masterEffectChain': masterEffectChain,
    };
  }
}

class RenderGraphExportHintsDto {
  final bool useProxyForPreview;
  final bool useOriginalForExport;
  final bool requiresGpuCompositor;
  final bool containsText;
  final bool containsImage;
  final bool containsVideo;
  final bool containsAudio;
  final bool containsAdjustment;
  final bool containsColorAdjustments;
  final bool containsCrop;
  final bool containsSpeedChanges;
  final bool containsFades;
  final bool containsLut;
  final bool containsPrimaryGrades;
  final bool containsColorCurves;
  final bool containsSecondaryGrades;
  final bool containsFilmLooks;
  final String outputMode;
  final bool isHdrOutput;
  final bool isWideColorOutput;
  final bool requiresTenBit;

  const RenderGraphExportHintsDto({
    required this.useProxyForPreview,
    required this.useOriginalForExport,
    required this.requiresGpuCompositor,
    required this.containsText,
    required this.containsImage,
    required this.containsVideo,
    required this.containsAudio,
    required this.containsAdjustment,
    required this.containsColorAdjustments,
    required this.containsCrop,
    required this.containsSpeedChanges,
    required this.containsFades,
    required this.containsLut,
    required this.containsPrimaryGrades,
    required this.containsColorCurves,
    required this.containsSecondaryGrades,
    required this.containsFilmLooks,
    required this.outputMode,
    required this.isHdrOutput,
    required this.isWideColorOutput,
    required this.requiresTenBit,
  });

  Map<String, dynamic> toJson() {
    return {
      'useProxyForPreview': useProxyForPreview,
      'useOriginalForExport': useOriginalForExport,
      'requiresGpuCompositor': requiresGpuCompositor,
      'containsText': containsText,
      'containsImage': containsImage,
      'containsVideo': containsVideo,
      'containsAudio': containsAudio,
      'containsAdjustment': containsAdjustment,
      'containsColorAdjustments': containsColorAdjustments,
      'containsCrop': containsCrop,
      'containsSpeedChanges': containsSpeedChanges,
      'containsFades': containsFades,
      'containsLut': containsLut,
      'containsPrimaryGrades': containsPrimaryGrades,
      'containsColorCurves': containsColorCurves,
      'containsSecondaryGrades': containsSecondaryGrades,
      'containsFilmLooks': containsFilmLooks,
      'outputMode': outputMode,
      'isHdrOutput': isHdrOutput,
      'isWideColorOutput': isWideColorOutput,
      'requiresTenBit': requiresTenBit,
    };
  }
}

// ============================================================
// 30A-PRO: COLOR PIPELINE DTO
// ============================================================

/// Carries the full NleColorManagementPipeline into the RenderGraph JSON
/// so the Android/iOS native compositor can apply correct color transforms.
class RenderGraphColorPipelineDto {
  final bool enabled;
  final String quality;
  final Map<String, dynamic> defaultInput;
  final Map<String, dynamic> working;
  final Map<String, dynamic> previewOutput;
  final Map<String, dynamic> exportOutput;
  final bool forceCompatibilityMode;
  final bool previewMatchesExport;

  /// Per-asset input transforms keyed by assetId.
  final Map<String, Map<String, dynamic>> assetInputTransforms;

  const RenderGraphColorPipelineDto({
    required this.enabled,
    required this.quality,
    required this.defaultInput,
    required this.working,
    required this.previewOutput,
    required this.exportOutput,
    required this.assetInputTransforms,
    this.forceCompatibilityMode = false,
    this.previewMatchesExport = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'quality': quality,
      'defaultInput': defaultInput,
      'working': working,
      'previewOutput': previewOutput,
      'exportOutput': exportOutput,
      'forceCompatibilityMode': forceCompatibilityMode,
      'previewMatchesExport': previewMatchesExport,
      'assetInputTransforms': assetInputTransforms,
    };
  }
}
