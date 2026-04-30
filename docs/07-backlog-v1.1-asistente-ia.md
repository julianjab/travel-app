# Backlog v1.1 — Asistentes IA

> Documento de backlog. Captura la dirección del producto post-MVP en lo que respecta a asistentes IA dentro de Vamos. No es PRD ni scope cerrado — es la base para retomar la conversación cuando el Caso 0 valide el MVP. Última actualización: abril 2026.

---

## 1. Contexto y alcance

Este documento captura la dirección de los **asistentes IA** dentro de Vamos. Es backlog, no scope: nada de esto entra al MVP del Caso 0. La razón de escribirlo ahora es no perder las decisiones tomadas y dejar el camino marcado para cuando se retome — probablemente entre v1.1 y v1.x según roadmap del PRD §2.

**Tesis del documento:**

Vamos no compite con apps de planeación individual con IA (Mindtrip, Layla.ai, Wonderplan). El producto core sigue siendo coordinación de grupos LATAM. Los asistentes IA son **capa transversal**: ayudan a miembros individuales a hacer mejor lo que ya hacen en Vamos (proponer items, registrar gastos), aprovechando el contexto único del grupo.

**Alcance del doc:**

- Asistente de itinerario (candidato fuerte para v1.1)
- Asistente de gastos (candidato para v1.2 — solo esbozo)
- Reglas de UX comunes a futuros asistentes
- Qué validar antes de construir

**No cubre:**

- Stack de implementación detallado (se decide al codear)
- Asistente como producto separado o app aparte
- AI generativa de destinos / planes completos sin grupo (sigue siendo "lo que NO va al MVP" del PRD §6)

---

## 2. Problema que resuelve dentro de Vamos

El MVP resuelve coordinación de grupo. Pero hay un dolor que el MVP no toca: **proponer un item decente requiere trabajo individual previo**.

Hoy en Vamos, si Laura quiere proponer una cena para el sábado, tiene que:

1. Salirse de Vamos.
2. Googlear restaurantes en Río con buenas reseñas.
3. Filtrar mentalmente: ¿Pedro era celíaco? ¿alguien marcó presupuesto ajustado?
4. Volver a Vamos y crear el item.

Eso es trabajo. Y se concentra en quien sabe googlear y se acuerda de los tags del grupo. Contradice el principio 3.2 (distribuir trabajo) en la práctica: el MVP distribuye **el acto de proponer**, pero no la **capacidad** de proponer bien.

**El asistente de itinerario apunta exactamente a eso:** que cualquier miembro pueda generar propuestas decentes en 30 segundos, con conciencia del contexto del grupo, sin salir de la app.

Mismo razonamiento aplica a gastos (v1.2): registrar un gasto bien (con foto, divididos correctos, descripción útil) es trabajo. Si un asistente puede ayudar, baja la fricción para que más gente registre.

---

## 3. Decisiones de producto cerradas

Decisiones tomadas en conversación previa. No reabrir sin evidencia nueva.

### 3.1 Asistente del individuo, no del grupo

Cada miembro tiene su propia conversación con el asistente. No hay "asistente compartido" que vea todo el grupo. El asistente es una herramienta para que un miembro arme propuestas mejores, no un participante más en la coordinación.

**Razón:** coherente con cómo funciona Vamos (cualquier miembro propone, el grupo vota). Un asistente compartido abre preguntas que no vale la pena contestar (chat compartido, prioridad entre peticiones contradictorias, costos de tokens cruzados).

### 3.2 El asistente conoce al grupo, sin ser restrictivo

El asistente tiene acceso a los miembros del viaje y sus tags (dieta, ritmo, presupuesto). Los usa para **avisar y filtrar suavemente**, no para bloquear.

Ejemplo de tono correcto:

> "Te sugiero estos 3 restaurantes. Aprazível es asado argentino — ojo que Laura es vegetariana. Si querés algo más amigable, mirá Teva o Govinda."

Ejemplo de tono incorrecto (restrictivo):

> ❌ "No puedo sugerir Aprazível porque Laura es vegetariana."

**Razón:** los tags son señales, no reglas. Vamos opera con visibilidad pasiva (decisión D1 del scope). El asistente extiende ese patrón.

### 3.3 El usuario es el filtro humano antes del grupo

El asistente nunca escribe items directo en el itinerario del grupo. Propone opciones al usuario; el usuario decide qué pasa al grupo.

**Razón:** si el asistente alucina un lugar, lo caza el usuario antes que el grupo. Si propone 5 opciones, el usuario elige 1-2 — el grupo no necesita votar 5. Reduce ruido y errores.

### 3.4 Cards "preview" con un tap para agregar

El asistente no propone con texto plano. Cuando sugiere algo, lo muestra como **card preview de item** estructurada: título, día sugerido, ubicación, costo estimado, notas. Cada card tiene un botón "Agregar al itinerario".

Tap → el item entra al itinerario del grupo en estado **propuesto**, sujeto a votación normal (Flujo 2 del MVP). Sin tap, no pasa nada.

Una vez agregado, el item es **idéntico a uno creado manualmente**. El autor queda como el usuario que lo agregó (no "Asistente"). El grupo no ve la diferencia.

### 3.5 FAB que abre el chat como overlay

El asistente vive en un FAB (floating action button) en la pantalla del viaje. Tap → bottom sheet con el chat encima de la pantalla actual. No hay tab dedicado.

**Razón:** el usuario abre el asistente desde donde está mirando el itinerario, ve las cards, agrega lo que quiere, cierra. Cero context switch. Si v1.2 trae asistente de gastos, mismo patrón en la pestaña de Gastos.

**Persistencia:** la conversación persiste **por viaje**, no por sesión. Si el usuario cierra el chat y lo vuelve a abrir mañana, el historial sigue ahí.

---

## 4. Asistente de itinerario (v1.1)

### 4.1 Qué hace

Conversa con un miembro del viaje y propone items para el itinerario, con conciencia del contexto del grupo (miembros, tags, fechas, items ya existentes, presupuesto agregado).

Ejemplos de cosas que el usuario le puede pedir:

- "Sugerime 3 restaurantes para la noche del sábado en Ipanema."
- "¿Qué actividad puedo hacer el lunes en la mañana cerca del Airbnb?"
- "Necesito una idea para el día 3, algo que no implique caminar mucho."
- "¿Vale la pena ir al Cristo Redentor en domingo?"

### 4.2 Tools que necesita

**Tools de lectura (sin efectos secundarios):**

- `get_trip_context()` — viaje actual, fechas, destino, miembros con sus tags, items ya en el itinerario, costo estimado total
- `search_places(query, location, type)` — restaurantes, atracciones, hoteles vía Google Places u equivalente
- `get_weather(location, dates)` — clima del destino para fechas del viaje
- `web_search(query)` — eventos, blogs, info no estructurada

**Tools de escritura — ninguna.**

El asistente no escribe directo. Las cards preview se generan en el cliente a partir de las propuestas estructuradas que devuelve el LLM. La escritura al itinerario pasa por el botón "Agregar" del usuario, que llama a la misma función que `crear item` del MVP.

Esto simplifica seguridad y reglas: el LLM nunca tiene permisos de escritura sobre datos del grupo.

### 4.3 Reglas de UX

- **Propone 2-3 opciones, nunca 10.** Coherente con prevenir parálisis por análisis (insight 4.3 del research).
- **Considera tiempos de traslado** entre items consecutivos del día. Si el usuario ya tiene una actividad a las 15:00 en Centro y pide cena a las 19:00, no sugiere algo en Barra da Tijuca.
- **Avisa de tags relevantes**, sin bloquear (decisión 3.2).
- **Avisa de presupuesto** si una opción es notablemente más cara que el promedio de items confirmados del viaje. Sin moralizar.
- **Cuando duda, pregunta.** Si el usuario dice "sugerime cena", el asistente puede preguntar "¿qué noche?" antes de buscar. No alucinar suposiciones.

### 4.4 Cómo se conecta al MVP existente

- **Flujo 2 (itinerario):** los items agregados desde el asistente entran como `proposed` y siguen el flujo de votación normal del MVP. Cero cambio en el modelo de datos del doc 05.
- **Costo estimado por persona** (campo `estimatedCostPerPerson` del item, doc 05 §2.2): el asistente lo pre-llena cuando puede inferirlo de la búsqueda. Si no puede, lo deja vacío. Coherente con el patrón actual.
- **Autor del item:** el `userId` del miembro que tapeó "Agregar". El sistema no marca "creado por IA" en ningún lado.

### 4.5 Qué se muestra y qué no

**Sí se muestra:**

- Cards preview en el chat con los campos del item (título, día sugerido, ubicación, costo estimado, notas).
- Conversación natural en español (tono según doc 06: voseo, cercano, sin jerga local).
- Avisos contextuales sobre tags ("ojo que Laura es vegetariana") y presupuesto.

**No se muestra:**

- Razonamiento interno del LLM (chain of thought).
- Tools que está llamando ("buscando en Google Places...") más allá de un loading discreto.
- Costos de tokens, "powered by" de modelos, ni nada técnico.

---

## 5. Asistente de gastos (v1.2 — esbozo)

Esto es exploratorio. Se profundiza cuando se acerque su momento.

### 5.1 Qué podría hacer

- **Registro asistido:** "registré una cena de R$ 1.200 que pagó Andrés, dividida entre todos" → asistente arma el gasto con los campos prellenados, usuario confirma.
- **Lectura de recibo (foto):** subir foto del recibo, asistente extrae monto y moneda. (Caso de uso clásico, valor obvio.)
- **Aclaración de saldos:** "¿por qué le debo tanto a María?" → asistente explica con los gastos relevantes en lenguaje natural.
- **Detección de patrones:** "los últimos 3 ubers los pagó siempre Laura" → señalar que la carga se está concentrando.

### 5.2 Lo que probablemente no debería hacer

- **Categorizar gastos automáticamente** sin que el usuario pida. El MVP decidió no tener categorías (doc 03 §3). Si v1.2 las agrega, es decisión de producto del momento, no del asistente.
- **Marcar deudas como pagadas.** Eso requiere acción humana explícita, no debería pasar por LLM.

### 5.3 Patrón compartido con v1.1

- FAB en la pestaña de Gastos.
- Cards preview con botón "Registrar".
- Mismas reglas de UX: propone, no escribe directo.
- Acceso a contexto del viaje (gastos ya registrados, miembros, etc.).

---

## 6. Reglas de UX comunes a todos los asistentes

Reglas que aplican a v1.1, v1.2 y cualquier asistente futuro. Son la "constitución" de los asistentes IA en Vamos.

1. **El asistente propone, el usuario confirma.** Nunca escribe directo en datos del grupo.
2. **2-3 opciones, no 10.** Reducir parálisis es parte del valor, no se sacrifica por completitud.
3. **Cards preview, no texto plano** cuando se propone algo accionable. El texto es para conversar; la acción va en card estructurada.
4. **Conciencia del grupo, no restricción del grupo.** Avisa de tags y presupuesto, no bloquea ni moraliza.
5. **Tono según doc 06.** Voseo, cercano, herramienta competente. No "asistente entusiasta" ni emojis decorativos.
6. **Cuando duda, pregunta.** Mejor una pregunta clarificadora que una alucinación con confianza.
7. **El asistente vive en FAB, no en tab.** Cada asistente cerca de lo que asiste.
8. **Conversación persiste por viaje.** No por sesión, no global cross-viajes.
9. **El usuario que usa el asistente paga el costo (en términos de límites).** Si v1.1 trae rate limits o tier Pro, son del usuario que hace las llamadas, no del grupo.

---

## 7. Costo y stack

### 7.1 Costo estimado por viaje

Asumiendo Claude Haiku 4.5 con prompt caching y compactación de contexto:

- **Bien optimizado:** $0.03–0.08 USD por viaje completo planeado.
- **Sin optimizar:** $0.10–0.20 USD.

Numerito de referencia, no compromiso. Hay que medir con uso real.

### 7.2 Stack

**Decisión:** se mantiene Flutter + Firebase del PRD §8.

El backend del asistente (llamadas a Claude API + tools de búsqueda) corre en **Firebase Cloud Functions**, no en infraestructura nueva. Razón: la decisión de stack está cerrada en el PRD y no hay evidencia que justifique reabrirla. Cloud Functions es suficiente para el patrón de "request → call LLM → return response" del asistente.

Las APIs externas (Google Places, OpenWeather, web search) se consumen desde la Cloud Function, no desde el cliente. El cliente solo habla con Firebase.

**Lo que NO se hace:**

- No se mueve a Cloudflare Workers / D1 / R2. Esa fue una propuesta del doc original, descartada porque migrar de stack en etapa de validación de producto no agrega valor.
- No hay backend separado solo para el asistente.

**Cuándo reabrir:** si Cloud Functions empieza a doler con latencia o costo cuando haya datos reales de uso (no antes).

### 7.3 Optimizaciones a aplicar desde v1.1

- **Prompt caching de Anthropic** para system prompt + tool definitions.
- **Compactación de contexto:** no mandar la conversación entera, mandar últimos N turnos + resumen del viaje + items actuales.
- **Cache de búsquedas:** Places por ciudad 24h, clima 6h, búsquedas idénticas en sesión forever.
- **Spending limit en console.anthropic.com** desde día 1. Mejor que API empiece a fallar a recibir factura sorpresa.

### 7.4 Rate limits

Esquema sugerido para v1.1, ajustable con datos reales:

- **Free:** 30 mensajes al asistente por día, por usuario.
- **Pro (cuando exista):** 300 mensajes/día.
- **Trigger de throttling:** si un usuario consume más de $2 USD de LLM en un día, throttle automático.

Track `llm_cost_cents` por usuario en Firestore para detectar abuso y power users.

---

## 8. Qué validar antes de construirlo

No construir v1.1 sin haber validado lo siguiente con datos reales del Caso 0 y Casos 1-5:

### 8.1 ¿Existe el dolor en serio?

Pregunta de validación: **¿en el Caso 0 y Casos 1-5, los miembros que no son el organizador propusieron items?**

- Si sí, en qué proporción y de qué calidad. El asistente puede escalar lo que ya pasa.
- Si no, el problema no es "proponer mejor", es "no proponer". El asistente no lo arregla. Hay que entender por qué no proponen antes de meter IA.

### 8.2 ¿La conciencia del grupo importa de verdad?

¿Hubo casos en los Casos 1-5 donde alguien propuso un item incompatible con tags de otro miembro? Si la respuesta es "no, los grupos se conocen y nadie metió la pata", el valor del asistente baja. Si la respuesta es "sí, varias veces", la killer feature está validada.

### 8.3 ¿La gente quiere chatear con una app?

El patrón "FAB → bottom sheet con chat" asume que la gente está dispuesta a escribir en un chat dentro de Vamos. Si el feedback de los Casos 1-5 muestra que la gente prefiere formularios estructurados ("agregar item" con dropdowns) sobre chat libre, el asistente tiene que rediseñarse.

### 8.4 ¿Cuánto cuesta de verdad?

Validar el rango $0.03–0.08/viaje con uso real, no con estimaciones. Si sale 5x más caro, hay que rediseñar antes de lanzar (compactación más agresiva, modelo más chico para sub-tareas, etc.).

### 8.5 Build vs no build

Si después de validar se decide que el asistente no resuelve dolor real, **se mata la feature** sin culpa. Este doc no es compromiso de construir, es preparación para una decisión informada.

---

## 9. Lo que queda fuera

Para evitar ambigüedad cuando aparezcan dudas:

- **AI que recomienda destinos** (a dónde ir). El grupo ya sabe a dónde va. Sigue siendo "no va al MVP" del PRD §6 y tampoco va a v1.x.
- **AI que arma el viaje completo de una vez.** Tipo "dame un plan de 7 días en Río". Contradice "el LLM propone, el usuario confirma" llevado al extremo. Si en v2+ aparece como feature, se diseña con cuidado.
- **Asistente compartido del grupo.** Decidido en 3.1.
- **Booking directo desde el asistente.** El asistente puede sugerir "Hotel X queda libre", pero la reserva pasa por flujo de afiliación / link externo. Sigue siendo "no va al MVP".
- **Asistente como producto separado o standalone.** Vamos es la app. El asistente es feature dentro.

---

## 10. Próximos pasos

Este documento es backlog. No tiene tarea inmediata asociada.

Cuándo retomarlo:

1. Cuando el Caso 0 cierre con resultado positivo y Casos 1-5 estén en marcha.
2. Cuando haya datos de los puntos de validación del §8.
3. Cuando se decida priorizar v1.1 sobre otras features candidatas (push notifications, mapa en itinerario, vault de documentos, modo crisis, etc.).

En ese momento se abre `08-prd-v1.1-asistente-itinerario.md` con el alcance específico, decisiones de implementación, y wireframes de las pantallas nuevas.