# Vamos · Design Kit para Flutter

Paquete con todo lo necesario para implementar el sistema de identidad de Vamos en Flutter (cross-platform iOS + Android).

## Estructura

```
vamos-design-kit/
├── README.md                       ← este archivo
├── tokens/
│   ├── design_tokens.json          ← fuente de verdad (formato W3C)
│   └── tokens.css                  ← para web/landing (espejo del .json)
├── flutter/
│   ├── vamos_theme.dart            ← ThemeData listo para usar
│   ├── vamos_colors.dart           ← paleta completa
│   ├── vamos_typography.dart       ← TextStyles
│   ├── vamos_spacing.dart          ← escalas de espaciado y radios
│   └── vamos_logo.dart             ← widget del lockup vam◯s
├── assets/
│   ├── logos/                      ← SVGs en todas las variantes
│   ├── app-icon/                   ← PNGs en todos los tamaños
│   └── fonts/                      ← .ttf (descargar manualmente, ver abajo)
└── manual-sistema.html             ← referencia visual (la "biblia")
```

---

## Setup en el proyecto Flutter

### 1. Copiar archivos

```bash
# desde la raíz de tu proyecto Flutter
cp -r vamos-design-kit/flutter lib/theme
cp -r vamos-design-kit/assets/fonts assets/fonts
cp -r vamos-design-kit/assets/logos assets/logos
```

### 2. Descargar fuentes

Las fuentes NO se incluyen en el kit (peso). Descargá:

- **Space Grotesk** — https://fonts.google.com/specimen/Space+Grotesk (pesos 400, 500, 600, 700)
- **Inter** — https://fonts.google.com/specimen/Inter (pesos 400, 500, 600, 700)
- **JetBrains Mono** — https://fonts.google.com/specimen/JetBrains+Mono (pesos 400, 500, 600)

Poné los `.ttf` en `assets/fonts/`.

### 3. Declarar en `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/logos/
    - assets/app-icon/

  fonts:
    - family: SpaceGrotesk
      fonts:
        - asset: assets/fonts/SpaceGrotesk-Regular.ttf
        - asset: assets/fonts/SpaceGrotesk-Medium.ttf
          weight: 500
        - asset: assets/fonts/SpaceGrotesk-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/SpaceGrotesk-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
        - asset: assets/fonts/JetBrainsMono-SemiBold.ttf
          weight: 600
```

### 4. Aplicar el theme en `main.dart`

```dart
import 'package:flutter/material.dart';
import 'theme/vamos_theme.dart';

void main() => runApp(const VamosApp());

class VamosApp extends StatelessWidget {
  const VamosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vamos',
      theme: VamosTheme.light,
      darkTheme: VamosTheme.dark,
      home: const HomeScreen(),
    );
  }
}
```

---

## Cómo usar el sistema

### Colores
```dart
Container(color: VamosColors.sol500)               // naranja sol
Container(color: VamosColors.bg)                   // crema fondo
Text('Hola', style: TextStyle(color: VamosColors.text))
```

### Tipografía
```dart
Text('vam◯s', style: VamosTypography.displayLarge)
Text('Tu viaje está listo', style: VamosTypography.headlineMedium)
Text('Brasil con los del barrio', style: VamosTypography.bodyMedium)
Text('\$24.500', style: VamosTypography.monoMedium)  // datos numéricos
```

### Espaciado
```dart
Padding(padding: EdgeInsets.all(VamosSpacing.md))   // 16
SizedBox(height: VamosSpacing.lg)                   // 24
```

### Logo
```dart
VamosLogo(size: 32)                                  // sin sombra (header)
VamosLogo(size: 96, withShadow: true)                // con sombra (hero)
VamosLogoMark(size: 64)                              // solo el punto
```

---

## Reglas de uso (resumen)

- **Sombra** solo en lockup ≥ 48px
- **Mono** solo para datos (montos, fechas, IDs) — nunca para UI general
- **Display (Space Grotesk)** solo para títulos y wordmark
- **UI text** siempre Inter
- **Tokens, no hex sueltos** — usa `VamosColors.sol500`, no `Color(0xFFFF5A1F)`

Para detalles, abrí `manual-sistema.html` en cualquier navegador.
