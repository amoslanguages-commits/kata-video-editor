import 'dart:convert';

import 'package:nle_editor/domain/rendering/render_graph_contract.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';

class RenderGraphValidationSeverity {
  static const String error = 'error';
  static const String warning = 'warning';

  const RenderGraphValidationSeverity._();
}

class RenderGraphValidationIssue {
  final String severity;
  final String code;
  final String message;
  final Map<String, Object?> context;

  const RenderGraphValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.context = const {},
  });

  bool get blocking => severity == RenderGraphValidationSeverity.error;

  Map<String, Object?> toJson() => {
        'severity': severity,
        'code': code,
        'message': message,
        'context': context,
      };
}

class RenderGraphValidationResult {
  final String? schema;
  final int? version;
  final List<RenderGraphValidationIssue> issues;

  const RenderGraphValidationResult({
    required this.schema,
    required this.version,
    required this.issues,
  });

  bool get passed => issues.every((issue) => !issue.blocking);

  Map<String, Object?> toJson() => {
        'schema': schema,
        'version': version,
        'passed': passed,
        'issues': issues.map((issue) => issue.toJson()).toList(),
      };
}

class VersionedRenderGraphPayload {
  final RenderGraphDto graph;
  final String json;
  final String schema;
  final int version;
  final String source;

  const VersionedRenderGraphPayload({
    required this.graph,
    required this.json,
    required this.schema,
    required this.version,
    required this.source,
  });

  factory VersionedRenderGraphPayload.fromGraph(RenderGraphDto graph) {
    final json = graph.toJsonString();
    final validation = RenderGraphVersionValidator.validateJsonString(json);
    if (!validation.passed) {
      throw StateError(
        'Render graph failed version validation: ${validation.issues.map((issue) => issue.code).join(', ')}',
      );
    }
    return VersionedRenderGraphPayload(
      graph: graph,
      json: json,
      schema: graph.schema,
      version: graph.version,
      source: graph.source,
    );
  }

  Map<String, Object?> toBridgeFields() => {
        RenderGraphContract.payloadRenderGraphJsonKey: json,
        RenderGraphContract.payloadRenderGraphSchemaKey: schema,
        RenderGraphContract.payloadRenderGraphVersionKey: version,
        'renderGraphSource': source,
      };
}

class RenderGraphVersionValidator {
  const RenderGraphVersionValidator._();

  static RenderGraphValidationResult validateGraph(RenderGraphDto graph) {
    return _validateMap(graph.toJson());
  }

  static RenderGraphValidationResult validateJsonString(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        return const RenderGraphValidationResult(
          schema: null,
          version: null,
          issues: [
            RenderGraphValidationIssue(
              severity: RenderGraphValidationSeverity.error,
              code: 'render_graph_not_object',
              message: 'Render graph payload must be a JSON object.',
            ),
          ],
        );
      }
      return _validateMap(decoded.map((key, value) => MapEntry(key.toString(), value)));
    } catch (error) {
      return RenderGraphValidationResult(
        schema: null,
        version: null,
        issues: [
          RenderGraphValidationIssue(
            severity: RenderGraphValidationSeverity.error,
            code: 'render_graph_json_invalid',
            message: 'Render graph payload is not valid JSON.',
            context: {'error': error.toString()},
          ),
        ],
      );
    }
  }

  static RenderGraphValidationResult _validateMap(Map<String, Object?> graph) {
    final issues = <RenderGraphValidationIssue>[];
    final schema = graph['schema']?.toString();
    final version = _int(graph['version']);

    if (schema != RenderGraphContract.schema) {
      issues.add(RenderGraphValidationIssue(
        severity: RenderGraphValidationSeverity.error,
        code: 'unsupported_render_graph_schema',
        message: 'Render graph schema is not supported by this app build.',
        context: {
          'expected': RenderGraphContract.schema,
          'actual': schema,
        },
      ));
    }

    if (version == null) {
      issues.add(const RenderGraphValidationIssue(
        severity: RenderGraphValidationSeverity.error,
        code: 'missing_render_graph_version',
        message: 'Render graph version is missing.',
      ));
    } else if (!RenderGraphContract.supportsVersion(version)) {
      issues.add(RenderGraphValidationIssue(
        severity: RenderGraphValidationSeverity.error,
        code: 'unsupported_render_graph_version',
        message: 'Render graph version is not supported by this app build.',
        context: {
          'minSupportedVersion': RenderGraphContract.minSupportedVersion,
          'maxSupportedVersion': RenderGraphContract.maxSupportedVersion,
          'actualVersion': version,
        },
      ));
    }

    final project = graph['project'];
    if (project is! Map) {
      issues.add(const RenderGraphValidationIssue(
        severity: RenderGraphValidationSeverity.error,
        code: 'missing_project_block',
        message: 'Render graph project block is missing.',
      ));
    }

    final assets = graph['assets'];
    if (assets is! List) {
      issues.add(const RenderGraphValidationIssue(
        severity: RenderGraphValidationSeverity.error,
        code: 'missing_assets_block',
        message: 'Render graph assets block is missing.',
      ));
    }

    final tracks = graph['tracks'];
    if (tracks is! List) {
      issues.add(const RenderGraphValidationIssue(
        severity: RenderGraphValidationSeverity.error,
        code: 'missing_tracks_block',
        message: 'Render graph tracks block is missing.',
      ));
    }

    return RenderGraphValidationResult(
      schema: schema,
      version: version,
      issues: issues,
    );
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
