import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';

import 'package:nle_editor/native_bridge/native_bridge_contract.dart';
import 'package:nle_editor/native_bridge/native_command.dart';
import 'package:nle_editor/native_bridge/native_event.dart';

class FakeNativeBridge extends NativeBridgeContract {
  final StreamController<NativeEvent> _eventsController =
      StreamController<NativeEvent>.broadcast();

  final Set<String> _cancelledJobs = {};
  final Map<String, String> _jobToAssetMap = {};

  static const _uuid = Uuid();

  bool _initialized = false;

  // ── Fake playhead state ──────────────────────────────────────────────────
  bool _isPlaying = false;
  int  _playheadMicros = 0;
  double _playbackRate = 1.0;
  Timer? _playbackTicker;

  static const _tickIntervalMs = 16; // ~60fps

  @override
  Stream<NativeEvent> get events => _eventsController.stream;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<NativeCommandResult> sendCommand(NativeCommand command) async {
    if (!_initialized) {
      return NativeCommandResult(
        commandId: command.id,
        accepted: false,
        message: 'Native bridge is not initialized.',
        errorCode: 'bridge_not_initialized',
      );
    }

    _emit(
      type: NativeEventTypes.commandAccepted,
      projectId: command.projectId,
      commandId: command.id,
      payload: {
        'commandType': command.type,
      },
    );

    switch (command.type) {
      case NativeCommandTypes.loadRenderGraph:
        _emit(
          type: NativeEventTypes.renderGraphLoaded,
          projectId: command.projectId,
          commandId: command.id,
          payload: {
            'status': 'loaded',
          },
        );
        break;

      case NativeCommandTypes.updateRenderGraph:
        _emit(
          type: NativeEventTypes.renderGraphUpdated,
          projectId: command.projectId,
          commandId: command.id,
          payload: {
            'status': 'updated',
          },
        );
        break;

      case NativeCommandTypes.play:
        _isPlaying = true;
        _startFakePlaybackTicker(command.projectId);
        _emit(
          type: NativeEventTypes.playbackStarted,
          projectId: command.projectId,
          commandId: command.id,
          payload: {'playheadMicros': _playheadMicros},
        );
        break;

      case NativeCommandTypes.pause:
        _isPlaying = false;
        _stopFakePlaybackTicker();
        _emit(
          type: NativeEventTypes.playbackPaused,
          projectId: command.projectId,
          commandId: command.id,
          payload: {'playheadMicros': _playheadMicros},
        );
        break;

      case NativeCommandTypes.seek:
        final micros = (command.payload['timelineMicros'] as num?)?.toInt() ?? 0;
        _playheadMicros = micros;
        _emit(
          type: NativeEventTypes.playheadChanged,
          projectId: command.projectId,
          commandId: command.id,
          payload: {'playheadMicros': _playheadMicros},
        );
        break;

      case NativeCommandTypes.startJob:
        final jobId = command.payload['jobId'] as String;
        final jobType = command.payload['jobType'] as String;

        _simulateJob(
          projectId: command.projectId,
          commandId: command.id,
          jobId: jobId,
          jobType: jobType,
        );
        break;

      case NativeCommandTypes.startProxyJob:
        final jobId = command.payload['jobId'] as String;
        final assetId = command.payload['assetId'] as String;
        final outputPath = command.payload['outputPath'] as String;
        _jobToAssetMap[jobId] = assetId;

        _simulateProxyJob(
          projectId: command.projectId,
          commandId: command.id,
          jobId: jobId,
          assetId: assetId,
          outputPath: outputPath,
        );
        break;

      case NativeCommandTypes.cancelProxyJob:
        final jobId = command.payload['jobId'] as String;
        _cancelledJobs.add(jobId);
        final assetId = _jobToAssetMap[jobId] ?? '';

        _emit(
          type: NativeEventTypes.proxyCancelled,
          projectId: command.projectId,
          commandId: command.id,
          jobId: jobId,
          payload: {
            'assetId': assetId,
          },
        );
        break;

      case NativeCommandTypes.startExportJob:
        final jobId = command.payload['jobId'] as String;
        _simulateExportJob(
          projectId: command.projectId,
          commandId: command.id,
          jobId: jobId,
          outputPath: command.payload['outputPath'] as String? ?? '/fake/output.mp4',
        );
        break;

      case NativeCommandTypes.cancelExportJob:
        final jobId = command.payload['jobId'] as String;
        _cancelledJobs.add(jobId);
        _emit(
          type: NativeEventTypes.exportCancelled,
          projectId: command.projectId,
          commandId: command.id,
          jobId: jobId,
          payload: {'stage': 'Cancelled'},
        );
        break;

      case NativeCommandTypes.probeDeviceCapabilities:
        _emit(
          type: NativeEventTypes.deviceCapabilities,
          projectId: command.projectId,
          commandId: command.id,
          payload: {
            'tier': 'flagship',
            'supportedCodecs': ['h264', 'hevc'],
          },
        );
        break;

      case NativeCommandTypes.hdrScanCapability:
        Timer(const Duration(milliseconds: 50), () {
          _emit(
            type: NativeEventTypes.hdrDeviceCapability,
            projectId: command.projectId,
            commandId: command.id,
            payload: {
              'displaySupportsHdr': true,
              'displaySupportsWideColor': true,
              'displayMaxNits': 1000.0,
              'encoderSupportsHdrHlg': true,
              'encoderSupportsHdrPq': true,
              'encoderSupportsWideColorP3': true,
              'encoderSupportsTenBit': true,
            },
          );
        });
        break;

      case NativeCommandTypes.hdrValidateExport:
        Timer(const Duration(milliseconds: 50), () {
          _emit(
            type: NativeEventTypes.hdrExportValidation,
            projectId: command.projectId,
            commandId: command.id,
            payload: {
              'isHdrSafe': true,
              'warnings': ['Fake HDR export warning: ensure peak nits matches destination mastering display.'],
              'errors': <String>[],
              'suggestedColorMode': command.payload['colorMode'] ?? 'rec709Sdr',
              'suggestedBitDepth': command.payload['bitDepth'] ?? 'eightBit',
              'suggestedTransferFunction': command.payload['transferFunction'] ?? 'sdr',
            },
          );
        });
        break;

      case NativeCommandTypes.hdrConfigurePreview:
        // Direct print simulation of setting native configuration values
        print('[FakeNativeBridge] Configured HDR Preview pipeline for project ${command.projectId}: ${command.payload}');
        break;

      case NativeCommandTypes.cancelJob:
        final jobId = command.payload['jobId'] as String;
        _cancelledJobs.add(jobId);

        _emit(
          type: NativeEventTypes.jobCancelled,
          projectId: command.projectId,
          commandId: command.id,
          jobId: jobId,
          payload: {
            'stage': 'Cancelled',
            'progress': 0,
          },
        );
        break;

      case NativeCommandTypes.createPreviewTexture:
        final width = command.payload['width'] as int;
        final height = command.payload['height'] as int;
        Timer(const Duration(milliseconds: 100), () {
          _emit(
            type: NativeEventTypes.previewSurfaceReady,
            projectId: command.projectId,
            commandId: command.id,
            payload: {
              'textureId': 999,
              'width': width,
              'height': height,
            },
          );
        });
        break;

      case NativeCommandTypes.attachPreviewTexture:
        final textureId = command.payload['textureId'] as int;
        Timer(const Duration(milliseconds: 50), () {
          _emit(
            type: NativeEventTypes.previewSurfaceAttached,
            projectId: command.projectId,
            commandId: command.id,
            payload: {
              'textureId': textureId,
            },
          );
        });
        break;

      case NativeCommandTypes.resizePreviewTexture:
        final textureId = command.payload['textureId'] as int;
        final width = command.payload['width'] as int;
        final height = command.payload['height'] as int;
        Timer(const Duration(milliseconds: 50), () {
          _emit(
            type: NativeEventTypes.previewSurfaceResized,
            projectId: command.projectId,
            commandId: command.id,
            payload: {
              'textureId': textureId,
              'width': width,
              'height': height,
            },
          );
        });
        break;

      case NativeCommandTypes.renderPreviewPlaceholder:
        final textureId = command.payload['textureId'] as int;
        final label = command.payload['label'] as String;
        final playheadMicros = command.payload['playheadMicros'] as int;
        Timer(const Duration(milliseconds: 50), () {
          _emit(
            type: NativeEventTypes.previewFrameRendered,
            projectId: command.projectId,
            commandId: command.id,
            payload: {
              'textureId': textureId,
              'label': label,
              'playheadMicros': playheadMicros,
            },
          );
        });
        break;

      case NativeCommandTypes.disposePreviewTexture:
        final textureId = command.payload['textureId'] as int;
        Timer(const Duration(milliseconds: 50), () {
          _emit(
            type: NativeEventTypes.previewSurfaceDisposed,
            projectId: command.projectId,
            commandId: command.id,
            payload: {
              'textureId': textureId,
            },
          );
        });
        break;

      case NativeCommandTypes.setPlaybackRate:
        final rate = (command.payload['rate'] as num?)?.toDouble() ?? 1.0;
        _playbackRate = rate;
        _emit(
          type: NativeEventTypes.audioEngineStateChanged,
          projectId: command.projectId,
          commandId: command.id,
          payload: {'playbackRate': rate},
        );
        break;

      case NativeCommandTypes.getAudioEngineState:
        _emit(
          type: NativeEventTypes.audioEngineStateChanged,
          projectId: command.projectId,
          commandId: command.id,
          payload: {
            'isPlaying':     _isPlaying,
            'playheadMicros': _playheadMicros,
            'playbackRate':  _playbackRate,
            'isSinkReady':   true,
          },
        );
        break;

      case NativeCommandTypes.renderGpuPreviewFrame:
        final timelineTimeMicros =
            (command.payload['timelineTimeMicros'] as num?)?.toInt() ?? 0;
        Timer(const Duration(milliseconds: 16), () {
          _emit(
            type: NativeEventTypes.gpuPreviewFrameRendered,
            projectId: command.projectId,
            commandId: command.id,
            payload: {
              'timelineTimeMicros': timelineTimeMicros,
              'surfacesRendered':   1,
            },
          );
        });
        break;
    }

    return NativeCommandResult(
      commandId: command.id,
      accepted: true,
      message: 'Command accepted by fake bridge.',
    );
  }

  Future<void> _simulateProxyJob({
    required String? projectId,
    required String commandId,
    required String jobId,
    required String assetId,
    required String outputPath,
  }) async {
    _cancelledJobs.remove(jobId);

    _emit(
      type: NativeEventTypes.proxyStarted,
      projectId: projectId,
      commandId: commandId,
      jobId: jobId,
      payload: {
        'assetId': assetId,
        'progress': 0,
      },
    );

    final stages = [
      'Analyzing video track',
      'Configuring MediaCodec H.264 encoder',
      'Scaling frames',
      'Writing proxy MP4 container',
    ];

    try {
      for (var i = 0; i < stages.length; i++) {
        if (_cancelledJobs.contains(jobId)) {
          _emit(
            type: NativeEventTypes.proxyCancelled,
            projectId: projectId,
            commandId: commandId,
            jobId: jobId,
            payload: {
              'assetId': assetId,
            },
          );
          return;
        }

        await Future<void>.delayed(
          Duration(milliseconds: 200 + Random().nextInt(150)),
        );

        final progress = (((i + 1) / stages.length) * 100).round();

        _emit(
          type: NativeEventTypes.proxyProgress,
          projectId: projectId,
          commandId: commandId,
          jobId: jobId,
          payload: {
            'assetId': assetId,
            'stage': stages[i],
            'progress': progress.clamp(0, 99),
          },
        );
      }

      _emit(
        type: NativeEventTypes.proxyCompleted,
        projectId: projectId,
        commandId: commandId,
        jobId: jobId,
        payload: {
          'assetId': assetId,
          'result': {
            'outputPath': outputPath,
            'fileSize': 1024 * 1024 * 5, // 5MB fake size
            'width': 640,
            'height': 360,
            'codec': 'video/avc',
          },
        },
      );
    } finally {
      _jobToAssetMap.remove(jobId);
    }
  }

  Future<void> _simulateExportJob({
    required String? projectId,
    required String commandId,
    required String jobId,
    required String outputPath,
  }) async {
    _cancelledJobs.remove(jobId);

    _emit(
      type: NativeEventTypes.exportStarted,
      projectId: projectId,
      commandId: commandId,
      jobId: jobId,
      payload: {
        'stage': 'Parsing project',
        'progress': 0,
      },
    );

    final stages = [
      'Parsing project',
      'Checking media',
      'Rendering video',
      'Encoding',
      'Saving file',
      'Adding to gallery',
    ];

    for (var i = 0; i < stages.length; i++) {
      if (_cancelledJobs.contains(jobId)) {
        _emit(
          type: NativeEventTypes.exportCancelled,
          projectId: projectId,
          commandId: commandId,
          jobId: jobId,
          payload: {'stage': 'Cancelled'},
        );
        return;
      }

      await Future<void>.delayed(
        Duration(milliseconds: 300 + Random().nextInt(200)),
      );

      final progress = (((i + 1) / stages.length) * 98).round().clamp(0, 98);

      _emit(
        type: NativeEventTypes.exportProgress,
        projectId: projectId,
        commandId: commandId,
        jobId: jobId,
        payload: {
          'stage': stages[i],
          'progress': progress,
        },
      );
    }

    _emit(
      type: NativeEventTypes.exportCompleted,
      projectId: projectId,
      commandId: commandId,
      jobId: jobId,
      payload: {
        'stage': 'Complete',
        'progress': 100,
        'result': {
          'outputPath': outputPath,
          'fileSize': 1024 * 1024 * 30, // 30 MB fake size
          'width': 1920,
          'height': 1080,
          'codec': 'video/avc',
        },
      },
    );
  }

  Future<void> _simulateJob({
    required String? projectId,
    required String commandId,
    required String jobId,
    required String jobType,
  }) async {
    _cancelledJobs.remove(jobId);

    _emit(
      type: NativeEventTypes.jobStarted,
      projectId: projectId,
      commandId: commandId,
      jobId: jobId,
      payload: {
        'jobType': jobType,
        'stage': 'Starting',
        'progress': 0,
      },
    );

    final stages = _stagesForJob(jobType);

    for (var i = 0; i < stages.length; i++) {
      if (_cancelledJobs.contains(jobId)) {
        _emit(
          type: NativeEventTypes.jobCancelled,
          projectId: projectId,
          commandId: commandId,
          jobId: jobId,
          payload: {
            'jobType': jobType,
            'stage': 'Cancelled',
            'progress': 0,
          },
        );

        return;
      }

      await Future<void>.delayed(
        Duration(milliseconds: 250 + Random().nextInt(250)),
      );

      final progress = (((i + 1) / stages.length) * 100).round();

      _emit(
        type: NativeEventTypes.jobProgress,
        projectId: projectId,
        commandId: commandId,
        jobId: jobId,
        payload: {
          'jobType': jobType,
          'stage': stages[i],
          'progress': progress.clamp(0, 99),
        },
      );
    }

    _emit(
      type: NativeEventTypes.jobCompleted,
      projectId: projectId,
      commandId: commandId,
      jobId: jobId,
      payload: {
        'jobType': jobType,
        'stage': 'Complete',
        'progress': 100,
        'result': {
          'message': 'Fake job completed.',
        },
      },
    );
  }

  List<String> _stagesForJob(String jobType) {
    switch (jobType) {
      case 'thumbnail':
        return [
          'Reading media',
          'Decoding frame',
          'Writing thumbnail',
        ];

      case 'waveform':
        return [
          'Reading audio',
          'Decoding samples',
          'Downsampling peaks',
          'Writing waveform',
        ];

      case 'proxy':
        return [
          'Checking source',
          'Creating proxy',
          'Encoding preview file',
          'Saving proxy',
        ];

      case 'export':
        return [
          'Preparing project',
          'Checking media',
          'Rendering video',
          'Mixing audio',
          'Encoding',
          'Saving file',
          'Adding to gallery',
        ];

      case 'cache_cleanup':
        return [
          'Scanning cache',
          'Deleting temporary files',
          'Updating storage stats',
        ];

      default:
        return [
          'Running',
          'Finishing',
        ];
    }
  }

  void _emit({
    required String type,
    String? projectId,
    String? commandId,
    String? jobId,
    required Map<String, dynamic> payload,
  }) {
    _eventsController.add(
      NativeEvent(
        id: _uuid.v4(),
        type: type,
        projectId: projectId,
        commandId: commandId,
        jobId: jobId,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _stopFakePlaybackTicker();
    await _eventsController.close();
  }

  // ── Fake ticker helpers ──────────────────────────────────────────────────

  void _startFakePlaybackTicker(String? projectId) {
    _playbackTicker?.cancel();
    _playbackTicker = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (_) {
        if (!_isPlaying) return;
        _playheadMicros +=
            (_tickIntervalMs * 1000 * _playbackRate).round();
        _emit(
          type: NativeEventTypes.playheadChanged,
          projectId: projectId,
          payload: {
            'playheadMicros': _playheadMicros,
            'isPlaying': true,
          },
        );
      },
    );
  }

  void _stopFakePlaybackTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = null;
  }
}
