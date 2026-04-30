# Convenciones — Landing web (Astro)

> Este archivo se aplica a todo lo que está bajo `web/`. Asumí que el `CLAUDE.md` raíz ya fue leído.

## Qué es

Sitio público de Vamos. Cubre dos cosas:

1. **Página de invitación** (`/j/[code]`) — la que abre el destinatario del link compartido por WhatsApp en F1.4. Resuelve el `inviteCode` contra Firestore, muestra el viaje (nombre, destino, fechas, foto, quién creó), y deep-linkea a la app móvil. Si la app no está instalada, redirige a App Store / Play Store.
2. **Landing de marketing** — home con qué es Vamos + features. **Fuera del scope core del MVP** — para Caso 0 alcanza con un placeholder mínimo. Marketing real entra post-Caso 0.

La landing **no es** una versión web de la app. No permite votar items, registrar gastos, ni editar perfil. Es lectura más deep-link.

## Stack

- **Astro** — framework SSG. Output estático por default, zero JS al cliente salvo donde sea inevitable.
- **TypeScript** — strict mode en todos los componentes y scripts.
- **Tailwind CSS** — utility-first. Un único sistema de estilos.
- **Firebase JS SDK** — solo para fetchear el viaje en `/j/[code]` desde el cliente. Mismo proyecto Firebase que la app.

### Por qué Astro y no Next.js

- Carga: HTML puro por default, Lighthouse 100 sin esfuerzo. Next.js obliga a manejar el split server/client y el bundle pesa más.
- SEO: SSG nativo, semantic HTML, metadata por página fácil. Para una landing es exactamente lo que queremos.
- Búsquedas por IA: HTML estático bien estructurado es lo que crawlers de LLMs (Perplexity, ChatGPT, Claude, etc.) pueden indexar. Astro nos deja agregar JSON-LD y `llms.txt` triviales.
- Implementación: file-based routing, componentes `.astro` simples, deploy estático. Curva de aprendizaje corta.
- Trade-off aceptado: comunidad más chica que Next. Si en algún momento necesitamos un dashboard administrativo con SSR pesado, ese se construye aparte.

## Estructura del proyecto

```
web/
├── astro.config.mjs
├── package.json
├── pnpm-lock.yaml
├── tsconfig.json
├── tailwind.config.cjs
├── public/                       ← assets estáticos (favicon, og-image, llms.txt)
│   ├── favicon.svg
│   └── llms.txt                  ← resumen del producto para crawlers de IA
└── src/
    ├── layouts/
    │   └── BaseLayout.astro      ← <html>, <head>, metadata, fuentes, footer
    ├── pages/
    │   ├── index.astro           ← home (placeholder en MVP)
    │   └── j/
    │       └── [code].astro      ← página de invitación (única dinámica)
    ├── components/               ← reutilizables entre páginas
    ├── lib/
    │   └── firebase.ts           ← init del SDK + helper para resolver invite
    └── styles/
        └── global.css            ← `@import "tailwindcss"` + tipografía base
```

## Reglas duras

1. **HTML estático por default.** Si una página puede ser SSG pura, lo es. Solo cargamos JS al cliente cuando hay interactividad inevitable (caso único en MVP: `/j/[code]` que fetchea el viaje).
2. **No duplicar microcopy de la app.** Los textos que aparecen en la landing y en la app deben venir del mismo lugar. Por ahora no hay shared package — copia + referencia a `docs/06-identidad-y-tono.md`. Si crece, evaluar paquete compartido.
3. **No replicar lógica de Firestore.** La landing toca Firestore solo para resolver el invite (lectura de `invites/{code}` y proyección mínima del trip). Nunca escribe.
4. **No reimplementar funcionalidad de la app.** Cualquier acción real (votar, registrar gasto, editar perfil) está fuera del alcance de la landing. Se redirige al deep-link de la app.
5. **Una página por archivo en `src/pages/`.** Sub-componentes específicos de una página viven en `src/components/<page>/`. Solo va a `src/components/` raíz lo que se reutiliza entre páginas.
6. **Imágenes optimizadas.** Usar `<Image>` de Astro para imports estáticos. Para imágenes que vienen de Storage (foto de portada del viaje), `<img loading="lazy">` con dimensiones explícitas para evitar CLS.

## SEO + búsquedas por IA

La landing tiene que indexar bien tanto en Google como en LLMs. Reglas concretas:

- **Metadata por página** en `BaseLayout.astro`: `title`, `description`, `og:image`, `og:url`, `twitter:card`. La home tiene metadata propia; `/j/[code]` tiene metadata genérica (no exponer el contenido del viaje a crawlers — los viajes son privados).
- **JSON-LD** estructurado en la home: `Organization`, `WebApplication`, eventualmente `FAQPage`. Inyectado como `<script type="application/ld+json">` en el layout.
- **`public/llms.txt`** con resumen del producto para crawlers de IA (qué es Vamos, problema que resuelve, audiencia, link a docs públicos si los hay). Formato siguiendo el draft de `llmstxt.org`.
- **`public/robots.txt`** explícito: permitir todo en `/`, bloquear `/j/*` (los viajes son privados, no indexar el invite code aunque sea opaco).
- **Sitemap** generado por la integración `@astrojs/sitemap`. Excluir `/j/*`.
- **Texto real**, no SVG con texto. Encabezados semánticos (`h1`, `h2`, etc.) y prose en HTML, no imágenes.

## Deploy

Firebase Hosting. Ver `firebase/CLAUDE.md` § Hosting para detalles.

```
cd web/
pnpm build              # genera dist/
cd ../firebase/
firebase deploy --only hosting
```

`firebase.json` ya tiene la config de hosting apuntando a `../web/dist`.

## Microcopy y tono

Mismo tono que la app: voseo, vocabulario LATAM compartido, sin jerga local. Ver `docs/06-identidad-y-tono.md` para el patrón completo.

Particularidades de la landing:

- **Página de invitación**: tono cálido y específico al viaje. "Te invitaron a *Brasil con los del barrio*" + foto + fechas + creador. CTA principal: "Abrir en la app". CTA secundario (cuando la app no está instalada): "Descargar la app".
- **Home (placeholder MVP)**: una frase de qué es Vamos + un CTA hacia las stores. Marketing real post-Caso 0.

## Lo que NO hacer

- No agregar SSR. Si una página parece necesitar SSR, primero evaluar si se puede resolver client-side.
- No agregar autenticación en la landing. La auth es responsabilidad de la app móvil.
- No replicar funcionalidad de la app (votar, gastos, etc.).
- No agregar otro framework de estilos sobre Tailwind.
- No agregar dependencias "por si acaso". Cada paquete suma peso al bundle y trabajo de mantenimiento.
- No agregar internacionalización. Solo español, igual que la app.
- No agregar analítica de terceros (Google Analytics, etc.) en MVP. Si después decidimos métricas, se reabre.

## Dependencias permitidas

Las que decidimos. Cualquier otra requiere justificación explícita.

- `astro`
- `@astrojs/tailwind`, `tailwindcss`
- `@astrojs/sitemap`
- `firebase` (solo módulos `app`, `firestore` — no `auth`, no `storage`)
- `typescript`

## Referencias

- Tono y microcopy: `docs/06-identidad-y-tono.md`
- Modelo de datos (página de invitación): `docs/05-modelo-datos-2.md` §2.2 (`invites/{inviteCode}`, `trips/{tripId}`)
- Wireframes (F1.4 onboarding del invitado): `docs/04-wireframes-mvp-2.md`
- Hosting / deploy: `firebase/CLAUDE.md`
