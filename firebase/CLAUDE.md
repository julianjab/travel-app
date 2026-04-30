# Firebase — Reglas, índices y modelo

> Este archivo se aplica a todo lo que está bajo `firebase/`. Asumí que el `CLAUDE.md` raíz ya fue leído.

## Modelo de datos

**Fuente única de verdad:** `docs/05-modelo-datos-2.md`.

Cualquier cambio al modelo (campo nuevo, colección nueva, tipo cambiado) requiere:

1. Actualizar `docs/05-modelo-datos-2.md` §2.2 primero.
2. Actualizar el modelo Dart correspondiente en `app/lib/data/models/`.
3. Si el campo afecta reglas de seguridad, actualizar `firestore.rules`.
4. Si requiere índice nuevo, agregar a `firestore.indexes.json`.

El orden importa: el doc primero. Si el doc no se actualiza, en 3 meses nadie va a recordar por qué un campo está ahí.

## Estructura de la carpeta

```
firebase/
├── CLAUDE.md                ← este archivo
├── firebase.json            ← config del proyecto Firebase
├── .firebaserc              ← alias del proyecto (dev / prod)
├── firestore.rules          ← reglas de seguridad
├── firestore.indexes.json   ← índices compuestos
├── storage.rules            ← reglas de Firebase Storage (fotos de recibos, portadas)
└── functions/               ← VACÍO HASTA v1.1+
```

## Reglas de seguridad

El esqueleto base está en `docs/05-modelo-datos-2.md` §4. **Es esqueleto, no production-ready.** Le falta:

- Validación de tipos (`request.resource.data.amount is number`)
- Límites de tamaño (string máximo de N caracteres)
- Validación de campos requeridos en `create`
- Prevención de spam en `invites` (rate limiting)
- Validación de inmutabilidad de campos (ej: `createdBy` no se puede cambiar después del create)

Cuando se cierre la versión production-ready de las reglas, vive en `firestore.rules` y se documenta en un archivo aparte (`docs/07-firestore-rules.md` está reservado para esto).

### Patrón general de las reglas

- **Solo miembros del viaje leen/escriben sus subcolecciones.** Esto se valida con `request.auth.uid in get(/databases/$(database)/documents/trips/$(tripId)).data.memberIds`.
- **Cada `get(...)` cuenta como una lectura adicional.** Es plata mínima en Caso 0 pero tener presente al evaluar escala.
- **`memberIds` es un array denormalizado en el doc del viaje.** Esto existe porque Firestore no permite reglas con join. Cualquier cambio en miembros tiene que actualizar el array Y la subcolección `members/`.

### Reglas específicas que NO son obvias

- **`expenses.update`:** cualquier miembro del viaje puede editar cualquier gasto, **excepto** si `hasSettlements == true`. Cada edición se registra en `editHistory`. Decisión 3.6 del modelo de datos.
- **`expenses.delete`:** solo el creador, y solo si `hasSettlements == false`. Borrar es destructivo (se va el historial con el gasto).
- **`items.delete`:** autor del item O facilitador del viaje.
- **`trips`:** no hay `delete`. Solo `archive` (cambiar `status` a `"archived"`).
- **`invites`:** lectura pública por diseño (cualquiera con el link puede ver el `tripId`). El `create` es solo para usuarios autenticados.

## Índices

Los índices simples los crea Firestore solo. Los compuestos hay que declararlos en `firestore.indexes.json`. Los del MVP están listados en `docs/05-modelo-datos-2.md` §5:

- `items` por `(day asc, createdAt asc)` — vista del itinerario por día
- `expenses` por `(date desc, createdAt desc)` — lista cronológica inversa
- `trips` por `(memberIds array-contains, status, startDate desc)` — home "Mis viajes"

Si una query nueva requiere índice, Firestore lo dice en runtime con el link directo para crearlo. Cuando aparezca, agregalo al JSON y commiteá; no lo crees solo desde la consola, queda fuera de versión.

## Cloud Functions

**No se usan en MVP.** Decisión cerrada en `docs/05-modelo-datos-2.md` §3.4.

La carpeta `functions/` existe vacía como placeholder para v1.1+. Los casos donde podrían entrar:

- **Notificaciones push** (FCM dispatch al votar / registrar gasto)
- **Limpieza automática** de viajes archivados (borrar documentos del Storage después de N meses)
- **Generación de `inviteCode` único** (si hay colisiones, aunque con 6+ caracteres random la probabilidad es despreciable para Caso 0)

Si te piden agregar una Cloud Function, alertar primero: "Esto implica salir del scope del MVP. ¿Confirmás?"

## Storage (firebase storage)

Para qué se usa:

- **Fotos de portada de viajes** (`coverPhotoURL` en `trips/{tripId}`)
- **Fotos de perfil de usuarios** (`photoURL` en `users/{userId}`)
- **Fotos de recibos de gastos** (`photoURL` en `trips/{tripId}/expenses/{expenseId}`)

### Reglas de Storage

Patrón equivalente a Firestore: solo miembros del viaje leen/escriben fotos de ese viaje. Foto de perfil es lectura pública (la ven en otros viajes), escritura solo del propio usuario.

Las reglas concretas se escriben cuando se implemente el primer flujo que sube fotos (probablemente F1.2 con la foto de portada).

## Cómo agregar un campo a una colección — checklist

Para no olvidarse de nada:

1. Actualizar `docs/05-modelo-datos-2.md` §2.2 con el campo nuevo (tipo, default, opcional/requerido)
2. Actualizar el modelo Dart en `app/lib/data/models/<colección>_model.dart`
3. Actualizar el repository en `app/lib/data/repositories/<colección>_repository.dart` para que serialize/deserialize el campo
4. Si el campo es requerido en `create`, actualizar la regla de `create` en `firestore.rules`
5. Si el campo afecta queries, evaluar si necesita índice en `firestore.indexes.json`
6. Si el campo es sensible (privacidad), documentar en PRD §4.5 o equivalente
7. Si la app tiene datos en producción, planificar migración (en MVP esto no aplica todavía)

## Lo que NO hacer

- No agregar campos al modelo sin actualizar el doc de modelo de datos primero.
- No deshabilitar reglas para "probar rápido" en producción. Para probar usar el emulador local de Firebase.
- No usar la consola de Firebase para crear índices fuera de versión.
- No agregar Cloud Functions sin discutir el caso.
- No agregar colecciones nuevas (notificaciones, logs, audit trail extra) — ver `docs/05-modelo-datos-2.md` §6 para lo que está deliberadamente fuera.

## Referencias rápidas

- Modelo de datos completo: `docs/05-modelo-datos-2.md`
- PRD §4.5 (datos sensibles): `docs/02-prd-inicial.md`
- Scope (qué NO va al MVP): `docs/03-mvp-scope.md` §4
