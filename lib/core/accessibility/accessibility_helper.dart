import 'package:flutter/material.dart';

class AccessibilityHelper {
  AccessibilityHelper._();

  static Widget wrap({
    required Widget child,
    required String label,
    String? hint,
    bool? button,
    bool? selected,
    bool? enabled,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      selected: selected,
      enabled: enabled,
      child: child,
    );
  }
}

extension AccessibilityWidgetExtension on Widget {
  Widget withSemantics({
    required String label,
    String? hint,
    bool? button,
    bool? selected,
    bool? enabled,
  }) {
    return AccessibilityHelper.wrap(
      child: this,
      label: label,
      hint: hint,
      button: button,
      selected: selected,
      enabled: enabled,
    );
  }
}
