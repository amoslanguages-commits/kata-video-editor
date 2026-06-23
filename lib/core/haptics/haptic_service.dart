import 'package:flutter/services.dart';

class HapticService {
  const HapticService();

  Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  Future<void> warning() async {
    await HapticFeedback.heavyImpact();
  }
}
