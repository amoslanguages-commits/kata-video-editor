import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color editorBackground = Color(0xFF0D0D0D);
  static const Color background = editorBackground;
  static const Color surfaceDark = Color(0xFF141414);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfaceMedium = surfaceElevated;
  static const Color surfaceOverlay = Color(0xFF2C2C2C);

  static const Color borderSubtle = Color(0xFF333333);
  static const Color border = borderSubtle;
  static const Color borderHighlight = Color(0xFF555555);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF808080);
  static const Color textDisabled = Color(0xFF666666);

  static const Color accentPrimary = Color(0xFF00D2FF);
  static const Color accentSecondary = Color(0xFF3A86FF);
  static const Color accentGradientStart = Color(0xFF00D2FF);
  static const Color accentGradientEnd = Color(0xFF3A86FF);

  static const Color timelineBackground = Color(0xFF141414);
  static const Color trackVideo = Color(0xFF2D1F3D);
  static const Color trackAudio = Color(0xFF1F2D3D);
  static const Color trackText = Color(0xFF3D2D1F);
  static const Color trackOverlay = Color(0xFF1F3D2D);

  static const Color playhead = Color(0xFFFF3366);
  static const Color selection = Color(0xFF00D2FF);

  static const Color warning = Color(0xFFFFA500);
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF00CC66);

  static const Color clipVideo = Color(0xFF4A3B5C);
  static const Color clipAudio = Color(0xFF3B4A5C);
  static const Color clipText = Color(0xFF5C4A3B);
  static const Color clipImage = Color(0xFF3B5C4A);

  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;
  static const double borderRadiusXLarge = 24;

  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: editorBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: surfaceDark,
        surfaceContainerHighest: surfaceElevated,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: borderSubtle,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: editorBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textMuted,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 0.5,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusLarge),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Pill shape for premium feel
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderSubtle),
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Pill shape
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPrimary,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentPrimary,
        inactiveTrackColor: surfaceOverlay,
        thumbColor: accentPrimary,
        overlayColor: accentPrimary.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
    );
  }
}
