# Backlog MVP — Vamos (Caso 0)

> El backlog operativo vive en GitHub. Este archivo solo apunta a las fuentes de verdad.

## Fuentes de verdad

- **Project (vista trabajable):** https://github.com/users/julianjab/projects/1
- **Issues filtradas al MVP:** https://github.com/julianjab/travel-app/issues?q=is%3Aissue+milestone%3A%22MVP+Caso+0%22
- **Milestone:** [`MVP Caso 0`](https://github.com/julianjab/travel-app/milestone/1) — due 2026-06-12

## Convenciones

- **ID estable** en el título: `[E0-02]`, `[F1-03]`, `[F3-07]`, `[X-05]`. No renumerar.
- **Labels de épica:** `epic:setup`, `epic:F1`, `epic:F2`, `epic:F3`, `epic:cross`. Todos los items del MVP llevan además `mvp`.
- **Commits y PRs** referencian el ID en el mensaje (ej. `feat(F1-02): crear viaje persiste en firestore`) para que GitHub linkee solo.

## Épicas

| Épica | Foco | Issues |
|---|---|---|
| `epic:setup` (E0) | Firebase, auth, navegación shell | E0-01 a E0-08 |
| `epic:F1` | Crear viaje + invitar al grupo | F1-01 a F1-08 |
| `epic:F2` | Itinerario + votación | F2-01 a F2-08 |
| `epic:F3` | Gastos + saldos | F3-01 a F3-11 |
| `epic:cross` (X) | Rules, índices, errores, releases | X-01 a X-08 |

## Cómo agregar items nuevos

1. Crear issue en `julianjab/travel-app` con título `[<ID>] <Descripción>`.
2. Aplicar labels `mvp` + la épica que toque.
3. Asociar al milestone `MVP Caso 0`.
4. Agregar al Project `Vamos MVP`.

Si el item está fuera del MVP (lista en `docs/03-mvp-scope.md` §4), no usar label `mvp`. Va a otro milestone (`v1.1+`) cuando exista.

## Próximo paso

Atacar **E0-02 → E0-06** en una sesión: proyecto Firebase + auth + shell de navegación. Sin eso, el resto es teoría.
