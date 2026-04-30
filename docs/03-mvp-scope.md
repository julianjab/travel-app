# MVP Scope — App de Viajes Compartidos

> Documento de alcance del MVP (Caso 0). Consolida las decisiones tomadas a partir del PRD inicial y define exactamente qué entra y qué no entra al primer release. Última actualización: abril 2026.

---

## 1. Contexto

Este MVP corresponde al **Caso 0** definido en el PRD (sección 8): el primer viaje real del grupo propio del fundador, en este caso un viaje a Brasil en 6+ semanas. El único objetivo es validar que el flujo end-to-end no se rompe en un viaje real.

No es un MVP comercial. No hay métricas de adquisición ni revenue. La métrica única es: **¿el grupo terminó el viaje usando la app de inicio a fin, o tuvieron que volver a Splitwise/Wanderlog/Docs en algún momento?**

---

## 2. Tesis a validar

> Un grupo LATAM real puede planear y ejecutar un viaje usando una sola app, sin volver a las herramientas que usan hoy (WhatsApp para coordinar + Google Docs para itinerario + Splitwise para gastos).

Si el Caso 0 sale bien, se abre la fase de Casos 1-5 (mes 2-4) descrita en el PRD. Si sale mal, se itera el MVP antes de invitar a nadie externo.

---

## 3. Alcance del MVP

Tres flujos core. Nada más.

### Flujo 1 — Crear viaje + sumar al grupo

**Funcionalidad:**
- Crear viaje con: nombre, destino, fechas (inicio/fin), moneda principal del viaje
- Generar **link público de invitación**. Cualquiera con el link entra al viaje sin aprobación.
- Onboarding del miembro al unirse: nombre, foto, tags de preferencia (multi-select):
  - Restricciones alimentarias (vegetariano, vegano, celíaco, alergias texto libre)
  - Estilo de viaje (camino mucho / camino poco, nocturno / madrugador)
  - Rango de presupuesto cómodo (3 niveles: ajustado / medio / amplio)
- Lista de miembros del viaje visible para todos, con sus tags.

**Rol implícito:** quien crea el viaje es el facilitador (definición sección 4.4 del PRD). En el MVP las únicas acciones exclusivas del facilitador son: invitar miembros (puede generar/regenerar el link) y archivar el viaje al final. Todo lo demás es plano.

**Fuera de este flujo en el MVP:**
- Datos del viajero a nivel perfil (cédula, pasaporte, viajero frecuente — sección 4.5 del PRD, va a v1.1+)
- Aprobación del facilitador para invitaciones
- Sacar miembros del grupo (se asume que en el Caso 0 nadie se sale)
- Transferir rol de facilitador
- Coordinación de fechas previa al viaje (caso 2 del PRD, fuera del MVP)

---

### Flujo 2 — Itinerario colaborativo con votación

**Funcionalidad:**
- Vista de itinerario organizada por días del viaje
- Cualquier miembro agrega "items" libremente. Cada item tiene:
  - Título
  - Día asignado
  - Hora (opcional)
  - Ubicación (texto libre, sin mapa)
  - Notas (texto libre)
  - Autor (quién lo propuso, automático)
  - Estado: **propuesto** o **confirmado**
- **Modelo de votación: items sueltos con votación libre (Modelo B).** No hay slots formales de "cena del día 2". Todos los items son iguales. Cualquier miembro puede votar **sí / no** a cualquier item, con conteo visible.
- Cuando hay items que compiten conceptualmente (ej: 3 restaurantes propuestos para la noche del día 2), el grupo se entiende solo viendo los conteos. El facilitador confirma el ganador manualmente cambiando el estado del item a "confirmado".
- Al lado del nombre de cada votante se muestran sus tags de preferencia (visibilidad pasiva — Decisión A3). Si alguien vegetariano vota "sí" a una steakhouse, queda visible.

**Fuera de este flujo en el MVP:**
- Mapa interactivo
- Import automático desde correos / screenshots (caso 7 del research, fuera del MVP)
- Sincronización con calendario externo
- Recordatorios push
- Notas colaborativas tipo Google Docs sobre items
- Reordenar / drag-drop sofisticado entre días (mover día se hace editando el campo)

---

### Flujo 3 — Gastos compartidos

**Funcionalidad:**
- Registrar gasto con:
  - Monto
  - Moneda (default: moneda principal del viaje, override por gasto disponible — Decisión C1.5)
  - Tasa de conversión a la moneda del viaje (manual, cuando hay override)
  - Quién pagó (un miembro, default: usuario actual)
  - Entre quiénes se divide (default: todos los miembros, editable)
  - Tipo de división: partes iguales (default), porcentajes, o montos absolutos
  - Descripción (opcional)
  - Foto del recibo (opcional)
- Lista de gastos ordenada por fecha, filtros básicos (por persona, por día)
- **Vista de saldos en tiempo real**, sin "cierre de cuentas":
  - Calculados continuamente desde el primer gasto registrado
  - Algoritmo de simplificación: en lugar de "A debe a B, B debe a C", la app sugiere transferencias directas mínimas (A le paga a C)
  - Todos los saldos se calculan en la moneda principal del viaje
- Marcar deuda como saldada manualmente (cuando alguien paga por fuera de la app)

**Fuera de este flujo en el MVP:**
- Integración con Nequi / Mercado Pago / transferencias bancarias (v1.1+)
- Cobro automatizado / recordatorios de cobro
- Exportar gastos a CSV / PDF
- Categorías de gastos (comida, transporte, alojamiento)
- Gastos recurrentes
- API de tasas de cambio (la tasa se mete manualmente)

---

## 4. Lo que NO entra al MVP (lista explícita)

Para que no haya ambigüedad cuando aparezcan dudas más adelante:

- Vault de documentos del viaje (caso 5 del PRD)
- Modo crisis (caso 6 del PRD)
- Datos del viajero a nivel perfil — pasaporte, cédula, etc. (sección 4.5 del PRD)
- Coordinación de fechas previa al viaje (caso 2 del PRD)
- Integración con WhatsApp más allá de compartir el link de invitación (sin bot, sin sincronización)
- Multi-idioma (solo español)
- Flutter web (la app móvil no se compila a web; la landing es un proyecto Astro separado bajo `web/`, con scope mínimo en MVP — solo página de invitación `/j/[code]`)
- Booking directo de vuelos / hoteles
- AI / recomendaciones de destinos
- Red social, feed público, marketplace
- Calendario corporativo

---

## 5. Decisiones de scope tomadas

Quedan registradas para no reabrirlas a menos que aparezca evidencia nueva:

| # | Decisión | Elegida | Razón |
|---|---|---|---|
| D1 | Preferencias en onboarding | A3 — capturadas y mostradas pasivamente como tags | Mata el onboarding vacío sin meter motor de lógica activa. Prueba la tesis sin construir el sistema completo. |
| D2 | Modelo de votación | B2 — voto binario sí/no con conteo visible | B1 (emojis) no resuelve parálisis por análisis. B3 (rankeada) es over-engineering para Caso 0. |
| D3 | Manejo de monedas | C1.5 — moneda del viaje + override por gasto, tasa manual | El viaje tiene 2-3 monedas máximo. API de tasas abre problemas (tasa del banco vs API, offline, fijación). Manual es controlable y funciona offline. |
| D4 | Invitaciones | Link público | Aprobación es seguridad a escala, irrelevante en grupo de amigos. |
| D5 | Modelo de items en itinerario | B — items sueltos con votación libre | A (slots formales) es burocracia. B refleja cómo funcionan los grupos reales en Google Docs. |
| D6 | Cálculo de deudas | Tiempo real continuo, sin cierre | Ataca directo el insight #4 del research: transparencia en tiempo real, no "hora de la verdad" al final. |

---

## 6. Trade-offs aceptados

Cosas que sé que no son ideales pero asumo a propósito en este MVP:

- **Sin mapa en itinerario.** Wanderlog gana en visualización geográfica. Lo aceptamos porque el Caso 0 es un viaje a Brasil donde el grupo va a estar mayormente en Río o São Paulo, y ubicaciones en texto bastan. Si el feedback dice que se sintió la falta, entra a v1.1.
- **Sin mapa, sin import automático, sin recordatorios.** El MVP está deliberadamente más cerca de "Google Doc estructurado + Splitwise pegado" que de "Wanderlog moderno". La diferenciación competitiva real (modo crisis, vault, distribución de trabajo, WhatsApp nativo) está fuera del MVP a propósito.
- **Tasa de cambio manual.** El usuario tiene que saber a cuánto pagó cuando metió un gasto en moneda distinta. Si no sabe, abre Google. Es fricción pero predecible.
- **Sin notificaciones push.** Las decisiones de votación y los gastos nuevos no notifican a nadie. Si alguien quiere ver si hay novedades, abre la app. Push entra a v1.1 si el feedback lo pide.
- **Sin sincronización offline real.** El MVP requiere conexión para escribir. La lectura puede quedar cacheada. El "funciona offline o no funciona" del principio 3.5 se va a probar en v1.1 cuando ya haya datos reales de uso.

Este último punto es el más delicado y vale la pena marcarlo: **el MVP rompe parcialmente con el principio 3.5 del PRD**. La justificación es que construir sincronización offline real (con resolución de conflictos en gastos compartidos editados por dos personas a la vez) es un proyecto de varias semanas por sí solo, y en el Caso 0 el grupo va a tener wifi del Airbnb + datos brasileros. Si el viaje tiene momentos sin señal donde la app falla, eso es feedback valioso para v1.1.

---

## 7. Estimación de esfuerzo

Aproximada, asumiendo desarrollo solo en Flutter + Firebase, una sola persona:

- **Setup inicial (Flutter + Firebase + auth + estructura base):** 3-5 días
- **Flujo 1 — Crear viaje + invitar:** 5-7 días
- **Flujo 2 — Itinerario + votación:** 7-10 días
- **Flujo 3 — Gastos + saldos:** 10-14 días (es el más complejo por el cálculo de deudas simplificadas)
- **Pulido, bugs, testing en grupo real:** 5-7 días

**Total estimado: 30-43 días de trabajo efectivo.** Encaja en 6 semanas si hay foco. Si hay días dispersos, queda justo.

---

## 8. Próximos pasos

1. Diseño de flujos / wireframes de baja fidelidad para los 3 flujos
2. Modelo de datos en Firestore (colecciones, documentos, reglas de seguridad)
3. Estructura del proyecto Flutter (carpetas, navegación, state management)
4. Primer flujo funcional end-to-end (probablemente Flujo 1 completo antes de tocar Flujo 2)

Cada uno de estos puntos se aborda como conversación independiente.
