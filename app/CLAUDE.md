# Convenciones de código — Flutter

> Este archivo se aplica a todo lo que está bajo `app/`. Asumí que el `CLAUDE.md` raíz ya fue leído.

## Estructura del proyecto

```
app/lib/
├── main.dart
├── app.dart                          ← MaterialApp + ProviderScope + router
│
├── core/                             ← cosas transversales
│   ├── theme/
│   ├── router/
│   ├── extensions/
│   └── utils/
│
├── data/                             ← capa fina de Firestore
│   ├── firebase/
│   │   └── firebase_providers.dart   ← providers de FirebaseAuth, FirebaseFirestore
│   ├── models/                       ← clases que mapean 1:1 a Firestore
│   └── repositories/                 ← única forma de tocar Firestore
│
├── features/                         ← un folder por flujo del MVP
│   ├── auth/
│   ├── trips/                        ← Flujo 1: crear viaje + sumar al grupo
│   ├── itinerary/                    ← Flujo 2: itinerario + votación
│   ├── expenses/                     ← Flujo 3: gastos compartidos
│   ├── members/                      ← Flujo 4: gente + ajustes del viaje
│   └── trip_shell/                   ← contenedor de tabs dentro del viaje
│
└── shared/                           ← widgets reutilizables entre features
    └── widgets/
```

Cada feature puede contener:
- `presentation/` — pantallas (`*_screen.dart`) y widgets propios del feature en `presentation/widgets/`
- `application/` — notifiers de Riverpod (`*_notifier.dart`)
- `domain/` — lógica pura, calculadoras, validadores. **Solo si el feature lo necesita.** No agregar carpetas vacías por simetría.

## Reglas duras

1. **La UI nunca toca Firestore directo.** Los widgets en `presentation/` solo hablan con notifiers en `application/`. Los notifiers solo hablan con repositories en `data/repositories/`. Los repositories son los únicos que importan `cloud_firestore`.
   - Razón: si en v1.1 migramos a Supabase, tocamos solo los repositories.

2. **Lógica calculada va en `domain/`, no en widgets ni en notifiers.**
   - Cálculo de saldos → `features/expenses/domain/balance_calculator.dart`
   - Cálculo del footer del itinerario (totales, conversiones) → `features/itinerary/domain/itinerary_summary.dart`
   - Razón: testeable sin Flutter ni Firebase.

3. **Notifiers son `AsyncNotifier` o `StreamNotifier`.** No `ChangeNotifier`. No `StateNotifier` legacy.
   - `AsyncNotifier` para acciones puntuales (crear viaje, registrar gasto)
   - `StreamNotifier` para escucha en vivo de Firestore (lista de viajes, items, gastos)

4. **Una pantalla = un archivo `*_screen.dart` en `presentation/`.**
   - Si una pantalla crece, sus sub-widgets bajan a `presentation/widgets/` del mismo feature.

5. **Widgets reutilizados en 2+ features → `shared/widgets/`.** Si vive en un solo feature, queda dentro del feature. **No hay `shared/` preventivo.**

6. **Nada de carpetas `services/`, `helpers/`, `utils/` (más allá de `core/utils/`).** Son donde van a morir cosas que nadie sabe dónde poner. Si aparece algo verdaderamente transversal, va a `core/`. Si es de un feature, va al feature.

7. **Cero valores visuales hardcoded en widgets.** Colores, spacings, radii y estilos de texto **siempre** vienen del theme o de los tokens en `core/theme/`. Detalle en § Design system y tokens.

## Design system y tokens

La app **no tiene identidad visual definitiva** (PRD §8 lo marca como pendiente). Mientras tanto, todos los valores visuales viven centralizados en `lib/core/theme/`. Cuando llegue el branding, se modifican los tokens y la app se adapta — **no se tocan widgets**.

### Estructura

```
lib/core/theme/
├── app_colors.dart       ← seed color + ColorScheme.fromSeed (light/dark) + semánticos custom (success, warning)
├── app_typography.dart   ← TextTheme basado en Material 3, fuente del sistema por ahora
├── app_spacing.dart      ← scale 4-8-16-24-32-48 (xs/sm/md/lg/xl/xxl)
├── app_radii.dart        ← scale 8-12-16-24 + pill (sm/md/lg/xl/pill)
└── app_theme.dart        ← arma la ThemeData final (Cards, Buttons, Inputs, Chips, etc.)
```

### Reglas duras (no negociables)

1. **Cero `Color(0xFF...)` ni `Colors.blue` en widgets.** Siempre `Theme.of(context).colorScheme.<token>` (primary, surface, onSurface, error, etc.) o `AppColors.success` / `AppColors.warning` para los semánticos custom del producto.

2. **Cero `EdgeInsets.all(16)` ni `SizedBox(height: 24)` con números crudos.** Siempre `AppSpacing.md`, `AppSpacing.lg`, etc.

3. **Cero `BorderRadius.circular(8)` con número crudo.** Siempre `AppRadii.md`, `AppRadii.lg`, etc.

4. **Cero `TextStyle(fontSize: 16, fontWeight: ...)` instanciado a mano.** Siempre `Theme.of(context).textTheme.<role>` (bodyLarge, titleMedium, labelLarge, etc.). Si necesitás un peso o color distinto, `.copyWith(...)` puntual sobre el estilo del theme.

5. **Cero `ThemeData(...)` ni overrides de theme fuera de `app_theme.dart`.** Si querés cambiar el shape de un `Card` o el color de los `FilledButton`, se hace en el `_build` de `AppTheme`. Una pantalla **nunca** envuelve algo en `Theme(data: ..., child: ...)`.

6. **Si necesitás un valor que no está en los tokens, agregalo al token.** Ampliar la escala (ej: `AppSpacing.xxxl = 64`) está bien si el caso aparece más de una vez. Hardcodear "porque es un caso único" es deuda — en 6 meses nadie va a saber por qué ese widget tiene `padding: EdgeInsets.all(13)`.

### Cómo usar

```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'En curso · día 3 de 10',
            style: text.bodyMedium?.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
```

### Cuándo evolucionar a componentes (`shared/widgets/`)

No anticipadamente. Si un patrón visual (ej: card de viaje, chip de tag, fila de gasto) aparece en **2+ pantallas con la misma estructura**, ahí se extrae a `shared/widgets/<componente>.dart`. Antes no — citando regla del proyecto: si un patrón aparece una sola vez, queda concreto.

### Cuándo cambiar los tokens

- **Llega la identidad visual definitiva** → editar `app_colors.dart` (seed + semánticos), `app_typography.dart` (fontFamily + asset en pubspec), eventualmente `app_radii.dart` y `app_spacing.dart` si el sistema lo pide.
- **El diseñador entrega Figma con tokens nombrados** → mapear 1:1 a los archivos de `core/theme/`. Si la nomenclatura difiere, ajustar la nuestra para coincidir — no inventar paralelos.
- **Aparece un nuevo color semántico del producto** (ej: "info" para notificaciones) → agregarlo en `AppColors`, no en el widget que lo necesitó primero.

## Naming

| Tipo | Patrón | Ejemplo |
|---|---|---|
| Pantalla | `<nombre>_screen.dart` | `expenses_screen.dart` |
| Widget reutilizable | `<sustantivo>.dart` | `expense_card.dart` |
| Notifier de Riverpod | `<plural>_notifier.dart` | `expenses_notifier.dart` |
| Repository | `<plural>_repository.dart` | `expenses_repository.dart` |
| Modelo de Firestore | `<singular>_model.dart` | `expense_model.dart` |
| Lógica pura | `<sustantivo descriptivo>.dart` | `balance_calculator.dart` |

- Clases en `PascalCase`, archivos en `snake_case`. Convención estándar de Dart.
- Nombres descriptivos, no abreviados. `expense_form_screen.dart`, no `exp_form.dart`.

## Patrones de Riverpod

### Provider de un repository

```dart
final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ExpensesRepository(firestore);
});
```

### StreamNotifier para escucha en vivo

Usar para listas que se actualizan en tiempo real (gastos del viaje, items del itinerario, miembros).

```dart
class ExpensesNotifier extends AutoDisposeFamilyStreamNotifier<List<Expense>, String> {
  @override
  Stream<List<Expense>> build(String tripId) {
    return ref.watch(expensesRepositoryProvider).watchByTrip(tripId);
  }
}

final expensesProvider = StreamNotifierProvider.autoDispose
    .family<ExpensesNotifier, List<Expense>, String>(ExpensesNotifier.new);
```

### AsyncNotifier para acciones puntuales

Usar para mutaciones (crear, editar, borrar). Los métodos exponen el resultado y manejan estado loading/error.

```dart
class CreateExpenseNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(Expense expense) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(expensesRepositoryProvider).create(expense);
    });
  }
}
```

### autoDispose por default

Casi todos los providers van con `autoDispose` para no leakear listeners. La excepción son providers globales (auth, instancia de Firestore).

## Microcopy

- **Voseo siempre.** Tenés, pedile, saltá, creá, andá. No mezclar con tuteo.
- **Vocabulario LATAM compartido**, sin jerga local (no parche, parceros, chido, güey).
- **Patrón de estados vacíos:** "Acá no hay nada todavía. + [explicación corta de qué va a aparecer y cómo empezar] + [botón]". Ver `docs/06-identidad-y-tono.md` §4.
- **Microcopy ya validados del MVP** están en `docs/06-identidad-y-tono.md` §5. Usar esos textos exactos cuando se implemente la pantalla correspondiente.
- **No prometer privacidad falsa.** Si algo lo va a ver el grupo, decirlo claro.

## Tests

- **Sí se testea:** lógica pura en `domain/`. Sobre todo el cálculo de saldos y la simplificación de transferencias — ahí es donde hay bugs que duelen.
- **No se testea en MVP:** widgets, screens, integración. Es trabajo que rinde poco para el Caso 0.
- **Estructura espejo en `test/`:** `test/features/expenses/domain/balance_calculator_test.dart`.

## Lo que NO hacer

- No agregar Cloud Functions (sin backend en MVP).
- No agregar paquete de internacionalización (`intl`/`l10n`). Solo español hardcodeado.
- No agregar features fuera del scope del MVP. Lista en `docs/03-mvp-scope.md` §4.
- No mezclar state managements (no agregar Bloc, ChangeNotifier, GetX).
- No agregar dependencias "por si acaso". Cada paquete suma peso, riesgo y mantenimiento.
- No abstraer prematuramente. Si un patrón aparece una sola vez, dejalo concreto. Si aparece la segunda, recién evaluar abstracción.
- **No hardcodear valores visuales en widgets.** Colores, spacings, radii, estilos de texto siempre desde el theme o tokens en `core/theme/`. Ver § Design system y tokens.
- No crear una librería de componentes custom (`AppButton`, `AppCard`, etc.) preventiva. Material 3 + tokens alcanza hasta que un patrón se repita 2+ veces.

## Dependencias permitidas

Las que decidimos. Cualquier otra requiere justificación explícita.

- `flutter` (SDK)
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `flutter_riverpod`, `riverpod_annotation` (si decidimos generación)
- `go_router` (navegación)
- `intl` (formato de fechas y números, no internacionalización)

## Referencias rápidas

- Modelo de datos: `docs/05-modelo-datos-2.md`
- Wireframes: `docs/04-wireframes-mvp-2.md`
- Tono y microcopy: `docs/06-identidad-y-tono.md`
- Scope: `docs/03-mvp-scope.md`
