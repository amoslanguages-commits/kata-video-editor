import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/title_clip_repository.dart';
import 'package:nle_editor/domain/titles/title_clip_models.dart';
import 'package:nle_editor/domain/titles/title_motion_models.dart';
import 'package:nle_editor/domain/titles/title_style_models.dart';

class TitleClipState {
  final bool loading;
  final NleTitleClipData? data;
  final String? error;

  const TitleClipState({
    required this.loading,
    this.data,
    this.error,
  });

  const TitleClipState.initial()
      : loading = false,
        data = null,
        error = null;

  TitleClipState copyWith({
    bool? loading,
    NleTitleClipData? data,
    String? error,
    bool clearError = false,
  }) {
    return TitleClipState(
      loading: loading ?? this.loading,
      data: data ?? this.data,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class TitleClipController extends StateNotifier<TitleClipState> {
  final String clipId;
  final TitleClipRepository repository;

  TitleClipController({
    required this.clipId,
    required this.repository,
  }) : super(const TitleClipState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final data = await repository.getTitleData(clipId);

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

  Future<void> save(NleTitleClipData data) async {
    state = state.copyWith(data: data, clearError: true);
    await repository.saveTitleData(clipId: clipId, data: data);
  }

  Future<void> setText(String text) async {
    final data = state.data;
    if (data == null) return;

    await save(data.copyWith(text: text));
  }

  Future<void> setSecondaryText(String text) async {
    final data = state.data;
    if (data == null) return;

    await save(data.copyWith(secondaryText: text));
  }

  Future<void> setStyle(NleTextStyleModel style) async {
    final data = state.data;
    if (data == null) return;

    await save(data.copyWith(style: style));
  }

  Future<void> setSecondaryStyle(NleTextStyleModel style) async {
    final data = state.data;
    if (data == null) return;

    await save(data.copyWith(secondaryStyle: style));
  }

  Future<void> setLayout(NleTitleLayout layout) async {
    final data = state.data;
    if (data == null) return;

    await save(data.copyWith(layout: layout));
  }

  Future<void> setMotion(NleTitleMotion motion) async {
    final data = state.data;
    if (data == null) return;

    await save(data.copyWith(motion: motion));
  }

  Future<void> applyTemplate(NleTitleTemplateId template) async {
    await repository.applyTemplate(
      clipId: clipId,
      template: template,
    );

    await load();
  }
}
