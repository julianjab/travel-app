# Code conventions — Flutter

> This file applies to everything under `app/`. Assume the root `CLAUDE.md` has already been read.

## Project structure

```
app/lib/
├── main.dart
├── app.dart                          ← MaterialApp + ProviderScope + router
│
├── core/                             ← cross-cutting concerns
│   ├── theme/
│   ├── router/
│   ├── extensions/
│   └── utils/
│
├── data/                             ← thin Firestore layer
│   ├── firebase/
│   │   └── firebase_providers.dart   ← FirebaseAuth, FirebaseFirestore providers
│   ├── models/                       ← classes mapping 1:1 to Firestore
│   └── repositories/                 ← the only way to touch Firestore
│
├── features/                         ← one folder per MVP flow
│   ├── auth/
│   ├── trips/                        ← Flow 1: create trip + add to group
│   ├── itinerary/                    ← Flow 2: itinerary + voting
│   ├── expenses/                     ← Flow 3: shared expenses
│   ├── members/                      ← Flow 4: people + trip settings
│   └── trip_shell/                   ← container for in-trip tabs
│
└── shared/                           ← widgets reused across features
    └── widgets/
```

Each feature may contain:
- `presentation/` — screens (`*_screen.dart`) and feature-specific widgets in `presentation/widgets/`
- `application/` — Riverpod notifiers (`*_notifier.dart`)
- `domain/` — pure logic, calculators, validators. **Only if the feature needs it.** Don't add empty folders for symmetry.

## Hard rules

1. **The UI never touches Firestore directly.** Widgets in `presentation/` only talk to notifiers in `application/`. Notifiers only talk to repositories in `data/repositories/`. Repositories are the only ones importing `cloud_firestore`.
   - Reason: if we migrate to Supabase in v1.1, we touch only the repositories.

2. **Computed logic lives in `domain/`, not in widgets or notifiers.**
   - Balance calculation → `features/expenses/domain/balance_calculator.dart`
   - Itinerary footer (totals, conversions) → `features/itinerary/domain/itinerary_summary.dart`
   - Reason: testable without Flutter or Firebase.

3. **Notifiers are `AsyncNotifier` or `StreamNotifier`.** Not `ChangeNotifier`. Not legacy `StateNotifier`.
   - `AsyncNotifier` for one-off actions (create trip, register expense)
   - `StreamNotifier` for live Firestore listening (trip list, items, expenses)

4. **One screen = one `*_screen.dart` file in `presentation/`.**
   - When a screen grows, its sub-widgets move down to `presentation/widgets/` of the same feature.

5. **Widgets reused in 2+ features → `shared/widgets/`.** If it lives in only one feature, it stays inside the feature. **No preventive `shared/`.**

6. **No `services/`, `helpers/`, `utils/` folders (beyond `core/utils/`).** That's where things go to die because no one knows where to put them. If something is truly cross-cutting, it goes to `core/`. If it's per-feature, it goes to the feature.

7. **Zero hardcoded visual values in widgets.** Colors, spacings, radii, and text styles **always** come from the theme or tokens in `core/theme/`. Detail in § Design system and tokens.

## Design system and tokens

The app **does not have a final visual identity** (PRD §8 marks it as pending). Meanwhile, all visual values live centralized in `lib/core/theme/`. When branding arrives, the tokens are modified and the app adapts — **widgets are not touched**.

### Structure

```
lib/core/theme/
├── app_colors.dart       ← seed color + ColorScheme.fromSeed (light/dark) + custom semantic (success, warning)
├── app_typography.dart   ← TextTheme based on Material 3, system font for now
├── app_spacing.dart      ← scale 4-8-16-24-32-48 (xs/sm/md/lg/xl/xxl)
├── app_radii.dart        ← scale 8-12-16-24 + pill (sm/md/lg/xl/pill)
└── app_theme.dart        ← assembles the final ThemeData (Cards, Buttons, Inputs, Chips, etc.)
```

### Hard rules (non-negotiable)

1. **No `Color(0xFF...)` or `Colors.blue` in widgets.** Always `Theme.of(context).colorScheme.<token>` (primary, surface, onSurface, error, etc.) or `AppColors.success` / `AppColors.warning` for the product's custom semantics.

2. **No `EdgeInsets.all(16)` or `SizedBox(height: 24)` with raw numbers.** Always `AppSpacing.md`, `AppSpacing.lg`, etc.

3. **No `BorderRadius.circular(8)` with raw numbers.** Always `AppRadii.md`, `AppRadii.lg`, etc.

4. **No `TextStyle(fontSize: 16, fontWeight: ...)` instantiated by hand.** Always `Theme.of(context).textTheme.<role>` (bodyLarge, titleMedium, labelLarge, etc.). If you need a different weight or color, use a spot `.copyWith(...)` over the theme style.

5. **No `ThemeData(...)` or theme overrides outside `app_theme.dart`.** If you want to change the shape of a `Card` or the color of `FilledButton`, do it in `_build` of `AppTheme`. A screen **never** wraps something in `Theme(data: ..., child: ...)`.

6. **If you need a value not in the tokens, add it to the token.** Extending the scale (e.g., `AppSpacing.xxxl = 64`) is fine if the case appears more than once. Hardcoding "because it's a one-off case" is debt — in 6 months no one will know why that widget has `padding: EdgeInsets.all(13)`.

### How to use

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

### When to evolve to components (`shared/widgets/`)

Not anticipatorily. If a visual pattern (e.g., trip card, tag chip, expense row) appears in **2+ screens with the same structure**, then it's extracted to `shared/widgets/<component>.dart`. Not before — citing the project rule: if a pattern appears only once, it stays concrete.

### When to change the tokens

- **Final visual identity arrives** → edit `app_colors.dart` (seed + semantics), `app_typography.dart` (fontFamily + asset in pubspec), eventually `app_radii.dart` and `app_spacing.dart` if the system asks.
- **The designer delivers Figma with named tokens** → map 1:1 to the files in `core/theme/`. If the naming differs, adjust ours to match — don't invent parallels.
- **A new product semantic color appears** (e.g., "info" for notifications) → add it in `AppColors`, not in the widget that needed it first.

## Naming

| Type | Pattern | Example |
|---|---|---|
| Screen | `<name>_screen.dart` | `expenses_screen.dart` |
| Reusable widget | `<noun>.dart` | `expense_card.dart` |
| Riverpod notifier | `<plural>_notifier.dart` | `expenses_notifier.dart` |
| Repository | `<plural>_repository.dart` | `expenses_repository.dart` |
| Firestore model | `<singular>_model.dart` | `expense_model.dart` |
| Pure logic | `<descriptive_noun>.dart` | `balance_calculator.dart` |

- Classes in `PascalCase`, files in `snake_case`. Standard Dart convention.
- Descriptive, not abbreviated. `expense_form_screen.dart`, not `exp_form.dart`.

## Riverpod patterns

### Repository provider

```dart
final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ExpensesRepository(firestore);
});
```

### StreamNotifier for live listening

Use for lists that update in real time (trip expenses, itinerary items, members).

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

### AsyncNotifier for one-off actions

Use for mutations (create, edit, delete). Methods expose the result and handle loading/error state.

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

### autoDispose by default

Almost all providers go with `autoDispose` to avoid leaking listeners. The exception is global providers (auth, Firestore instance).

## Microcopy

- **Voseo always.** Tenés, pedile, saltá, creá, andá. Don't mix with tuteo.
- **Shared LATAM vocabulary**, no local slang (no parche, parceros, chido, güey).
- **Empty-state pattern:** "Acá no hay nada todavía. + [short explanation of what will appear and how to start] + [button]". See `docs/06-identidad-y-tono.md` §4.
- **Validated MVP microcopy** lives in `docs/06-identidad-y-tono.md` §5. Use those exact strings when implementing the corresponding screen.
- **Don't promise false privacy.** If something will be seen by the group, say it clearly.

## Dependencias y override pattern

### When to declare a repository as an interface

Every data-layer repository has **two files**:

```
app/lib/data/repositories/
├── <plural>_repository.dart              ← abstract class (the contract)
└── firestore_<plural>_repository.dart    ← Firestore impl + Riverpod provider
```

The abstract class is the public surface. Notifiers, widgets, and tests depend on
it. The `Firestore*` implementation is the only file that imports `cloud_firestore`.

Rule: **if the feature talks to Firestore, there must be an abstract repo for it**.
Non-data abstractions (router, theme, auth state) are NOT abstracted this way.

### Provider always returns the abstract type

```dart
// In firestore_trip_repository.dart
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return FirestoreTripRepository(ref.watch(firestoreProvider));
});
```

Consumers never reference `FirestoreTripRepository`. They only import
`trip_repository.dart` (the abstract type) and `firestore_trip_repository.dart`
(for the provider symbol).

### How to override in tests

```dart
// In your test file:
final mock = MockTripRepository()..setTrips([trip1, trip2]);

await tester.pumpWidget(
  ProviderScope(
    overrides: [
      tripRepositoryProvider.overrideWithValue(mock),
      currentUserIdProvider.overrideWithValue('user_test'),
    ],
    child: MaterialApp.router(routerConfig: _testRouter),
  ),
);
```

No Firebase needed. No `fake_cloud_firestore` needed for simple tests.
Mock lives in `test/data/mocks/mock_<plural>_repository.dart`.

### How to override in dev mode (main_dev.dart)

```dart
// lib/main_dev.dart — run with: flutter run -t lib/main_dev.dart
runApp(
  ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user_dev'),
      tripRepositoryProvider.overrideWithValue(
        MockTripRepository()..setTrips(TripFixtures.sortedSet()),
      ),
    ],
    child: const VamosApp(),
  ),
);
```

Imports the mock from `test/data/mocks/` — that's intentional. The mock is
test infrastructure shared between unit tests and the dev entry point.

### Hypothetical backend migration (Supabase, etc.)

If the backend changes, the only file that changes is the Firestore impl
and the provider line:

```dart
// Before:
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return FirestoreTripRepository(ref.watch(firestoreProvider));
});

// After migrating to Supabase:
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return SupabaseTripRepository(ref.watch(supabaseProvider));
});
```

Zero changes in notifiers, screens, or tests. That's the point.

### Platform variant (web vs mobile) — when needed

If a future web variant needs a different impl, add a branch in the provider:

```dart
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  if (kIsWeb) return WebTripRepository(ref.watch(httpClientProvider));
  return FirestoreTripRepository(ref.watch(firestoreProvider));
});
```

Don't anticipate this. Add it when it's actually needed.

### currentUserIdProvider

A simple overrideable provider for the authenticated user ID:

```dart
// Default: empty string (unauthenticated). Override in tests and dev.
final currentUserIdProvider = Provider<String>((ref) => '');
```

TODO(E0-06): replace the default with the real auth provider once Firebase
Auth is wired: `ref.watch(authStateProvider).value?.uid ?? ''`.

## Tests

- **What's tested:** pure logic in `domain/`. Especially balance calculation and transfer simplification — that's where the painful bugs live.
- **Widget tests with override:** use `ProviderScope(overrides: [...])` + `MockXxxRepository`. See `test/features/trips/presentation/my_trips_screen_test.dart` as reference.
- **What's NOT tested in MVP:** integration, golden, or screenshot tests. Low ROI for Case 0.
- **Mirror structure in `test/`:** `test/features/expenses/domain/balance_calculator_test.dart`.
- **Test names and inline comments are written in English.**

## What NOT to do

- Don't add Cloud Functions (no backend in MVP).
- Don't add internationalization packages (`intl`/`l10n`). Spanish hardcoded only.
- Don't add features outside MVP scope. List in `docs/03-mvp-scope.md` §4.
- Don't mix state managements (no Bloc, ChangeNotifier, GetX).
- Don't add dependencies "just in case". Each package adds weight, risk, and maintenance.
- Don't abstract prematurely. If a pattern appears once, leave it concrete. If it appears a second time, then evaluate abstraction.
- **Don't hardcode visual values in widgets.** Colors, spacings, radii, text styles always from theme or tokens in `core/theme/`. See § Design system and tokens.
- Don't create a custom component library (`AppButton`, `AppCard`, etc.) preventively. Material 3 + tokens is enough until a pattern repeats 2+ times.

## Allowed dependencies

The ones we decided. Anything else requires explicit justification.

- `flutter` (SDK)
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `flutter_riverpod`, `riverpod_annotation` (if we decide on codegen)
- `go_router` (navigation)
- `intl` (date and number formatting, NOT internationalization)
- `decimal` (money handling, mandatory for any monetary calculation)

## Quick references

- Data model: `docs/05-modelo-datos-2.md`
- Wireframes: `docs/04-wireframes-mvp-2.md`
- Tone and microcopy: `docs/06-identidad-y-tono.md`
- Scope: `docs/03-mvp-scope.md`
