import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/timeline/timeline_edit_engine.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final timelineEditProvider = Provider<TimelineEditEngine>((ref) {
  return TimelineEditEngine(repository: ref.watch(timelineRepositoryProvider));
});
