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

The app uses the **Vamos Design Kit** (`vamos-design-kit/`). The Flutter files live in `lib/core/theme/` (copied from `vamos-design-kit/flutter/`). When tokens change, only those files are touched — widgets are never modified directly.

### Structure

```
lib/core/theme/
├── vamos_colors.dart      ← full palette + semantic colors (sol, bg, text, border, red, green)
├── vamos_typography.dart  ← three font families with strict roles (Space Grotesk, Inter, JetBrains Mono)
├── vamos_spacing.dart     ← spacing scale (xs/sm/md/lg/xl/xxl/xxxl) + VamosRadius + VamosShadow
├── vamos_theme.dart       ← ThemeData light + dark assembled with the tokens above
└── vamos_logo.dart        ← VamosLogo and VamosLogoMark widgets
```

Font families and their roles (enforced):
- **Space Grotesk** (`fontDisplay`) → display titles, hero, wordmark only
- **Inter** (`fontUI`) → all other UI text
- **JetBrains Mono** (`fontMono`) → numeric data, IDs, timestamps, overlines **only**

### Hard rules (non-negotiable)

1. **No `Color(0xFF...)` or `Colors.blue` in widgets.** Always `VamosColors.<token>` (e.g., `VamosColors.sol500`, `VamosColors.bg`, `VamosColors.text`) or `Theme.of(context).colorScheme.<role>` for Material roles.

2. **No `EdgeInsets.all(16)` or `SizedBox(height: 24)` with raw numbers.** Always `VamosSpacing.md` (16), `VamosSpacing.lg` (24), etc.

3. **No `BorderRadius.circular(8)` with raw numbers.** Always `VamosRadius.brMd`, `VamosRadius.brLg`, etc.

4. **No `TextStyle(fontSize: 16, fontWeight: ...)` instantiated by hand.** Always `VamosTypography.<style>` (e.g., `VamosTypography.bodyMedium`, `VamosTypography.monoLarge`) or `Theme.of(context).textTheme.<role>`. For spot adjustments, use `.copyWith(...)`.

5. **Mono font only for data.** `VamosTypography.monoMedium` / `monoLarge` / `overline` are for amounts, dates, IDs, and overline labels — never for regular UI text.

6. **No `ThemeData(...)` or theme overrides outside `vamos_theme.dart`.** A screen **never** wraps a subtree in `Theme(data: ..., child: ...)`.

7. **If you need a value not in the tokens, add it to the token.** Extending the scale (e.g., a new semantic color) is fine if the case appears more than once. Hardcoding "because it's a one-off case" is debt.

### How to use

```dart
import '../../core/theme/vamos_colors.dart';
import '../../core/theme/vamos_spacing.dart';
import '../../core/theme/vamos_typography.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.title, required this.amount});
  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VamosSpacing.lg),
      decoration: BoxDecoration(
        color: VamosColors.surface,
        borderRadius: VamosRadius.brLg,
        boxShadow: VamosShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VamosTypography.headlineMedium),
          const SizedBox(height: VamosSpacing.sm),
          Text(amount, style: VamosTypography.monoLarge),  // mono solo para datos
          Text('En curso · día 3 de 10', style: VamosTypography.caption),
        ],
      ),
    );
  }
}
```

### When to evolve to components (`shared/widgets/`)

Not anticipatorily. If a visual pattern (e.g., trip card, tag chip, expense row) appears in **2+ screens with the same structure**, then it's extracted to `shared/widgets/<component>.dart`. Not before.

### When to change the tokens

- **Palette or branding change** → edit `vamos_colors.dart`. The source of truth is `vamos-design-kit/tokens/design_tokens.json`.
- **New typography role or font weight** → add to `vamos_typography.dart`. Always use one of the three established font families.
- **New spacing or radius value needed 2+ times** → add to `vamos_spacing.dart`.
- **A new product semantic color** (e.g., "info" for notifications) → add it in `VamosColors`, not in the widget that needed it first.

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
Mock lives in `lib/dev/mocks/mock_<plural>_repository.dart`.

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

Imports the mock from `lib/dev/mocks/` — that's intentional. The mock is
dev/test infrastructure shared between unit tests and the dev entry point.
Note: `test/` is not part of the Flutter build graph; mocks used in `main_dev.dart`
must live under `lib/`.

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
