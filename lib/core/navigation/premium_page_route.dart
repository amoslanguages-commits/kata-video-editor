import 'package:flutter/material.dart';

import 'package:nle_editor/core/ui/premium_ui_tokens.dart';

class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  PremiumPageRoute({
    required this.page,
  }) : super(
          transitionDuration: PremiumMotion.normal,
          reverseTransitionDuration: PremiumMotion.fast,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: PremiumMotion.curve,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0.02),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
