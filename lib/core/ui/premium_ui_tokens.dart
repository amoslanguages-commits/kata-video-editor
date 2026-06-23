import 'package:flutter/material.dart';

class PremiumSpacing {
  PremiumSpacing._();

  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double xxl = 32;
  static const double section = 44;
}

class PremiumRadius {
  PremiumRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 30;
  static const double pill = 999;
}

class PremiumMotion {
  PremiumMotion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve entranceCurve = Curves.easeOutBack;
}

class PremiumShadows {
  PremiumShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.18),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glow(Color color) {
    return [
      BoxShadow(
        color: color.withOpacity(0.22),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }
}

class PremiumGradients {
  PremiumGradients._();

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF121A2A),
      Color(0xFF152E42),
      Color(0xFF271B47),
    ],
  );

  static const LinearGradient proGold = LinearGradient(
    colors: [
      Color(0xFFFFD36A),
      Color(0xFFFF8A00),
    ],
  );

  static const LinearGradient cyanGlow = LinearGradient(
    colors: [
      Color(0xFF00E5FF),
      Color(0xFF7C4DFF),
    ],
  );

  static const LinearGradient brandGlow = LinearGradient(
    colors: [
      Color(0xFF00E5FF),
      Color(0xFF7C4DFF),
    ],
  );
}
