import 'package:flutter/material.dart';

/// Tokens de color de la app.
///
/// **Estado:** placeholder neutro. La identidad visual está pendiente
/// (PRD §8). Cuando llegue el branding, cambiar `seed` regenera todo el
/// `ColorScheme`. Los semánticos custom (`success`, `warning`) también
/// se ajustan acá.
///
/// Reglas en `app/CLAUDE.md` § Design system y tokens:
/// - Cero `Color(0xFF...)` ni `Colors.blue` en widgets.
/// - Color principal y derivados: `Theme.of(context).colorScheme.<token>`.
/// - Custom semánticos del producto: `AppColors.success`, `AppColors.warning`.
abstract final class AppColors {
  AppColors._();

  /// Color semilla del branding. Cambiar acá regenera el `ColorScheme`
  /// completo (primary, secondary, tertiary, surfaces, etc.).
  static const Color seed = Color(0xFF3B5BDB);

  /// Verde de éxito. Usado en estados positivos: items confirmados,
  /// saldos a favor, transferencias marcadas como pagadas.
  static const Color success = Color(0xFF2F9E44);

  /// Ámbar de advertencia. Usado en estados intermedios: items en
  /// votación, saldos pendientes, viajes "por planear".
  static const Color warning = Color(0xFFF59F00);

  static ColorScheme light() => ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      );

  static ColorScheme dark() => ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      );
}
