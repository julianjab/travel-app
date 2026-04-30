# PRD Inicial — App de Viajes Compartidos

> Documento de requisitos del producto en su versión inicial. Vivo, se irá refinando. Última actualización: abril 2026.

---

## 1. Visión

Una app que convierte la planeación de viajes en grupo de un trabajo emocional desgastante en una experiencia que **acerca al grupo en lugar de alejarlo**. Diseñada desde el inicio para grupos latinoamericanos: en español, multi-moneda, con WhatsApp como capa de comunicación, y conectada a métodos de pago locales.

## 2. Misión a 12 meses

- **Mes 1-3:** MVP funcional para uso personal y de círculo cercano (5-10 grupos)
- **Mes 4-6:** Pulido + primeros 100 usuarios externos vía invitación
- **Mes 7-12:** Lanzamiento abierto en Colombia, evaluación de expansión a México

## 3. Principios de producto

Estas son las reglas que ganan cuando hay decisiones difíciles:

### 3.1 Prevenir conflictos > organizar tareas
La app no compite con Wanderlog en quién organiza mejor. Compite en quién evita más peleas de grupo. Cada feature se evalúa contra la pregunta: "¿esto previene un conflicto que hoy ocurre?"

### 3.2 Distribuir trabajo, no concentrarlo
Cada vez que detectemos que una persona está cargando todo, la app debe redistribuir. El "mártir del viaje" es el enemigo del producto.

### 3.3 LATAM-first, no LATAM-translated
No es una app gringa con español pegado. Las decisiones de UX, monedas, métodos de pago, integraciones nacen pensando en Bogotá, CDMX, Buenos Aires.

### 3.4 WhatsApp es aliado, no competencia
Reemplazar WhatsApp es perder. Integrarse con WhatsApp es ganar. Bot que sincroniza, links que enriquecen, notificaciones que llegan ahí donde la gente ya vive.

### 3.5 Funciona offline o no funciona
Si una feature core requiere conexión permanente, está mal diseñada. Itinerario, documentos y gastos deben servir sin señal.

### 3.6 Lo simple gana
Cada feature nueva se evalúa contra "¿esto hace la app más usable o más completa?". Si solo es "más completa", se rechaza.

---

## 4. Usuarios objetivo

### 4.1 Persona primaria — "El organizador agotado"
**Andrés, 32 años, Medellín.** Ingeniero o profesional. Viaja 3-4 veces al año, casi siempre en grupos de 4-8 personas. Es el que termina haciendo todo: spreadsheet en Drive, grupo de WhatsApp, calculadora en mano para dividir gastos. Frustrado de ser el mártir, pero no confía si no lo hace él. Quiere herramientas que le quiten carga sin perder control.

### 4.2 Persona secundaria — "La participante involucrada"
**Laura, 28 años, Bogotá.** Diseñadora. Va a los viajes que organizan otros pero quiere opinar más sin ser invasiva. Tiene preferencias claras (presupuesto medio, vegetariana, le gusta caminar) pero no las dice por no friccionar. Quiere votar, opinar y aportar sin tener que organizar.

### 4.3 Persona terciaria — "El pasivo que se deja llevar"
**Juan, 35 años, Cali.** Va al viaje porque sus amigos van. No le gusta planear, no quiere apps complicadas. Solo quiere saber cuánto debe pagar, dónde estar y a qué hora. Si la app le pide más de 30 segundos, no la abre.

**Implicación de diseño:** la app debe servir a los tres niveles de involucramiento — organizador activo, participante opinante, y pasivo total — sin pedirle a Juan lo que le pediría a Andrés.

### 4.4 Modelo de roles dentro del grupo

La app opera con un modelo plano con un **facilitador**, no con un admin. Esto refleja cómo funcionan realmente los grupos de viaje en LATAM (siempre hay alguien que arranca y cierra) sin concentrar poder ni contradecir el principio 3.2.

**Facilitador (quien crea el viaje):**
- Puede invitar nuevos miembros
- Puede archivar el viaje al cerrarlo
- Puede transferir el rol de facilitador a otra persona del grupo

**Todos los miembros (incluido el facilitador):**
- Crean, editan y comentan en el itinerario
- Sugieren y votan opciones
- Registran y editan gastos propios
- Suben documentos al vault
- Salen del viaje cuando quieren

**Lo que nadie puede hacer unilateralmente:**
- Sacar a otro miembro del grupo (requiere votación)
- Borrar gastos ajenos
- Cancelar/eliminar el viaje completo (solo archivar al final)

El facilitador es un rol funcional mínimo, no una jerarquía. Si más adelante el research muestra que los grupos quieren responsabilidades repartidas por área (hospedaje, transporte, gastos), se evalúa evolucionar a un modelo de roles rotativos.

### 4.5 Datos del viajero (nivel usuario)

La app distingue entre **datos del viajero** (atributos que viven en el perfil del usuario) y **documentos del viaje** (archivos específicos de un viaje, ver caso de uso 5).

**Qué son los datos del viajero:**
Información que el usuario carga una vez en su perfil y queda disponible para todos sus viajes. El objetivo es que cualquier miembro del grupo pueda gestionar compras (vuelos, hoteles, tours) sin tener que pedir datos por WhatsApp. Operacionaliza el principio 3.2 directamente: el que compra no le pide al resto, lo consulta en la app.

**Campos contemplados:**
- Nombre completo como aparece en documento de viaje
- Tipo y número de documento (cédula, pasaporte)
- Fecha de vencimiento del pasaporte
- Nacionalidad
- Fecha de nacimiento
- Número de viajero frecuente (opcional)
- Preferencias de asiento y comida (opcional)
- Restricciones alimentarias y alergias (opcional)

**Reglas:**
- Todos los campos son **opt-in**. El usuario decide qué carga y qué no.
- Los datos son visibles solo para miembros de viajes en los que el usuario participa activamente.
- Cuando el usuario sale de un viaje, los demás miembros pierden acceso a sus datos.
- Los datos viven en el perfil del usuario, no se duplican por viaje.

**Trade-off asumido:** guardar números de documento sigue siendo data sensible. La mitigación es transparencia (opt-in informado) y reglas estrictas de Firebase. Si el usuario prefiere no cargarlos, la app sigue funcionando — solo pierde el beneficio de evitar la fricción de pedir datos por fuera.

---

## 5. Casos de uso prioritarios

En orden de importancia para el MVP:

1. **Crear un viaje y sumar al grupo** — onboarding de cada persona con sus preferencias en menos de 2 minutos
2. **Coordinar fechas posibles** — poll de disponibilidad antes de comprar nada
3. **Construir itinerario colaborativo** — todos pueden sugerir, votación ligera para decidir
4. **Registrar y dividir gastos** durante el viaje — multi-moneda, integración con métodos LATAM
5. **Vault de documentos del viaje** — reservas, tickets, seguros y visas específicas de ese viaje en un solo lugar (offline). No incluye datos personales del viajero (esos viven en el perfil de usuario, ver 4.5). Los documentos se borran automáticamente 2 meses después de archivado el viaje, configurable por el facilitador entre 1 y 12 meses.
6. **Modo crisis** — cuando algo se cae, reorganización asistida + notificación grupal

---

## 6. Lo que NO va al MVP

Para evitar la trampa del "todo para todos":

- ❌ Booking directo de vuelos/hoteles (afiliación viene después)
- ❌ AI que recomienda destinos (el grupo ya sabe a dónde va)
- ❌ Red social de viajeros / feed público
- ❌ Marketplace de tour operadores
- ❌ Versión web completa (mobile first, web solo para vista de respaldo)
- ❌ Soporte multi-idioma fuera de español (portugués viene en v2)
- ❌ Integraciones complejas con calendarios corporativos

---

## 7. Métricas de éxito

### MVP (primeros 3 meses)
- 5 grupos reales completaron un viaje usando la app de inicio a fin
- NPS interno ≥ 8 entre los participantes
- ≥ 70% de los participantes registraron al menos un gasto durante el viaje (no solo el organizador)

### Validación de tracción (mes 6)
- 100 usuarios activos
- ≥ 30% de viajes completados (no abandonados)
- Tiempo promedio de planeación reducido vs. método anterior del usuario

### Distribución (mes 12)
- 1,000 usuarios activos en Colombia
- ≥ 40% de retención mes 3 (usuarios que vuelven a crear un segundo viaje)
- Modelo de monetización validado (al menos un canal probado)

---

## 8. Decisiones pendientes

Cosas que hay que resolver pronto pero no urgente para empezar:

- [x] Stack técnico → Flutter (iOS + Android con un solo codebase)
- [x] Backend → Firebase (auth, Firestore, Storage para documentos, Cloud Functions, FCM para notificaciones)
- [x] Modelo de monetización del MVP → gratis sin restricciones durante el MVP. La decisión de modelo de monetización de largo plazo (freemium, comisión sobre bookings, híbrido) se reabre en mes 6 con datos reales de uso. No hay métrica de revenue en el MVP.
- [x] Estrategia de adquisición de los primeros 5 grupos → enfoque en fases. **Caso 0** (mes 1-2): grupo propio, único objetivo es validar que el flujo end-to-end no se rompe en un viaje real. **Casos 1-5** (mes 2-4, solo si caso 0 sale bien): combinación de círculos de segundo grado (1-2 grupos vía amigos del grupo 0 invitando sus otros grupos de viaje) + comunidades LATAM de viajeros (2-3 grupos vía grupos de Facebook, subreddits, Telegram). Reclutamiento por red profesional queda como backup. No invitar grupos externos hasta cerrar caso 0 con resultado positivo.
- [ ] Naming del producto y dominio
- [ ] Branding visual (paleta, tono, identidad)
- [x] Política de privacidad y datos → Nivel A (Firebase estándar) con reglas estrictas, separación entre datos del viajero (4.5) y documentos del viaje (caso 5), opt-in por campo, retención de documentos configurable (default 2 meses post-archivo)
- [x] Modelo de roles dentro del grupo → resuelto en sección 4.4 (facilitador, no admin)
