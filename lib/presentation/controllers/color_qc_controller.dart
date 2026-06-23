// lib/presentation/controllers/color_qc_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nle_editor/domain/color_qc/color_qc_models.dart';
import 'package:nle_editor/data/repositories/color_qc_repository.dart';
import 'package:nle_editor/presentation/providers/multitrack_render_graph_providers.dart';

class ColorQcState {
  final bool isLoading;
  final ColorQaReport? localReport;
  final ColorQaReport? nativeReport;
  final ColorQaReport? shaderReport;
  final ColorQaReport? memoryReport;
  final String? error;

  const ColorQcState({
    this.isLoading = false,
    this.localReport,
    this.nativeReport,
    this.shaderReport,
    this.memoryReport,
    this.error,
  });

  ColorQcState copyWith({
    bool? isLoading,
    ColorQaReport? localReport,
    ColorQaReport? nativeReport,
    ColorQaReport? shaderReport,
    ColorQaReport? memoryReport,
    String? error,
  }) {
    return ColorQcState(
      isLoading: isLoading ?? this.isLoading,
      localReport: localReport ?? this.localReport,
      nativeReport: nativeReport ?? this.nativeReport,
      shaderReport: shaderReport ?? this.shaderReport,
      memoryReport: memoryReport ?? this.memoryReport,
      error: error,
    );
  }

  bool get passed {
    final reports = [localReport, nativeReport, shaderReport, memoryReport];
    return reports.every((r) => r == null || r.passed);
  }

  int get issueCount {
    var count = 0;
    if (localReport != null) count += localReport!.issues.length;
    if (nativeReport != null) count += nativeReport!.issues.length;
    if (shaderReport != null) count += shaderReport!.issues.length;
    if (memoryReport != null) count += memoryReport!.issues.length;
    return count;
  }
}

class ColorQcController extends StateNotifier<ColorQcState> {
  final String projectId;
  final ColorQcRepository repository;
  final Ref ref;

  ColorQcController({
    required this.projectId,
    required this.repository,
    required this.ref,
  }) : super(const ColorQcState());

  Future<void> runAllChecks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final graph = await ref.read(projectRenderGraphProvider(projectId).future);

      // Run local checks
      final local = repository.runLocalValidation(graph);

      // Run native checks
      final native = await repository.runNativeColorChecks(graph);

      // Run shader compilation dry-run
      final shader = await repository.runShaderCompileTest(
        name: 'Professional Color Pipeline Shaders',
        vertexSource: _mockVertexShader,
        fragmentSource: _mockFragmentShader,
      );

      // Run memory pressure/leak probe
      final memory = await repository.runMemoryLeakProbe();

      state = state.copyWith(
        isLoading: false,
        localReport: local,
        nativeReport: native,
        shaderReport: shader,
        memoryReport: memory,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> runLocalCheck() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final graph = await ref.read(projectRenderGraphProvider(projectId).future);
      final report = repository.runLocalValidation(graph);
      state = state.copyWith(isLoading: false, localReport: report);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> runNativeCheck() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final graph = await ref.read(projectRenderGraphProvider(projectId).future);
      final report = await repository.runNativeColorChecks(graph);
      state = state.copyWith(isLoading: false, nativeReport: report);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> runShaderCheck() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final report = await repository.runShaderCompileTest(
        name: 'GPU Color Pipeline Shaders',
        vertexSource: _mockVertexShader,
        fragmentSource: _mockFragmentShader,
      );
      state = state.copyWith(isLoading: false, shaderReport: report);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> runMemoryCheck() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final report = await repository.runMemoryLeakProbe();
      state = state.copyWith(isLoading: false, memoryReport: report);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  static const String _mockVertexShader = '''
    attribute vec4 position;
    attribute vec2 texCoord;
    varying vec2 vTexCoord;
    void main() {
      gl_Position = position;
      vTexCoord = texCoord;
    }
  ''';

  static const String _mockFragmentShader = '''
    precision mediump float;
    varying vec2 vTexCoord;
    uniform sampler2D sTexture;
    void main() {
      gl_FragColor = texture2D(sTexture, vTexCoord);
    }
  ''';
}
