class JobPriorityLevel {
  JobPriorityLevel._();

  static const int urgent = 100;
  static const int high = 75;
  static const int normal = 50;
  static const int low = 25;
  static const int idle = 5;
}

class BackgroundJobPriorityTuner {
  int priorityFor({
    required String jobType,
    required bool userWaiting,
    required bool deviceUnderStress,
  }) {
    if (userWaiting) {
      return JobPriorityLevel.urgent;
    }

    if (deviceUnderStress) {
      if (jobType == 'export') return JobPriorityLevel.normal;
      if (jobType == 'proxy') return JobPriorityLevel.low;
      return JobPriorityLevel.idle;
    }

    switch (jobType) {
      case 'export':
        return JobPriorityLevel.high;
      case 'proxy':
        return JobPriorityLevel.normal;
      case 'thumbnail':
        return JobPriorityLevel.low;
      case 'waveform':
        return JobPriorityLevel.low;
      case 'autosave':
        return JobPriorityLevel.idle;
      default:
        return JobPriorityLevel.normal;
    }
  }
}
