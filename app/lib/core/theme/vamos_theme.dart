import 'package:flutter/material.dart';
import 'vamos_colors.dart';
import 'vamos_spacing.dart';
import 'vamos_typography.dart';

/// ThemeData de Vamos (Material 3, cross-platform iOS + Android).
///
/// Usage in app.dart:
///   MaterialApp(theme: VamosTheme.light, darkTheme: VamosTheme.dark)
class VamosTheme {
  VamosTheme._();

  static final ThemeData light = _build(
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
    scaffoldBg: VamosColors.bg,
    textDark: false,
  );

  static final ThemeData dark = _build(
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
    scaffoldBg: VamosColors.bgDark,
    textDark: true,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required bool textDark,
  }) {
    final textTheme = textDark
        ? TextTheme(
            displayLarge: VamosTypography.displayLarge.copyWith(color: VamosColors.textDark),
            displayMedium: VamosTypography.displayMedium.copyWith(color: VamosColors.textDark),
            displaySmall: VamosTypography.headlineMedium.copyWith(color: VamosColors.textDark),
            headlineLarge: VamosTypography.displayMedium.copyWith(color: VamosColors.textDark),
            headlineMedium: VamosTypography.headlineMedium.copyWith(color: VamosColors.textDark),
            headlineSmall: VamosTypography.titleMedium.copyWith(color: VamosColors.textDark),
            titleLarge: VamosTypography.titleMedium.copyWith(color: VamosColors.textDark),
            titleMedium: VamosTypography.titleMedium.copyWith(color: VamosColors.textDark),
            bodyLarge: VamosTypography.bodyLarge.copyWith(color: VamosColors.textDark),
            bodyMedium: VamosTypography.bodyMedium.copyWith(color: VamosColors.text2Dark),
            bodySmall: VamosTypography.caption.copyWith(color: VamosColors.text3Dark),
            labelLarge: VamosTypography.titleMedium.copyWith(color: VamosColors.textDark),
            labelMedium: VamosTypography.caption.copyWith(color: VamosColors.text3Dark),
            labelSmall: VamosTypography.overline.copyWith(color: VamosColors.text3Dark),
          )
        : const TextTheme(
            displayLarge: VamosTypography.displayLarge,
            displayMedium: VamosTypography.displayMedium,
            displaySmall: VamosTypography.headlineMedium,
            headlineLarge: VamosTypography.displayMedium,
            headlineMedium: VamosTypography.headlineMedium,
            headlineSmall: VamosTypography.titleMedium,
            titleLarge: VamosTypography.titleMedium,
            titleMedium: VamosTypography.titleMedium,
            bodyLarge: VamosTypography.bodyLarge,
            bodyMedium: VamosTypography.bodyMedium,
            bodySmall: VamosTypography.caption,
            labelLarge: VamosTypography.titleMedium,
            labelMedium: VamosTypography.caption,
            labelSmall: VamosTypography.overline,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      fontFamily: VamosTypography.fontUI,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        // Space Grotesk 22px per kit spec — differentiates from Inter body text.
        titleTextStyle: textDark
            ? VamosTypography.headlineMedium.copyWith(color: VamosColors.textDark)
            : VamosTypography.headlineMedium,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: VamosRadius.brLg,
          side: BorderSide(color: colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: VamosSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: VamosRadius.brMd),
          textStyle: VamosTypography.titleMedium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: VamosRadius.brMd),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: VamosRadius.brMd),
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: VamosRadius.brMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VamosRadius.brMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VamosRadius.brMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
        side: BorderSide.none,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: VamosRadius.brMd),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: VamosRadius.brLg),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: VamosRadius.lg),
        ),
      ),

      dividerColor: colorScheme.outline,
    );
  }
}
