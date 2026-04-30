# Vamos — App de viajes compartidos para grupos LATAM

## Qué es

Vamos es una app móvil para planear y ejecutar viajes en grupo, diseñada desde el inicio para grupos latinoamericanos. Convierte la planeación de viajes en grupo —que hoy se hace fragmentada entre WhatsApp + Google Docs + Splitwise— en una experiencia que prevenga conflictos en lugar de generarlos.

**Fase actual:** MVP Caso 0. Único objetivo: validar que el flujo end-to-end no se rompe en un viaje real (viaje a Brasil, ~6 semanas, grupo propio del fundador).

**No es:** un MVP comercial. No hay métricas de adquisición ni revenue. La métrica única es: ¿el grupo terminó el viaje usando la app de inicio a fin, o tuvieron que volver a Splitwise/Wanderlog/Docs en algún momento?

## Contexto obligatorio

Antes de cualquier decisión de producto o de código, leé los documentos relevantes:

- **`docs/02-prd-inicial.md`** → principios del producto, personas, modelo de roles dentro del grupo, casos de uso prioritarios
- **`docs/03-mvp-scope.md`** → qué entra y qué NO entra al MVP, decisiones de scope tomadas, trade-offs aceptados
- **`docs/04-wireframes-mvp-2.md`** → wireframes de las 17 pantallas del MVP, decisiones de UX por pantalla
- **`docs/05-modelo-datos-2.md`** → modelo de datos en Firestore (colecciones, campos, reglas de seguridad, índices)
- **`docs/06-identidad-y-tono.md`** → nombre, tono de voz, microcopy validado del MVP
- **`docs/01-research-mercado.md`** → research de mercado, gaps, oportunidad. Referencia, no urgente para el día a día.

Si la pregunta es de código en Flutter, además leé `app/CLAUDE.md`. Si es de Firestore (reglas, índices, modelo), además leé `firebase/CLAUDE.md`. Si es del sitio web (Astro, landing, página de invitación), además leé `web/CLAUDE.md`.

## Principios del producto (no negociables)

Estos ganan cuando hay decisiones difíciles. Definidos en PRD §3.

1. **Prevenir conflictos > organizar tareas.** Cada feature se evalúa contra "¿esto previene un conflicto que hoy ocurre?"
2. **Distribuir trabajo, no concentrarlo.** El "mártir del viaje" es el enemigo del producto.
3. **LATAM-first, no LATAM-translated.** Decisiones de UX, monedas, métodos de pago nacen pensando en Bogotá, CDMX, Buenos Aires.
4. **WhatsApp es aliado, no competencia.** Reemplazarlo es perder; integrarse es ganar.
5. **Funciona offline o no funciona.** Itinerario, documentos y gastos deben servir sin señal. (Nota: el MVP rompe parcialmente este principio; ver scope §6.)
6. **Lo simple gana.** Cada feature nueva se evalúa contra "¿esto hace la app más usable o más completa?". Si solo es "más completa", se rechaza.

## Decisiones tomadas (no reabrir sin evidencia nueva)

### Stack
- **Frontend (app móvil):** Flutter (iOS + Android, un solo codebase). Bundle ID `com.jabsolutions.vamos`.
- **Backend:** Firebase (Auth, Firestore, Storage, FCM). Sin Cloud Functions en MVP.
- **State management:** Riverpod (`AsyncNotifier` / `StreamNotifier`). No ChangeNotifier, no Bloc.
- **Estructura:** híbrida pragmática (features + capa fina de repositories que aísla Firestore). No clean architecture estricta.
- **Landing web:** Astro (SSG, zero JS por default). Deploy en Firebase Hosting. Sirve la página de invitación (`/j/[code]`) que sostiene F1.4 y eventualmente marketing. **No es Flutter web.**

### Producto
- **Idioma:** solo español en MVP. Portugués en v2.
- **Plataformas:** app móvil (iOS + Android, Flutter) + landing web (Astro) que sostiene la página de invitación (`/j/[code]`) en F1.4 y eventualmente marketing. Sin Flutter web.
- **Monetización:** gratis sin restricciones durante el MVP. Modelo de largo plazo se reabre en mes 6 con datos reales.
- **Roles:** modelo plano con un facilitador. Ver PRD §4.4.
- **Datos sensibles:** el MVP NO maneja datos del viajero a nivel perfil (cédula, pasaporte, viajero frecuente). Eso va en v1.1+.

### Lo que NO va al MVP
Definido explícito en `docs/03-mvp-scope.md` §4. Resumen:
- Vault de documentos del viaje
- Modo crisis
- Datos del viajero a nivel perfil
- Coordinación de fechas previa al viaje
- Integración con WhatsApp más allá del link de invitación
- Multi-idioma
- Flutter web (la app móvil no se compila a web; la landing es un proyecto Astro separado bajo `web/`, scope mínimo en MVP — solo página de invitación)
- Booking directo
- AI / recomendaciones
- Push notifications (entra en v1.1 si el feedback lo pide)
- Sincronización offline real (idem)

Si se te pide implementar algo de esta lista, alertar al usuario antes de avanzar: "Esto está fuera del scope del MVP. ¿Confirmás que querés sumarlo igual?"

## Cómo trabajar conmigo (Andrés)

- **Idioma y tono:** español, voseo, conversacional pero directo. Sin formalismos.
- **Postura:** crítico no complaciente. Si una idea no funciona, decímelo con argumentos. Si hay un trade-off importante, ponelo sobre la mesa antes de implementarlo.
- **Opciones:** máximo 3 alternativas con trade-offs explícitos. Nada de listas de 10 opciones equivalentes.
- **Foco:** lo simple sobre lo completo. El producto se mata por ambición, no por falta de features.
- **No reabrir decisiones tomadas** a menos que aparezca evidencia nueva. Si en una conversación previa cerramos algo, asumí que sigue vigente.
- **Pensá como product manager senior** antes que como developer. La pregunta es "¿esto resuelve un problema real del usuario?" antes de "¿cómo lo construimos?".
- **Preguntá si la pregunta es vaga.** Pero si es razonablemente clara, respondé y avanzá. No pidas confirmación de cosas obvias.
- **Marcá lo que solo sirve para mi caso personal** y no escala al producto distribuible.

## Estructura del repositorio

```
vamos/
├── CLAUDE.md                       ← este archivo (contexto global)
├── README.md                       ← cómo correr el proyecto
├── app/                            ← proyecto Flutter
│   ├── CLAUDE.md                   ← convenciones de código Flutter
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
├── firebase/                       ← infra Firebase
│   ├── CLAUDE.md                   ← reglas, índices, modelo, hosting
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── firebase.json
│   └── functions/                  ← vacío hasta v1.1+
├── web/                            ← landing web (Astro)
│   ├── CLAUDE.md                   ← convenciones del sitio
│   ├── src/
│   ├── astro.config.mjs
│   └── package.json
└── docs/                           ← documentación del producto
    ├── 01-research-mercado.md
    ├── 02-prd-inicial.md
    ├── 03-mvp-scope.md
    ├── 04-wireframes-mvp-2.md
    ├── 05-modelo-datos-2.md
    └── 06-identidad-y-tono.md
```
