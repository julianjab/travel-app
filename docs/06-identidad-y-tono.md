# Identidad y tono — App de Viajes Compartidos

> Documento de identidad de marca y tono de voz del MVP. Define nombre, ejes de personalidad, patrón de estados vacíos y microcopy validado para las pantallas del MVP. Última actualización: abril 2026.

---

## 1. Contexto

Este documento captura las decisiones de identidad tomadas a partir del PRD inicial (`02-prd-inicial.md`) y los wireframes (`04-wireframes-mvp-2.md`). No cubre identidad visual (paleta, tipografía, logo) — eso queda para cuando se llegue a diseño high-fi.

El alcance es: nombre, tono de voz, principios operativos para escribir microcopy, y los microcopys ya validados de las pantallas del MVP.

---

## 2. Nombre

**Vamos.**

### 2.1 Por qué Vamos

- Palabra de acción colectiva, alineada con el insight central del producto: viajes en grupo, no individuales.
- LATAM compartido — funciona en Colombia, México, Argentina, Uruguay, Chile, Perú sin sentirse de un solo país.
- Coloquial sutil sin ser jerga (eje 3C del tono, ver §3).
- Corta, fácil de decir por teléfono, fácil de tipear.
- Funciona como verbo y como sustantivo en frases de la app: "abrir en Vamos", "te invitaron a un viaje en Vamos".

### 2.2 Trade-off asumido

El espacio de "Vamos" en App Store y Google Play está saturado:

- Múltiples apps de transporte y movilidad ya se llaman "Vamos" (Vamos Mobility en California, Vamos taxi en Venezuela y otros mercados LATAM).
- "Vamoos" (con doble o) es una app europea grande de tour operators — riesgo de confusión fonética.
- Existe al menos un side-project en fly.dev llamado "Vamos - Collaborative Travel Planning" con posicionamiento idéntico al nuestro.

**Consecuencia:** ASO (App Store Optimization) va a ser pelea cuesta arriba. Si alguien busca "Vamos" en una store, va a encontrar 4-5 apps de transporte antes que la nuestra.

**Apuesta:** la adquisición temprana es por invitación viral (link de WhatsApp), no por búsqueda en stores. Para Caso 0 + Casos 1-5 esto funciona. Si crecimiento orgánico vía búsqueda se vuelve relevante, se reabre la decisión.

### 2.3 Cuándo reabrir el naming

No antes, no después de:

- **Antes** del empuje serio de adquisición orgánica (probablemente mes 9-12 según roadmap del PRD §2).
- **Antes** si en Casos 1-5 alguien reporta "no encontré la app cuando la busqué" o "descargué la otra" (Vamoos / Vamos Mobility) por error.

Hasta que eso pase, el nombre está fijado.

---

## 3. Tono de voz

El tono se define en 3 ejes independientes. Cada uno tiene un trade-off; cada decisión está fundamentada.

### 3.1 Eje 1 — Cercanía: **Herramienta competente (B)**

La app habla clara y directa, no como "amiga del grupo". El nombre "Vamos" ya carga la calidez — el microcopy puede ser más seco sin enfriarse.

**Ejemplo:**
- ✅ "5 de 7 votos. Faltan Pedro y Camila."
- ❌ "Ya votaron 5 de 7. Falta Pedro y Camila — ¿les damos un toque?"

### 3.2 Eje 2 — Postura emocional: **Reconoce el drama, modulado (A modulado)**

La app reconoce que los viajes en grupo son tensos en momentos de baja tensión (estados vacíos, éxito, onboarding). En momentos de fricción real (alguien acaba de registrar un gasto controvertido, edición de gasto ajeno, saldos finales) la app es neutra y no comenta.

**Ejemplo de modulación:**
- ✅ Estado vacío de gastos: tono jovial sobrio.
- ✅ Pantalla de saldos pendientes: cero guiños. Es plata, es serio.

### 3.3 Eje 3 — Formalidad regional: **Coloquial sutil con voseo (C)**

La app usa voseo (tenés, pedile, saltá) y vocabulario LATAM compartido. No usa jerga local (parche, parceros, chido). El voseo es palabra LATAM compartida — se entiende en toda la región sin friccionar.

**Ejemplo:**
- ✅ "Compartí este link con el grupo. Quien lo abra, entra."
- ❌ "Comparte este link con tu grupo, parceros. Quien lo abra entra."
- ❌ "Comparta este enlace con su grupo. Quien lo abra ingresará."

---

## 4. Patrón oficial: estados vacíos

Todo estado vacío del MVP arranca con la misma frase:

```
Acá no hay nada todavía.

[Frase corta que explica qué va a aparecer cuando se llene
 + qué hay que hacer para empezar.]

[Botón de acción]
```

### 4.1 Por qué este patrón

- **Consistencia.** Cuando el usuario lo lee 3 veces en distintas pantallas, ya reconoce que es Vamos hablando.
- **Tono cargado, sin esfuerzo.** "Acá" en lugar de "aquí" carga voseo + calidez sin chiste forzado.
- **Honesto.** No promete nada, no hace fanfarria, no se hace el simpático.

### 4.2 Excepción: estado completado ≠ estado vacío

Cuando una pantalla "se vació" porque algo se completó (no porque aún no empieza), el patrón **no aplica**. Ahí el mensaje correcto es de logro, no de inicio.

**Caso del MVP:** F3.4 (saldos) cuando todos quedaron parejos después de haber pagado todo.

```
Todos quedaron parejos.

[Pagados (12) ▼]
```

---

## 5. Microcopy validado del MVP

Microcopys ya escritos y aprobados para las pantallas del MVP. Cuando se implementen las pantallas, este es el texto a usar.

### 5.1 F1.1 — Mis viajes vacío

> Acá no hay nada todavía.
>
> Creá un viaje, o pedile el link a quien ya armó uno.
>
> [+ Nuevo viaje]

### 5.2 F1.3 — Pantalla de éxito al crear viaje

Título destacado:

> Tu viaje está listo

(Resto de la pantalla según wireframe — link, botones de compartir, ir al viaje.)

### 5.3 F1.5 — Onboarding de tags

Header de la pantalla:

> Esto lo va a ver el grupo. Saltá lo que no aplique.

### 5.4 F2.1 — Itinerario vacío

> Acá no hay nada todavía.
>
> Cualquiera puede tirar la primera idea — un vuelo, un restaurante, lo que sea. Después se vota.
>
> [+ Agregar primer item]

### 5.5 F3.1 — Gastos vacío

> Acá no hay nada todavía.
>
> Cuando alguien registre el primer gasto, te decimos a quién pagarle.
>
> [+ Agregar primer gasto]

### 5.6 F3.4 — Saldos vacío (sin transferencias pendientes desde el inicio)

> Acá no hay nada todavía.
>
> Cuando haya gastos para saldar, las transferencias aparecen acá.

### 5.7 F3.4 — Saldos completado (todos parejos después de haber pagado)

> Todos quedaron parejos.
>
> [Pagados (N) ▼]

### 5.8 F3.4 — Header con transferencias pendientes

> Para que todos queden parejos, estas son las transferencias más cortas:

### 5.9 F3.5 — Microcopy al editar gasto ajeno

> Estás editando un gasto registrado por otra persona. La edición queda registrada.

---

## 6. Principios operativos para microcopy futura

Reglas para escribir microcopy nueva manteniendo consistencia con todo lo de arriba.

### 6.1 Siempre voseo

Tenés, pedile, saltá, creá, andá. **No** mezclar con tuteo dentro de una misma pantalla. **No** usar usted (es España/formal).

### 6.2 Vocabulario LATAM compartido, sin jerga local

Sí: plata, finde, ojo, listo, parejos, acá, allá, cuadrar, andar.

No: parche, parceros (Colombia), chido, güey (México), pibe, chabón (Argentina), bacano (Colombia), padrísimo (México).

Cuando dudes, preguntate: "¿Esto se entiende igual en Bogotá, CDMX y Buenos Aires?". Si la respuesta es no, no va.

### 6.3 Guiños solo en momentos de baja tensión

Estados vacíos, pantallas de éxito, onboarding pueden cargar tono sutil. Mensajes de error, edición de datos sensibles, saldos pendientes y momentos de plata real son neutros.

**Regla concreta:** si el usuario está estresado o concentrado, la app no comenta. Si el usuario está explorando o esperando algo bueno, la app puede tener carácter.

### 6.4 Promesa de valor, no descripción de mecánica

En estados vacíos y onboarding, decir **qué va a pasar para el usuario**, no **cómo funciona internamente**.

- ✅ "Cuando alguien registre el primer gasto, te decimos a quién pagarle."
- ❌ "Los saldos se calculan automáticamente a medida que se registran gastos."

### 6.5 No prometer privacidad falsa

Si algo lo va a ver el grupo, decirlo. Si una edición queda registrada, decirlo. Sin diplomacia que esconda el costo real.

- ✅ "Esto lo va a ver el grupo."
- ❌ "Tus preferencias quedan visibles." (suaviza algo que no necesita suavizarse)

### 6.6 Cortar, cortar, cortar

Microcopy bueno se siente más corto que el original. Si una frase tiene 3 ideas, son 3 frases. Si una frase tiene una palabra de relleno ("ya", "actualmente", "simplemente"), se va.

---

## 7. Lo que queda fuera de este documento

Para evitar ambigüedad cuando aparezcan dudas:

- **Identidad visual** (paleta, tipografía, iconografía, logo) — viene en fase de diseño high-fi.
- **Dominio definitivo** — `vamos.app` está taken por el side-project en fly.dev. Opciones a evaluar cuando se llegue a registro: `vamos.travel`, `holavamos.com`, `usavamos.com`, etc.
- **Microcopy de notificaciones, errores y confirmaciones** — se escribe cuando se llegue a la pantalla correspondiente y se agrega a §5.
- **Microcopy de pantallas que aún no existen** (modo crisis, vault, datos del viajero a nivel perfil) — fuera del MVP, se escribe en su momento.

---

## 8. Próximos pasos

Identidad y tono cerrados (versión MVP). Los siguientes pasos del proyecto son:

1. **Estructura del proyecto Flutter** — carpetas, navegación, state management. (`07-flutter-structure.md`)
2. **Reglas de seguridad de Firestore** versión production-ready. (`08-firestore-rules.md`)
3. **Primer flujo end-to-end** — implementar Flujo 1 completo.

Cada uno se aborda como conversación independiente.
