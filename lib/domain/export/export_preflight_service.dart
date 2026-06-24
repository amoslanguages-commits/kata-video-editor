import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class ExportPreflightSeverity {
  static const info = 'info';
  static const warning = 'warning';
  static const error = 'error';
}

class ExportPreflightIssue {
  final String severity;
  final String code;
  final String message;
  final Map<String, dynamic> context;

  const ExportPreflightIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.context = const {},
  });

  bool get blocking => severity == ExportPreflightSeverity.error;

  Map<String, dynamic> toJson() => {
        'severity': severity,
        'code': code,
        'message': message,
        'context': context,
      };
}

class ExportPreflightReport {
  final String projectId;
  final String outputPath;
  final DateTime generatedAt;
  final int estimatedOutputBytes;
  final bool preferProxy;
  final List<ExportPreflightIssue> issues;

  const ExportPreflightReport({
    required this.projectId,
    required this.outputPath,
    required this.generatedAt,
    required this.estimatedOutputBytes,
    required this.preferProxy,
    required this.issues,
  });

  bool get ready => issues.every((issue) => !issue.blocking);

  List<ExportPreflightIssue> get blockingIssues =>
      issues.where((issue) => issue.blocking).toList(growable: false);

  List<ExportPreflightIssue> get warnings => issues
      .where((issue) => issue.severity == ExportPreflightSeverity.warning)
      .toList(growable: false);

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'outputPath': outputPath,
        'generatedAt': generatedAt.toIso8601String(),
        'estimatedOutputBytes': estimatedOutputBytes,
        'preferProxy': preferProxy,
        'ready': ready,
        'issues': issues.map((issue) => issue.toJson()).toList(),
      };

  String blockingSummary() {
    final blocking = blockingIssues;
    if (blocking.isEmpty) return 'Export is ready.';
    return blocking.map((issue) => issue.message).join('\n');
  }
}

class ExportPreflightService {
  const ExportPreflightService();

  Future<ExportPreflightReport> check({
    required String projectId,
    required String renderGraphJson,
    required String outputPath,
    required Map<String, dynamic> settings,
  }) async {
    final issues = <ExportPreflightIssue>[];
    final outputFile = File(outputPath);
    final outputDirectory = outputFile.parent;

    await _checkOutputPath(outputFile, outputDirectory, issues);

    var durationMicros = 0;
    var projectWidth = _int(settings['width']) ?? _int(settings['targetWidth']) ?? 1920;
    var projectHeight = _int(settings['height']) ?? _int(settings['resolution']) ?? _int(settings['targetHeight']) ?? 1080;
    var frameRate = _int(settings['frameRate']) ?? 30;
    var preferProxy = _bool(settings['preferProxy']) ??
        _bool(settings['useProxy']) ??
        _bool(settings['useProxyForExport']) ??
        false;

    try {
      final root = jsonDecode(renderGraphJson);
      if (root is! Map) {
        issues.add(const ExportPreflightIssue(
          severity: ExportPreflightSeverity.error,
          code: 'render_graph_not_object',
          message: 'Export render graph is invalid.',
        ));
      } else {
        final graph = root.map((key, value) => MapEntry(key.toString(), value));
        final project = _map(graph['project']) ?? graph;
        durationMicros = _int(project['durationMicros']) ?? 0;
        projectWidth = _int(project['width']) ?? _int(project['targetWidth']) ?? projectWidth;
        projectHeight = _int(project['height']) ?? _int(project['targetHeight']) ?? projectHeight;
        frameRate = _int(project['frameRate']) ?? frameRate;
        final exportHints = _map(graph['exportHints']) ?? const <String, dynamic>{};
        preferProxy = _bool(settings['preferProxy']) ??
            _bool(settings['useProxy']) ??
            _bool(settings['useProxyForExport']) ??
            !(_bool(exportHints['useOriginalForExport']) ?? true);
        _checkGraphStructure(graph, preferProxy: preferProxy, issues: issues);
      }
    } catch (error) {
      issues.add(ExportPreflightIssue(
        severity: ExportPreflightSeverity.error,
        code: 'render_graph_parse_failed',
        message: 'Export render graph could not be parsed.',
        context: {'error': error.toString()},
      ));
    }

    if (durationMicros <= 0) {
      issues.add(const ExportPreflightIssue(
        severity: ExportPreflightSeverity.error,
        code: 'empty_duration',
        message: 'The project has no exportable duration.',
      ));
    }
    if (projectWidth <= 0 || projectHeight <= 0) {
      issues.add(const ExportPreflightIssue(
        severity: ExportPreflightSeverity.error,
        code: 'invalid_resolution',
        message: 'Export resolution is invalid.',
      ));
    }
    if (frameRate <= 0 || frameRate > 240) {
      issues.add(ExportPreflightIssue(
        severity: ExportPreflightSeverity.error,
        code: 'invalid_frame_rate',
        message: 'Export frame rate is invalid.',
        context: {'frameRate': frameRate},
      ));
    }

    final estimatedBytes = _estimateOutputBytes(
      durationMicros: durationMicros,
      width: projectWidth,
      height: projectHeight,
      frameRate: frameRate,
      settings: settings,
    );
    await _checkOutputCapacity(outputDirectory, estimatedBytes, issues);

    return ExportPreflightReport(
      projectId: projectId,
      outputPath: outputPath,
      generatedAt: DateTime.now(),
      estimatedOutputBytes: estimatedBytes,
      preferProxy: preferProxy,
      issues: issues,
    );
  }

  Future<void> _checkOutputPath(
    File outputFile,
    Directory outputDirectory,
    List<ExportPreflightIssue> issues,
  ) async {
    final extension = p.extension(outputFile.path).toLowerCase();
    if (extension != '.mp4') {
      issues.add(ExportPreflightIssue(
        severity: ExportPreflightSeverity.warning,
        code: 'non_mp4_extension',
        message: 'The native export pipeline is optimized for MP4 output.',
        context: {'extension': extension},
      ));
    }

    try {
      await outputDirectory.create(recursive: true);
      final probe = File(p.join(outputDirectory.path, '.nle_export_write_probe'));
      await probe.writeAsString('ok', flush: true);
      if (await probe.exists()) await probe.delete();
    } catch (error) {
      issues.add(ExportPreflightIssue(
        severity: ExportPreflightSeverity.error,
        code: 'output_not_writable',
        message: 'Export destination is not writable.',
        context: {'path': outputDirectory.path, 'error': error.toString()},
      ));
    }
  }

  Future<void> _checkOutputCapacity(
    Directory outputDirectory,
    int estimatedBytes,
    List<ExportPreflightIssue> issues,
  ) async {
    try {
      final tempProbe = File(p.join(outputDirectory.path, '.nle_export_space_probe'));
      await tempProbe.writeAsBytes(const [0], flush: true);
      if (await tempProbe.exists()) await tempProbe.delete();
    } catch (error) {
      issues.add(ExportPreflightIssue(
        severity: ExportPreflightSeverity.error,
        code: 'output_space_probe_failed',
        message: 'Export destination could not accept a test write.',
        context: {'error': error.toString()},
      ));
      return;
    }

    if (estimatedBytes > 4 * 1024 * 1024 * 1024) {
      issues.add(ExportPreflightIssue(
        severity: ExportPreflightSeverity.warning,
        code: 'very_large_export_estimate',
        message: 'Estimated export size is very large. Export may fail on low-storage devices.',
        context: {'estimatedOutputBytes': estimatedBytes},
      ));
    }
  }

  void _checkGraphStructure(
    Map<String, dynamic> graph, {
    required bool preferProxy,
    required List<ExportPreflightIssue> issues,
  }) {
    final assets = _listOfMaps(graph['assets']);
    final tracks = _listOfMaps(graph['tracks']);
    var clips = _listOfMaps(graph['clips']);
    if (clips.isEmpty) {
      clips = tracks.expand((track) => _listOfMaps(track['clips'])).toList();
    }
    final enabledClips = clips.where((clip) => _bool(clip['isDisabled']) != true).toList();
    if (enabledClips.isEmpty) {
      issues.add(const ExportPreflightIssue(
        severity: ExportPreflightSeverity.error,
        code: 'no_enabled_clips',
        message: 'The timeline has no enabled clips to export.',
      ));
      return;
    }

    final assetsById = <String, Map<String, dynamic>>{
      for (final asset in assets)
        if (_string(asset['id']) != null) _string(asset['id'])!: asset,
    };

    for (final clip in enabledClips) {
      final type = _string(clip['clipType']) ?? _string(clip['type']) ?? 'video';
      if (type == 'text' || type == 'adjustment') continue;
      final assetId = _string(clip['assetId']) ?? _string(clip['asset_id']);
      if (assetId == null || assetId.isEmpty) {
        issues.add(ExportPreflightIssue(
          severity: ExportPreflightSeverity.error,
          code: 'clip_missing_asset',
          message: 'A $type clip has no linked media asset.',
          context: {'clipId': _string(clip['id'])},
        ));
        continue;
      }
      final asset = assetsById[assetId];
      if (asset == null) {
        issues.add(ExportPreflightIssue(
          severity: ExportPreflightSeverity.error,
          code: 'asset_not_in_graph',
          message: 'A timeline clip references an asset that is not in the export graph.',
          context: {'assetId': assetId, 'clipId': _string(clip['id'])},
        ));
        continue;
      }
      final resolvedPath = _resolveAssetPath(asset, preferProxy: preferProxy);
      if (resolvedPath == null) {
        issues.add(ExportPreflightIssue(
          severity: ExportPreflightSeverity.error,
          code: 'asset_path_missing',
          message: 'An export asset has no usable source path.',
          context: {'assetId': assetId, 'preferProxy': preferProxy},
        ));
        continue;
      }
      if (!resolvedPath.startsWith('content://') && !File(resolvedPath).existsSync()) {
        issues.add(ExportPreflightIssue(
          severity: ExportPreflightSeverity.error,
          code: 'asset_file_missing',
          message: 'An export asset file is missing on disk.',
          context: {'assetId': assetId, 'path': resolvedPath},
        ));
      }
    }
  }

  String? _resolveAssetPath(Map<String, dynamic> asset, {required bool preferProxy}) {
    final selected = _string(asset['resolvedPath']) ?? _string(asset['selectedMediaPath']);
    final proxy = _string(asset['proxyPath']) ?? _string(asset['proxy_uri']);
    final original = _string(asset['projectPath']) ??
        _string(asset['exportPath']) ??
        _string(asset['sourcePath']) ??
        _string(asset['originalPath']) ??
        _string(asset['filePath']) ??
        _string(asset['path']) ??
        _string(asset['uri']);
    final candidates = [
      selected,
      if (preferProxy) proxy,
      original,
      if (!preferProxy) proxy,
    ];
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) return candidate.trim();
    }
    return null;
  }

  int _estimateOutputBytes({
    required int durationMicros,
    required int width,
    required int height,
    required int frameRate,
    required Map<String, dynamic> settings,
  }) {
    final fallbackBitrate = ((width * height * frameRate) ~/ 2)
        .clamp(4 * 1000 * 1000, 60 * 1000 * 1000)
        .toInt();
    final bitrate = _int(settings['videoBitrate']) ??
        _int(settings['videoBitrateBps']) ??
        _int(settings['bitRate']) ??
        fallbackBitrate;
    final audioBitrate = _int(settings['audioBitrate']) ?? 192000;
    final seconds = durationMicros / 1000000.0;
    final totalBits = (bitrate + audioBitrate) * seconds;
    return (totalBits / 8).ceil();
  }

  Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
    return null;
  }

  List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => entry.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value.toInt() != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return null;
  }
}
