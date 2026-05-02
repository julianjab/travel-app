import 'package:flutter/material.dart';

/// Paleta completa de Vamos.
/// Espejo 1:1 de tokens/design_tokens.json.
/// NUNCA usar Color(0xFF...) directo — siempre referenciar acá.
class VamosColors {
  VamosColors._();

  // === Sol · marca ===
  static const Color sol50  = Color(0xFFFFF5ED);
  static const Color sol100 = Color(0xFFFFE9DC);
  static const Color sol200 = Color(0xFFFFD2B8);
  static const Color sol300 = Color(0xFFFFAB80);
  static const Color sol400 = Color(0xFFFF8550);
  static const Color sol500 = Color(0xFFFF5A1F); // light mode
  static const Color sol600 = Color(0xFFE84812);
  static const Color sol700 = Color(0xFFB8370D);

  /// Naranja calentado para dark mode (el sol500 vibra demasiado en dark)
  static const Color sol500Dark = Color(0xFFFF7A45);

  // === Backgrounds ===
  static const Color bg         = Color(0xFFF8F4EA); // light
  static const Color bgDark     = Color(0xFF1A1612); // dark · grafito de marca
  static const Color surface    = Color(0xFFFFFDF7);
  static const Color surface2   = Color(0xFFF0EADD);
  static const Color surfaceDark   = Color(0xFF26201A);
  static const Color surface2Dark  = Color(0xFF332B23);

  // === Text ===
  static const Color text       = Color(0xFF1A1612);
  static const Color text2      = Color(0xFF3D352C);
  static const Color text3      = Color(0xFF6E6356);
  static const Color textMuted  = Color(0xFFB5AB9B);
  static const Color textOnDark = Color(0xFFFFFDF7);

  static const Color textDark      = Color(0xFFFFFDF7);
  static const Color text2Dark     = Color(0xFFD4CCC0);
  static const Color text3Dark     = Color(0xFF9B9285);

  // === Border ===
  static const Color border     = Color(0xFFE6DFD2);
  static const Color borderDark = Color(0xFF3D352C);

  // === Semantic ===
  static const Color red     = Color(0xFFC43D2A);
  static const Color green   = Color(0xFF2F7D4F);
  // Product-specific: no equivalent in base kit. Used for pending/warning states.
  static const Color warning = Color(0xFFF59F00);
}
