/// Escala de border radius de la app.
///
/// Reglas en `app/CLAUDE.md` § Design system y tokens:
/// - Cero `BorderRadius.circular(8)` con número crudo. Usar `AppRadii.sm`.
abstract final class AppRadii {
  AppRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}
