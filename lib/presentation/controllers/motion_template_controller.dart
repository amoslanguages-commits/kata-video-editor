import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/motion_template_repository.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_models.dart';
import 'package:nle_editor/domain/motion_templates/motion_template_value_models.dart';

class MotionTemplateBrowserState {
  final bool loading;
  final List<NleMotionTemplatePack> packs;
  final List<String> favorites;
  final List<String> recents;
  final String? selectedTemplateId;
  final Map<String, List<NleTemplateParameterValue>> editedParameters;
  final String? error;

  const MotionTemplateBrowserState({
    required this.loading,
    required this.packs,
    required this.favorites,
    required this.recents,
    this.selectedTemplateId,
    required this.editedParameters,
    this.error,
  });

  const MotionTemplateBrowserState.initial()
      : loading = false,
        packs = const [],
        favorites = const [],
        recents = const [],
        selectedTemplateId = null,
        editedParameters = const {},
        error = null;

  MotionTemplateBrowserState copyWith({
    bool? loading,
    List<NleMotionTemplatePack>? packs,
    List<String>? favorites,
    List<String>? recents,
    String? selectedTemplateId,
    Map<String, List<NleTemplateParameterValue>>? editedParameters,
    String? error,
    bool clearError = false,
  }) {
    return MotionTemplateBrowserState(
      loading: loading ?? this.loading,
      packs: packs ?? this.packs,
      favorites: favorites ?? this.favorites,
      recents: recents ?? this.recents,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      editedParameters: editedParameters ?? this.editedParameters,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class MotionTemplateController extends StateNotifier<MotionTemplateBrowserState> {
  final MotionTemplateRepository repository;

  MotionTemplateController({required this.repository})
      : super(const MotionTemplateBrowserState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final packs = await repository.getTemplatePacks();
      final favoritesList = <String>[];
      final recentsList = <String>[];

      for (final pack in packs) {
        for (final template in pack.templates) {
          final usage = await repository.database.getTemplateUsage(template.id);
          if (usage != null) {
            if (usage.favorite) {
              favoritesList.add(template.id);
            }
            if (usage.lastUsedAt != null) {
              recentsList.add(template.id);
            }
          }
        }
      }

      state = state.copyWith(
        loading: false,
        packs: packs,
        favorites: favoritesList,
        recents: recentsList,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void selectTemplate(String? templateId) {
    state = state.copyWith(selectedTemplateId: templateId);
  }

  void updateParameterValue(
    String templateId,
    String parameterId,
    NleTemplateParameterType type,
    Object? val,
  ) {
    final currentValues =
        List<NleTemplateParameterValue>.from(state.editedParameters[templateId] ?? []);
    final index = currentValues.indexWhere((v) => v.parameterId == parameterId);
    final newValue =
        NleTemplateParameterValue(parameterId: parameterId, type: type, value: val);

    if (index != -1) {
      currentValues[index] = newValue;
    } else {
      currentValues.add(newValue);
    }

    final updatedMap = Map<String, List<NleTemplateParameterValue>>.from(state.editedParameters);
    updatedMap[templateId] = currentValues;

    state = state.copyWith(editedParameters: updatedMap);
  }

  Future<void> toggleFavorite(String templateId, bool favorite) async {
    await repository.database.setTemplateFavorite(
      templateId: templateId,
      favorite: favorite,
    );
    await load();
  }

  Future<NleTemplateApplyResult> applyTemplate({
    required String projectId,
    required String trackId,
    required int timelineStartMicros,
    required String templateId,
  }) async {
    final template = await repository.getTemplateById(templateId);
    if (template == null) throw StateError('Template not found');

    final finalValues = <NleTemplateParameterValue>[];
    final edited = state.editedParameters[templateId] ?? [];

    for (final def in template.parameters) {
      final userVal = edited.where((e) => e.parameterId == def.id).firstOrNull;
      finalValues.add(userVal ?? def.defaultValue);
    }

    final req = NleTemplateApplyRequest(
      projectId: projectId,
      trackId: trackId,
      timelineStartMicros: timelineStartMicros,
      templateId: templateId,
      values: finalValues,
    );

    final result = await repository.applyTemplate(req);
    await load();
    return result;
  }
}
