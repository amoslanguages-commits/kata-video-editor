import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/overlay_clip_repository.dart';
import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/overlays/overlay_motion_models.dart';
import 'package:nle_editor/domain/overlays/overlay_style_models.dart';
import 'package:nle_editor/domain/overlays/overlay_template_factory.dart';
import 'package:nle_editor/domain/overlays/overlay_value_models.dart';

class OverlayClipState {
  final bool loading;
  final NleOverlayClipData? data;
  final String? error;

  const OverlayClipState({
    required this.loading,
    this.data,
    this.error,
  });

  const OverlayClipState.initial()
      : loading = false,
        data = null,
        error = null;

  OverlayClipState copyWith({
    bool? loading,
    NleOverlayClipData? data,
    String? error,
    bool clearError = false,
  }) {
    return OverlayClipState(
      loading: loading ?? this.loading,
      data: data ?? this.data,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class OverlayClipController extends StateNotifier<OverlayClipState> {
  final String clipId;
  final OverlayClipRepository repository;

  OverlayClipController({
    required this.clipId,
    required this.repository,
  }) : super(const OverlayClipState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final data = await repository.getOverlayData(clipId);

      state = state.copyWith(
        loading: false,
        data: data,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> save(NleOverlayClipData data) async {
    state = state.copyWith(data: data, clearError: true);

    await repository.saveOverlayData(
      clipId: clipId,
      data: data,
    );
  }

  Future<void> setTransform(NleOverlayTransform transform) async {
    final data = state.data;
    if (data == null || data.locked) return;

    await save(data.copyWith(transform: transform));
  }

  Future<void> setShapeStyle(NleShapeStyle style) async {
    final data = state.data;
    if (data == null || data.locked) return;

    await save(data.copyWith(shapeStyle: style));
  }

  Future<void> setLineStyle(NleLineStyle style) async {
    final data = state.data;
    if (data == null || data.locked) return;

    await save(data.copyWith(lineStyle: style));
  }

  Future<void> setStickerStyle(NleStickerStyle style) async {
    final data = state.data;
    if (data == null || data.locked) return;

    await save(data.copyWith(stickerStyle: style));
  }

  Future<void> setMotion(NleOverlayMotion motion) async {
    final data = state.data;
    if (data == null || data.locked) return;

    await save(data.copyWith(motion: motion));
  }

  Future<void> setHidden(bool hidden) async {
    final data = state.data;
    if (data == null) return;

    await save(data.copyWith(hidden: hidden));
  }

  Future<void> setLocked(bool locked) async {
    final data = state.data;
    if (data == null) return;

    await save(data.copyWith(locked: locked));
  }

  Future<void> applyTemplate(NleOverlayTemplateId template) async {
    await repository.applyTemplate(
      clipId: clipId,
      template: template,
    );

    await load();
  }
}
