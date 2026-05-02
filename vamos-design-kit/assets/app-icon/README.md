# Vamos · App Icons

Todos los íconos están sobre fondo grafito **#1A1612** (color de marca) con el punto naranja **#FF5A1F** centrado. Los de iOS vienen en squircle (radio 22.5%); los de Android, full-bleed cuadrado.

## iOS (Xcode `Assets.xcassets/AppIcon.appiconset/`)

| Archivo | Uso |
|---|---|
| `ios-1024.png` | App Store |
| `ios-180.png` | iPhone @3x (60pt) |
| `ios-167.png` | iPad Pro |
| `ios-152.png` | iPad |
| `ios-120.png` | iPhone @2x (60pt) |
| `ios-87.png` | iPhone Settings @3x (29pt) |
| `ios-80.png` | Spotlight @2x (40pt) |
| `ios-60.png` | Spotlight @3x (20pt) |
| `ios-58.png` | Settings @2x (29pt) |
| `ios-40.png` | Spotlight @2x (20pt) |
| `ios-29.png` | Settings (29pt) |

## Android (`android/app/src/main/res/mipmap-*/`)

### Legacy (cuadrado)
| Archivo | Carpeta |
|---|---|
| `android-mdpi-48.png` | `mipmap-mdpi/ic_launcher.png` |
| `android-hdpi-72.png` | `mipmap-hdpi/ic_launcher.png` |
| `android-xhdpi-96.png` | `mipmap-xhdpi/ic_launcher.png` |
| `android-xxhdpi-144.png` | `mipmap-xxhdpi/ic_launcher.png` |
| `android-xxxhdpi-192.png` | `mipmap-xxxhdpi/ic_launcher.png` |

### Adaptive (Android 8+)
| Archivo | Uso |
|---|---|
| `android-adaptive-fg-432.png` | Foreground layer (punto en safe zone 66%) |
| `android-adaptive-bg-432.png` | Background layer (grafito sólido) |

## Web / favicon

| Archivo | Uso |
|---|---|
| `favicon-16.png` | Tab del navegador |
| `favicon-32.png` | Tab retina |
| `favicon-192.png` | PWA / Android Chrome |
| `favicon-512.png` | PWA splash |

## Atajo recomendado: `flutter_launcher_icons`

En `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "vamos-design-kit/assets/app-icon/ios-1024.png"
  adaptive_icon_background: "#1A1612"
  adaptive_icon_foreground: "vamos-design-kit/assets/app-icon/android-adaptive-fg-432.png"
  web:
    generate: true
    image_path: "vamos-design-kit/assets/app-icon/favicon-512.png"
```

Después: `flutter pub run flutter_launcher_icons`
