# Wireframes MVP — App de Viajes Compartidos

> Wireframes de baja fidelidad para los 3 flujos del MVP (Caso 0). Estructura y navegación, no diseño visual. Última actualización: abril 2026.

---

## Convenciones

- `[Texto]` = botón o elemento tappable
- `›` = navega a otra pantalla
- `(...)` = nota de comportamiento (no es UI visible)
- Pantallas numeradas por flujo: `F1.1`, `F2.3`, etc.

---

## Mapa de navegación general

```
                    [Splash / Auth]
                          │
                          ▼
                  ┌───────────────┐
                  │  Mis viajes   │ ◄──── home, lista de viajes del usuario
                  └───────┬───────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
       [+ Nuevo viaje]         [Tap un viaje]
              │                       │
              ▼                       ▼
        Flujo 1 (crear)        ┌──────────────┐
                               │ Tabs viaje   │
                               ├──────────────┤
                               │ Itinerario   │ ◄── Flujo 2
                               │ Gastos       │ ◄── Flujo 3
                               │ Miembros     │
                               │ Ajustes      │
                               └──────────────┘
```

Decisiones de navegación:

- **Tabs dentro del viaje, no stack profundo.** El usuario está casi siempre en uno de tres lugares: itinerario, gastos, gente. Tabs lo refleja.
- **Sin home tipo dashboard.** "Mis viajes" es lista pura. No hay actividad reciente, no hay feed. La app no es una red social.
- **Auth se asume pero no se diseña ahora.** Firebase Auth con Google/Apple, pantalla estándar. No vale gastar wireframe en eso.

---

# FLUJO 1 — Crear viaje + sumar al grupo

## F1.1 — Mis viajes (home, estado con viajes)

```
┌─────────────────────────────────┐
│  Mis viajes              [👤]   │  ← perfil arriba derecha
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐  │
│  │ ░░░░░░░ FOTO ░░░░░░░░░░░░ │  │  ← header visual del viaje
│  │ ░░░ DE PORTADA ░░░░░░░░░░ │  │
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░ │  │
│  ├───────────────────────────┤  │
│  │ Brasil con los del barrio │  │  ← tap › F2.1
│  │ 12-22 jun · 7 personas    │  │
│  │ 🟢 En curso · día 3 de 10 │  │  ← estado calculado por fechas
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ░░░░░░░ FOTO ░░░░░░░░░░░░ │  │
│  ├───────────────────────────┤  │
│  │ Año nuevo en Mendoza      │  │
│  │ 28 dic - 3 ene · 5 personas│ │
│  │ 🟡 Por planear · en 8 mes │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ [color/inicial: C]        │  │  ← placeholder cuando no hay foto
│  ├───────────────────────────┤  │
│  │ Cartagena finde           │  │
│  │ 8-10 mar · 4 personas     │  │
│  │ ⚪ Terminado              │  │
│  └───────────────────────────┘  │
│                                 │
│            [+ Nuevo viaje]      │  ← FAB abajo derecha
│                                 │
└─────────────────────────────────┘
```

**Orden de la lista:** En curso (🟢) primero, después Por planear (🟡) ordenados por fecha de inicio más cercana, después Terminado (⚪) y Archivado (📦) por fecha de fin más reciente.

**Estados del viaje (calculados automáticamente por fechas, Nivel 1):**

| Estado | Cuándo | Microcopy en la card |
|---|---|---|
| 🟡 Por planear | hoy < fecha inicio | "en X días/meses" |
| 🟢 En curso | inicio ≤ hoy ≤ fin | "día N de M" |
| ⚪ Terminado | hoy > fecha fin | (sin extra) |
| 📦 Archivado | facilitador archivó | (sin extra) |

El estado es **solo etiqueta visual + ordenamiento**. No cambia comportamiento de la app: en cualquier estado se puede agregar items, registrar gastos, etc. La idea de cambiar tab default según estado o congelar ediciones queda fuera del MVP — abre preguntas que no quiero contestar todavía.

**Foto de portada:** opcional. Si no hay foto, se renderiza un placeholder con color generado del nombre del viaje + inicial grande. Esto evita el "estado roto" de cards sin imagen.

**Estado vacío** (primera vez que abre la app): mismo layout, lista vacía, copy tipo "Aún no has creado ni te han invitado a un viaje. Crea el primero o pídele a alguien el link."

---

## F1.2 — Crear viaje (form mínimo)

```
┌─────────────────────────────────┐
│  ←  Nuevo viaje                 │
├─────────────────────────────────┤
│                                 │
│  Foto de portada (opcional)     │
│  ┌───────────────────────────┐  │
│  │   📷 Subir foto           │  │  ← galería del SO o cámara
│  └───────────────────────────┘  │
│                                 │
│  Nombre del viaje               │
│  ┌───────────────────────────┐  │
│  │ Brasil con los del barrio│  │
│  └───────────────────────────┘  │
│                                 │
│  Destino                        │
│  ┌───────────────────────────┐  │
│  │ Río de Janeiro            │  │  ← texto libre, sin autocomplete en MVP
│  └───────────────────────────┘  │
│                                 │
│  Fechas                         │
│  ┌─────────────┐ ┌────────────┐ │
│  │ 12 jun 2026 │ │ 22 jun 2026│ │
│  └─────────────┘ └────────────┘ │
│                                 │
│  Moneda principal               │
│  ┌───────────────────────────┐  │
│  │ COP — Peso colombiano  ▼ │  │  ← dropdown, default = moneda del país del user
│  └───────────────────────────┘  │
│                                 │
│                                 │
│         [Crear viaje]           │  ← se activa cuando nombre, destino, fechas y moneda están llenos
│                                 │
└─────────────────────────────────┘
```

**Decisiones de scope aquí:**

- **Foto opcional, no bloquea.** Si no se sube, se genera placeholder con color del nombre + inicial. Esto mata el "viaje feo" en la lista pero no obliga a tener foto antes de planear.
- Sin descripción larga del viaje. Si lo necesitan, lo ponen en el chat de WhatsApp.
- Moneda principal **no se puede cambiar después** en el MVP. Cambiarla rompería los saldos calculados. Esto va escrito en un microcopy chiquito debajo del dropdown.

---

## F1.3 — Pantalla de éxito + invitar

```
┌─────────────────────────────────┐
│                                 │
│           ✓ Viaje creado        │
│                                 │
│   Brasil con los del barrio     │
│        12-22 jun 2026           │
│                                 │
│  ─────────────────────────────  │
│                                 │
│   Comparte este link con tu     │
│   grupo. Quien lo abra entra.   │
│                                 │
│   ┌─────────────────────────┐   │
│   │ vamos.app/j/x7k2m9      │   │
│   │            [📋 Copiar]  │   │
│   └─────────────────────────┘   │
│                                 │
│   [Compartir por WhatsApp]      │  ← deep link a WhatsApp con el link prellenado
│   [Compartir por otro lado]     │  ← share sheet nativo del SO
│                                 │
│                                 │
│         [Ir al viaje] ›         │  ← entra a F2.1
│                                 │
└─────────────────────────────────┘
```

**Por qué esta pantalla y no mandarlo directo al viaje:**

El momento "acabo de crear el viaje" es exactamente cuando hay que invitar. Si mando al usuario al itinerario vacío, el siguiente paso (compartir el link) queda enterrado en algún menú. Esta pantalla pone la acción correcta al frente.

WhatsApp se ofrece explícitamente, no escondido en el share sheet — es el principio 3.4 del PRD operacionalizado.

---

## F1.4 — Onboarding del invitado (al abrir el link)

Esta pantalla la ve quien recibió el link, no quien creó el viaje. La pantalla cambia según si el usuario ya tiene cuenta o no.

**Caso A — Usuario nuevo (no tiene cuenta en la app)**

Después de pasar por auth (Firebase, Google/Apple) se le pide su perfil base **una sola vez en la vida**:

```
┌─────────────────────────────────┐
│                                 │
│    Bienvenido. Antes de         │
│    sumarte al viaje...          │
│                                 │
│  ─────────────────────────────  │
│                                 │
│   Tu nombre                     │
│   ┌───────────────────────────┐ │
│   │ Andrés Gómez              │ │
│   └───────────────────────────┘ │
│                                 │
│   Foto de perfil (opcional)     │
│   [📷 Subir foto]               │
│                                 │
│   Este es tu perfil. Puedes     │
│   usar un alias diferente en    │
│   cada viaje en la pantalla     │
│   siguiente.                    │
│                                 │
│         [Continuar] ›           │  ← va a F1.4b
│                                 │
└─────────────────────────────────┘
```

**Caso B — Usuario que ya tiene cuenta**

Salta directo a F1.4b. El nombre y la foto del perfil ya existen.

---

## F1.4b — Alias para este viaje

Esta pantalla la ven todos los invitados, sea su primer viaje o no. Es donde se elige el alias del viaje:

```
┌─────────────────────────────────┐
│                                 │
│    Te invitaron al viaje        │
│                                 │
│   ░░░ Foto del viaje ░░░░░      │
│                                 │
│   Brasil con los del barrio     │
│        12-22 jun 2026           │
│       Creado por Andrés         │
│                                 │
│  ─────────────────────────────  │
│                                 │
│   ¿Cómo te van a llamar         │
│   en este viaje?                │
│                                 │
│   ┌───────────────────────────┐ │
│   │ Pollo                     │ │  ← default = nombre del perfil, editable
│   └───────────────────────────┘ │
│                                 │
│   En tu perfil eres "Andrés     │
│   Gómez". Aquí puedes usar      │
│   apodo, nickname o lo que      │
│   te llame el grupo.            │
│                                 │
│                                 │
│         [Continuar] ›           │  ← va a F1.5
│                                 │
└─────────────────────────────────┘
```

**Decisiones del modelo de alias (Opción A):**

- El perfil del usuario tiene **nombre real** (carga una vez, persistente).
- Cada viaje tiene un **alias por miembro** (puede coincidir con el nombre real o no).
- El default del alias es el nombre real. Si el usuario no toca nada, queda igual.
- Lo que ven los demás miembros del viaje es el **alias**, no el nombre real. El nombre real no es visible para nadie en el MVP.
- El alias se puede editar después desde Ajustes del viaje (F4.2).
- La foto del perfil es global. **No hay foto por alias** en el MVP — agregaría un cuarto modelo de identidad y no resuelve un problema real. Si el grupo necesita "ver al pollo con cara de pollo", el grupo usa la foto del perfil.

**Por qué esta separación:** prepara el terreno para v1.1+ cuando entren datos del viajero a nivel perfil (PRD 4.5: cédula, pasaporte, viajero frecuente). Esos datos viven con el nombre real, no con el alias.

---

## F1.5 — Onboarding: tags de preferencia

```
┌─────────────────────────────────┐
│  ←  Cuéntanos un poco           │
├─────────────────────────────────┤
│                                 │
│   Tus preferencias quedan       │
│   visibles para el grupo.       │
│   Salta lo que no aplique.      │
│                                 │
│  ─────────────────────────────  │
│                                 │
│   🍴 ¿Comes de todo?            │
│                                 │
│   [ Como de todo ]              │
│   [ Vegetariano ]               │
│   [ Vegano ]                    │
│   [ Celíaco ]                   │
│   [ Otra alergia... ]  ← abre input texto
│                                 │
│  ─────────────────────────────  │
│                                 │
│   🚶 Estilo de viaje            │
│                                 │
│   [ Camino mucho ] [ Camino poco ] │
│   [ Madrugador ] [ Nocturno ]   │
│                                 │
│  ─────────────────────────────  │
│                                 │
│   💰 Presupuesto cómodo         │
│                                 │
│   [ Ajustado ] [ Medio ] [ Amplio ] │
│                                 │
│                                 │
│         [Entrar al viaje] ›     │  ← va a F2.1, siempre habilitado
│                                 │
└─────────────────────────────────┘
```

**Decisiones aquí:**

- Multi-select en restricciones (alguien puede ser vegetariano + celíaco).
- Single-select en presupuesto (los rangos no se mezclan).
- "Camino mucho/poco" y "Madrugador/Nocturno" se pueden combinar libre — alguien puede ser madrugador que camina poco.
- Botón siempre activo. Decisión A3 del scope: tags son opcionales, no bloquean. Si alguien quiere entrar sin marcar nada, entra.
- Sin barra de progreso ni "paso 1 de 2". Una sola pantalla de tags, que se sienta corto.

**Microcopy importante** arriba: "quedan visibles para el grupo". Cero promesas de privacidad falsa. La visibilidad pasiva (D1) requiere que el usuario sepa que lo que marca lo verá el grupo.

---

# FLUJO 2 — Itinerario colaborativo con votación

## F2.1 — Itinerario (vista principal del viaje)

```
┌─────────────────────────────────┐
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│  ░░░░░░ FOTO DE PORTADA ░░░░░░  │  ← header colapsable al hacer scroll
│  ░░░░░░░ DEL VIAJE ░░░░░░░░░░░  │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│   Brasil con los del barrio     │  ← título sobreimpreso o debajo
│   12-22 jun · 🟢 día 3 de 10    │  ← estado calculado
├─────────────────────────────────┤
│  [Itinerario] Gastos  Gente  ⚙  │  ← tabs, "Itinerario" activo
├─────────────────────────────────┤
│                                 │
│  ── Vie 12 jun ──────────────   │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ✓ Vuelo BOG → GIG         │  │  ← confirmado (palomita)
│  │   06:30 · Avianca AV245   │  │
│  │   ~$1.200.000/persona     │  │  ← costo estimado, si está
│  │   Por: Andrés             │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ✓ Check-in Airbnb Ipanema │  │
│  │   18:00                   │  │
│  │   ~$280.000/persona       │  │
│  │   Por: Andrés             │  │
│  └───────────────────────────┘  │
│                                 │
│  ── Sáb 13 jun ──────────────   │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 💭 Pao de Açucar          │  │  ← propuesto (lamparita)
│  │   Mañana · sin hora       │  │
│  │   ~$85.000/persona        │  │
│  │   👍 4   👎 0             │  │  ← contador de votos
│  │   Por: Laura              │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 💭 Cena en Aprazível      │  │
│  │   20:00                   │  │
│  │   (sin costo estimado)    │  │  ← microcopy chiquito
│  │   👍 3   👎 2             │  │
│  │   Por: Juan               │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 💭 Cena en Oro            │  │
│  │   20:00                   │  │
│  │   ~$220.000/persona       │  │
│  │   👍 5   👎 1             │  │
│  │   Por: María              │  │
│  └───────────────────────────┘  │
│                                 │
│  ─────────────────────────────  │
│  Estimado del viaje             │
│  $1.480.000 confirmado          │  ← suma de items confirmados con costo
│  + $305.000 en votación         │  ← suma de items propuestos con costo
│  por persona                    │
│                                 │
│  ($10.360.000 + $2.135.000      │  ← total grupo, parentético, secundario
│   total grupo, 7 personas)      │
│                                 │
│  ⓘ 1 item sin costo estimado    │  ← solo si hay items sin estimar
│  ─────────────────────────────  │
│                                 │
│         [+ Agregar item]        │  ← FAB
│                                 │
└─────────────────────────────────┘
```

**Header del viaje:**

- Foto de portada arriba (la misma de F1.2 / F1.1).
- Al hacer scroll, el header colapsa a una barra slim con el nombre del viaje + estado, dejando más espacio para el itinerario.
- El estado del viaje (🟡 Por planear / 🟢 En curso / ⚪ Terminado) se ve siempre, calculado por fechas.

**Decisiones de diseño del itinerario:**

- **Confirmados y propuestos en la misma lista**, diferenciados por icono y por orden (confirmados arriba dentro de cada día). No los separo en pestañas porque el grupo necesita ver el día completo, no andar saltando.
- **Días sin items no se muestran como secciones vacías** en MVP, solo aparecen cuando hay al menos un item. Si el grupo quiere planear el día 5 desde cero, pasa por "agregar item" y elige el día.
- **Conteo de votos visible en la card**, sin abrirla. Esto es lo que reemplaza al chat infinito: el conteo vive donde se ve.
- **Sin avatares de quién votó qué en la card.** Para no saturar visualmente. Eso vive en el detalle del item (F2.3).
- **Nombre del autor visible** ("Por: Laura") refuerza que cada propuesta tiene dueño y mata el anonimato pasivo.
- **Costo estimado por persona en la card** cuando está declarado. Cuando no está, microcopy chiquito "(sin costo estimado)" en su lugar. Esto invita a que alguien lo llene sin obligar al autor original.

**Footer de estimado del viaje (al final del scroll):**

- **Dos totales separados** (confirmado / en votación). Ver "$1.480.000 confirmado + $305.000 en votación" da dimensión real: lo que está cerrado y lo que aún se está decidiendo. Sumarlos en uno solo escondería la diferencia.
- **Por persona prominente, total del grupo entre paréntesis.** Lo que la gente quiere saber primero es "¿cuánto me sale a mí?". El total del grupo dimensiona pero secundario.
- **"X items sin costo estimado"** se muestra solo cuando hay al menos uno. Honesto: el total no incluye esos items, el grupo lo sabe.
- **Items propuestos con costo se cuentan en "en votación"**, independiente de cuántos votos lleven. Si hay 3 restaurantes propuestos compitiendo para la cena, los 3 entran al sumatorio. Sí, infla el número, pero la realidad es que esa noche el grupo va a gastar plata en uno de los tres — el dato es "esta noche estamos hablando de algo entre $X y $Y".
- **Conversión de monedas:** items en moneda distinta a la del viaje se convierten usando la tasa que el usuario metió al crear el item. Si no metió tasa, el item se trata como "sin costo estimado".

**Estado vacío del footer:** si **ningún item** tiene costo estimado, el footer no se muestra. No queremos un footer vacío que diga "$0".

**Estado vacío del viaje completo:**

```
        Aún no hay nada planeado.

   El primer item lo crea cualquiera:
   un vuelo, un restaurante, una idea
   suelta. Después se vota.

         [+ Agregar primer item]
```

---

## F2.2 — Crear / editar item

```
┌─────────────────────────────────┐
│  ←  Nuevo item        [Guardar] │
├─────────────────────────────────┤
│                                 │
│  Título                         │
│  ┌───────────────────────────┐  │
│  │ Cena en Aprazível         │  │
│  └───────────────────────────┘  │
│                                 │
│  Día                            │
│  ┌───────────────────────────┐  │
│  │ Sáb 13 jun             ▼  │  │  ← dropdown con días del viaje
│  └───────────────────────────┘  │
│                                 │
│  Hora (opcional)                │
│  ┌───────────────────────────┐  │
│  │ 20:00                   ▼ │  │  ← time picker, "sin hora" como opción
│  └───────────────────────────┘  │
│                                 │
│  Ubicación (opcional)           │
│  ┌───────────────────────────┐  │
│  │ R. Aprazível 62, Sta Te.  │  │  ← texto libre, sin maps
│  └───────────────────────────┘  │
│                                 │
│  Costo estimado por persona     │
│  (opcional)                     │
│  ┌────────────┐ ┌─────────────┐ │
│  │  150.000   │ │ COP      ▼  │ │  ← misma moneda override que gastos
│  └────────────┘ └─────────────┘ │
│                                 │
│  Notas (opcional)               │
│  ┌───────────────────────────┐  │
│  │ Reservar con anticipación,│  │
│  │ vista al cerro            │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Sin "tipo de item" (vuelo / hotel / actividad / comida).** Categorías abren preguntas que no quiero contestar todavía (¿qué pasa si no hay categoría que aplica? ¿filtro por tipo? ¿iconos diferentes?). Es chrome del Modelo A camuflado. Si el grupo lo necesita, lo escribe en el título o las notas.

**Costo estimado por persona:**

- Es **por persona, no total**. La pregunta que el usuario tiene es "¿cuánto me cuesta esto a mí?".
- Es **opcional**. Si quien propone el item no sabe cuánto cuesta, lo deja vacío y otro miembro lo puede llenar después editando.
- Acepta **moneda distinta a la del viaje** (mismo override que gastos en D3). Si el viaje está en COP y la cena cuesta R$ 200, se mete así. La conversión a la moneda del viaje se hace al sumar para el footer total.
- Si la moneda del item es distinta a la del viaje, se pide tasa de cambio igual que en F3.2 (no la pinto acá para no duplicar — es exactamente el mismo subbloque).
- **No se valida nada.** No hay "está muy alto" o "está fuera de presupuesto". Es información, no juicio.

---

## F2.3 — Detalle de item (con votos)

```
┌─────────────────────────────────┐
│  ←  Cena en Oro          [⋯]    │  ← menú: editar / eliminar
├─────────────────────────────────┤
│                                 │
│  💭 Propuesto                   │
│                                 │
│  Cena en Oro                    │
│  Sáb 13 jun · 20:00             │
│  R. Frei Leandro 20, Lagoa      │
│                                 │
│  ~$220.000 por persona          │  ← costo estimado, si está
│                                 │
│  Notas:                         │
│  3 estrellas Michelin. Reservar │
│  con 3 semanas de anticipación. │
│                                 │
│  Por: María                     │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Tu voto                        │
│                                 │
│      [ 👍 Sí ]    [ 👎 No ]     │  ← uno se ilumina cuando votas
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Votos del grupo                │
│                                 │
│  👍 Sí (5)                      │
│   • María 🍴Vegetariano 💰Medio │  ← visibilidad pasiva (D1)
│   • Andrés 💰Amplio             │
│   • Laura 🍴Vegetariana 💰Medio │
│   • Juan 💰Amplio               │
│   • Tú 💰Medio                  │
│                                 │
│  👎 No (1)                      │
│   • Pedro 💰Ajustado            │
│                                 │
│  Sin votar (1)                  │
│   • Camila                      │
│                                 │
│  ─────────────────────────────  │
│                                 │
│      [ ✓ Marcar confirmado ]    │  ← cualquiera puede tocarlo
│                                 │
│      [ 💰 Registrar gasto ]     │  ← abre F3.2 prellenado, ver nota abajo
│                                 │
└─────────────────────────────────┘
```

**Esta es la pantalla más cargada del MVP y vale defenderla:**

- **Tags visibles al lado del nombre del votante.** Si Laura es vegetariana y vota sí a Aprazível (asado argentino), el grupo lo ve sin tener que pelear. Operacionaliza el principio 3.1 (prevenir conflictos).
- **"Sin votar" es explícito.** El silencio en grupos suele significar "no leí" o "me da igual", y eso es información. Verlo escrito empuja a votar o explicar.
- **El botón de confirmar es plano y visible para todos** (cambio que tomamos en la conversación previa).
- **Cuando alguien lo confirma, los demás pueden revertirlo.** En el estado "confirmado" el botón cambia a `[ ↩ Volver a propuesto ]`. Sin diálogo de confirmación — si fue por error es trivial deshacer, si fue intencional el grupo lo hablará.

**Botón "Registrar gasto" desde el item:**

Al tocarlo se abre F3.2 con prellenado:
- **Descripción** = título del item ("Cena en Oro")
- **Día del gasto** = día del item (sáb 13 jun)
- **Foto del recibo, monto, moneda, quién pagó, divide entre, tipo de división** = vacíos / defaults

Después de guardar el gasto, el usuario **vuelve a la pantalla anterior que inició la creación**: si vino desde F2.3 (detalle del item), regresa a F2.3; si vino desde F3.1 (lista de gastos), regresa a F3.1.

Esto refleja que crear un gasto es una acción puntual dentro de un flujo más grande — no debe romper el contexto donde estaba el usuario.

**Pregunta abierta que dejo marcada:** cuando un item se confirma, ¿se notifica al grupo? En MVP, no (no hay push según trade-off del scope §6). Esto significa que el grupo se entera la próxima vez que abra la app. Asumido.

---

# FLUJO 3 — Gastos compartidos

## F3.1 — Lista de gastos + saldos (vista principal de gastos)

```
┌─────────────────────────────────┐
│  Brasil con los del barrio      │
│  Itinerario [Gastos] Gente  ⚙   │
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐  │
│  │ Tus saldos                │  │  ← card destacada arriba
│  │                           │  │
│  │ Te deben: $340.000 COP    │  │
│  │ Debes: $0                 │  │
│  │                           │  │
│  │ [ Ver detalle de saldos ] │  │  ← › F3.4
│  └───────────────────────────┘  │
│                                 │
│  ── Sáb 13 jun ──────────────   │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Cena en Oro               │  │
│  │ R$ 1.200 (≈ $1.020.000)   │  │
│  │ Pagó: Andrés              │  │
│  │ Divide entre: todos       │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Uber al aeropuerto        │  │
│  │ R$ 80 (≈ $68.000)         │  │
│  │ Pagó: Laura               │  │
│  │ Divide entre: 4           │  │
│  └───────────────────────────┘  │
│                                 │
│  ── Vie 12 jun ──────────────   │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Vuelo BOG-GIG             │  │
│  │ $2.800.000 COP            │  │
│  │ Pagó: Andrés              │  │
│  │ Divide entre: todos       │  │
│  └───────────────────────────┘  │
│                                 │
│         [+ Agregar gasto]       │  ← FAB
│                                 │
└─────────────────────────────────┘
```

**Decisiones de diseño aquí:**

- **Saldo del usuario en card destacada arriba.** Es la pregunta #1 que el usuario tiene cuando entra a esta pestaña: "¿cómo voy?". Ponerlo abajo es entierro.
- **Lista agrupada por día**, en orden cronológico inverso (más reciente arriba). Refleja cómo la gente recuerda gastos: "lo de ayer, lo de antier".
- **Conversión visible al lado del monto** cuando la moneda del gasto es distinta a la del viaje. Sin esto, la gente pierde el contexto de "ah, esto fue caro".
- **Tap en una card de gasto abre el detalle (F3.5), no edición directa.** Esto cambió respecto a la versión anterior: el detalle es necesario porque ahí vive el historial de cambios.
- **Sin filtros visibles en MVP.** El scope dice filtros básicos por persona/día — los pongo detrás de un icono `[🔍]` arriba si llegamos. Para Caso 0 con 2 semanas de viaje y ~30 gastos, scroll basta. Si el feedback dice que se siente la falta, entra a v1.1.

**Estado vacío:**

```
         No hay gastos aún.

   Cualquiera registra el primero.
   Los saldos se calculan solos
   a medida que se van sumando.

         [+ Agregar primer gasto]
```

---

## F3.2 — Crear / editar gasto

```
┌─────────────────────────────────┐
│  ←  Editar gasto      [Guardar] │  ← título cambia: "Nuevo gasto" o "Editar gasto"
├─────────────────────────────────┤
│                                 │
│  ⓘ Estás editando un gasto      │  ← solo aparece editando ajeno
│  registrado por María. Quedará  │
│  en el historial.               │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Monto                          │
│  ┌────────────┐ ┌─────────────┐ │
│  │  1200      │ │ BRL      ▼  │ │  ← moneda override (D3 / C1.5)
│  └────────────┘ └─────────────┘ │
│                                 │
│  ⚠ El viaje está en COP.        │  ← solo aparece si moneda ≠ moneda del viaje
│  Tasa de cambio: 1 BRL =        │
│  ┌────────────────────┐         │
│  │ 850                │ COP     │  ← input manual de tasa
│  └────────────────────┘         │
│                                 │
│  ≈ $1.020.000 COP               │  ← preview del monto convertido
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Descripción (opcional)         │
│  ┌───────────────────────────┐  │
│  │ Cena en Oro               │  │
│  └───────────────────────────┘  │
│                                 │
│  Foto del recibo (opcional)     │
│  [📷 Subir]                     │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Pagó                           │
│  ┌───────────────────────────┐  │
│  │ Andrés (yo)            ▼  │  │
│  └───────────────────────────┘  │
│                                 │
│  Divide entre                   │
│  ┌───────────────────────────┐  │
│  │ Todos (7)              ▼  │  │  ← tap › abre F3.3 (selector)
│  └───────────────────────────┘  │
│                                 │
│  Tipo de división               │
│  [ Partes iguales ] [ % ] [ $ ] │  ← segmented control
│                                 │
└─────────────────────────────────┘
```

**Decisiones aquí:**

- **Moneda al lado del monto, no en sección aparte.** Es atributo del monto, no campo separado.
- **La tasa de cambio aparece solo cuando es necesaria.** Si la moneda del gasto = moneda del viaje, no se ve. Reduce ruido en el caso común.
- **Preview del monto convertido en vivo** mientras se escribe la tasa. Sin esto, el usuario está adivinando si metió bien la tasa.
- **"Pagó" default = usuario actual** (al crear). Al editar, "Pagó" muestra el valor actual, editable.
- **Tipo de división por defecto = partes iguales.** Cuando se cambia a % o $, abajo aparecen los inputs por persona.
- **Microcopy de edición ajena** aparece solo cuando el usuario actual no es el creador del gasto. Sin asustar (ⓘ informativo, no ⚠ warning), pero claro.
- **Si el guardado no cambia ningún campo respecto al estado actual, no se registra entrada en el historial.** Evita ruido si alguien abre "Editar" por curiosidad y guarda sin tocar nada.

**Lo que dejo fuera y por qué:**

- Sin categorías de gasto. Trade-off explícito del scope §3.
- Sin "deuda saldada" en este formulario. Eso vive en F3.4.
- Sin gastos recurrentes. Idem.

---

## F3.3 — Selector de "divide entre"

```
┌─────────────────────────────────┐
│  ←  Divide entre        [Listo] │
├─────────────────────────────────┤
│                                 │
│  [✓ Seleccionar todos]          │  ← shortcut útil cuando empezó deseleccionado
│                                 │
│  ┌───────────────────────────┐  │
│  │ ☑  Andrés                 │  │
│  │ ☑  Laura                  │  │
│  │ ☑  Juan                   │  │
│  │ ☑  María                  │  │
│  │ ☐  Pedro                  │  │  ← Pedro no estuvo en esta cena
│  │ ☑  Camila                 │  │
│  │ ☑  Tú                     │  │
│  └───────────────────────────┘  │
│                                 │
│  6 de 7 seleccionados           │
│                                 │
└─────────────────────────────────┘
```

Pantalla simple. Lo único que vale la pena defender: **el default es todos seleccionados**, no vacío. Caso más común en viajes es "esto fue de todos". Forzar a marcar uno por uno cada vez es fricción.

---

## F3.4 — Detalle de saldos (transferencias mínimas)

```
┌─────────────────────────────────┐
│  ←  Saldos del viaje            │
├─────────────────────────────────┤
│                                 │
│  Para que todos queden a mano,  │
│  estas son las transferencias   │
│  más simples:                   │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Pedro → Andrés            │  │
│  │ $340.000 COP              │  │
│  │                           │  │
│  │ [ Marcar como pagado ]    │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Camila → Andrés           │  │
│  │ $180.000 COP              │  │
│  │                           │  │
│  │ [ Marcar como pagado ]    │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Juan → Laura              │  │
│  │ $90.000 COP               │  │
│  │                           │  │
│  │ [ Marcar como pagado ]    │  │
│  └───────────────────────────┘  │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Pagados (1)              [▼]   │  ← collapsible
│                                 │
└─────────────────────────────────┘
```

**Esta pantalla es la que defiende D6 (cálculo en tiempo real, sin "hora de la verdad").**

- **Lista directa de transferencias mínimas**, calculadas con algoritmo de simplificación. Si A le debe a B, B le debe a C y A le debe a C, la app sugiere solo "A → C" cuando el monto cuadra.
- **"Marcar como pagado"** mueve la transferencia a la sección colapsable de abajo. No borra el gasto original — el gasto se mantiene en la lista, lo que cambia es el saldo.
- **Sin cierre de cuentas final.** El usuario puede entrar a esta pantalla en cualquier momento del viaje. Si alguien quiere pagar a mitad de viaje, lo hace.

**Lo que falta y queda como pregunta abierta:** ¿qué pasa si dos personas marcan "pagado" la misma transferencia (dos personas usando la app a la vez)? En MVP asumo last-write-wins sin manejo de conflictos. Es el riesgo del trade-off de "sin sincronización offline real" del scope §6. Si pasa en el viaje a Brasil, es feedback.

---

## F3.5 — Detalle del gasto

Pantalla nueva. Es la que se abre al tocar una card de gasto en F3.1. Muestra el estado actual del gasto + el historial de cambios. Desde aquí se accede a edición (F3.2).

```
┌─────────────────────────────────┐
│  ←  Cena en Oro          [⋯]    │  ← menú: editar / borrar (borrar solo creador)
├─────────────────────────────────┤
│                                 │
│  R$ 1.500                       │  ← monto actual destacado
│  ≈ $1.275.000 COP               │
│                                 │
│  Pagó: María                    │
│  Divide entre: todos (7)        │
│  Partes iguales                 │
│                                 │
│  Sáb 13 jun                     │
│                                 │
│  Foto del recibo:               │
│  [imagen miniatura]             │  ← tap › abre full screen
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Registrado por Andrés          │
│  15 jun · 21:00                 │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Historial (2 ediciones)        │
│                                 │
│  ┌───────────────────────────┐  │
│  │ María · 15 jun 22:30  [▼] │  │  ← más reciente arriba
│  │ 3 cambios                 │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Juan · 15 jun 22:15   [▼] │  │
│  │ 1 cambio                  │  │
│  └───────────────────────────┘  │
│                                 │
│  ─────────────────────────────  │
│                                 │
│         [ Editar gasto ]        │  ← cualquier miembro
│                                 │
└─────────────────────────────────┘
```

**Una entrada del historial expandida:**

```
┌───────────────────────────┐
│ María · 15 jun 22:30  [▲] │
│ 3 cambios                 │
│                           │
│ Antes:                    │
│ • Monto: R$ 1.200         │
│ • Descripción: "Cena"     │
│ • Pagó: Andrés            │
│                           │
└───────────────────────────┘
```

**Decisiones de diseño aquí:**

- **El historial guarda solo los valores anteriores, no los nuevos.** El estado actual del gasto vive arriba en la misma pantalla — es el "valor nuevo" implícito de la última edición. Cero redundancia.
- **Orden cronológico inverso.** Más reciente arriba. Si entras al detalle ves primero el último cambio.
- **Solo se registra entrada en el historial si hubo cambios reales.** Si alguien abre "Editar" y guarda sin tocar nada, el historial no crece.
- **"Divide entre" se muestra como cantidad, no como lista de nombres.** Si el gasto se dividía entre 7 y ahora entre 5, el historial dice "Divide entre: 7 personas" como valor anterior. Ver lista exacta requiere recordar el viaje, asumimos que es caso raro.
- **Foto del recibo en el historial: si fue cambiada, aparece "Foto del recibo: (foto anterior)" con miniatura tappable.** Si fue agregada o eliminada, lo dice ("Foto del recibo: (sin foto)" o "(foto eliminada)").
- **Borrado del gasto** sigue siendo solo del creador, accesible desde el menú `[⋯]`. La regla no cambió: editar se abre a todos, borrar no.

**Pregunta abierta marcada:** si un gasto se borra, ¿qué pasa con su historial? En MVP el borrado es destructivo — se va el gasto y se va el historial con él. Si alguien recordara haber editado el gasto borrado, no queda evidencia. Es asumido y consistente con que solo el creador puede borrar (control de daños mínimo).

---

# FLUJO 4 — Soporte (no es flujo core, pero hay 2 pantallas que faltan)

## F4.1 — Miembros del viaje

```
┌─────────────────────────────────┐
│  Brasil con los del barrio      │
│  Itinerario  Gastos [Gente]  ⚙  │
├─────────────────────────────────┤
│                                 │
│  7 personas                     │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 👤 Andrés (facilitador)   │  │
│  │   🍴Como de todo          │  │
│  │   🚶Camino mucho          │  │
│  │   💰Medio                 │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 👤 Laura                  │  │
│  │   🍴Vegetariana           │  │
│  │   🚶Camino mucho · 🌙Noctur│  │
│  │   💰Medio                 │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 👤 Pedro                  │  │
│  │   🍴Celíaco               │  │
│  │   💰Ajustado              │  │
│  └───────────────────────────┘  │
│                                 │
│  ...                            │
│                                 │
│         [+ Invitar más]         │  ← solo visible para facilitador
│                                 │
└─────────────────────────────────┘
```

**Decisión:** los tags se ven aquí también, no solo cuando alguien vota. Esto es un punto de consulta consciente: "antes de proponer un restaurante, miro a ver si alguien es celíaco". Operacionaliza activamente la prevención de conflictos.

---

## F4.2 — Ajustes del viaje

```
┌─────────────────────────────────┐
│  Brasil con los del barrio      │
│  Itinerario  Gastos  Gente [⚙]  │
├─────────────────────────────────┤
│                                 │
│  DEL VIAJE                      │
│                                 │
│  Nombre                         │
│  Brasil con los del barrio   ›  │
│                                 │
│  Fechas                         │
│  12-22 jun 2026              ›  │
│                                 │
│  Moneda principal               │
│  COP (no se puede cambiar)      │
│                                 │
│  Link de invitación             │
│  vamos.app/j/x7k2m9          ›  │  ← solo facilitador
│                                 │
│  ─────────────────────────────  │
│                                 │
│  TUS PREFERENCIAS               │
│                                 │
│  Editar tus tags             ›  │  ← cualquier miembro edita las propias
│                                 │
│  Salir del viaje             ›  │  ← cualquiera, con confirmación
│                                 │
│  ─────────────────────────────  │
│                                 │
│  ZONA PELIGROSA                 │
│                                 │
│  Archivar viaje              ›  │  ← solo facilitador, modal de confirmación
│                                 │
└─────────────────────────────────┘
```

Pantalla minimalista. Las decisiones que importan ya están en el modelo de roles del PRD (4.4): nadie saca a nadie unilateralmente, solo el facilitador archiva, transferir facilitador queda fuera del MVP.

---

# Resumen: pantallas totales del MVP

| Flujo | Pantallas | Notas |
|---|---|---|
| Auth | 1 (estándar) | No diseñado, Firebase out-of-the-box |
| Mis viajes | 1 (F1.1) | Home con foto de portada y estado por fechas |
| Crear viaje | 2 (F1.2, F1.3) | Form + éxito-con-link |
| Onboarding usuario nuevo | 1 (F1.4) | Nombre real del perfil, una sola vez |
| Onboarding invitado al viaje | 2 (F1.4b, F1.5) | Alias del viaje + tags |
| Itinerario | 3 (F2.1, F2.2, F2.3) | Lista + form + detalle |
| Gastos | 5 (F3.1, F3.2, F3.3, F3.4, F3.5) | Lista + form + selector + saldos + detalle con historial |
| Soporte | 2 (F4.1, F4.2) | Gente + ajustes |
| **Total** | **17 pantallas** | |

Diecisiete pantallas. F3.5 entró al sumar el detalle del gasto con historial de cambios (audit nivel B). Sigue siendo manejable.

Si en el siguiente paso (modelo de datos en Firestore) algo apunta a que sobra o falta una pantalla, la ajustamos antes de empezar a codear.

---

# Cosas que me quedaron rondando y vale revisar

Estas no son decisiones, son observaciones que pueden afectar v1.1:

1. **Edición de gastos con settlements ya marcados.** Si un gasto ya tiene transferencias marcadas como pagadas (en F3.4) y alguien edita el monto, los saldos calculados rompen su correspondencia con lo que ya se pagó. En MVP el botón "Editar gasto" en F3.5 queda deshabilitado para gastos que tengan al menos un settlement asociado, con microcopy "No se puede editar: ya hay pagos marcados como saldados. Deshaz los pagos en Saldos para volver a editar." Esto vale para todos los miembros, incluido el creador.

2. **Tags pasivamente visibles vs. notificación activa.** En F2.3 mostramos que Laura vegetariana votó sí a Aprazível, pero nadie la frena. ¿Vale la pena un microcopy tipo "ojo: Laura es vegetariana" cuando alguien va a confirmar un restaurante de carne? Iría más allá de visibilidad pasiva (D1) hacia visibilidad activa. Decisión consciente de no hacerlo en MVP, pero vale tenerlo en lista.

3. **Estado del viaje en MVP es Nivel 1 (etiqueta + ordenamiento).** No cambia comportamiento de la app. Si en el Caso 0 el grupo siente que durante el viaje se confunde entrando a Itinerario cuando lo que necesita es Gastos, considerar Nivel 2 (tab default según estado) en v1.1.

4. **Foto del viaje y foto del perfil son globales — no hay foto por alias.** Si en el Caso 0 alguien dice "yo en este grupo soy el pollo y quería poner cara de pollo", se considera para v1.1. Por ahora la foto del perfil aplica a todos los viajes.

5. **Alerta automática de presupuesto vs tags.** F2.3 muestra el costo estimado y los tags de cada votante (incluido si alguien marcó "ajustado"), pero no hay microcopy activo tipo "ojo: 2 personas marcaron presupuesto ajustado y este item es de $X". Decisión consciente para MVP — agregaría una capa de juicio sobre los tags que rompería el patrón de visibilidad pasiva. Si en el Caso 0 hay un caso de "Pedro pagó algo que no podía", entra a v1.1.

6. **Costo estimado se infla en items que compiten.** Si hay 3 restaurantes propuestos para la cena del sábado, los 3 con costo estimado, el footer suma los 3 aunque solo se va a hacer uno. Es honesto pero confunde. Mitigaciones posibles para v1.1: (a) agrupar items por slot temporal, (b) marcar items que compiten entre sí explícitamente, (c) mostrar rango "entre $X y $Y" en lugar de suma. Ninguna entra al MVP — todas reabren la pregunta de "items vs slots" que ya cerramos en D5.
