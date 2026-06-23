// lib/domain/source_preview/source_preview_render_graph_builder.dart
//
// 29F: Builds a minimal single-clip RenderGraph for the Source Preview monitor.

import 'dart:convert';

import 'package:nle_editor/domain/source_preview/source_preview_models.dart';

/// Inline schema constants (see render_graph_dto.dart for the canonical values).
const _kRenderGraphSchema  = 'nle.render_graph';
const _kRenderGraphVersion = 3;

class SourcePreviewRenderGraphBuilder {
  const SourcePreviewRenderGraphBuilder();

  String buildJsonString({
    required SourcePreviewAsset asset,
    required int inPointMicros,
    required int outPointMicros,
  }) {
    return jsonEncode(
      _build(
        asset: asset,
        inPointMicros: inPointMicros,
        outPointMicros: outPointMicros,
      ),
    );
  }

  Map<String, dynamic> _build({
    required SourcePreviewAsset asset,
    required int inPointMicros,
    required int outPointMicros,
  }) {
    final safeIn  = inPointMicros.clamp(0, asset.durationMicros);
    final safeOut = outPointMicros.clamp(safeIn + 1, asset.durationMicros);
    final selectedDuration = safeOut - safeIn;

    final visual = asset.isVisual;
    final audio  = asset.hasAudio;

    const visualTrackId = 'source_v1';
    const audioTrackId  = 'source_a1';

    final trackType = asset.assetType.toLowerCase() == 'image' ? 'image' : 'video';
    final hasManagedSource = asset.originalPath != null && asset.originalPath!.trim().isNotEmpty;
    final hasProxySource = asset.proxyPath != null && asset.proxyPath!.trim().isNotEmpty;
    final resolvedPreviewPath = hasProxySource ? asset.proxyPath : asset.originalPath;

    return {
      'schema':  _kRenderGraphSchema,
      'version': _kRenderGraphVersion,
      'source':  'source_preview',
      'project': {
        'id':             'source_${asset.id}',
        'name':           asset.name,
        'durationMicros': selectedDuration,
        'width':          asset.width  > 0 ? asset.width  : 1080,
        'height':         asset.height > 0 ? asset.height : 1920,
        'frameRate':      30.0,
        'aspectRatio':    'source',
        'backgroundColor':'#000000',
      },
      'assets': [
        {
          'id':            asset.id,
          'type':          asset.assetType,
          // In this source-preview graph, originalPath is already the managed
          // project copy when one exists. SourcePreviewController resolves that
          // before this graph is built.
          'originalPath':  asset.originalPath,
          'proxyPath':     asset.proxyPath,
          'resolvedPreviewPath': resolvedPreviewPath,
          'thumbnailPath': asset.thumbnailPath,
          'displayName':   asset.name,
          'durationMicros':asset.durationMicros,
          'width':         asset.width,
          'height':        asset.height,
          'hasVideo':      asset.hasVideo,
          'hasAudio':      asset.hasAudio,
          'codec':         null,
          'frameRate':     null,
          'rotationDegrees': 0,
          'preferProxy':   true,
          'hasManagedSource': hasManagedSource,
          'mediaMissing':  !hasManagedSource,
        },
      ],
      'tracks': [
        if (visual)
          {
            'id':          visualTrackId,
            'name':        'Source Video',
            'type':        trackType,
            'trackType':   trackType,
            'role':        'source',
            'sortOrder':   1,
            'isMuted':     false,
            'isSolo':      false,
            'isLocked':    false,
            'isHidden':    false,
            'height':      80.0,
            'colorHex':    '#00E5FF',
            'isVisual':    true,
            'isAudio':     false,
            'layerOrder':  0,
            'clips': [
              _clipJson(
                asset:                asset,
                trackId:              visualTrackId,
                type:                 trackType,
                timelineStartMicros:  0,
                timelineEndMicros:    selectedDuration,
                sourceStartMicros:    safeIn,
                sourceEndMicros:      safeOut,
                resolvedPreviewPath:  resolvedPreviewPath,
                mediaMissing:         !hasManagedSource,
              ),
            ],
          },
        if (audio)
          {
            'id':          audioTrackId,
            'name':        'Source Audio',
            'type':        'audio',
            'trackType':   'audio',
            'role':        'source',
            'sortOrder':   1,
            'isMuted':     false,
            'isSolo':      false,
            'isLocked':    false,
            'isHidden':    false,
            'height':      64.0,
            'colorHex':    '#66FF99',
            'isVisual':    false,
            'isAudio':     true,
            'layerOrder':  0,
            'clips': [
              _clipJson(
                asset:               asset,
                trackId:             audioTrackId,
                type:                'audio',
                timelineStartMicros: 0,
                timelineEndMicros:   selectedDuration,
                sourceStartMicros:   safeIn,
                sourceEndMicros:     safeOut,
                resolvedPreviewPath: resolvedPreviewPath,
                mediaMissing:        !hasManagedSource,
              ),
            ],
          },
      ],
      'composition': {
        'visualTrackIdsBottomToTop':         visual ? [visualTrackId] : [],
        'enabledVisualTrackIdsBottomToTop':  visual ? [visualTrackId] : [],
        'audioTrackIds':                     audio  ? [audioTrackId]  : [],
        'enabledAudioTrackIds':              audio  ? [audioTrackId]  : [],
        'hasSoloAudio':    false,
        'hasHiddenTracks': false,
        'visualLayerCount': visual ? 1 : 0,
        'audioLayerCount':  audio  ? 1 : 0,
      },
      'audioMix': {
        'enabled':            audio,
        'hasSoloAudio':       false,
        'soloAudioTrackIds':  <String>[],
        'mutedAudioTrackIds': <String>[],
        'activeAudioTrackIds': audio ? [audioTrackId] : <String>[],
        'sampleRate':  48000,
        'channels':    2,
      },
      'exportHints': {
        'useProxyForPreview':    true,
        'useOriginalForExport':  false,
        'resolvedPreviewPath':   resolvedPreviewPath,
        'usesManagedMediaPath':  hasManagedSource,
        'mediaMissing':          !hasManagedSource,
        'requiresGpuCompositor': visual,
        'containsText':          false,
        'containsImage':         asset.assetType.toLowerCase() == 'image' ||
                                 asset.assetType.toLowerCase() == 'photo',
        'containsVideo':         asset.assetType.toLowerCase() == 'video',
        'containsAudio':         audio,
        'containsAdjustment':    false,
        'containsColorAdjustments': false,
        'containsCrop':          false,
        'containsSpeedChanges':  false,
        'containsFades':         false,
      },
      'metadata': {
        'builder': 'SourcePreviewRenderGraphBuilder',
        'step':    '29F',
        'pathResolution': 'managed-project-copy-first',
      },
    };
  }

  Map<String, dynamic> _clipJson({
    required SourcePreviewAsset asset,
    required String trackId,
    required String type,
    required int timelineStartMicros,
    required int timelineEndMicros,
    required int sourceStartMicros,
    required int sourceEndMicros,
    required String? resolvedPreviewPath,
    required bool mediaMissing,
  }) {
    return {
      'id':                  'source_clip_${asset.id}',
      'projectId':           'source_${asset.id}',
      'trackId':             trackId,
      'assetId':             asset.id,
      'type':                type,
      'clipType':            type,
      'name':                asset.name,
      'timelineStartMicros': timelineStartMicros,
      'timelineEndMicros':   timelineEndMicros,
      'sourceStartMicros':   sourceStartMicros,
      'sourceEndMicros':     sourceEndMicros,
      'durationMicros':      timelineEndMicros - timelineStartMicros,
      'sourcePath':          resolvedPreviewPath,
      'resolvedPreviewPath': resolvedPreviewPath,
      'originalPath':        asset.originalPath,
      'proxyPath':           asset.proxyPath,
      'preferProxy':         true,
      'mediaMissing':        mediaMissing,
      'speed':               1.0,
      'opacity':             1.0,
      'positionX':           0.0,
      'positionY':           0.0,
      'scale':               1.0,
      'rotation':            0.0,
      'fitMode':             'fit',
      'cropLeft':            0.0,
      'cropTop':             0.0,
      'cropRight':           0.0,
      'cropBottom':          0.0,
      'brightness':          0.0,
      'contrast':            1.0,
      'saturation':          1.0,
      'volume':              1.0,
      'fadeInMicros':        0,
      'fadeOutMicros':       0,
      'textContent':         null,
      'textStyleJson':       null,
      'colorHex':            null,
      'isDisabled':          false,
      'zIndex':              0,
      'transform': {
        'positionX': 0.0,
        'positionY': 0.0,
        'scale':     1.0,
        'rotation':  0.0,
        'opacity':   1.0,
      },
      'crop': {
        'fitMode': 'fit',
        'left':    0.0,
        'top':     0.0,
        'right':   0.0,
        'bottom':  0.0,
      },
      'color': {
        'brightness': 0.0,
        'contrast':   1.0,
        'saturation': 1.0,
      },
      'audio': {
        'volume':       1.0,
        'fadeInMicros': 0,
        'fadeOutMicros':0,
      },
      'text': null,
    };
  }
}
