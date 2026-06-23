import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/data/repositories/keyframe_repository.dart';
import 'package:nle_editor/domain/keyframes/keyframe_editing_tools.dart';
import 'package:nle_editor/domain/keyframes/keyframe_models.dart';
import 'package:nle_editor/domain/keyframes/keyframe_value_models.dart';

class KeyframeEditorState {
  final bool loading;
  final NleKeyframeTrack? track;
  final String? selectedPropertyId;
  final String? selectedKeyframeId;
  final String? error;

  const KeyframeEditorState({
    required this.loading,
    this.track,
    this.selectedPropertyId,
    this.selectedKeyframeId,
    this.error,
  });

  const KeyframeEditorState.initial()
      : loading = false,
        track = null,
        selectedPropertyId = null,
        selectedKeyframeId = null,
        error = null;

  NleAnimatableProperty? get selectedProperty {
    final current = track;
    if (current == null || selectedPropertyId == null) return null;

    return current.properties
        .where((property) => property.id == selectedPropertyId)
        .firstOrNull;
  }

  NleKeyframe? get selectedKeyframe {
    final property = selectedProperty;
    if (property == null || selectedKeyframeId == null) return null;

    return property.keyframes
        .where((kf) => kf.id == selectedKeyframeId)
        .firstOrNull;
  }

  KeyframeEditorState copyWith({
    bool? loading,
    NleKeyframeTrack? track,
    String? selectedPropertyId,
    String? selectedKeyframeId,
    String? error,
    bool clearError = false,
  }) {
    return KeyframeEditorState(
      loading: loading ?? this.loading,
      track: track ?? this.track,
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      selectedKeyframeId: selectedKeyframeId ?? this.selectedKeyframeId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class KeyframeController extends StateNotifier<KeyframeEditorState> {
  final String clipId;
  final String clipType;
  final int clipDurationMicros;
  final KeyframeRepository repository;
  final KeyframeEditingTools tools;

  KeyframeController({
    required this.clipId,
    required this.clipType,
    required this.clipDurationMicros,
    required this.repository,
    this.tools = const KeyframeEditingTools(),
  }) : super(const KeyframeEditorState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final track = await repository.getTrackForClip(
        clipId: clipId,
        clipType: clipType,
        clipDurationMicros: clipDurationMicros,
      );

      state = state.copyWith(
        loading: false,
        track: track,
        selectedPropertyId:
            track.properties.isNotEmpty ? track.properties.first.id : null,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  void selectProperty(String propertyId) {
    state = state.copyWith(
      selectedPropertyId: propertyId,
      selectedKeyframeId: null,
    );
  }

  void selectKeyframe(String keyframeId) {
    state = state.copyWith(selectedKeyframeId: keyframeId);
  }

  Future<void> addKeyframeAt({
    required int timeOffsetMicros,
    required NleKeyframeValue value,
  }) async {
    final track = state.track;
    final property = state.selectedProperty;
    if (track == null || property == null) return;

    final updatedProperty = tools.addKeyframe(
      property: property,
      timeOffsetMicros: timeOffsetMicros,
      value: value,
    );

    await _replaceProperty(track, updatedProperty);
  }

  Future<void> moveSelectedKeyframe(int timeOffsetMicros) async {
    final track = state.track;
    final property = state.selectedProperty;
    final keyframe = state.selectedKeyframe;

    if (track == null || property == null || keyframe == null) return;

    final updatedProperty = tools.moveKeyframe(
      property: property,
      keyframeId: keyframe.id,
      timeOffsetMicros: timeOffsetMicros,
      clipDurationMicros: track.clipDurationMicros,
    );

    await _replaceProperty(track, updatedProperty);
  }

  Future<void> updateSelectedValue(NleKeyframeValue value) async {
    final track = state.track;
    final property = state.selectedProperty;
    final keyframe = state.selectedKeyframe;

    if (track == null || property == null || keyframe == null) return;

    final updatedProperty = tools.updateKeyframeValue(
      property: property,
      keyframeId: keyframe.id,
      value: value,
    );

    await _replaceProperty(track, updatedProperty);
  }

  Future<void> removeSelectedKeyframe() async {
    final track = state.track;
    final property = state.selectedProperty;
    final keyframe = state.selectedKeyframe;

    if (track == null || property == null || keyframe == null) return;

    final updatedProperty = tools.removeKeyframe(
      property: property,
      keyframeId: keyframe.id,
    );

    await _replaceProperty(track, updatedProperty);

    state = state.copyWith(selectedKeyframeId: null);
  }

  Future<void> setSelectedInterpolation(
    NleKeyframeInterpolation interpolation,
  ) async {
    final track = state.track;
    final property = state.selectedProperty;
    final keyframe = state.selectedKeyframe;

    if (track == null || property == null || keyframe == null) return;

    final updatedProperty = tools.setInterpolation(
      property: property,
      keyframeId: keyframe.id,
      interpolation: interpolation,
    );

    await _replaceProperty(track, updatedProperty);
  }

  Future<void> _replaceProperty(
    NleKeyframeTrack track,
    NleAnimatableProperty property,
  ) async {
    final properties = track.properties.map((item) {
      return item.id == property.id ? property : item;
    }).toList();

    final nextTrack = track.copyWith(properties: properties);

    state = state.copyWith(track: nextTrack, clearError: true);

    await repository.saveTrack(nextTrack);
  }
}
