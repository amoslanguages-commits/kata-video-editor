import 'package:nle_editor/core/performance/performance_timers.dart';
import 'package:nle_editor/domain/services/project_autosave_service.dart';

class AutosaveThrottleService {
  final ProjectAutosaveService autosaveService;
  final Debouncer _debouncer;

  AutosaveThrottleService({
    required this.autosaveService,
    Duration delay = const Duration(seconds: 2),
  }) : _debouncer = Debouncer(delay: delay);

  void scheduleProjectAutosave(String projectId) {
    _debouncer.run(() {
      autosaveService.autosaveProject(projectId);
    });
  }

  Future<void> flush(String projectId) async {
    _debouncer.cancel();
    await autosaveService.autosaveProject(projectId);
  }

  void dispose() {
    _debouncer.dispose();
  }
}
