import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/domain/rendering/native_graph_update_scheduler.dart';
import 'package:nle_editor/presentation/providers/multitrack_render_graph_providers.dart';
import 'package:nle_editor/presentation/providers/editor_providers.dart';

final nativeGraphUpdateSchedulerProvider =
    Provider<NativeGraphUpdateScheduler>((ref) {
  final scheduler = NativeGraphUpdateScheduler(
    renderGraphService: ref.watch(multitrackRenderGraphServiceProvider),
    validator: ref.watch(renderGraphValidatorProvider),
    nativeCommandService: ref.watch(nativeCommandServiceProvider),
  );

  ref.onDispose(scheduler.dispose);

  return scheduler;
});
