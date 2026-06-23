import 'dart:convert';

import 'package:nle_editor/data/database/app_database.dart' as db;
import 'package:nle_editor/data/mappers/render_graph_asset_mapper.dart';
import 'package:nle_editor/data/repositories/film_look_repository.dart';
import 'package:nle_editor/data/repositories/lut_repository.dart';
import 'package:nle_editor/data/repositories/multitrack_timeline_repository.dart';
import 'package:nle_editor/data/repositories/primary_grade_repository.dart';
import 'package:nle_editor/domain/color/color_management_models.dart';
import 'package:nle_editor/domain/color/project_color_settings.dart';
import 'package:nle_editor/data/repositories/color_curve_repository.dart';
import 'package:nle_editor/data/repositories/secondary_grade_repository.dart';
import 'package:nle_editor/domain/color_curves/color_curve_models.dart';
import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';
import 'package:nle_editor/domain/color_lut/color_lut_models.dart';
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';
import 'package:nle_editor/domain/film_look/film_look_models.dart';
import 'package:nle_editor/domain/rendering/multitrack_render_graph_mapper.dart';
import 'package:nle_editor/domain/rendering/render_graph_dto.dart';
import 'package:nle_editor/data/repositories/hdr_output_repository.dart';
import 'package:nle_editor/domain/rendering/render_graph_hdr_output_dto.dart';
import 'package:nle_editor/domain/color_output/hdr_output_models.dart';

import 'package:nle_editor/domain/proxy/proxy_settings_models.dart';
import 'package:nle_editor/domain/proxy/proxy_value_models.dart';
import 'package:nle_editor/domain/proxy/proxy_resolution_service.dart';

class MultitrackRenderGraphService {
  final db.AppDatabase database;
  final MultitrackTimelineRepository timelineRepository;
  final RenderGraphAssetMapper assetMapper;
  final MultitrackRenderGraphMapper graphMapper;
  final LutRepository lutRepository;
  final PrimaryGradeRepository primaryGradeRepository;
  final ColorCurveRepository colorCurveRepository;
  final SecondaryGradeRepository secondaryGradeRepository;
  final FilmLookRepository filmLookRepository;
  final HdrOutputRepository hdrOutputRepository;

  const MultitrackRenderGraphService({
    required this.database,
    required this.timelineRepository,
    this.assetMapper = const RenderGraphAssetMapper(),
    this.graphMapper = const MultitrackRenderGraphMapper(),
    required this.lutRepository,
    required this.primaryGradeRepository,
    required this.colorCurveRepository,
    required this.secondaryGradeRepository,
    required this.filmLookRepository,
    required this.hdrOutputRepository,
  });

  Future<RenderGraphDto> buildGraph(
    String projectId, {
    bool autoDuckingEnabled = false,
    bool isExport = false,
  }) async {
    final project = await database.getProjectById(projectId);
    final timeline = await timelineRepository.getProjectTimelineOnce(projectId);
    final hdrSettings = await hdrOutputRepository.getSettings(projectId);

    final usedAssetIds = timeline.clips
        .map((clip) => clip.assetId)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    final assetRows = await database.getMediaAssetsByIds(usedAssetIds);

    // Resolve proxy settings
    NleProjectProxySettings proxySettings = const NleProjectProxySettings.defaults();
    final rawProxySettings = await database.getProjectProxySettingsJson(projectId);
    if (rawProxySettings != null && rawProxySettings.trim().isNotEmpty) {
      try {
        proxySettings = NleProjectProxySettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawProxySettings) as Map),
        );
      } catch (_) {}
    }

    const resolutionService = ProxyResolutionService();
    final assets = assetRows.map((row) {
      final assetModel = assetMapper.fromDb(row);
      final mediaAsset = assetMapper.toMediaAsset(row);

      final resolved = isExport
          ? resolutionService.resolveForExport(asset: mediaAsset, settings: proxySettings)
          : resolutionService.resolveForPreview(asset: mediaAsset, settings: proxySettings);

      return RenderGraphAssetDto(
        id: assetModel.id,
        type: assetModel.type,
        originalPath: resolved.path ?? assetModel.originalPath,
        proxyPath: assetModel.proxyPath,
        thumbnailPath: assetModel.thumbnailPath,
        displayName: assetModel.displayName,
        durationMicros: assetModel.durationMicros,
        width: assetModel.width,
        height: assetModel.height,
        hasVideo: assetModel.hasVideo,
        hasAudio: assetModel.hasAudio,
        codec: assetModel.codec,
        frameRate: assetModel.frameRate,
        rotationDegrees: assetModel.rotationDegrees,
      );
    }).toList();

    final clipLutStacks = <String, NleClipLutStack>{};
    final clipPrimaryGrades = <String, NlePrimaryGrade>{};
    final clipColorCurves = <String, NleColorCurveStack>{};
    final clipSecondaryGrades = <String, NleSecondaryGradeStack>{};
    final clipFilmLooks = <String, NleFilmLookSettings>{};
    final clipEffectChains = <String, Map<String, dynamic>?>{};
    for (final clip in timeline.clips) {
      final lutStack = await lutRepository.getClipLutStack(clipId: clip.id);
      clipLutStacks[clip.id] = lutStack;

      final primaryGrade = await primaryGradeRepository.getPrimaryGrade(clip.id);
      clipPrimaryGrades[clip.id] = primaryGrade;

      final colorCurves = await colorCurveRepository.getCurveStack(clip.id);
      clipColorCurves[clip.id] = colorCurves;

      final secondaryGrades = await secondaryGradeRepository.getStack(clip.id);
      clipSecondaryGrades[clip.id] = secondaryGrades;

      final filmLook = await filmLookRepository.getClipFilmLook(clip.id);
      clipFilmLooks[clip.id] = filmLook;

      final chainJson = await database.getClipEffectChainJson(clip.id);
      if (chainJson != null && chainJson.trim().isNotEmpty) {
        try {
          clipEffectChains[clip.id] = jsonDecode(chainJson) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    final trackEffectChains = <String, Map<String, dynamic>?>{};
    for (final track in timeline.tracks) {
      final chainJson = await database.getTrackEffectChainJson(track.id);
      if (chainJson != null && chainJson.trim().isNotEmpty) {
        try {
          trackEffectChains[track.id] = jsonDecode(chainJson) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    Map<String, dynamic>? masterEffectChain;
    final masterChainJson = project.masterEffectChainJson;
    if (masterChainJson != null && masterChainJson.trim().isNotEmpty) {
      try {
        masterEffectChain = jsonDecode(masterChainJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    final tracks = graphMapper.mapTracks(
      timeline,
      autoDuckingEnabled: autoDuckingEnabled,
      clipLutStacks: clipLutStacks,
      clipPrimaryGrades: clipPrimaryGrades,
      clipColorCurves: clipColorCurves,
      clipSecondaryGrades: clipSecondaryGrades,
      clipFilmLooks: clipFilmLooks,
      clipEffectChains: clipEffectChains,
      trackEffectChains: trackEffectChains,
    );

    // 30A-PRO: Color Management Pipeline
    final colorPipeline = await _buildColorPipeline(project, assetRows);

    return RenderGraphDto.create(
      project: RenderGraphProjectDto(
        id: project.id,
        name: project.name,
        durationMicros: timeline.durationMicros,
        width: _projectWidth(project),
        height: _projectHeight(project),
        frameRate: _projectFrameRate(project),
        aspectRatio: _projectAspectRatio(project),
        backgroundColor: _projectBackgroundColor(project),
      ),
      assets: assets,
      tracks: tracks,
      composition: graphMapper.mapComposition(timeline),
      audioMix: graphMapper.mapAudioMix(timeline, masterEffectChain: masterEffectChain),
      exportHints: graphMapper.mapExportHints(
        timeline,
        hdrSettings: hdrSettings,
        clipLutStacks: clipLutStacks,
        clipPrimaryGrades: clipPrimaryGrades,
        clipColorCurves: clipColorCurves,
        clipSecondaryGrades: clipSecondaryGrades,
        clipFilmLooks: clipFilmLooks,
      ),
      colorPipeline: colorPipeline,
      hdrOutput: RenderGraphHdrOutputDto(settings: hdrSettings),
      metadata: {
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'builder': 'MultitrackRenderGraphService',
        'step': '30J-PRO',
      },
    );
  }

  Future<RenderGraphColorPipelineDto> _buildColorPipeline(
    db.Project project,
    List<db.MediaAsset> assetRows,
  ) async {
    // Parse project color settings (falls back to Rec.709 SDR default).
    NleColorManagementPipeline pipeline;
    final jsonString = project.colorSettingsJson;
    if (jsonString != null && jsonString.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString) as Map?;
        if (decoded != null) {
          final settings = ProjectColorSettings.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          pipeline = settings.pipeline;
        } else {
          pipeline = const NleColorManagementPipeline.defaultRec709();
        }
      } catch (_) {
        pipeline = const NleColorManagementPipeline.defaultRec709();
      }
    } else {
      pipeline = const NleColorManagementPipeline.defaultRec709();
    }

    // Build per-asset input transforms from the DB metadata columns.
    final assetInputTransforms = <String, Map<String, dynamic>>{};
    for (final asset in assetRows) {
      Map<String, dynamic> videoInfo = {};
      try {
        videoInfo = jsonDecode(asset.videoInfoJson) as Map<String, dynamic>;
      } catch (_) {}

      assetInputTransforms[asset.id] = {
        'colorSpace': videoInfo['colorSpace'] ?? 'auto',
        'transferCurve': 'auto',
        'fullRange': true,
        'hdr': videoInfo['hasHdr'] == true,
        'wideGamut': false,
        'cameraLogProfile': null,
        'bitDepth': 8,
      };
    }

    return RenderGraphColorPipelineDto(
      enabled: pipeline.enabled,
      quality: pipeline.quality.name,
      defaultInput: pipeline.defaultInput.toJson(),
      working: pipeline.working.toJson(),
      previewOutput: pipeline.previewOutput.toJson(),
      exportOutput: pipeline.exportOutput.toJson(),
      forceCompatibilityMode: pipeline.forceCompatibilityMode,
      previewMatchesExport: pipeline.previewMatchesExport,
      assetInputTransforms: assetInputTransforms,
    );
  }

  Future<Map<String, dynamic>> buildGraphJson(
    String projectId, {
    bool autoDuckingEnabled = false,
    bool isExport = false,
  }) async {
    return (await buildGraph(
      projectId,
      autoDuckingEnabled: autoDuckingEnabled,
      isExport: isExport,
    )).toJson();
  }

  Future<String> buildGraphJsonString(
    String projectId, {
    bool autoDuckingEnabled = false,
    bool isExport = false,
  }) async {
    return (await buildGraph(
      projectId,
      autoDuckingEnabled: autoDuckingEnabled,
      isExport: isExport,
    )).toJsonString();
  }

  int _projectWidth(db.Project project) {
    return project.targetWidth;
  }

  int _projectHeight(db.Project project) {
    return project.targetHeight;
  }

  double _projectFrameRate(db.Project project) {
    return project.targetFrameRate.toDouble();
  }

  String _projectAspectRatio(db.Project project) {
    return project.aspectRatio;
  }

  String _projectBackgroundColor(db.Project project) {
    return '#000000';
  }
}
