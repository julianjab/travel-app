import 'package:flutter/material.dart';
import 'vamos_colors.dart';
import 'vamos_typography.dart';

/// ThemeData de Vamos para Flutter (Material 3).
/// Cross-platform: mismo theme en iOS y Android.
///
/// Uso en main.dart:
///   MaterialApp(
///     theme: VamosTheme.light,
///     darkTheme: VamosTheme.dark,
///   )
class VamosTheme {
  VamosTheme._();

  // ===========================================================================
  // LIGHT
  // ===========================================================================
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      primary: VamosColors.sol500,
      onPrimary: VamosColors.textOnDark,
      primaryContainer: VamosColors.sol100,
      onPrimaryContainer: VamosColors.sol700,

      secondary: VamosColors.text,
      onSecondary: VamosColors.textOnDark,

      surface: VamosColors.surface,
      onSurface: VamosColors.text,
      surfaceContainerHighest: VamosColors.surface2,

      error: VamosColors.red,
      onError: VamosColors.textOnDark,

      outline: VamosColors.border,
      outlineVariant: VamosColors.surface2,
    ),

    scaffoldBackgroundColor: VamosColors.bg,
    canvasColor: VamosColors.bg,

    fontFamily: VamosTypography.fontUI,

    textTheme: const TextTheme(
      displayLarge:   VamosTypography.displayLarge,
      displayMedium:  VamosTypography.displayMedium,
      displaySmall:   VamosTypography.headlineMedium,
      headlineLarge:  VamosTypography.displayMedium,
      headlineMedium: VamosTypography.headlineMedium,
      headlineSmall:  VamosTypography.titleMedium,
      titleLarge:     VamosTypography.titleMedium,
      titleMedium:    VamosTypography.titleMedium,
      bodyLarge:      VamosTypography.bodyLarge,
      bodyMedium:     VamosTypography.bodyMedium,
      bodySmall:      VamosTypography.caption,
      labelLarge:     VamosTypography.titleMedium,
      labelMedium:    VamosTypography.caption,
      labelSmall:     VamosTypography.overline,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VamosColors.sol500,
        foregroundColor: VamosColors.textOnDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: VamosTypography.titleMedium.copyWith(color: VamosColors.textOnDark),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VamosColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: VamosColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: VamosColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: VamosColors.sol500, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: VamosColors.bg,
      foregroundColor: VamosColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: VamosTypography.headlineMedium,
    ),

    dividerColor: VamosColors.border,
  );

  // ===========================================================================
  // DARK
  // ===========================================================================
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary: VamosColors.sol500Dark,
      onPrimary: VamosColors.bgDark,
      primaryContainer: Color(0xFF4A2818),
      onPrimaryContainer: VamosColors.sol200,

      secondary: VamosColors.textDark,
      onSecondary: VamosColors.bgDark,

      surface: VamosColors.surfaceDark,
      onSurface: VamosColors.textDark,
      surfaceContainerHighest: VamosColors.surface2Dark,

      error: VamosColors.red,
      onError: VamosColors.textDark,

      outline: VamosColors.borderDark,
    ),

    scaffoldBackgroundColor: VamosColors.bgDark,
    canvasColor: VamosColors.bgDark,
    fontFamily: VamosTypography.fontUI,

    textTheme: TextTheme(
      displayLarge:   VamosTypography.displayLarge.copyWith(color: VamosColors.textDark),
      displayMedium:  VamosTypography.displayMedium.copyWith(color: VamosColors.textDark),
      headlineMedium: VamosTypography.headlineMedium.copyWith(color: VamosColors.textDark),
      titleMedium:    VamosTypography.titleMedium.copyWith(color: VamosColors.textDark),
      bodyLarge:      VamosTypography.bodyLarge.copyWith(color: VamosColors.textDark),
      bodyMedium:     VamosTypography.bodyMedium.copyWith(color: VamosColors.text2Dark),
      bodySmall:      VamosTypography.caption.copyWith(color: VamosColors.text3Dark),
      labelSmall:     VamosTypography.overline.copyWith(color: VamosColors.text3Dark),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: VamosColors.bgDark,
      foregroundColor: VamosColors.textDark,
      elevation: 0,
      centerTitle: false,
    ),

    dividerColor: VamosColors.borderDark,
  );
}
