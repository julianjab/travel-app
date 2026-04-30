/// Escala de espaciado de la app. Base 4px.
///
/// Reglas en `app/CLAUDE.md` § Design system y tokens:
/// - Cero `EdgeInsets.all(16)` en widgets. Usar `AppSpacing.md`.
/// - Si necesitás un valor que no está acá, ampliá la escala — no hardcodees.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
