import 'dart:convert';

class RenderGraph {
  final String graphVersion;
  final RenderGraphProject project;
  final List<RenderGraphAsset> assets;
  final List<RenderGraphTrack> tracks;
  final List<RenderGraphClip> clips;
  final List<RenderGraphKeyframe> keyframes;
  final List<RenderGraphTransition> transitions;
  final Map<String, dynamic> exportDefaults;
  final DateTime generatedAt;

  const RenderGraph({
    required this.graphVersion,
    required this.project,
    required this.assets,
    required this.tracks,
    required this.clips,
    required this.keyframes,
    required this.transitions,
    required this.exportDefaults,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'graphVersion': graphVersion,
      'generatedAt': generatedAt.toIso8601String(),
      'project': project.toJson(),
      'assets': assets.map((asset) => asset.toJson()).toList(),
      'tracks': tracks.map((track) => track.toJson()).toList(),
      'clips': clips.map((clip) => clip.toJson()).toList(),
      'keyframes': keyframes.map((keyframe) => keyframe.toJson()).toList(),
      'transitions': transitions.map((transition) => transition.toJson()).toList(),
      'exportDefaults': exportDefaults,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class RenderGraphProject {
  final String id;
  final String name;
  final String aspectRatio;
  final int targetWidth;
  final int targetHeight;
  final int targetFrameRate;
  final int durationMicros;
  final String colorSpace;
  final bool hasWatermark;
  final String exportPreset;
  final String previewQuality;
  final String proxyMode;

  const RenderGraphProject({
    required this.id,
    required this.name,
    required this.aspectRatio,
    required this.targetWidth,
    required this.targetHeight,
    required this.targetFrameRate,
    required this.durationMicros,
    required this.colorSpace,
    required this.hasWatermark,
    required this.exportPreset,
    required this.previewQuality,
    required this.proxyMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'aspectRatio': aspectRatio,
      'targetWidth': targetWidth,
      'targetHeight': targetHeight,
      'targetFrameRate': targetFrameRate,
      'durationMicros': durationMicros,
      'colorSpace': colorSpace,
      'hasWatermark': hasWatermark,
      'exportPreset': exportPreset,
      'previewQuality': previewQuality,
      'proxyMode': proxyMode,
    };
  }
}

class RenderGraphAsset {
  final String id;
  final String originalPath;
  final String? proxyPath;
  final String previewPath;
  final String exportPath;
  final String fileName;
  final String fileType;
  final int fileSize;
  final int? durationMicros;
  final int? width;
  final int? height;
  final double? frameRate;
  final String? codec;
  final String? audioCodec;
  final int? audioChannels;
  final int? audioSampleRate;
  final int rotation;
  final bool hasVideo;
  final bool hasAudio;
  final bool isMissing;
  final bool isVariableFrameRate;
  final String proxyStatus;
  final String importStatus;

  const RenderGraphAsset({
    required this.id,
    required this.originalPath,
    required this.proxyPath,
    required this.previewPath,
    required this.exportPath,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.durationMicros,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.codec,
    required this.audioCodec,
    required this.audioChannels,
    required this.audioSampleRate,
    required this.rotation,
    required this.hasVideo,
    required this.hasAudio,
    required this.isMissing,
    required this.isVariableFrameRate,
    required this.proxyStatus,
    required this.importStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalPath': originalPath,
      'proxyPath': proxyPath,
      'previewPath': previewPath,
      'exportPath': exportPath,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'durationMicros': durationMicros,
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'codec': codec,
      'audioCodec': audioCodec,
      'audioChannels': audioChannels,
      'audioSampleRate': audioSampleRate,
      'rotation': rotation,
      'hasVideo': hasVideo,
      'hasAudio': hasAudio,
      'isMissing': isMissing,
      'isVariableFrameRate': isVariableFrameRate,
      'proxyStatus': proxyStatus,
      'importStatus': importStatus,
    };
  }
}

class RenderGraphTrack {
  final String id;
  final String projectId;
  final String name;
  final String type;
  final int index;
  final bool isMuted;
  final bool isSolo;
  final bool isLocked;
  final bool isVisible;
  final bool isCollapsed;
  final double volume;
  final double opacity;
  final int height;

  const RenderGraphTrack({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    required this.index,
    required this.isMuted,
    required this.isSolo,
    required this.isLocked,
    required this.isVisible,
    required this.isCollapsed,
    required this.volume,
    required this.opacity,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'type': type,
      'index': index,
      'isMuted': isMuted,
      'isSolo': isSolo,
      'isLocked': isLocked,
      'isVisible': isVisible,
      'isCollapsed': isCollapsed,
      'volume': volume,
      'opacity': opacity,
      'height': height,
    };
  }
}

class RenderGraphClip {
  final String id;
  final String projectId;
  final String trackId;
  final String? assetId;
  final String clipType;

  final int timelineStartMicros;
  final int timelineEndMicros;
  final int sourceInMicros;
  final int sourceOutMicros;

  final double speed;
  final bool isReversed;
  final bool isDisabled;

  final RenderGraphTransform transform;
  final RenderGraphColor color;
  final RenderGraphAudio audio;
  final RenderGraphText? text;

  final String? blendMode;
  final String? lutPath;
  final String? effectStack;

  final int sortOrder;

  const RenderGraphClip({
    required this.id,
    required this.projectId,
    required this.trackId,
    required this.assetId,
    required this.clipType,
    required this.timelineStartMicros,
    required this.timelineEndMicros,
    required this.sourceInMicros,
    required this.sourceOutMicros,
    required this.speed,
    required this.isReversed,
    required this.isDisabled,
    required this.transform,
    required this.color,
    required this.audio,
    required this.text,
    required this.blendMode,
    required this.lutPath,
    required this.effectStack,
    required this.sortOrder,
  });

  int get durationMicros => timelineEndMicros - timelineStartMicros;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'trackId': trackId,
      'assetId': assetId,
      'clipType': clipType,
      'timelineStartMicros': timelineStartMicros,
      'timelineEndMicros': timelineEndMicros,
      'sourceInMicros': sourceInMicros,
      'sourceOutMicros': sourceOutMicros,
      'durationMicros': durationMicros,
      'speed': speed,
      'isReversed': isReversed,
      'isDisabled': isDisabled,
      'transform': transform.toJson(),
      'color': color.toJson(),
      'audio': audio.toJson(),
      'text': text?.toJson(),
      'blendMode': blendMode,
      'lutPath': lutPath,
      'effectStack': effectStack,
      'sortOrder': sortOrder,
    };
  }
}

class RenderGraphTransform {
  final double positionX;
  final double positionY;
  final double anchorX;
  final double anchorY;
  final double scale;
  final double rotation;
  final double opacity;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  const RenderGraphTransform({
    required this.positionX,
    required this.positionY,
    required this.anchorX,
    required this.anchorY,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
  });

  Map<String, dynamic> toJson() {
    return {
      'positionX': positionX,
      'positionY': positionY,
      'anchorX': anchorX,
      'anchorY': anchorY,
      'scale': scale,
      'rotation': rotation,
      'opacity': opacity,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropRight': cropRight,
      'cropBottom': cropBottom,
    };
  }
}

class RenderGraphColor {
  final double exposure;
  final double contrast;
  final double saturation;
  final double temperature;
  final double tint;
  final double highlights;
  final double shadows;

  const RenderGraphColor({
    required this.exposure,
    required this.contrast,
    required this.saturation,
    required this.temperature,
    required this.tint,
    required this.highlights,
    required this.shadows,
  });

  Map<String, dynamic> toJson() {
    return {
      'exposure': exposure,
      'contrast': contrast,
      'saturation': saturation,
      'temperature': temperature,
      'tint': tint,
      'highlights': highlights,
      'shadows': shadows,
    };
  }
}

class RenderGraphAudio {
  final double volume;
  final double pan;
  final bool muted;
  final int fadeInMicros;
  final int fadeOutMicros;

  const RenderGraphAudio({
    required this.volume,
    required this.pan,
    required this.muted,
    required this.fadeInMicros,
    required this.fadeOutMicros,
  });

  Map<String, dynamic> toJson() {
    return {
      'volume': volume,
      'pan': pan,
      'muted': muted,
      'fadeInMicros': fadeInMicros,
      'fadeOutMicros': fadeOutMicros,
    };
  }
}

class RenderGraphText {
  final String content;
  final Map<String, dynamic> style;

  const RenderGraphText({
    required this.content,
    required this.style,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'style': style,
    };
  }
}

class RenderGraphKeyframe {
  final String id;
  final String clipId;
  final String parameter;
  final int timeMicros;
  final String valueType;
  final String valueJson;
  final String interpolation;
  final String easing;

  const RenderGraphKeyframe({
    required this.id,
    required this.clipId,
    required this.parameter,
    required this.timeMicros,
    required this.valueType,
    required this.valueJson,
    required this.interpolation,
    required this.easing,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clipId': clipId,
      'parameter': parameter,
      'timeMicros': timeMicros,
      'valueType': valueType,
      'valueJson': valueJson,
      'interpolation': interpolation,
      'easing': easing,
    };
  }
}

class RenderGraphTransition {
  final String id;
  final String type;
  final String outgoingClipId;
  final String incomingClipId;
  final int durationMicros;
  final String direction;
  final String easing;

  const RenderGraphTransition({
    required this.id,
    required this.type,
    required this.outgoingClipId,
    required this.incomingClipId,
    required this.durationMicros,
    required this.direction,
    required this.easing,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'outgoingClipId': outgoingClipId,
      'incomingClipId': incomingClipId,
      'durationMicros': durationMicros,
      'direction': direction,
      'easing': easing,
    };
  }
}
