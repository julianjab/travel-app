import 'package:flutter/material.dart';
import 'vamos_colors.dart';

/// Sistema tipográfico de Vamos.
/// Tres familias con roles estrictos:
///   - Space Grotesk (display) → títulos, hero, wordmark
///   - Inter (ui)              → todo el resto del UI
///   - JetBrains Mono (mono)   → datos numéricos, IDs, timestamps, overlines
class VamosTypography {
  VamosTypography._();

  // === Families (constantes para reusar) ===
  static const String fontDisplay = 'SpaceGrotesk';
  static const String fontUI      = 'Inter';
  static const String fontMono    = 'JetBrainsMono';

  // === Display · Space Grotesk ===
  static const TextStyle displayXL = TextStyle(
    fontFamily: fontDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 64,
    height: 1.0,
    letterSpacing: -2.56, // -0.04em a 64px
    color: VamosColors.text,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 48,
    height: 1.05,
    letterSpacing: -1.68, // -0.035em
    color: VamosColors.text,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontDisplay,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.1,
    letterSpacing: -0.8,
    color: VamosColors.text,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontDisplay,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 1.2,
    letterSpacing: -0.33,
    color: VamosColors.text,
  );

  // === UI · Inter ===
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontUI,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 1.3,
    letterSpacing: -0.085,
    color: VamosColors.text,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontUI,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    color: VamosColors.text,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontUI,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
    color: VamosColors.text2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontUI,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.4,
    letterSpacing: 0.12,
    color: VamosColors.text3,
  );

  // === Mono · JetBrains Mono · solo datos ===
  static const TextStyle monoMedium = TextStyle(
    fontFamily: fontMono,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.4,
    color: VamosColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle monoLarge = TextStyle(
    fontFamily: fontMono,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.3,
    color: VamosColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Overline mono para etiquetas de sección, eyebrows
  static const TextStyle overline = TextStyle(
    fontFamily: fontMono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 1.4,
    letterSpacing: 1.32, // 0.12em a 11px
    color: VamosColors.text3,
  );
}
