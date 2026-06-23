import 'package:nle_editor/domain/qa/multitrack_qa_models.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/domain/timeline/multitrack_timeline_view_model.dart';

class MultitrackQaRunner {
  const MultitrackQaRunner();

  MultitrackQaReport run({
    required String projectId,
    required MultitrackTimelineViewModel timeline,
    required RenderGraphDto graph,
  }) {
    final checks = <MultitrackQaCheck>[
      ..._projectChecks(timeline, graph),
      ..._trackChecks(timeline, graph),
      ..._visualCompositionChecks(graph),
      ..._audioMixChecks(graph),
      ..._clipChecks(timeline, graph),
      ..._inspectorFieldChecks(graph),
      ..._exportHintChecks(graph),
    ];

    return MultitrackQaReport(
      projectId: projectId,
      generatedAt: DateTime.now(),
      checks: checks,
    );
  }

  List<MultitrackQaCheck> _projectChecks(
    MultitrackTimelineViewModel timeline,
    RenderGraphDto graph,
  ) {
    final checks = <MultitrackQaCheck>[];

    checks.add(
      graph.schema == 'nle.render_graph' && graph.version >= 2
          ? _pass(
              'project.schema',
              'RenderGraph schema',
              'RenderGraph schema and version are valid.',
            )
          : _fail(
              'project.schema',
              'RenderGraph schema',
              'RenderGraph must use schema nle.render_graph and version 2+.',
              {
                'schema': graph.schema,
                'version': graph.version,
              },
            ),
    );

    checks.add(
      graph.project.durationMicros == timeline.durationMicros
          ? _pass(
              'project.duration',
              'Project duration',
              'RenderGraph duration matches timeline duration.',
            )
          : _fail(
              'project.duration',
              'Project duration',
              'RenderGraph duration does not match timeline duration.',
              {
                'timelineDurationMicros': timeline.durationMicros,
                'graphDurationMicros': graph.project.durationMicros,
              },
            ),
    );

    checks.add(
      graph.project.width > 0 && graph.project.height > 0
          ? _pass(
              'project.size',
              'Project size',
              'Project output width and height are valid.',
            )
          : _fail(
              'project.size',
              'Project size',
              'Project output width/height must be greater than zero.',
              {
                'width': graph.project.width,
                'height': graph.project.height,
              },
            ),
    );

    checks.add(
      graph.project.frameRate > 0
          ? _pass(
              'project.frameRate',
              'Project frame rate',
              'Project frame rate is valid.',
            )
          : _fail(
              'project.frameRate',
              'Project frame rate',
              'Project frame rate must be greater than zero.',
              {'frameRate': graph.project.frameRate},
            ),
    );

    return checks;
  }

  List<MultitrackQaCheck> _trackChecks(
    MultitrackTimelineViewModel timeline,
    RenderGraphDto graph,
  ) {
    final checks = <MultitrackQaCheck>[];

    final timelineTrackIds = timeline.tracks.map((track) => track.id).toSet();
    final graphTrackIds = graph.tracks.map((track) => track.id).toSet();

    checks.add(
      timelineTrackIds.length == graphTrackIds.length &&
              timelineTrackIds.containsAll(graphTrackIds)
          ? _pass(
              'tracks.allSerialized',
              'All tracks serialized',
              'Every timeline track exists in RenderGraph.',
            )
          : _fail(
              'tracks.allSerialized',
              'All tracks serialized',
              'Some timeline tracks are missing from RenderGraph.',
              {
                'timelineTrackIds': timelineTrackIds.toList(),
                'graphTrackIds': graphTrackIds.toList(),
              },
            ),
    );

    for (final track in graph.tracks) {
      checks.add(
        track.type.isNotEmpty && track.trackType.isNotEmpty
            ? _pass(
                'track.${track.id}.type',
                'Track type: ${track.name}',
                'Track type and trackType are present.',
              )
            : _fail(
                'track.${track.id}.type',
                'Track type: ${track.name}',
                'Track type/trackType cannot be empty.',
              ),
      );

      checks.add(
        track.height > 0
            ? _pass(
                'track.${track.id}.height',
                'Track height: ${track.name}',
                'Track height is valid.',
              )
            : _warning(
                'track.${track.id}.height',
                'Track height: ${track.name}',
                'Track height is zero or negative.',
                {'height': track.height},
              ),
      );
    }

    return checks;
  }

  List<MultitrackQaCheck> _visualCompositionChecks(
    RenderGraphDto graph,
  ) {
    final checks = <MultitrackQaCheck>[];

    final visualTracks = graph.tracks.where((track) => track.isVisual).toList();

    final enabledIds = graph.composition.enabledVisualTrackIdsBottomToTop.toSet();

    final shouldBeEnabled = visualTracks.where((track) {
      if (track.isHidden) return false;
      if (track.isMuted) return false;
      return true;
    }).map((track) {
      return track.id;
    }).toSet();

    checks.add(
      enabledIds.length == shouldBeEnabled.length &&
              enabledIds.containsAll(shouldBeEnabled)
          ? _pass(
              'visual.enabledTracks',
              'Enabled visual tracks',
              'Hidden/muted visual tracks are excluded correctly.',
            )
          : _fail(
              'visual.enabledTracks',
              'Enabled visual tracks',
              'enabledVisualTrackIdsBottomToTop does not match hidden/muted track rules.',
              {
                'expected': shouldBeEnabled.toList(),
                'actual': enabledIds.toList(),
              },
            ),
    );

    final bottomToTop = graph.composition.visualTrackIdsBottomToTop;

    checks.add(
      bottomToTop.length == visualTracks.length
          ? _pass(
              'visual.order.count',
              'Visual order count',
              'Visual composition contains all visual tracks.',
            )
          : _fail(
              'visual.order.count',
              'Visual order count',
              'visualTrackIdsBottomToTop must include every visual track.',
              {
                'visualTrackCount': visualTracks.length,
                'compositionCount': bottomToTop.length,
              },
            ),
    );

    final sortedVisual = [...visualTracks]
      ..sort((a, b) => a.layerOrder.compareTo(b.layerOrder));

    final expectedOrder = sortedVisual.map((track) => track.id).toList();

    checks.add(
      _listEquals(bottomToTop, expectedOrder)
          ? _pass(
              'visual.order.bottomToTop',
              'Visual bottom-to-top order',
              'Visual track order is stable and export-ready.',
            )
          : _warning(
              'visual.order.bottomToTop',
              'Visual bottom-to-top order',
              'Visual track order may not match expected layerOrder.',
              {
                'expected': expectedOrder,
                'actual': bottomToTop,
              },
            ),
    );

    for (final track in visualTracks) {
      if (track.isLocked) {
        checks.add(
          _pass(
            'visual.locked.${track.id}',
            'Locked visual track renders',
            'Locked track ${track.name} is still serialized. Lock only blocks editing.',
          ),
        );
      }
    }

    return checks;
  }

  List<MultitrackQaCheck> _audioMixChecks(
    RenderGraphDto graph,
  ) {
    final checks = <MultitrackQaCheck>[];

    final audioTracks = graph.tracks.where((track) => track.isAudio).toList();
    final hasSolo = audioTracks.any((track) => track.isSolo);

    final expectedActive = audioTracks.where((track) {
      if (track.isMuted) return false;
      if (hasSolo && !track.isSolo) return false;
      return true;
    }).map((track) {
      return track.id;
    }).toSet();

    final actualActive = graph.audioMix.activeAudioTrackIds.toSet();

    checks.add(
      hasSolo == graph.audioMix.hasSoloAudio
          ? _pass(
              'audio.soloFlag',
              'Audio solo flag',
              'hasSoloAudio matches track solo states.',
            )
          : _fail(
              'audio.soloFlag',
              'Audio solo flag',
              'hasSoloAudio does not match audio track solo states.',
              {
                'expected': hasSolo,
                'actual': graph.audioMix.hasSoloAudio,
              },
            ),
    );

    checks.add(
      expectedActive.length == actualActive.length &&
              expectedActive.containsAll(actualActive)
          ? _pass(
              'audio.activeTracks',
              'Active audio tracks',
              'Muted/solo audio rules are serialized correctly.',
            )
          : _fail(
              'audio.activeTracks',
              'Active audio tracks',
              'activeAudioTrackIds does not match mute/solo rules.',
              {
                'expected': expectedActive.toList(),
                'actual': actualActive.toList(),
              },
            ),
    );

    checks.add(
      graph.audioMix.sampleRate >= 8000
          ? _pass(
              'audio.sampleRate',
              'Audio sample rate',
              'Audio sample rate is valid.',
            )
          : _fail(
              'audio.sampleRate',
              'Audio sample rate',
              'Audio sample rate is too low.',
              {'sampleRate': graph.audioMix.sampleRate},
            ),
    );

    checks.add(
      graph.audioMix.channels == 1 || graph.audioMix.channels == 2
          ? _pass(
              'audio.channels',
              'Audio channel count',
              'Audio channel count is valid.',
            )
          : _fail(
              'audio.channels',
              'Audio channel count',
              'Only mono or stereo is supported.',
              {'channels': graph.audioMix.channels},
            ),
    );

    return checks;
  }

  List<MultitrackQaCheck> _clipChecks(
    MultitrackTimelineViewModel timeline,
    RenderGraphDto graph,
  ) {
    final checks = <MultitrackQaCheck>[];

    final graphClips = graph.tracks.expand((track) => track.clips).toList();
    final timelineClipIds = timeline.clips.map((clip) => clip.id).toSet();
    final graphClipIds = graphClips.map((clip) => clip.id).toSet();

    checks.add(
      timelineClipIds.length == graphClipIds.length &&
              timelineClipIds.containsAll(graphClipIds)
          ? _pass(
              'clips.allSerialized',
              'All clips serialized',
              'Every timeline clip exists in RenderGraph.',
            )
          : _fail(
              'clips.allSerialized',
              'All clips serialized',
              'Some clips are missing from RenderGraph.',
              {
                'timelineClipIds': timelineClipIds.toList(),
                'graphClipIds': graphClipIds.toList(),
              },
            ),
    );

    for (final clip in graphClips) {
      checks.add(
        clip.timelineEndMicros > clip.timelineStartMicros
            ? _pass(
                'clip.${clip.id}.timing',
                'Clip timing: ${clip.name}',
                'Clip timeline timing is valid.',
              )
            : _fail(
                'clip.${clip.id}.timing',
                'Clip timing: ${clip.name}',
                'Clip end must be greater than clip start.',
                {
                  'start': clip.timelineStartMicros,
                  'end': clip.timelineEndMicros,
                },
              ),
      );

      checks.add(
        clip.speed > 0
            ? _pass(
                'clip.${clip.id}.speed',
                'Clip speed: ${clip.name}',
                'Clip speed is valid.',
              )
            : _fail(
                'clip.${clip.id}.speed',
                'Clip speed: ${clip.name}',
                'Clip speed must be greater than zero.',
                {'speed': clip.speed},
              ),
      );

      checks.add(
        clip.transform.opacity >= 0 && clip.transform.opacity <= 1
            ? _pass(
                'clip.${clip.id}.opacity',
                'Clip opacity: ${clip.name}',
                'Clip opacity is valid.',
              )
            : _fail(
                'clip.${clip.id}.opacity',
                'Clip opacity: ${clip.name}',
                'Clip opacity must be between 0 and 1.',
                {'opacity': clip.transform.opacity},
              ),
      );

      if (clip.assetId == null && clip.type != 'text' && clip.type != 'adjustment') {
        checks.add(
          _warning(
            'clip.${clip.id}.asset',
            'Clip asset: ${clip.name}',
            'Clip has no asset. This is okay only for text/adjustment clips.',
            {
              'clipType': clip.type,
              'assetId': clip.assetId,
            },
          ),
        );
      }
    }

    return checks;
  }

  List<MultitrackQaCheck> _inspectorFieldChecks(
    RenderGraphDto graph,
  ) {
    final checks = <MultitrackQaCheck>[];

    final clips = graph.tracks.expand((track) => track.clips).toList();

    for (final clip in clips) {
      checks.add(
        clip.transform.scale > 0
            ? _pass(
                'inspector.${clip.id}.scale',
                'Inspector scale: ${clip.name}',
                'Scale is export-ready.',
              )
            : _fail(
                'inspector.${clip.id}.scale',
                'Inspector scale: ${clip.name}',
                'Scale must be greater than zero.',
                {'scale': clip.transform.scale},
              ),
      );

      checks.add(
        clip.crop.left >= 0 &&
                clip.crop.top >= 0 &&
                clip.crop.right >= 0 &&
                clip.crop.bottom >= 0
            ? _pass(
                'inspector.${clip.id}.crop',
                'Inspector crop: ${clip.name}',
                'Crop values are valid.',
              )
            : _fail(
                'inspector.${clip.id}.crop',
                'Inspector crop: ${clip.name}',
                'Crop values cannot be negative.',
                {
                  'left': clip.crop.left,
                  'top': clip.crop.top,
                  'right': clip.crop.right,
                  'bottom': clip.crop.bottom,
                },
              ),
      );

      checks.add(
        clip.color.contrast >= 0 && clip.color.saturation >= 0
            ? _pass(
                'inspector.${clip.id}.color',
                'Inspector color: ${clip.name}',
                'Color controls are valid.',
              )
            : _fail(
                'inspector.${clip.id}.color',
                'Inspector color: ${clip.name}',
                'Contrast and saturation cannot be negative.',
                {
                  'contrast': clip.color.contrast,
                  'saturation': clip.color.saturation,
                },
              ),
      );

      checks.add(
        clip.audio.volume >= 0 && clip.audio.fadeInMicros >= 0 && clip.audio.fadeOutMicros >= 0
            ? _pass(
                'inspector.${clip.id}.audio',
                'Inspector audio: ${clip.name}',
                'Volume and fades are valid.',
              )
            : _fail(
                'inspector.${clip.id}.audio',
                'Inspector audio: ${clip.name}',
                'Volume/fades cannot be negative.',
                {
                  'volume': clip.audio.volume,
                  'fadeInMicros': clip.audio.fadeInMicros,
                  'fadeOutMicros': clip.audio.fadeOutMicros,
                },
              ),
      );
    }

    return checks;
  }

  List<MultitrackQaCheck> _exportHintChecks(
    RenderGraphDto graph,
  ) {
    final checks = <MultitrackQaCheck>[];

    final clips = graph.tracks.expand((track) => track.clips).toList();

    final hasVideo = clips.any((clip) => clip.type == 'video');
    final hasImage = clips.any((clip) => clip.type == 'image');
    final hasText = clips.any((clip) => clip.type == 'text');
    final hasAudio = clips.any((clip) => clip.type == 'audio' || clip.type == 'video');

    checks.add(
      graph.exportHints.containsVideo == hasVideo
          ? _pass(
              'hints.video',
              'Export hint: video',
              'containsVideo is correct.',
            )
          : _warning(
              'hints.video',
              'Export hint: video',
              'containsVideo does not match clips.',
              {
                'expected': hasVideo,
                'actual': graph.exportHints.containsVideo,
              },
            ),
    );

    checks.add(
      graph.exportHints.containsImage == hasImage
          ? _pass(
              'hints.image',
              'Export hint: image',
              'containsImage is correct.',
            )
          : _warning(
              'hints.image',
              'Export hint: image',
              'containsImage does not match clips.',
              {
                'expected': hasImage,
                'actual': graph.exportHints.containsImage,
              },
            ),
    );

    checks.add(
      graph.exportHints.containsText == hasText
          ? _pass(
              'hints.text',
              'Export hint: text',
              'containsText is correct.',
            )
          : _warning(
              'hints.text',
              'Export hint: text',
              'containsText does not match clips.',
              {
                'expected': hasText,
                'actual': graph.exportHints.containsText,
              },
            ),
    );

    checks.add(
      graph.exportHints.containsAudio == hasAudio
          ? _pass(
              'hints.audio',
              'Export hint: audio',
              'containsAudio is correct.',
            )
          : _warning(
              'hints.audio',
              'Export hint: audio',
              'containsAudio does not match clips.',
              {
                'expected': hasAudio,
                'actual': graph.exportHints.containsAudio,
              },
            ),
    );

    return checks;
  }

  MultitrackQaCheck _pass(
    String id,
    String title,
    String message, [
    Map<String, dynamic> details = const {},
  ]) {
    return MultitrackQaCheck(
      id: id,
      title: title,
      message: message,
      severity: MultitrackQaSeverity.pass,
      details: details,
    );
  }

  MultitrackQaCheck _warning(
    String id,
    String title,
    String message, [
    Map<String, dynamic> details = const {},
  ]) {
    return MultitrackQaCheck(
      id: id,
      title: title,
      message: message,
      severity: MultitrackQaSeverity.warning,
      details: details,
    );
  }

  MultitrackQaCheck _fail(
    String id,
    String title,
    String message, [
    Map<String, dynamic> details = const {},
  ]) {
    return MultitrackQaCheck(
      id: id,
      title: title,
      message: message,
      severity: MultitrackQaSeverity.fail,
      details: details,
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}
