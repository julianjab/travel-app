---
name: design-system
description: Use before writing or editing any Flutter widget in app/lib/. Reference card for the Vamos design system — colors, spacing, radius, shadows, typography — so agents never hardcode Color(0xFF...), Colors.*, EdgeInsets.all(16), BorderRadius.circular(8) or TextStyle(fontSize:...). Loads the canonical token names and theme-aware patterns required for ThemeMode.system (light + dark) compatibility.
when_to_use: Load before flutter-builder (or any agent) writes/edits a widget, screen, card, chip, button, container, or text style. Mandatory check whenever a UI change touches app/lib/features/**, app/lib/core/**, or any *.dart file containing build(). Re-read after touching app/lib/core/theme/ tokens.
allowed-tools: Bash(grep *), Bash(rg *)
---

# Vamos design system — reference card

Reference for any agent about to write Flutter UI in `app/lib/`. The Vamos app uses `ThemeMode.system`, so every widget MUST be theme-aware. Read this file before producing widget code; grep your draft against the checklist before committing.

Token sources (canonical, do not duplicate):

- `app/lib/core/theme/vamos_colors.dart` — palette + light/dark semantic colors
- `app/lib/core/theme/vamos_typography.dart` — three font families with strict roles
- `app/lib/core/theme/vamos_spacing.dart` — spacing scale, `VamosRadius`, `VamosShadow`
- `app/lib/core/theme/vamos_theme.dart` — assembles `ThemeData` light + dark (CardTheme, AppBarTheme, etc.)

## Golden rule

Never write any of these inline in a widget:

| Forbidden | Use instead |
|-----------|-------------|
| `Color(0xFF...)` | `Theme.of(context).colorScheme.*` or `VamosColors.*` token |
| `Colors.red`, `Colors.grey`, etc. | `VamosColors.red` / `VamosColors.green` / `colorScheme.error` |
| `EdgeInsets.all(16)`, `EdgeInsets.symmetric(horizontal: 24)` | `EdgeInsets.all(VamosSpacing.md)` etc. |
| `BorderRadius.circular(8)` | `VamosRadius.brSm` / `brMd` / `brLg` / `brFull` |
| `TextStyle(fontSize: 14, ...)` | `VamosTypography.<role>` (optionally `.copyWith(color: ...)`) |
| `SizedBox(height: 16)` | `SizedBox(height: VamosSpacing.md)` |
| `BoxShadow(...)` literal | `VamosShadow.sm` / `VamosShadow.md` |

Exception: `withValues(alpha: ...)` on a token color is allowed for transient overlays.

## Colors — theme-aware first

The app runs in light AND dark via `ThemeMode.system`. Picking the wrong token breaks dark mode silently.

### Rule of thumb: use `colorScheme` for surfaces

For any backgrounds, borders, containers, chips, or interactive surfaces, prefer `Theme.of(context).colorScheme.*`. The theme already maps light/dark variants:

| Need | Token |
|------|-------|
| Page background | `colorScheme.surface` (Scaffold handles automatically — don't set) |
| Card / elevated surface | `colorScheme.surface` (CardTheme handles — don't set on Card) |
| Subtle inset surface (rows, list items) | `colorScheme.surfaceContainerHighest` |
| Tinted brand chip background | `colorScheme.primaryContainer` |
| Tinted brand chip text/icon | `colorScheme.onPrimaryContainer` |
| Brand emphasis (button bg, link, focus) | `colorScheme.primary` |
| Text/icon on brand emphasis | `colorScheme.onPrimary` |
| Border, divider, outline | `colorScheme.outline` |
| Subtle border / muted divider | `colorScheme.outlineVariant` |
| Body text | `colorScheme.onSurface` |
| Secondary text | `colorScheme.onSurfaceVariant` |
| Error bg | `colorScheme.errorContainer` |
| Error fg | `colorScheme.onErrorContainer` / `colorScheme.error` |

Idiomatic prelude inside `build`:

```dart
final cs = Theme.of(context).colorScheme;
```

### `VamosColors.*` — when it IS OK

Use `VamosColors` directly only for:

- Brand palette ramps that have no `colorScheme` analogue: `VamosColors.sol50`–`sol700`, and `sol500Dark` (use `sol500Dark` in dark mode if you need the brand yellow on dark — `sol500` is too bright).
- Pure semantic accents that should NOT shift between light and dark: `VamosColors.red`, `VamosColors.green`, `VamosColors.warning`, `VamosColors.sol500`.
- Decorative non-interactive colors (avatar tints, decorative icon fills) where contrast is computed locally.
- Static "on dark" surfaces: `VamosColors.textOnDark`, `VamosColors.textMuted`.

### `VamosColors.*` — NEVER use directly in widgets

These are light-mode-only and break dark mode:

- `VamosColors.bg` → use `colorScheme.surface` (or just let Scaffold handle it)
- `VamosColors.surface` → use `colorScheme.surface`
- `VamosColors.surface2` → use `colorScheme.surfaceContainerHighest`
- `VamosColors.border` → use `colorScheme.outline` or `outlineVariant`
- `VamosColors.text` → use `colorScheme.onSurface`
- `VamosColors.text2` / `text3` → use `colorScheme.onSurfaceVariant`

The `*Dark` siblings (`bgDark`, `surfaceDark`, `surface2Dark`, `borderDark`, `textDark`, `text2Dark`, `text3Dark`) exist only to feed `vamos_theme.dart`. Never reference them from a widget.

## Spacing — `VamosSpacing`

Single scale, one source of truth:

| Token | Value |
|-------|-------|
| `VamosSpacing.xs` | 4 |
| `VamosSpacing.sm` | 8 |
| `VamosSpacing.md` | 16 |
| `VamosSpacing.lg` | 24 |
| `VamosSpacing.xl` | 32 |
| `VamosSpacing.xxl` | 48 |
| `VamosSpacing.xxxl` | 64 |

If a design needs a value outside this scale, stop and ask — adding ad-hoc spacing breaks visual rhythm.

## Radius — `VamosRadius`

| Token | Use |
|-------|-----|
| `VamosRadius.brSm` | Inputs, small chips |
| `VamosRadius.brMd` | Cards, sheets, dialogs |
| `VamosRadius.brLg` | Hero / featured surfaces |
| `VamosRadius.brFull` | Pill chips, avatars, FAB |

## Shadows — `VamosShadow`

| Token | Use |
|-------|-----|
| `VamosShadow.sm` | Cards at rest |
| `VamosShadow.md` | Floating sheets, popovers |

CardTheme already applies the right shadow — don't add one to a Card.

## Typography — strict family roles

Three families, each with one job. Mixing them ruins the brand.

| Family | Constant | Allowed roles |
|--------|----------|---------------|
| Space Grotesk | `VamosTypography.fontDisplay` | Titles, hero copy, screen-level headers ONLY |
| Inter | `VamosTypography.fontUI` | Everything else (body, labels, buttons, inputs) |
| JetBrains Mono | `VamosTypography.fontMono` | Amounts, IDs, timestamps, codes ONLY |

Always use the prebuilt `VamosTypography.<style>` — never `TextStyle(fontSize: ...)`. Common styles:

- `displayLarge`, `displayMedium`, `displaySmall` — hero titles (Space Grotesk)
- `titleLarge`, `titleMedium`, `titleSmall` — section / card titles
- `bodyLarge`, `bodyMedium`, `bodySmall` — body text (Inter)
- `labelLarge`, `labelMedium`, `caption`, `overline` — supporting UI text
- `monoLarge`, `monoMedium`, `monoSmall` — money, IDs, timestamps

Color overrides go through `.copyWith(color: cs.<token>)`, never `TextStyle(color: ...)`.

## Scaffold / AppBar / Card — DON'T override

`vamos_theme.dart` already configures these. Setting them inline overrides theme-aware behavior:

| Widget | Don't set | Why |
|--------|-----------|-----|
| `Scaffold` | `backgroundColor` | ThemeData handles light + dark |
| `AppBar` | `backgroundColor`, `foregroundColor`, `elevation` | AppBarTheme handles all of these |
| `Card` | `color`, `shape`, `elevation`, `margin` | CardTheme is already correct |
| `BottomNavigationBar` | colors, elevation | NavigationBarTheme handles it |
| `ElevatedButton` / `FilledButton` | color, shape, padding inline | Use the theme; only override on truly custom CTAs |

If you find yourself setting these, the right move is to fix the theme in `vamos_theme.dart`, not patch the widget.

## Correct chip pattern (canonical example)

```dart
final cs = Theme.of(context).colorScheme;

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: VamosSpacing.md,
    vertical: VamosSpacing.sm,
  ),
  decoration: BoxDecoration(
    color: cs.primaryContainer,
    border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
    borderRadius: VamosRadius.brFull,
  ),
  child: Text(
    'Confirmado',
    style: VamosTypography.caption.copyWith(color: cs.onPrimaryContainer),
  ),
)
```

## Correct money / amount pattern

```dart
final cs = Theme.of(context).colorScheme;

Text(
  '\$ 1.250.000',
  style: VamosTypography.monoLarge.copyWith(color: cs.onSurface),
)
```

## Correct surface row pattern

```dart
final cs = Theme.of(context).colorScheme;

Container(
  padding: const EdgeInsets.all(VamosSpacing.md),
  decoration: BoxDecoration(
    color: cs.surfaceContainerHighest,
    borderRadius: VamosRadius.brMd,
    border: Border.all(color: cs.outlineVariant),
  ),
  child: Text('...', style: VamosTypography.bodyMedium),
)
```

## Self-check before committing

Run these greps from `app/` against your edited files. Any hit is a violation — fix before commit.

```bash
# Hardcoded colors
rg -n 'Color\(0xFF' app/lib
rg -n 'Colors\.' app/lib

# Hardcoded spacing
rg -n 'EdgeInsets\.all\(\d' app/lib
rg -n 'EdgeInsets\.symmetric\([^)]*\d{2,}' app/lib
rg -n 'SizedBox\((width|height): \d' app/lib

# Hardcoded radius / typography
rg -n 'BorderRadius\.circular\(\d' app/lib
rg -n 'fontSize:' app/lib

# Light-only tokens used in widgets (must be colorScheme)
rg -n 'backgroundColor: VamosColors\.' app/lib
rg -n 'VamosColors\.(bg|surface2?|border|text2?|text3)\b' app/lib/features app/lib/core/widgets 2>/dev/null
```

Allowed hits:

- Inside `app/lib/core/theme/` — these files DEFINE the tokens.
- `VamosColors.red`, `VamosColors.green`, `VamosColors.warning`, `VamosColors.sol*` — semantic / brand palette, OK.
- `withValues(alpha: ...)` on a token — OK.

Anything else: replace with the right token from this card.

## Output

When this skill is invoked as a reference (no arguments), respond with:

```
Design system loaded:
  Tokens:        VamosColors / VamosTypography / VamosSpacing / VamosRadius / VamosShadow
  Theme-aware:   colorScheme.* for surfaces, borders, text
  Light+dark:    do NOT use VamosColors.bg/surface/surface2/border/text* in widgets
  Self-check:    ran grep checklist  -> <count> violations
```

If invoked as part of a widget edit, do not emit this block — just apply the rules silently while writing code, then run the self-check greps before declaring done.

## Error handling

| Condition | Action |
|-----------|--------|
| Token file missing under `app/lib/core/theme/` | STOP — report which file is missing; do not write widget code against an undefined token. |
| Design needs a value outside `VamosSpacing` scale | STOP — ask the user; don't introduce ad-hoc spacing. |
| Design needs a color with no `colorScheme` or `VamosColors` analogue | STOP — propose adding the token to `vamos_colors.dart` + `vamos_theme.dart` instead of inlining. |
| Self-check grep finds violations after edit | Fix every hit before reporting done; do not commit with violations. |
