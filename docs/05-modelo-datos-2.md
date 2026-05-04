# Modelo de datos — App de Viajes Compartidos

> Modelo de datos para el MVP (Caso 0). Define colecciones de Firestore, campos por documento, reglas de seguridad e índices necesarios. Última actualización: abril 2026.

---

## 1. Contexto

Este documento traduce el scope del MVP (`03-mvp-scope.md`) y los wireframes (`04-wireframes-mvp.md`) a un modelo de datos concreto en Firestore. No es decisión de arquitectura — eso ya está cerrado en el PRD (`02-prd-inicial.md` §8): Flutter + Firebase.

El alcance del modelo cubre los 3 flujos del MVP: crear viaje + invitar, itinerario colaborativo con votación, y gastos compartidos. No cubre lo que está deliberadamente fuera del MVP (vault de documentos, modo crisis, datos del viajero a nivel perfil, etc.).

---

## 2. Modelo final

### 2.1 Mapa de colecciones

```
users/{userId}                          ← perfil global del usuario
trips/{tripId}                          ← viaje
  members/{userId}                      ← miembro del viaje (alias, tags, rol)
  items/{itemId}                        ← item del itinerario (con votos como map)
  expenses/{expenseId}                  ← gasto
  settlements/{settlementId}            ← transferencias marcadas como pagadas
invites/{inviteCode}                    ← link público de invitación
```

### 2.2 Esquema por documento

#### `users/{userId}`

```
displayName: string              ← nombre real (futuro: pasaporte, cédula)
alias: string                    ← cómo le dicen, default del alias por viaje
photoURL: string?
authProvider: string             ← "google" | "apple"
createdAt: timestamp
```

Deliberadamente flaco. Datos del viajero (cédula, pasaporte, viajero frecuente) van en v1.1+ según PRD §4.5.

#### `trips/{tripId}`

```
name: string                     ← "Brasil con los del barrio"
destination: string              ← texto libre, sin geocoding en MVP
startDate: timestamp
endDate: timestamp
mainCurrency: string             ← ISO 4217: "COP", "BRL", "USD"
coverPhotoURL: string?
facilitatorId: string            ← userId del facilitador actual
memberIds: array<string>         ← denormalizado, ver §3.1
memberAliases: map<string,string> ← lookup uid → alias para UI sin lecturas extra (X-11)
status: string                   ← "active" | "archived"
createdAt: timestamp
createdBy: string
```

#### `trips/{tripId}/members/{userId}`

```
alias: string                    ← alias específico de este viaje (puede diferir del alias global)
tags: {
  diet: array<string>            ← ["vegetariano", "celiaco"] o ["alergia:mani"]
  pace: array<string>            ← ["camina_mucho", "nocturno"]
  budget: string                 ← "ajustado" | "medio" | "amplio"
}
joinedAt: timestamp
```

El `userId` es el ID del documento, no un campo. `displayName` y `photoURL` no se duplican — viven en `users/{userId}` y la app hace lookup.

**Sobre `memberAliases` en el doc del trip (X-11):**

Se denormaliza un `Map<userId, alias>` en `trips/{tripId}.memberAliases` para que la UI pueda renderizar nombres (TripCard, expense_form, balances) sin pagar N lecturas extra a la subcolección `members/`.

- El `alias` autoritativo sigue viviendo en `trips/{tripId}/members/{userId}.alias`.
- `memberAliases` es una **proyección de solo nombre** mantenida atómicamente junto con `memberIds`: cuando un usuario entra (o el facilitador crea el viaje), se escribe en la misma transacción `arrayUnion(memberIds, uid)` + `memberAliases.{uid} = alias` + el doc en `members/`.
- Invariante: `memberAliases.size() == memberIds.size()` y cada uid en `memberIds` aparece como key.
- Las reglas permiten a cada usuario escribir SOLO su propia entrada en `memberAliases` (no la de otros).
- No se usa un array de `[{id, name}]` porque `array-contains` solo matchea valores exactos: la query `where('members', arrayContains: {id, name})` se rompería al cambiar el alias.
- Editar el alias post-join no está en MVP (queda como mejora futura).

#### `trips/{tripId}/items/{itemId}`

```
title: string
day: timestamp                   ← día asignado (sin hora, hora va aparte)
time: string?                    ← "20:00" o null
location: string?                ← texto libre, sin mapa
notes: string?
authorId: string
status: string                   ← "proposed" | "confirmed"
votes: map<userId, "yes"|"no">
estimatedCostPerPerson: number?  ← costo estimado en moneda original
estimatedCostCurrency: string?   ← ISO 4217. Si null, el item no tiene costo declarado
estimatedCostExchangeRate: number? ← tasa a mainCurrency. 1 si misma moneda. Null si sin costo.
createdAt: timestamp
updatedAt: timestamp
```

Conteos de votos no se guardan, se calculan en cliente desde el map.

**Sobre el costo estimado:**

- Es un dato **opcional** del item. Si no se declara, los tres campos quedan `null`.
- Es **por persona**, no total. La división entre miembros se calcula en cliente al sumar para el footer de F2.1 (multiplicar por la cantidad actual de miembros del viaje).
- Acepta moneda distinta a la del viaje (mismo patrón que `expenses`). La tasa se mete manual al crear el item, igual que en gastos.
- **No hay flag de "este costo ya se materializó como gasto"** — un item puede tener costo estimado y además tener un gasto asociado (el que se crea desde F2.3 con el botón "Registrar gasto"). Son cosas distintas: el estimado es proyección, el gasto es realidad. No vale la pena unirlos.

#### `trips/{tripId}/expenses/{expenseId}`

```
amount: number                   ← monto en moneda original
currency: string                 ← "BRL"
exchangeRate: number             ← 1 si currency = mainCurrency
amountInMainCurrency: number     ← denormalizado, calculado al guardar
description: string?
photoURL: string?
paidBy: string
splitBetween: array<string>
splitType: string                ← "equal" | "percentage" | "amount"
splitDetails: map?               ← solo si splitType ≠ "equal"
date: timestamp                  ← día del gasto (puede ≠ createdAt)
createdAt: timestamp
createdBy: string
hasSettlements: boolean          ← flag para deshabilitar edición
editHistory: array<{
  editedBy: string                 ← userId de quien editó
  editedAt: timestamp
  changes: array<{
    field: string                  ← "amount" | "currency" | "exchangeRate" | "description"
                                   ←   | "photoURL" | "paidBy" | "splitBetween"
                                   ←   | "splitType" | "splitDetails" | "date"
    oldValue: any                  ← valor anterior (el nuevo vive en el doc raíz)
  }>
}>
```

**Notas sobre `editHistory`:**

- Solo se guarda lo que cambió y su valor anterior. El valor actual (post-edición) vive en el documento raíz del gasto. Esto evita duplicación.
- `splitBetween` se guarda como array completo (no diff de "agregaron a Pedro / sacaron a Camila"). En la UI se muestra como cantidad ("7 personas") pero el dato bruto está si en v1.1 queremos mostrar nombres.
- Si una edición no resulta en cambios reales (el usuario abrió el form y guardó sin tocar nada), no se agrega entrada al `editHistory`.

#### `trips/{tripId}/settlements/{settlementId}`

```
fromUserId: string
toUserId: string
amount: number                   ← en mainCurrency del viaje
markedAt: timestamp
markedBy: string                 ← userId de quien marcó (auditoría mínima)
```

#### `invites/{inviteCode}`

```
tripId: string
createdBy: string
createdAt: timestamp
active: boolean                  ← facilitador puede invalidar y regenerar
```

`inviteCode` es un string corto generado tipo `x7k2m9`. La URL `vamos.app/j/x7k2m9` lo resuelve.

---

## 3. Decisiones tomadas y razonamiento

Estas son las decisiones que cuestan caro revertir. Quedan registradas para no reabrirlas a menos que aparezca evidencia nueva.

### 3.1 Miembros como subcolección, no array embebido

**Decisión:** `trips/{tripId}/members/{userId}` como subcolección.

**Alternativa considerada:** array de miembros embebido en el doc del viaje.

**Razón:** dos problemas con el array. (1) Las reglas de seguridad granulares — "un miembro solo edita sus propios tags" — son un dolor con array. Subcolección lo hace trivial: `userId` es el ID del doc. (2) El límite de 1MB del documento se acerca rápido si todo cuelga del trip. Subcolección escala limpio.

**Trade-off asumido:** denormalización de `memberIds` array en el doc del trip. Firestore no permite reglas con join, entonces para escribir "solo los miembros leen este viaje" hay que tener el array de userIds en el doc padre. Cada vez que alguien entra o sale del viaje, se actualiza el array Y se crea/borra el doc en la subcolección. Es duplicación; es el patrón estándar de Firestore.

### 3.2 Items y gastos como subcolecciones, no top-level

**Decisión:** `trips/{tripId}/items/...` y `trips/{tripId}/expenses/...`

**Alternativa considerada:** colecciones top-level con `tripId` como campo.

**Razón:** la query principal es siempre "items/gastos de ESTE viaje". Subcolección hace eso natural. Las reglas de seguridad son una línea — "si eres miembro del viaje padre, lees/escribes". Top-level solo gana si necesitás queries cross-viaje (ej: "todos mis gastos en todos mis viajes"), que no es caso del MVP.

**Cuándo reabrir:** si en v2 aparece un dashboard global "tus gastos en todos los viajes", se evalúa migrar a top-level con índice por `userId`.

### 3.3 Votos como map en el item, no subcolección

**Decisión:** `item.votes = { userId1: "yes", userId2: "no" }`.

**Alternativa considerada:** `items/{itemId}/votes/{userId}` como subcolección.

**Razón:** con grupos de 5-10 personas, el map cabe sobrado y leés el item con sus votos en una sola lectura. Subcolección es más "correcto" pero te obliga a queries adicionales para pintar la lista del itinerario (F2.1) con conteos visibles.

**Trade-off asumido:** si después querés histórico de votos (alguien cambió de voto, cuándo), el map lo hace harder. No es necesidad del MVP.

**Cuándo reabrir:** grupos de 50+ personas, o necesidad de tracking de cambios de voto.

### 3.4 Saldos calculados en cliente

**Decisión:** Flutter computa saldos a partir de `expenses` + `settlements`.

**Alternativas consideradas:** (1) Cloud Function que escribe a `trips/{tripId}/balances` cuando cambia un gasto. (2) Doc denormalizado actualizado por transacción desde el cliente.

**Razón:** con un viaje típico (30-50 gastos, 7 personas), computar en cliente es instantáneo. Cloud Functions agregan complejidad de despliegue, latencia eventual, y costo. La regla "el viaje es chico" lo permite.

**Cuándo reabrir:** un viaje con 500+ gastos, o si la app crece a viajes con 50+ personas.

### 3.5 Settlements separados de expenses

**Decisión:** `settlements` como subcolección independiente.

**Razón:** son entidades distintas. Un gasto es "qué pasó", un settlement es "alguien le pagó a alguien fuera de la app para saldar". Mezclarlos en una sola colección `transactions` con un `type` discriminador parecía elegante pero ensucia las reglas y los cálculos.

### 3.6 Cualquier miembro puede editar gastos con audit trail completo

**Decisión:** `expenses.update` permitido para **cualquier miembro del viaje**, no solo el creador. Cada edición queda registrada en `editHistory` con diff completo (campo, valor anterior). Excepción: si el gasto tiene `hasSettlements = true`, nadie puede editar (ni siquiera el creador).

**Alternativas consideradas:**
- Solo el creador edita (más restrictivo).
- Solo creador + facilitador edita (intermedio, lo que estaba antes).

**Razón:** la edición abierta es coherente con el resto de la app — cualquiera registra gastos, confirma items, marca pagos. Que solo el creador pudiera editar era una excepción extraña que concentraba trabajo (contradice principio 3.2 del PRD). El audit trail con diff completo (Nivel B) habilita esto sin perder transparencia: cada cambio queda visible en el detalle del gasto (F3.5) con quién, cuándo y qué cambió.

**Trade-off asumido:** cualquiera puede meterle mano a un gasto ajeno. Mitigaciones:
- Audit trail visible para todo el grupo (no escondido en logs).
- Microcopy explícito al editar gasto ajeno ("Estás editando un gasto de María. Quedará en el historial.").
- Borrar sigue siendo solo del creador — editar es reversible (puedes editar de vuelta), borrar destruye el gasto y su historial.
- Gastos con settlements quedan congelados — proteger los saldos ya pagados es más importante que permitir corrección tardía.

**Cuándo reabrir:** si en el Caso 0 alguien siente que hubo abuso de la edición ajena, considerar volver a "creador + facilitador" en v1.1.

### 3.7 Borrar items: autor o facilitador

**Decisión:** `items.delete` permitido para autor del item Y facilitador.

**Razón:** items abandonados (alguien propuso algo y nunca volvió) pueden ensuciar el itinerario. Que el facilitador pueda limpiar es razonable. Es decisión que el PRD no toca explícito; se asume esta interpretación. Si en el Caso 0 aparece fricción, se reabre.

### 3.8 Sin colección de notificaciones

**Decisión:** no hay colección `notifications` ni similar.

**Razón:** no hay push en MVP (trade-off del scope §6). Si entra push en v1.1, se modela en ese momento.

### 3.9 Color de portada se deriva del nombre, no se guarda

**Decisión:** cuando un viaje no tiene `coverPhotoURL`, el color del placeholder se computa en cliente desde un hash del `name`.

**Razón:** guardar `coverPhotoColor` es estado redundante. Si el name no cambia, el color tampoco. Cliente computa.

---

## 4. Reglas de seguridad

Esqueleto. No es production-ready — falta validación de tipos, límites de tamaño, prevención de spam de invitaciones. Se cierra en `07-firestore-rules.md` cuando se llegue a esa fase.

```
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

match /trips/{tripId} {
  allow read: if request.auth.uid in resource.data.memberIds;
  allow create: if request.auth != null
                && request.auth.uid == request.resource.data.facilitatorId
                && request.auth.uid in request.resource.data.memberIds;
  allow update: if request.auth.uid in resource.data.memberIds;
  // delete: nadie. Solo archivar (status = "archived")

  match /members/{memberId} {
    allow read: if request.auth.uid in get(/databases/$(database)/documents/trips/$(tripId)).data.memberIds;
    allow write: if request.auth.uid == memberId;  // solo edita lo propio
  }

  match /items/{itemId} {
    allow read, create, update: if request.auth.uid in get(...).data.memberIds;
    allow delete: if request.auth.uid == resource.data.authorId
                  || request.auth.uid == get(...).data.facilitatorId;
  }

  match /expenses/{expenseId} {
    allow read, create: if request.auth.uid in get(...).data.memberIds;
    allow update: if request.auth.uid in get(...).data.memberIds
                  && resource.data.hasSettlements == false;
    allow delete: if request.auth.uid == resource.data.createdBy
                  && resource.data.hasSettlements == false;
  }

  match /settlements/{settlementId} {
    allow read, create: if request.auth.uid in get(...).data.memberIds;
    allow delete: if request.auth.uid == resource.data.markedBy;
  }
}

match /invites/{inviteCode} {
  allow read: if true;       // público por diseño
  allow create, update: if request.auth != null;
}
```

**Costo de las lecturas con `get(...)`:** cada verificación con `get()` cuenta como una lectura adicional. Es plata mínima en el Caso 0 pero vale tenerlo presente cuando se evalúe escala.

---

## 5. Índices compuestos requeridos

Firestore crea índices simples auto. Los compuestos hay que declararlos en `firestore.indexes.json`:

- `items` por `(day asc, createdAt asc)` — vista del itinerario agrupada por día
- `expenses` por `(date desc, createdAt desc)` — lista de gastos cronológica inversa
- `trips` por `(memberIds array-contains, status, startDate desc)` — home "Mis viajes" filtrando por activos

Los demás se resuelven con índices simples.

---

## 6. Lo que está deliberadamente fuera

Para que no haya ambigüedad cuando aparezcan dudas:

- **Notificaciones / push** — no hay push en MVP
- **Audit log global** — solo `editHistory` en gastos. Nada más se loggea.
- **Cache de saldos calculados** — cliente calcula en vivo
- **Histórico de cambios de voto** — el map se sobrescribe
- **Datos del viajero (cédula, pasaporte, viajero frecuente)** — van en v1.1+ según PRD §4.5
- **Vault de documentos del viaje** — caso 5 del PRD, fuera del MVP
- **Geocoding / coordenadas de location** — solo texto libre

---

## 7. Backend alternativo evaluado

**Decisión:** Firestore. No se cambia.

Se evaluaron Supabase y PocketBase como alternativas free-tier. El razonamiento de quedarse en Firestore: la decisión está tomada en el PRD §8, y migrar de backend en etapa de validación de producto es trabajo que no agrega valor al Caso 0. La fricción de cambiar (Flutter SDK menos pulido en Supabase, ops propio en PocketBase) supera cualquier ventaja teórica de un Postgres real para un grupo de 7 personas.

**Cuándo reabrir:** si el modelo de datos empieza a doler de verdad en producción (queries cross-viaje frecuentes, joins complejos, migraciones difíciles), se evalúa Supabase con datos reales en mano.

---

## 8. Próximos pasos

Este documento cierra el modelo de datos. Los siguientes pasos son:

1. **Estructura del proyecto Flutter** — carpetas, navegación, state management. (`06-flutter-structure.md`)
2. **Reglas de seguridad completas** — versión production-ready de las del §4. (`07-firestore-rules.md`)
3. **Primer flujo end-to-end** — implementar Flujo 1 (crear viaje + invitar) completo.

Cada uno se aborda como conversación independiente.
