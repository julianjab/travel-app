import 'package:flutter/material.dart';

/// Tipografía de la app.
///
/// **Estado:** usa la fuente del sistema (San Francisco en iOS, Roboto en
/// Android) y la escala default de Material 3. Cuando llegue la identidad
/// visual, cambiar `fontFamily` (y agregar el asset en `pubspec.yaml`)
/// actualiza toda la app.
///
/// Reglas en `app/CLAUDE.md` § Design system y tokens:
/// - Cero `TextStyle(fontSize: 16, ...)` instanciado en widgets.
/// - Siempre `Theme.of(context).textTheme.<role>` (bodyLarge, titleMedium,
///   etc.). Si necesitás un peso o color distinto, `.copyWith(...)` puntual.
abstract final class AppTypography {
  AppTypography._();

  /// `null` = fuente del sistema. Reemplazar por el nombre de la familia
  /// custom cuando se sume al `pubspec.yaml`.
  static const String? fontFamily = null;

  static TextTheme textTheme(ColorScheme scheme) {
    final base = Typography.material2021(
      platform: TargetPlatform.iOS,
      colorScheme: scheme,
    ).black;
    return base.apply(
      fontFamily: fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
  }
}
