# Vamos — Setup del repo

Este README es un brief operativo para Cowork (Anthropic). Define el estado actual del proyecto y las tareas que Cowork tiene que ejecutar para dejar el repo armado y listo para desarrollo.

Última actualización: abril 2026.

## 1. Qué es Vamos

App móvil para planear y ejecutar viajes en grupo, diseñada desde el inicio para grupos latinoamericanos. Convierte la planeación de viajes en grupo —que hoy se hace fragmentada entre WhatsApp + Google Docs + Splitwise— en una experiencia que prevenga conflictos en lugar de generarlos.

Fase actual: MVP Caso 0. Único objetivo: validar que el flujo end-to-end no se rompe en un viaje real (viaje a Brasil, ~6 semanas, grupo propio del fundador). No es un MVP comercial.

Stack: Flutter (iOS + Android) + Firebase (Auth, Firestore, Storage). State management con Riverpod. Sin Cloud Functions en MVP.

Para el contexto completo de producto, leer `docs/02-prd-inicial.md` y `docs/03-mvp-scope.md` después de que Cowork arme el repo.

## 2. Estado actual del directorio

Cuando Cowork arranca, en la raíz del proyecto (`/vamos/`) hay:

- 6 documentos del proyecto en la raíz, sueltos:
  - `01-research-mercado.md`
  - `02-prd-inicial.md`
  - `03-mvp-scope.md`
  - `04-wireframes-mvp-2.md`
  - `05-modelo-datos-2.md`
  - `06-identidad-y-tono.md`
- Tres archivos `CLAUDE.md` que ya están escritos y deben quedar en sus posiciones finales:
  - `CLAUDE.md` (raíz)
  - `app/CLAUDE.md`
  - `firebase/CLAUDE.md`
- Este `README.md`

El estado final esperado se describe en la sección 4.

## 3. Tareas para Cowork

Las tareas están en orden de ejecución. Cada una tiene un criterio de éxito explícito.

### Tarea 1 — Crear estructura de carpetas

Crear las siguientes carpetas vacías en la raíz del proyecto si no existen:

- `app/`
- `firebase/`
- `firebase/functions/`
- `docs/`

Criterio de éxito: las 4 carpetas existen.

### Tarea 2 — Mover los 6 documentos a `docs/`

Mover (no copiar) los siguientes archivos desde la raíz del proyecto a la carpeta `docs/`:

- `01-research-mercado.md` → `docs/01-research-mercado.md`
- `02-prd-inicial.md` → `docs/02-prd-inicial.md`
- `03-mvp-scope.md` → `docs/03-mvp-scope.md`
- `04-wireframes-mvp-2.md` → `docs/04-wireframes-mvp-2.md`
- `05-modelo-datos-2.md` → `docs/05-modelo-datos-2.md`
- `06-identidad-y-tono.md` → `docs/06-identidad-y-tono.md`

Criterio de éxito: los 6 archivos están en `docs/` y ya no están en la raíz.

### Tarea 3 — Verificar que los 3 CLAUDE.md están en su lugar

Confirmar que los siguientes archivos existen exactamente en estas rutas:

- `CLAUDE.md` (raíz del proyecto)
- `app/CLAUDE.md`
- `firebase/CLAUDE.md`

Si alguno no existe, alertar al usuario antes de crearlo. No regenerar contenido de estos archivos — fueron escritos manualmente y no deben ser modificados.

Criterio de éxito: los 3 archivos existen y mantienen su contenido original.

### Tarea 4 — Crear archivos placeholder

Crear los siguientes archivos con el contenido especificado.

#### 4.1 `.gitignore` (raíz)

```
# Flutter / Dart
app/.dart_tool/
app/.flutter-plugins
app/.flutter-plugins-dependencies
app/.packages
app/.pub-cache/
app/.pub/
app/build/
app/ios/Pods/
app/ios/.symlinks/
app/ios/Flutter/Flutter.framework
app/ios/Flutter/Flutter.podspec
app/android/.gradle/
app/android/captures/
app/android/gradlew
app/android/gradlew.bat
app/android/local.properties
app/android/**/GeneratedPluginRegistrant.java
app/.flutter-plugins
app/pubspec.lock

# IDE
.idea/
.vscode/
*.iml

# Firebase
firebase/.firebase/
firebase/firebase-debug.log
firebase/functions/node_modules/
firebase/functions/lib/

# OS
.DS_Store
Thumbs.db

# Env
.env
.env.local
```

#### 4.2 `firebase/firestore.rules`

Crear con este contenido placeholder:

```
rules_version = '2';

// PLACEHOLDER — esqueleto de reglas.
// La versión completa se cierra en docs/07-firestore-rules.md (pendiente).
// Mientras tanto, ver docs/05-modelo-datos-2.md §4 para el esqueleto base.

service cloud.firestore {
  match /databases/{database}/documents {
    // Bloquear todo por default. Reglas específicas se agregan cuando se
    // implemente cada flujo del MVP.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

#### 4.3 `firebase/firestore.indexes.json`

```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

Los 3 índices compuestos del MVP están listados en `docs/05-modelo-datos-2.md` §5. Se agregan cuando se implemente cada flujo, no preventivamente.

#### 4.4 `firebase/storage.rules`

```
rules_version = '2';

// PLACEHOLDER — reglas de Storage.
// Se completan cuando se implemente el primer flujo que sube fotos
// (probablemente F1.2 con la foto de portada del viaje).

service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

#### 4.5 `firebase/firebase.json`

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

#### 4.6 `firebase/.firebaserc`

```json
{
  "projects": {
    "default": "REPLACE_WITH_FIREBASE_PROJECT_ID"
  }
}
```

Nota: este archivo tiene un placeholder. El usuario lo va a completar cuando corra `firebase init` (ver sección 5).

#### 4.7 `firebase/functions/.gitkeep`

Crear archivo vacío. La carpeta `functions/` queda lista para v1.1+ pero no se usa en MVP.

Criterio de éxito: los 7 archivos existen con el contenido especificado.

### Tarea 5 — Inicializar repositorio de Git

Ejecutar en la raíz del proyecto:

```
git init
git add .
git commit -m "Initial commit: estructura del repo + docs + CLAUDE.md"
```

Criterio de éxito: el repo de Git está inicializado y el primer commit incluye todos los archivos creados hasta acá.

### Tarea 6 — Reportar estado final

Al terminar, reportar al usuario:

- Qué tareas se completaron
- Si alguna tarea falló o requirió decisión, cuál fue
- Confirmar que la estructura final coincide con la sección 4

## 4. Estructura final esperada

Después de que Cowork ejecute las tareas, el repo debe verse así:

```
vamos/
├── README.md                       ← este archivo
├── CLAUDE.md                       ← contexto global del proyecto
├── .gitignore
│
├── app/                            ← proyecto Flutter (vacío hasta sección 5)
│   └── CLAUDE.md
│
├── firebase/                       ← infra Firebase
│   ├── CLAUDE.md
│   ├── firebase.json
│   ├── .firebaserc
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── storage.rules
│   └── functions/
│       └── .gitkeep
│
├── web/                            ← landing web (Astro, vacío hasta sección 5)
│   └── CLAUDE.md
│
└── docs/                           ← documentación del producto
    ├── 01-research-mercado.md
    ├── 02-prd-inicial.md
    ├── 03-mvp-scope.md
    ├── 04-wireframes-mvp-2.md
    ├── 05-modelo-datos-2.md
    └── 06-identidad-y-tono.md
```

## 5. Lo que tiene que hacer el usuario después

Estas tareas requieren intervención manual del usuario (Andrés). Cowork no las ejecuta — quedan documentadas acá para que el usuario las haga después.

### 5.1 Setup de Flutter

Requiere Flutter SDK instalado en la máquina.

```
cd app/
flutter create . --org com.jabsolutions --project-name vamos --platforms=ios,android
```

Después editar `pubspec.yaml` y agregar las dependencias permitidas según `app/CLAUDE.md`:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `flutter_riverpod`
- `go_router`
- `intl`

Correr `flutter pub get` para instalar.

### 5.2 Setup de Firebase

Requiere cuenta de Firebase + Firebase CLI instalado.

1. Crear proyecto en https://console.firebase.google.com (sugerido: `vamos-mvp`)
2. Habilitar Authentication (con providers Google y Apple)
3. Habilitar Cloud Firestore (modo producción, región `southamerica-east1` u otra de LATAM)
4. Habilitar Storage
5. En la raíz del proyecto, conectar el proyecto local:

```
cd firebase/
firebase login
firebase use --add        # seleccionar el proyecto creado
```

6. Configurar Flutter para usar Firebase:

```
cd ../app/
flutterfire configure
```

### 5.3 Setup de la landing web (Astro)

Requiere Node 20+ y pnpm (o npm) instalado.

```
cd web/
pnpm create astro@latest . -- --template minimal --typescript strict --install --no-git
pnpm add firebase
pnpm add -D @astrojs/tailwind tailwindcss
```

Después de scaffoldar:

1. Configurar Astro en modo `static` en `astro.config.mjs`.
2. Agregar la integración de Tailwind (`pnpm astro add tailwind`).
3. Crear `src/pages/index.astro` (landing placeholder) y `src/pages/j/[code].astro` (página de invitación).
4. Crear `src/lib/firebase.ts` con la config del proyecto Firebase (mismo `.firebaserc`).

Ver convenciones completas en `web/CLAUDE.md`.

Para deploy:

```
cd web/
pnpm build              # genera dist/
cd ../firebase/
firebase deploy --only hosting
```

`firebase.json` ya tiene la config de hosting apuntando a `../web/dist`.

### 5.4 Primer flujo end-to-end

Una vez que el setup técnico esté completo, el primer flujo a implementar es F1.1 — Mis Viajes (definido en `docs/04-wireframes-mvp-2.md`). Es el más simple y prueba todo el plumbing: auth, repository, notifier, UI con Riverpod, navegación.

## 6. Reglas para Cowork

Estas reglas aplican a Cowork mientras ejecuta las tareas:

- No modificar el contenido de los 3 archivos `CLAUDE.md`. Fueron escritos manualmente.
- No modificar el contenido de los 6 documentos en `docs/`. Solo moverlos.
- No intentar correr `flutter create`, `firebase init`, ni ningún comando interactivo. Esos los corre el usuario manualmente (sección 5).
- No agregar dependencias, archivos o carpetas que no estén en este README. Si surge una duda, alertar al usuario antes de tomar la decisión.
- Si alguna tarea falla (ej: un archivo de los esperados no existe, un permiso falta), alertar al usuario y no continuar con las siguientes tareas.

## Release builds

### Android (Play Internal Testing)

1. Copy `app/android/key.properties.example` to `app/android/key.properties` and fill in your keystore path and passwords. This file is gitignored and must never be committed.
2. Run:
   ```bash
   cd app/android && make build-android-release
   ```
   The signed AAB lands at `app/build/app/outputs/bundle/release/app-release.aab`.
3. Upload the AAB to Google Play Console → Internal Testing.

### iOS (TestFlight)

1. Copy `app/ios/ExportOptions.plist.example` to `app/ios/ExportOptions.plist` and fill in your `teamID`. This file is gitignored.
2. Make sure your Apple Developer account is signed in to Xcode and the provisioning profile for `com.jabsolutions.vamos` is installed.
3. Run:
   ```bash
   app/ios/release_build.sh
   ```
   The IPA lands at `app/build/ios-release/vamos.ipa`.
4. Upload via Xcode Organizer or `xcrun altool`.

---

## 7. Referencias

- Producto: `docs/02-prd-inicial.md` (PRD), `docs/03-mvp-scope.md` (alcance del MVP)
- Diseño: `docs/04-wireframes-mvp-2.md`
- Datos: `docs/05-modelo-datos-2.md`
- Tono: `docs/06-identidad-y-tono.md`
- Convenciones de código Flutter: `app/CLAUDE.md`
- Convenciones de Firebase: `firebase/CLAUDE.md`
